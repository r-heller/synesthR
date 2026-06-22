#' Launch the synesthR demo Shiny app
#'
#' Opens an interactive demo: paste text, choose a language, and see the
#' generated image, palette, and hear the audio. The optional LLM interpretation
#' panel activates only when an \pkg{ellmer} backend is reachable. Requires
#' \pkg{shiny}.
#'
#' @param ... Passed to [shiny::runApp()].
#' @return Invisibly `NULL`; called for its side effect of launching the app.
#' @family app functions
#' @examplesIf interactive()
#' syn_run_app()
#' @export
syn_run_app <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.fn syn_run_app} requires the {.pkg shiny} package.",
      "i" = "Install it with {.code install.packages(\"shiny\")}."
    ))
  }
  app_dir <- system.file("shiny", "synesthR", package = "synesthR")
  if (!nzchar(app_dir)) {
    cli::cli_abort("Could not locate the bundled Shiny app.")
  }
  shiny::runApp(app_dir, ...)
  invisible(NULL)
}
