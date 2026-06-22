# Arc smoothing window as a fraction of sentence count (documented constant).
# Revisited in the final audit; fixed here so the score is reproducible.
.ARC_WINDOW_FRAC <- 0.25

# Map a synesthR language code to a syuzhet NRC language name.
.SYUZHET_LANG <- c(de = "german", en = "english", fr = "french")

#' Score literary text into a prosody_score
#'
#' Extracts per-sentence linguistic features (valence, length, lexical
#' diversity, punctuation density) and a global emotional arc from text read by
#' [syn_read_text()], returning a `prosody_score` object that drives both
#' [syn_paint()] and [syn_play()]. The result is deterministic: the same text
#' and `seed` always yield an identical score.
#'
#' @param text A tibble from [syn_read_text()].
#' @param seed Integer seed stored on the score for reproducible downstream
#'   mapping and rendering. Default `1L`.
#' @param call The calling environment, for error reporting. Experts only.
#' @return A `prosody_score` object: a list with `features` (a per-sentence
#'   tibble of `sentence_id`, `sentence`, `valence`, `length`, `lex_diversity`,
#'   `punct_density`), `arc` (smoothed valence trajectory), `lang`, `seed`, and
#'   `meta`.
#' @family scoring functions
#' @seealso [syn_read_text()] for input, [syn_paint()] and [syn_play()] for output.
#' @examples
#' txt <- syn_read_text(syn_example_text("en"), lang = "en")
#' syn_score(txt)
#' @export
syn_score <- function(text, seed = 1L, call = rlang::caller_env()) {
  if (!is.data.frame(text) || !all(c("sentence_id", "sentence") %in% names(text))) {
    cli::cli_abort(
      c("{.arg text} must be a tibble from {.fn syn_read_text}.",
        "i" = "It needs {.field sentence_id} and {.field sentence} columns."),
      call = call
    )
  }
  seed <- as.integer(.check_choice_int(seed, call = call))
  lang <- attr(text, "lang") %||% (if ("lang" %in% names(text)) text$lang[1] else NA_character_)

  # Empty input -> empty, type-stable score.
  if (nrow(text) == 0L) {
    features <- tibble::tibble(
      sentence_id = integer(), sentence = character(), valence = numeric(),
      length = integer(), lex_diversity = numeric(), punct_density = numeric()
    )
    return(validate_prosody_score(
      new_prosody_score(features, numeric(), lang, seed, list(n = 0L)), call = call
    ))
  }

  sentences <- text$sentence
  valence <- .valence(sentences, lang)
  features <- tibble::tibble(
    sentence_id   = as.integer(text$sentence_id),
    sentence      = sentences,
    valence       = valence,
    length        = .word_counts(sentences),
    lex_diversity = vapply(sentences, .lexical_diversity, numeric(1), USE.NAMES = FALSE),
    punct_density = vapply(sentences, .punct_density, numeric(1), USE.NAMES = FALSE)
  )
  arc <- .smooth_arc(valence)

  validate_prosody_score(
    new_prosody_score(features, arc, lang, seed,
                      meta = list(n = nrow(features), arc_window_frac = .ARC_WINDOW_FRAC)),
    call = call
  )
}

# Coerce/validate an integer-ish scalar seed.
.check_choice_int <- function(x, call = rlang::caller_env()) {
  if (length(x) != 1L || is.na(x) || !is.numeric(x)) {
    cli::cli_abort("{.arg seed} must be a single integer.", call = call)
  }
  x
}

# Per-sentence NRC valence, language-aware and deterministic.
.valence <- function(sentences, lang) {
  language <- unname(.SYUZHET_LANG[lang %||% "en"])
  if (is.na(language)) language <- "english"
  as.numeric(syuzhet::get_sentiment(sentences, method = "nrc", language = language))
}

# Word counts per sentence (integer, type-stable on empty).
.word_counts <- function(sentences) {
  if (length(sentences) == 0L) return(integer())
  as.integer(tokenizers::count_words(sentences))
}

# Type-token ratio for one sentence.
.lexical_diversity <- function(sentence) {
  words <- tokenizers::tokenize_words(sentence)[[1]]
  if (length(words) == 0L) return(0)
  length(unique(words)) / length(words)
}

# Punctuation characters / total characters for one sentence.
.punct_density <- function(sentence) {
  n <- nchar(sentence)
  if (is.na(n) || n == 0L) return(0)
  m <- gregexpr("[[:punct:]]", sentence)[[1]]
  n_punct <- if (length(m) == 1L && m[1] == -1L) 0L else length(m)
  n_punct / n
}

# Centered rolling-mean smoothing of the valence trajectory.
.smooth_arc <- function(valence) {
  n <- length(valence)
  if (n == 0L) return(numeric())
  if (n == 1L) return(as.numeric(valence))
  w <- max(1L, round(n * .ARC_WINDOW_FRAC))
  if (w %% 2L == 0L) w <- w + 1L
  half <- (w - 1L) %/% 2L
  vapply(seq_len(n), function(i) {
    lo <- max(1L, i - half)
    hi <- min(n, i + half)
    mean(valence[lo:hi])
  }, numeric(1))
}
