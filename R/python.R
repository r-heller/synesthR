# ---------------------------------------------------------------------------
# OPTIONAL RIM EXTENSION: Python interop via {reticulate}.
#
# Strictly optional enrichment. Python output may AUGMENT a prosody_score (in a
# clearly-named, separate `enrichment` slot) but never ALTER the deterministic
# core features or the mapping used for the reproducibility snapshot. The core
# never calls this file. Guarded by the rim helper .check_pymod() (R/rim.R).
# Exemplar uses only a light, well-behaved module (numpy).
# ---------------------------------------------------------------------------

#' Enrich a prosody_score with optional Python-computed features
#'
#' If \pkg{reticulate} and \pkg{numpy} are available, computes auxiliary
#' dynamics of the valence series (gradient and cumulative trajectory) in
#' Python and attaches them to the score's `enrichment` slot. The deterministic
#' core features, arc, and mapping are left untouched — enrichment is additive
#' and never feeds the reproducibility snapshot.
#'
#' @param score A `prosody_score` from [syn_score()].
#' @param call The calling environment, for error reporting. Experts only.
#' @return The `score` with `score$enrichment$py_features` added (a tibble of
#'   `sentence_id`, `valence_gradient`, `valence_cumulative`). Requires
#'   \pkg{reticulate} + Python \pkg{numpy}.
#' @family assist functions
#' @export
syn_py_features <- function(score, call = rlang::caller_env()) {
  .check_class(score, "prosody_score", call = call)
  .check_pymod("numpy", call = call)

  py_file <- system.file("python", "features.py", package = "synesthR")
  env <- new.env(parent = emptyenv())
  reticulate::source_python(py_file, envir = env)
  res <- env$valence_dynamics(score$features$valence)

  enr <- tibble::tibble(
    sentence_id        = score$features$sentence_id,
    valence_gradient   = as.numeric(res$gradient),
    valence_cumulative = as.numeric(res$cumulative)
  )
  score$enrichment <- utils::modifyList(
    score$enrichment %||% list(), list(py_features = enr)
  )
  score
}
