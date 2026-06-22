#' Read literary text into a tidy tibble
#'
#' Accepts a character string, a path to a text file, or a tibble with a text
#' column, and returns a tidy one-row-per-sentence tibble ready for scoring.
#' The language is auto-detected with the \pkg{cld3} package when available;
#' otherwise the `lang` argument is required.
#'
#' @param x A single character string, a character vector, a path to an
#'   existing `.txt` file, or a tibble/data frame containing a text column.
#' @param lang Language code, one of `"de"`, `"en"`, `"fr"`. If `NULL` (the
#'   default), the language is auto-detected via \pkg{cld3}. If \pkg{cld3} is
#'   not installed and `lang` is `NULL`, an error is raised.
#' @param text_col When `x` is a tibble, the name of the column holding text.
#' @param call The calling environment, for error reporting. Experts only.
#'
#' @return A [tibble::tibble()] with columns `sentence_id` (integer),
#'   `sentence` (character), and `lang` (character), plus a `lang` attribute.
#'   Empty input returns a zero-row tibble of the same type.
#' @family reading functions
#' @seealso [syn_score()] for the next step.
#' @examples
#' syn_read_text("A short tale. It has two sentences.", lang = "en")
#' @export
syn_read_text <- function(x, lang = NULL, text_col = "text",
                          call = rlang::caller_env()) {
  text <- .as_text(x, text_col = text_col, call = call)
  full <- paste(text, collapse = " ")

  # Empty / whitespace-only input: type-stable empty tibble.
  if (length(text) == 0L || !nzchar(trimws(full))) {
    resolved <- if (is.null(lang)) NA_character_ else .check_choice(lang, c("de", "en", "fr"), call = call)
    return(.new_text_tbl(integer(), character(), resolved))
  }

  resolved <- .detect_lang(full, lang, call = call)
  sentences <- tokenizers::tokenize_sentences(full)[[1]]
  sentences <- trimws(sentences)
  sentences <- sentences[nzchar(sentences)]

  .new_text_tbl(seq_along(sentences), sentences, resolved)
}

# Build the canonical text tibble with its `lang` attribute.
.new_text_tbl <- function(ids, sentences, lang) {
  out <- tibble::tibble(
    sentence_id = as.integer(ids),
    sentence = as.character(sentences),
    lang = rep(lang, length.out = length(sentences))
  )
  attr(out, "lang") <- lang
  out
}

# Internal: coerce supported inputs to a character vector of text.
.as_text <- function(x, text_col = "text", call = rlang::caller_env()) {
  if (is.data.frame(x)) {
    if (!text_col %in% names(x)) {
      cli::cli_abort(
        c("Column {.val {text_col}} not found in the supplied data frame.",
          "i" = "Pass {.arg text_col} to name the text column."),
        call = call
      )
    }
    return(as.character(x[[text_col]]))
  }
  if (is.character(x)) {
    if (length(x) == 1L && !is.na(x) && nzchar(x) &&
        file.exists(x) && !dir.exists(x)) {
      return(readLines(x, warn = FALSE, encoding = "UTF-8"))
    }
    return(x)
  }
  cli::cli_abort(
    c("{.arg x} must be a string, a file path, or a data frame.",
      "x" = "You supplied {.obj_type_friendly {x}}."),
    call = call
  )
}

# Internal: resolve language, auto-detect if cld3 available, else require `lang`.
.detect_lang <- function(text, lang = NULL, call = rlang::caller_env()) {
  if (!is.null(lang)) {
    return(.check_choice(lang, c("de", "en", "fr"), call = call))
  }
  if (!requireNamespace("cld3", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "Cannot auto-detect language: package {.pkg cld3} is not installed.",
        "i" = "Install {.pkg cld3}, or pass {.arg lang} explicitly ({.val de}, {.val en}, or {.val fr})."
      ),
      call = call
    )
  }
  detected <- cld3::detect_language(text)
  if (length(detected) != 1L || is.na(detected) ||
      !detected %in% c("de", "en", "fr")) {
    cli::cli_warn(c(
      "Detected language {.val {detected}} is outside the supported set ({.val de}, {.val en}, {.val fr}).",
      "i" = "Falling back to {.val en}. Pass {.arg lang} to override."
    ))
    detected <- "en"
  }
  detected
}

#' Bundled example passages
#'
#' Returns a short public-domain-style passage in the requested language, useful
#' for examples and quick experiments.
#'
#' @param lang Language code, one of `"en"`, `"de"`, `"fr"`.
#' @return A single character string.
#' @family reading functions
#' @examples
#' syn_example_text("en")
#' @export
syn_example_text <- function(lang = c("en", "de", "fr")) {
  lang <- match.arg(lang)
  path <- system.file("extdata", paste0("sample_", lang, ".txt"),
                      package = "synesthR")
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = " ")
}
