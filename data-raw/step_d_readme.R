# STEP D: a patchwork "workflow" banner for the README — text -> score ->
# paint / play / palette, all from one shared score. Uses the package's own
# bundled example text (not external literature).
suppressMessages({ library(ggplot2); library(patchwork); pkgload::load_all(".", quiet = TRUE) })

text  <- syn_read_text(syn_example_text("en"), lang = "en")
score <- syn_score(text)
pal   <- syn_palette(score)
ink   <- pal$colors[length(pal$colors)]
bg    <- pal$colors[1]

step_title <- function(p, lab) p + labs(title = lab) +
  theme(plot.title = element_text(face = "bold", size = 13, colour = ink),
        plot.background = element_rect(fill = bg, colour = NA),
        panel.background = element_rect(fill = bg, colour = NA))

# A — the input text (package's own example), as a card
sample_txt <- paste(score$features$sentence[1:2], collapse = " ")
sample_txt <- paste(strwrap(sample_txt, width = 34), collapse = "\n")
A <- ggplot() +
  annotate("text", x = 0, y = 0, label = sample_txt, colour = ink,
           size = 3.4, lineheight = 1.15, hjust = 0.5, vjust = 0.5) +
  xlim(-1, 1) + ylim(-1, 1) +
  syn_theme(pal) +
  theme(axis.text = element_blank(), panel.grid = element_blank(),
        axis.title = element_blank())
A <- step_title(A, "1 · text")

# B — the score, as its sentiment arc
arc_df <- data.frame(i = seq_along(score$arc), arc = score$arc)
B <- ggplot(arc_df, aes(i, arc)) +
  geom_hline(yintercept = 0, colour = pal$colors[3], linewidth = 0.3) +
  geom_line(colour = ink, linewidth = 1.2) +
  geom_point(colour = ink, size = 2) +
  labs(x = NULL, y = NULL) +
  syn_theme(pal) +
  theme(axis.text = element_blank(), panel.grid = element_blank())
B <- step_title(B, "2 · score")

# C — paint (the hero panel)
C <- step_title(syn_paint(score) + labs(title = NULL, subtitle = NULL), "3 · paint")

# D — play, as the waveform
w <- syn_play(score); samp <- w@left / 32767
idx <- round(seq(1, length(samp), length.out = 1500))
D <- ggplot(data.frame(t = idx, a = samp[idx]), aes(t, a)) +
  geom_line(colour = ink, linewidth = 0.3) +
  labs(x = NULL, y = NULL) +
  syn_theme(pal) +
  theme(axis.text = element_blank(), panel.grid = element_blank())
D <- step_title(D, "4 · play")

# E — palette swatch
E <- ggplot(data.frame(i = seq_along(pal$colors), col = pal$colors),
            aes(i, 1, fill = col)) +
  geom_tile(width = 0.95, colour = bg, linewidth = 1) +
  scale_fill_identity() +
  labs(x = NULL, y = NULL) +
  theme_void() +
  theme(plot.background = element_rect(fill = bg, colour = NA))
E <- step_title(E, "palette + theme")

design <- "
ACD
BCE
"
banner <- A + B + C + D + E +
  plot_layout(design = design, widths = c(1, 1.25, 1.25), heights = c(1, 1)) +
  plot_annotation(
    title = "synesthR · one shared score, rendered three ways",
    subtitle = "read → score → paint · play · palette  (deterministic given text + seed)",
    theme = theme(
      plot.title = element_text(face = "bold", size = 17, colour = ink),
      plot.subtitle = element_text(size = 11, colour = pal$colors[4]),
      plot.background = element_rect(fill = bg, colour = NA))
  )

ggsave("man/figures/README-workflow.png", banner, width = 11, height = 6.2,
       dpi = 150, bg = bg)
cat("WROTE man/figures/README-workflow.png", file.exists("man/figures/README-workflow.png"), "\n")
