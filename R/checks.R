# Internal input validators shared across the package.
#
# Each validator returns the value invisibly on success and raises a
# {cli} error on failure. They take `arg` (the caller's argument name,
# resolved automatically) and `call` (the caller's environment) so that
# error messages point at the user's call site, not at the validator.

# Single non-NA, non-empty character scalar.
.check_string <- function(x,
                          arg = rlang::caller_arg(x),
                          call = rlang::caller_env()) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be a single non-missing string, not {.obj_type_friendly {x}}.",
      call = call
    )
  }
  invisible(x)
}

# Single non-NA logical scalar.
.check_flag <- function(x,
                        arg = rlang::caller_arg(x),
                        call = rlang::caller_env()) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be a single {.code TRUE} or {.code FALSE}, not {.obj_type_friendly {x}}.",
      call = call
    )
  }
  invisible(x)
}

# Object inheriting from class `cls`.
.check_class <- function(x, cls,
                         arg = rlang::caller_arg(x),
                         call = rlang::caller_env()) {
  if (!inherits(x, cls)) {
    cli::cli_abort(
      "{.arg {arg}} must be a {.cls {cls}} object, not {.obj_type_friendly {x}}.",
      call = call
    )
  }
  invisible(x)
}

# Fixed-choice string argument; wraps match.arg() with a {cli} error.
.check_choice <- function(x, choices,
                          arg = rlang::caller_arg(x),
                          call = rlang::caller_env()) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !x %in% choices) {
    cli::cli_abort(
      c("{.arg {arg}} must be one of {.or {.val {choices}}}.",
        "x" = "You supplied {.val {x}}."),
      call = call
    )
  }
  invisible(match.arg(x, choices))
}
