# ---------------------------------------------------------------------------
# OPTIONAL ASSISTIVE LAYER (rim extension: local LLM).
#
# Nothing in the deterministic core (syn_score / syn_paint / syn_play /
# syn_palette / .map_params) may call anything in this file. These functions
# orchestrate a local LLM through the {ellmer} package (provider-agnostic; the
# default path is a local Ollama model, fully offline, no API key). They are
# non-deterministic, advisory, and degrade gracefully when the backend is
# unavailable. They assist the workflow; they are never part of the mapping.
#
# All entry points reuse the rim guard .check_client() (see R/rim.R) rather
# than hand-rolling a connection check.
# ---------------------------------------------------------------------------

.DEFAULT_LLM_MODEL <- "mistral-small"

# Construct a local-Ollama chat via ellmer, guarded by the rim client check.
# The probe both confirms {ellmer} is installed and that a chat object can be
# constructed (which reaches the local server).
.ollama_chat <- function(model, call = rlang::caller_env()) {
  .check_client(
    "ellmer",
    probe = function() {
      ellmer::chat_ollama(model = model)
      TRUE
    },
    call = call
  )
  ellmer::chat_ollama(model = model)
}

# Build a compact, source-free brief of the score's features for the model.
# Deliberately sends features (not the raw text) so the assist layer can never
# leak or alter the analysed source.
.feature_brief <- function(score) {
  s <- summary(score)
  m <- .map_params(score)$music
  v <- .map_params(score)$visual
  paste(
    "You are interpreting a synesthR prosody analysis of a literary passage.",
    "Do not ask for the source text; reason only from these features.",
    sprintf("Language: %s. Sentences: %d.", s$lang %||% "?", s$n_sentences),
    sprintf("Mean valence: %.3f (range %.3f).", s$mean_valence, s$valence_range),
    sprintf("Emotional arc: from %.3f to %.3f.", s$arc_start, s$arc_end),
    sprintf("Mean sentence length: %.1f words; lexical diversity: %.3f.",
            s$mean_length, s$mean_lex_div),
    sprintf("Mapped music: key %s %s, tempo %d BPM%s.",
            m$key, m$mode, m$tempo_bpm, if (m$staccato) ", staccato" else ""),
    sprintf("Mapped palette temperature: %.3f (%s).",
            v$temperature, if (v$temperature > 0) "warm" else "cool"),
    sep = "\n"
  )
}

#' Interpret a prosody_score in prose using a local LLM
#'
#' Sends a compact, source-free summary of the score's features to a local LLM
#' (via \pkg{ellmer}'s Ollama backend) and returns a short prose "reading" of
#' why the image and music turned out as they did. Optional, non-deterministic,
#' and never part of the core mapping.
#'
#' @param score A `prosody_score` from [syn_score()].
#' @param model Model name. Default `"mistral-small"` (local Ollama).
#' @param ... Passed to the underlying \pkg{ellmer} chat call.
#' @param call The calling environment, for error reporting. Experts only.
#' @return A character string. Requires \pkg{ellmer} and a reachable backend.
#' @family assist functions
#' @export
syn_interpret <- function(score, model = .DEFAULT_LLM_MODEL, ...,
                          call = rlang::caller_env()) {
  .check_class(score, "prosody_score", call = call)
  chat <- .ollama_chat(model, call = call)
  chat$chat(.feature_brief(score), ...)
}

#' Suggest palette or tempo tweaks via a local LLM (advisory only)
#'
#' Returns a suggested adjustment as data the user may choose to apply. It never
#' mutates the score or auto-applies changes, preserving reproducibility. Any
#' malformed model response falls back to an empty (no-op) suggestion rather
#' than flowing unchecked into the deterministic parameters.
#'
#' @param score A `prosody_score`.
#' @param target One of `"palette"` or `"tempo"`.
#' @param model Model name. Default `"mistral-small"`.
#' @param ... Passed to the underlying \pkg{ellmer} chat call.
#' @param call The calling environment, for error reporting. Experts only.
#' @return A list with `target`, `suggestion` (advisory text or `NA`), and
#'   `applied = FALSE`. Requires \pkg{ellmer} + a reachable backend.
#' @family assist functions
#' @export
syn_suggest <- function(score, target = c("palette", "tempo"),
                        model = .DEFAULT_LLM_MODEL, ...,
                        call = rlang::caller_env()) {
  target <- match.arg(target)
  .check_class(score, "prosody_score", call = call)
  chat <- .ollama_chat(model, call = call)
  prompt <- paste0(
    .feature_brief(score),
    sprintf("\n\nSuggest one concrete %s adjustment and why, in 2-3 sentences. ",
            target),
    "This is advisory only; do not assume it will be applied."
  )
  suggestion <- tryCatch(chat$chat(prompt, ...), error = function(e) NA_character_)
  list(target = target, suggestion = suggestion, applied = FALSE)
}

#' Summarise or condense long text before scoring (opt-in, mutates input)
#'
#' For very long inputs, condense to a representative passage using a local LLM
#' before [syn_score()]. Opt-in because it changes the text being analysed.
#'
#' @param text A tibble from [syn_read_text()].
#' @param model Model name. Default `"mistral-small"`.
#' @param ... Passed to the underlying \pkg{ellmer} chat call.
#' @param call The calling environment, for error reporting. Experts only.
#' @return A tibble in the same shape as [syn_read_text()] output. Requires
#'   \pkg{ellmer} + a reachable backend.
#' @family assist functions
#' @export
syn_llm_condense <- function(text, model = .DEFAULT_LLM_MODEL, ...,
                             call = rlang::caller_env()) {
  if (!is.data.frame(text) || !"sentence" %in% names(text)) {
    cli::cli_abort(
      "{.arg text} must be a tibble from {.fn syn_read_text}.", call = call
    )
  }
  chat <- .ollama_chat(model, call = call)
  full <- paste(text$sentence, collapse = " ")
  condensed <- chat$chat(
    paste0("Condense the following passage to a shorter, representative ",
           "passage that preserves its tone and arc:\n\n", full),
    ...
  )
  syn_read_text(condensed, lang = attr(text, "lang"))
}
