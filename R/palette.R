# Low-level constructor for the palette object. Internal.
new_syn_palette <- function(colors = character(),
                            roles = character(),
                            mode = NA_character_,
                            temperature = NA_real_,
                            source = NA_character_) {
  stopifnot(is.character(colors), is.character(roles))
  structure(
    list(colors = colors, roles = roles, mode = mode,
         temperature = temperature, source = source),
    class = "syn_palette"
  )
}

# Build a luminance-ordered palette from a hue base + temperature + saturation.
.build_palette <- function(hue_base, temperature, saturation, richness,
                           n, source) {
  n <- max(2L, as.integer(n))
  hues   <- (hue_base + seq(-1, 1, length.out = n) * 40 * richness) %% 360
  chroma <- 30 + 50 * max(0, min(1, saturation))
  lums   <- seq(28, 92, length.out = n)
  cols   <- grDevices::hcl(h = hues, c = chroma, l = lums, fixup = TRUE)
  mode   <- if (temperature > 0.1) "warm" else if (temperature < -0.1) "cool" else "mixed"
  new_syn_palette(colors = cols, roles = .role_names(n), mode = mode,
                  temperature = round(temperature, 4), source = source)
}

# Role names ordered from darkest to lightest.
.role_names <- function(n) {
  base <- c("background", "shadow", "mid", "accent", "highlight")
  if (n <= length(base)) return(base[seq_len(n)])
  c(base, paste0("detail", seq_len(n - length(base))))
}

#' Extract a colour palette from any supported source
#'
#' A generic that derives a reproducible `syn_palette` from a prosody score, an
#' image, an audio waveform, or raw text. Each source type has its own method;
#' the result is always the same `syn_palette` object, so palettes are
#' interchangeable across the suite regardless of where they came from.
#'
#' @param x A source object: a `prosody_score`, a `magick-image`, a
#'   [tuneR::Wave], or a character string.
#' @param n Number of colours. Default `5L`.
#' @param ... Passed to methods.
#' @return A `syn_palette` object with `colors` (hex), `roles`, `mode`
#'   (`"warm"`/`"cool"`/`"mixed"`), `temperature` (-1 cool to 1 warm), and
#'   `source` (what it was extracted from).
#' @family palette functions
#' @examples
#' syn_palette(syn_score(syn_read_text("A bright warm day.", lang = "en")))
#' @export
syn_palette <- function(x, n = 5L, ...) {
  UseMethod("syn_palette")
}

#' @rdname syn_palette
#' @method syn_palette prosody_score
#' @export
syn_palette.prosody_score <- function(x, n = 5L, ...) {
  rlang::check_dots_empty()
  v <- .map_params(x)$visual
  .build_palette(v$hue_base, v$temperature, v$saturation, v$richness,
                 n = n, source = "prosody_score")
}

#' @rdname syn_palette
#' @param lang Language code passed through to [syn_read_text()] for the
#'   character method.
#' @method syn_palette character
#' @export
syn_palette.character <- function(x, n = 5L, lang = NULL, ...) {
  syn_palette(syn_score(syn_read_text(x, lang = lang)), n = n, ...)
}

#' @rdname syn_palette
#' @method syn_palette magick-image
#' @export
`syn_palette.magick-image` <- function(x, n = 5L, ...) {
  rlang::check_dots_empty()
  if (!requireNamespace("magick", quietly = TRUE)) {
    cli::cli_abort(c(
      "Extracting a palette from an image requires the {.pkg magick} package.",
      "i" = "Install it with {.code install.packages(\"magick\")}."
    ))
  }
  n <- max(2L, as.integer(n))
  img <- magick::image_convert(magick::image_resize(x, "120x120"), colorspace = "sRGB")
  d <- magick::image_data(img, channels = "rgb")
  rgb <- t(matrix(as.integer(d), nrow = 3)) / 255  # npix x 3
  lab <- grDevices::convertColor(rgb, from = "sRGB", to = "Lab")
  km <- .with_seed(1L, stats::kmeans(lab, centers = min(n, nrow(unique(lab))),
                                     iter.max = 30, nstart = 1))
  centers_rgb <- grDevices::convertColor(km$centers, from = "Lab", to = "sRGB")
  centers_rgb[] <- pmax(0, pmin(1, centers_rgb))
  cols <- grDevices::rgb(centers_rgb[, 1], centers_rgb[, 2], centers_rgb[, 3])
  lums <- km$centers[, 1]                    # L* channel
  ord <- order(lums)
  cols <- cols[ord]
  temp <- mean(2 * (rgb[, 1] - rgb[, 3]))    # red vs blue -> warmth
  mode <- if (temp > 0.05) "warm" else if (temp < -0.05) "cool" else "mixed"
  new_syn_palette(colors = cols, roles = .role_names(length(cols)),
                  mode = mode, temperature = round(temp, 4), source = "image")
}

