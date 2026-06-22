# ---------------------------------------------------------------------------
# THE ORCHESTRATION RIM — safety harness.
#
# These internal helpers are the ONE reusable pattern every optional
# external-tool extension (LLM, Python, CLI tools) uses to detect and invoke
# software that may or may not exist on the user's machine. They never bundle
# or hard-depend on anything: a missing tool yields an informative {cli} abort
# with install guidance, never a core failure.
#
# Hard rule: the deterministic core (read -> score -> map -> paint/play/
# palette/media) NEVER calls anything in this file. The rim may call the core;
# the core never calls the rim. One-directional, absolute. (Enforced by a test
# in test-rim.R.)
# ---------------------------------------------------------------------------

# Detect a command-line tool on the PATH. Absent -> informative abort.
# Present -> the resolved absolute path.
.check_tool <- function(bin, install_hint = NULL, call = rlang::caller_env()) {
  .check_string(bin, call = call)
  path <- unname(Sys.which(bin))
  if (!nzchar(path)) {
    msg <- "Required command-line tool {.val {bin}} was not found on the {.envvar PATH}."
    if (!is.null(install_hint)) msg <- c(msg, "i" = install_hint)
    msg <- c(msg, "i" = "This is optional; the core {.pkg synesthR} workflow does not need it.")
    cli::cli_abort(msg, call = call)
  }
  path
}

# Verify a Python module is importable via reticulate. Absent reticulate OR
# module -> clean abort.
.check_pymod <- function(module, call = rlang::caller_env()) {
  .check_string(module, call = call)
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    cli::cli_abort(c(
      "Python interop requires the {.pkg reticulate} package.",
      "i" = "Install it with {.code install.packages(\"reticulate\")}.",
      "i" = "This is optional; the core {.pkg synesthR} workflow does not need it."
    ), call = call)
  }
  if (!reticulate::py_module_available(module)) {
    cli::cli_abort(c(
      "Python module {.val {module}} is not available to {.pkg reticulate}.",
      "i" = "Install it, e.g. {.code reticulate::py_require(\"{module}\")}."
    ), call = call)
  }
  invisible(TRUE)
}

# Verify a client package is installed AND (optionally) its backend is
# reachable via a user-supplied probe closure. Either failing -> clean abort.
.check_client <- function(pkg, probe = NULL, call = rlang::caller_env()) {
  .check_string(pkg, call = call)
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cli::cli_abort(c(
      "This feature requires the {.pkg {pkg}} package.",
      "i" = "Install it with {.code install.packages(\"{pkg}\")}.",
      "i" = "This is optional; the core {.pkg synesthR} workflow does not need it."
    ), call = call)
  }
  if (!is.null(probe)) {
    ok <- tryCatch(isTRUE(probe()), error = function(e) FALSE)
    if (!ok) {
      cli::cli_abort(c(
        "The {.pkg {pkg}} backend is installed but not reachable.",
        "i" = "Start the backend service and try again."
      ), call = call)
    }
  }
  invisible(TRUE)
}

# Run a command-line tool via system2(), capturing stdout/stderr. A non-zero
# exit status becomes an informative abort. Writes nothing outside tempdir().
.run_tool <- function(bin, args = character(), call = rlang::caller_env()) {
  path <- .check_tool(bin, call = call)
  out <- suppressWarnings(
    system2(path, args = args, stdout = TRUE, stderr = TRUE)
  )
  status <- attr(out, "status")
  if (!is.null(status) && status != 0L) {
    cli::cli_abort(c(
      "Command {.val {bin}} failed (exit status {status}).",
      "x" = paste(utils::head(out, 10L), collapse = "\n")
    ), call = call)
  }
  out
}
