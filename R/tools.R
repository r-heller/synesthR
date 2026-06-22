# ---------------------------------------------------------------------------
# OPTIONAL RIM EXTENSION: open-source CLI tools.
#
# Orchestrate command-line tools (e.g. ffmpeg) when present, via the rim
# helpers .check_tool() / .run_tool() (R/rim.R). No CLI tool is ever required;
# absent -> informative {cli} message. The core never calls this file. Per the
# agreed v0.1 scope, video export stays a documented, honest stub.
# ---------------------------------------------------------------------------

#' Export a synesthR piece as video (reserved for a future release)
#'
#' A documented stub that demonstrates the CLI-orchestration pattern: it probes
#' for the `ffmpeg` binary and reports status, but video export is intentionally
#' not enabled in this version. Use [syn_paint()] for a still image and
#' [syn_write_wav()] for audio.
#'
#' @param score A `prosody_score` from [syn_score()].
#' @param path Intended output path (unused in this version).
#' @param fps Frames per second for the future implementation. Default `12`.
#' @param call The calling environment, for error reporting. Experts only.
#' @return Never returns normally in this version: always aborts with guidance.
#' @family assist functions
#' @export
syn_export_video <- function(score, path, fps = 12, call = rlang::caller_env()) {
  .check_class(score, "prosody_score", call = call)
  ffmpeg <- tryCatch(
    .check_tool("ffmpeg",
                install_hint = "When enabled, install ffmpeg from {.url https://ffmpeg.org}."),
    error = function(e) NULL
  )
  status <- if (is.null(ffmpeg)) {
    "ffmpeg was not found; it will be required when this feature ships."
  } else {
    sprintf("ffmpeg was detected, but video export is not enabled in this version.")
  }
  cli::cli_abort(c(
    "{.fn syn_export_video} is reserved for a future {.pkg synesthR} release.",
    "i" = status,
    "i" = "For now use {.fn syn_paint} (still image) and {.fn syn_write_wav} (audio)."
  ), call = call)
}
