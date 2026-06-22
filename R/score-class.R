# Low-level constructor: trusted input, no validation. Internal.
new_prosody_score <- function(features = tibble::tibble(),
                              arc = numeric(),
                              lang = NA_character_,
                              seed = NA_integer_,
                              meta = list()) {
  stopifnot(is.data.frame(features), is.numeric(arc), is.list(meta))
  structure(
    list(features = features, arc = arc, lang = lang, seed = seed, meta = meta),
    class = "prosody_score"
  )
}

# Validator: checks invariants, returns the object or errors.
validate_prosody_score <- function(x, call = rlang::caller_env()) {
  required <- c("sentence_id", "valence", "length", "lex_diversity", "punct_density")
  missing <- setdiff(required, names(x$features))
  if (length(missing) > 0) {
    cli::cli_abort(
      c("Invalid {.cls prosody_score}: missing feature column{?s}.",
        "x" = "Missing: {.val {missing}}"),
      call = call
    )
  }
  x
}

#' Test whether an object is a prosody_score
#' @param x An object to test.
#' @return A logical scalar.
#' @export
is_prosody_score <- function(x) inherits(x, "prosody_score")

#' @export
print.prosody_score <- function(x, ...) {
  rlang::check_dots_empty()
  cli::cli_text(
    "{.cls prosody_score} \u2014 {nrow(x$features)} sentence{?s}, lang {.val {x$lang}}"
  )
  invisible(x)
}

#' @method summary prosody_score
#' @export
summary.prosody_score <- function(object, ...) {
  rlang::check_dots_empty()
  f <- object$features
  arc <- object$arc
  tibble::tibble(
    n_sentences       = nrow(f),
    lang              = object$lang,
    mean_valence      = if (nrow(f)) mean(f$valence) else NA_real_,
    valence_range     = if (nrow(f)) diff(range(f$valence)) else NA_real_,
    arc_start         = if (length(arc)) arc[1] else NA_real_,
    arc_end           = if (length(arc)) arc[length(arc)] else NA_real_,
    mean_length       = if (nrow(f)) mean(f$length) else NA_real_,
    mean_lex_div      = if (nrow(f)) mean(f$lex_diversity) else NA_real_,
    mean_punct_density = if (nrow(f)) mean(f$punct_density) else NA_real_
  )
}
