# The shared interchange currency for the suite: a thing + its type + metadata.
# Lets image / audio / text / score flow between functions and (eventually) the
# sibling packages through one predictable object. Video is reserved for a
# later release.

# Low-level constructor. Internal.
new_syn_media <- function(content = NULL,
                          type = NA_character_,
                          meta = list()) {
  stopifnot(is.list(meta))
  structure(list(content = content, type = type, meta = meta),
            class = "syn_media")
}

#' Wrap a media object in the suite interchange container
#'
#' Coerces a supported object into a `syn_media` object carrying its content,
#' a type tag (`"text"`, `"image"`, `"audio"`, `"score"`), and metadata. This
#' is the common currency that lets images, audio, text, and prosody scores be
#' passed freely between \pkg{synesthR} functions.
#'
#' @param x A character string/tibble (text), `magick-image` (image),
#'   [tuneR::Wave] (audio), or `prosody_score` (score).
#' @param ... Passed to methods.
#' @return A `syn_media` object.
#' @export
as_syn_media <- function(x, ...) {
  UseMethod("as_syn_media")
}

#' @rdname as_syn_media
#' @export
as_syn_media.syn_media <- function(x, ...) x

#' @rdname as_syn_media
#' @export
as_syn_media.prosody_score <- function(x, ...) {
  new_syn_media(content = x, type = "score", meta = list(lang = x$lang))
}

#' @rdname as_syn_media
#' @export
as_syn_media.character <- function(x, ...) {
  new_syn_media(content = x, type = "text")
}

#' @rdname as_syn_media
#' @export
as_syn_media.Wave <- function(x, ...) {
  new_syn_media(content = x, type = "audio",
                meta = list(sample_rate = x@samp.rate))
}

#' @rdname as_syn_media
#' @method as_syn_media magick-image
#' @export
`as_syn_media.magick-image` <- function(x, ...) {
  new_syn_media(content = x, type = "image")
}

#' @rdname as_syn_media
#' @method as_syn_media default
#' @export
as_syn_media.default <- function(x, ...) {
  cli::cli_abort(c(
    "Cannot coerce {.obj_type_friendly {x}} to a {.cls syn_media} object.",
    "i" = "Supported sources: text, image ({.pkg magick}), audio ({.cls Wave}), or a {.cls prosody_score}."
  ))
}

#' Test whether an object is a syn_media container
#' @param x An object to test.
#' @return A logical scalar.
#' @family media functions
#' @export
is_syn_media <- function(x) inherits(x, "syn_media")

#' Accessors for syn_media content and type
#'
#' @param x A `syn_media` object.
#' @return `media_type()` returns the type tag (`"text"`, `"image"`, `"audio"`,
#'   `"score"`); `media_content()` returns the wrapped object.
#' @family media functions
#' @examples
#' m <- as_syn_media("some text")
#' media_type(m)
#' @export
media_type <- function(x) {
  .check_class(x, "syn_media")
  x$type
}

#' @rdname media_type
#' @export
media_content <- function(x) {
  .check_class(x, "syn_media")
  x$content
}

#' @export
print.syn_media <- function(x, ...) {
  rlang::check_dots_empty()
  cli::cli_text("{.cls syn_media} of type {.val {x$type}}")
  if (length(x$meta) > 0) cli::cli_text("  meta: {.val {names(x$meta)}}")
  invisible(x)
}
