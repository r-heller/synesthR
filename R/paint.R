#' Render a prosody_score as a generative still image
#'
#' Builds a generative \pkg{ggplot2} composition from the deterministic visual
#' parameters mapped from the score. The element cloud, colours, and theme are
#' all derived from the same score that drives [syn_play()], so the picture and
#' the music are two views of one analysis. The object is returned, never
#' printed.
#'
#' @param score A `prosody_score` from [syn_score()].
#' @param ... Reserved for future use; must be empty.
#' @return A \pkg{ggplot2} object.
#' @family rendering functions
#' @seealso [syn_play()] for the audio view, [syn_animate()] for animation.
#' @examples
#' p <- syn_paint(syn_score(syn_read_text(syn_example_text("en"), lang = "en")))
#' @export
syn_paint <- function(score, ...) {
  rlang::check_dots_empty()
  .check_class(score, "prosody_score")
  v <- .map_params(score)$visual
  pal <- syn_palette(score)
  el <- v$elements

  if (nrow(el) == 0L) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 0, y = 0, label = "(empty score)",
                        colour = pal$colors[length(pal$colors)])
  } else {
    p <- ggplot2::ggplot(el, ggplot2::aes(x = .data$x, y = .data$y)) +
      ggplot2::geom_point(
        ggplot2::aes(size = .data$size, colour = .data$value, alpha = .data$value)
      ) +
      ggplot2::scale_colour_gradientn(colours = pal$colors) +
      ggplot2::scale_size_continuous(range = c(1, 12)) +
      ggplot2::scale_alpha_continuous(range = c(0.4, 0.95)) +
      ggplot2::guides(size = "none", alpha = "none", colour = "none") +
      ggplot2::coord_fixed()
  }

  p +
    syn_theme(pal) +
    ggplot2::labs(
      title = "synesthR",
      subtitle = sprintf("%s \u00b7 %s \u00b7 arc %s",
                         score$lang %||% "?", pal$mode, v$gradient_direction),
      x = NULL, y = NULL
    ) +
    ggplot2::theme(
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank()
    )
}

#' Render an evolving animation across the text's arc (optional)
#'
#' Animates the element cloud across the narrative, revealing it sentence by
#' sentence so the emotional arc unfolds in time. Requires \pkg{gganimate}.
#'
#' @param score A `prosody_score` from [syn_score()].
#' @param ... Passed to [gganimate::transition_states()].
#' @return A \pkg{gganimate} animation object. Requires \pkg{gganimate}.
#' @family rendering functions
#' @export
syn_animate <- function(score, ...) {
  .check_class(score, "prosody_score")
  if (!requireNamespace("gganimate", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.fn syn_animate} requires the {.pkg gganimate} package.",
      "i" = "Install it, or use {.fn syn_paint} for a still image."
    ))
  }
  v <- .map_params(score)$visual
  el <- v$elements
  if (nrow(el) == 0L) {
    cli::cli_abort("Cannot animate an empty score.")
  }
  pal <- syn_palette(score)
  ggplot2::ggplot(el, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_point(
      ggplot2::aes(size = .data$size, colour = .data$value, alpha = .data$value)
    ) +
    ggplot2::scale_colour_gradientn(colours = pal$colors) +
    ggplot2::scale_size_continuous(range = c(1, 12)) +
    ggplot2::guides(size = "none", alpha = "none", colour = "none") +
    ggplot2::coord_fixed() +
    syn_theme(pal) +
    ggplot2::labs(title = "synesthR", x = NULL, y = NULL) +
    gganimate::transition_states(.data$sentence_id, ...) +
    gganimate::shadow_mark(past = TRUE, alpha = 0.3)
}