#' @rdname syn_palette
#' @method syn_palette Wave
#' @export
syn_palette.Wave <- function(x, n = 5L, ...) {
  rlang::check_dots_empty()
  samp <- as.numeric(x@left)
  if (length(samp) < 2L) {
    return(.build_palette(210, 0, 0.5, 0.5, n = n, source = "audio"))
  }
  sr <- x@samp.rate
  centroid <- .spectral_centroid(samp, sr)
  brightness <- max(0, min(1, centroid / (sr / 2)))   # 0..1
  temperature <- 2 * brightness - 1                   # bright -> warm
  hue_base <- (220 - (temperature + 1) / 2 * 190) %% 360
  norm <- if (x@bit > 0) 2^(x@bit - 1) else max(abs(samp))
  if (norm == 0) norm <- 1
  energy <- sqrt(mean((samp / norm)^2))
  saturation <- max(0, min(1, energy * 4))
  .build_palette(hue_base, temperature, saturation, 0.6, n = n, source = "audio")
}

# Spectral centroid (Hz) via base FFT; no external dependency.
.spectral_centroid <- function(samp, sr) {
  samp <- samp - mean(samp)
  N <- length(samp)
  half <- N %/% 2
  if (half < 1L) return(0)
  mag <- Mod(stats::fft(samp))[seq_len(half)]
  freq <- (seq_len(half) - 1) * sr / N
  if (sum(mag) == 0) return(0)
  sum(freq * mag) / sum(mag)
}

#' Test whether an object is a syn_palette
#' @param x An object to test.
#' @return A logical scalar.
#' @family palette functions
#' @export
is_syn_palette <- function(x) inherits(x, "syn_palette")

#' @method print syn_palette
#' @export
print.syn_palette <- function(x, ...) {
  rlang::check_dots_empty()
  cli::cli_text(
    "{.cls syn_palette} - {length(x$colors)} colour{?s}, {x$mode}, from {x$source}"
  )
  for (i in seq_along(x$colors)) cli::cli_text("  {.val {x$colors[i]}}  {x$roles[i]}")
  invisible(x)
}

#' Build a ggplot2 theme from a palette or any palette source
#'
#' Maps a palette's luminance-ordered roles onto plot chrome: the darkest
#' colour becomes the background, the lightest the foreground text and lines.
#'
#' @param x A `syn_palette`, or any object [syn_palette()] accepts.
#' @param ... Passed to [ggplot2::theme()].
#' @return A \pkg{ggplot2} theme object (classes `theme`/`gg`).
#' @family palette functions
#' @examples
#' syn_theme(syn_palette(syn_score(syn_read_text("Calm sea.", lang = "en"))))
#' @export
syn_theme <- function(x, ...) {
  if (!inherits(x, "syn_palette")) x <- syn_palette(x)
  cols <- x$colors
  bg <- cols[1]
  fg <- cols[length(cols)]
  grid <- cols[max(1L, length(cols) %/% 2L)]
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.background  = ggplot2::element_rect(fill = bg, colour = NA),
      panel.background = ggplot2::element_rect(fill = bg, colour = NA),
      panel.grid       = ggplot2::element_line(colour = grid, linewidth = 0.2),
      text             = ggplot2::element_text(colour = fg),
      axis.text        = ggplot2::element_text(colour = fg),
      plot.title       = ggplot2::element_text(colour = fg, face = "bold"),
      ...
    )
}
