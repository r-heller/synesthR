# STEP D: a patchwork "workflow" banner for the README / pkgdown home —
# text -> score -> paint / play / palette, all from one shared score.
# Branded piece: a fixed Hugo-Coder-inspired BLUE palette and a fully
# TRANSPARENT background (so it sits on the light/dark site theme), rather than
# the green a cool example text would deterministically produce.
suppressMessages({ library(ggplot2); library(patchwork); pkgload::load_all(".", quiet = TRUE) })

text  <- syn_read_text(syn_example_text("en"), lang = "en")
score <- syn_score(text)

# --- Hugo Coder-flavoured blue ramp (indigo -> blue -> cyan, suite-purple nod) ---
ramp   <- c("#312E81", "#4338CA", "#2563EB", "#0EA5E9", "#22D3EE")  # low -> high value
ink    <- "#6366F1"   # titles/body: mid indigo, readable on white AND dark
accent <- "#2563EB"   # lines
spark  <- "#22D3EE"   # points / highlights
sub    <- "#60A5FA"   # subtitle

# transparent theme shared by all panels
clear <- theme(
  plot.background  = element_rect(fill = NA, colour = NA),
  panel.background = element_rect(fill = NA, colour = NA),
  legend.background = element_rect(fill = NA, colour = NA),
  panel.grid = element_blank(),
  axis.text = element_blank(), axis.ticks = element_blank(),
  axis.title = element_blank(),
  text = element_text(colour = ink)
)
titled <- function(p, lab)
  p + labs(title = lab) +
    theme(plot.title = element_text(face = "bold", size = 13, colour = ink))

# A — input text card (package's own example text)
sample_txt <- paste(strwrap(paste(score$features$sentence[1:2], collapse = " "),
                            width = 34), collapse = "\n")
A <- titled(ggplot() +
  annotate("text", x = 0, y = 0, label = sample_txt, colour = ink,
           size = 3.4, lineheight = 1.15) +
  xlim(-1, 1) + ylim(-1, 1) + theme_void() + clear, "1 · text")

# B — score, as its sentiment arc
arc_df <- data.frame(i = seq_along(score$arc), arc = score$arc)
B <- titled(ggplot(arc_df, aes(i, arc)) +
  geom_hline(yintercept = 0, colour = ramp[2], linewidth = 0.3) +
  geom_line(colour = accent, linewidth = 1.2) +
  geom_point(colour = spark, size = 2) +
  theme_minimal(base_size = 12) + clear, "2 · score")

# C — paint (hero): reuse syn_paint, then swap its gradient + go transparent
C <- titled(syn_paint(score) +
  scale_colour_gradientn(colours = ramp) +
  labs(title = NULL, subtitle = NULL, x = NULL, y = NULL) +
  clear, "3 · paint")

# D — play, as the waveform
w <- syn_play(score); samp <- w@left / 32767
idx <- round(seq(1, length(samp), length.out = 1500))
D <- titled(ggplot(data.frame(t = idx, a = samp[idx]), aes(t, a)) +
  geom_line(colour = accent, linewidth = 0.3) +
  theme_minimal(base_size = 12) + clear, "4 · play")

# E — palette swatch (the new blue ramp)
E <- titled(ggplot(data.frame(i = seq_along(ramp), col = ramp), aes(i, 1, fill = col)) +
  geom_tile(width = 0.95) + scale_fill_identity() +
  theme_void() + clear, "palette + theme")

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
      plot.subtitle = element_text(size = 11, colour = sub),
      plot.background = element_rect(fill = NA, colour = NA))
  )

ggsave("man/figures/README-workflow.png", banner, width = 11, height = 6.2,
       dpi = 150, bg = "transparent")
info <- magick::image_info(magick::image_read("man/figures/README-workflow.png"))
cat(sprintf("WROTE README-workflow.png  %dx%d  alpha=%s\n",
            info$width, info$height, info$matte))
