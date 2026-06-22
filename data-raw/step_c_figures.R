# STEP C: arcs + deep-emotion radar + PCA/UMAP/SONG dim-reduction figures.
# Reads only .rds/.txt from disk; writes only PNGs. No literary text printed.
suppressMessages({
  library(ggplot2); library(patchwork); pkgload::load_all(".", quiet = TRUE)
})
fig <- function(n) file.path("vignettes", "figures", n)
ok  <- function(p) cat(sprintf("WROTE %-22s %s\n", basename(p), file.exists(p)))
save_plot <- function(p, n, w, h, dpi = 150)
  { ggsave(fig(n), p, width = w, height = h, dpi = dpi, bg = "white"); ok(fig(n)) }

all <- readRDS("data-raw/features_all.rds")
all$author <- factor(all$author,
  levels = c("shakespeare", "goethe", "balzac"),
  labels = c("Shakespeare (en)", "Goethe (de)", "Balzac (fr)"))
auth_cols <- c("Shakespeare (en)" = "#B23A48",
               "Goethe (de)"      = "#2E7D46",
               "Balzac (fr)"      = "#2E5A88")
emos <- c("anger","anticipation","disgust","fear","joy","sadness","surprise","trust")

# ---- 1. Sentiment arcs (faceted) -----------------------------------------
p_arc <- ggplot(all, aes(sentence_id, arc, colour = author)) +
  geom_hline(yintercept = 0, colour = "grey80", linewidth = 0.3) +
  geom_line(linewidth = 0.9) +
  facet_wrap(~author, ncol = 1, scales = "free_y") +
  scale_colour_manual(values = auth_cols, guide = "none") +
  labs(title = "Sentiment arcs of the classics",
       subtitle = "smoothed valence across 120 consecutive sentences",
       x = "sentence", y = "valence (smoothed)") +
  theme_minimal(base_size = 12) +
  theme(strip.text = element_text(face = "bold"),
        plot.title = element_text(face = "bold"))
save_plot(p_arc, "classics-arcs.png", w = 7, h = 6)

# ---- 2. Deep NRC emotion radar (normalized profile per author) -----------
em <- aggregate(all[, emos], by = list(author = all$author), FUN = mean)
long <- reshape(em, varying = emos, v.names = "value", times = emos,
                timevar = "emotion", direction = "long")
# normalize within author so the German lexicon's lower coverage is comparable
long$prop <- ave(long$value, long$author, FUN = function(v) if (sum(v) > 0) v / sum(v) else v)
long$emotion <- factor(long$emotion, levels = emos)
p_emo <- ggplot(long, aes(emotion, prop, colour = author, group = author, fill = author)) +
  geom_polygon(alpha = 0.12, linewidth = 0.9) +
  geom_point(size = 2) +
  coord_polar() +
  scale_colour_manual(values = auth_cols) +
  scale_fill_manual(values = auth_cols) +
  labs(title = "Deep emotion profiles (NRC)",
       subtitle = "share of each author's total emotion signal",
       x = NULL, y = NULL, colour = NULL, fill = NULL) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        axis.text.y = element_blank(), panel.grid.minor = element_blank())
save_plot(p_emo, "classics-emotions.png", w = 7, h = 5)

# ---- 3. Dimensionality reduction: PCA / UMAP / SONG ----------------------
feat_cols <- c("valence","length","lex_diversity","punct_density","arc", emos)
M <- as.matrix(all[, feat_cols])
M <- M[, apply(M, 2, stats::sd) > 0, drop = FALSE]   # drop zero-variance cols
Xs <- scale(M)

# PCA
pca <- stats::prcomp(Xs)
ve  <- round(100 * pca$sdev^2 / sum(pca$sdev^2), 1)
pca_df <- data.frame(x = pca$x[, 1], y = pca$x[, 2], author = all$author)

# UMAP
set.seed(42)
um <- uwot::umap(Xs, n_neighbors = 18, min_dist = 0.25, n_components = 2)
um_df <- data.frame(x = um[, 1], y = um[, 2], author = all$author)

# SONG (songR) — quiet the epoch log
set.seed(42)
song_emb <- NULL
invisible(utils::capture.output(suppressMessages({
  sm <- songR::song(Xs)
  song_emb <- if (!is.null(sm$embedding)) sm$embedding else sm$Y
})))
song_df <- data.frame(x = song_emb[, 1], y = song_emb[, 2], author = all$author)
cat(sprintf("SONG embedding dims: %d x %d (rows match: %s)\n",
            nrow(song_emb), ncol(song_emb), nrow(song_emb) == nrow(all)))

dr_panel <- function(df, title, sub) {
  ggplot(df, aes(x, y, colour = author)) +
    geom_point(size = 2, alpha = 0.85) +
    scale_colour_manual(values = auth_cols) +
    labs(title = title, subtitle = sub, x = NULL, y = NULL, colour = NULL) +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold"),
          axis.text = element_blank(), panel.grid.minor = element_blank())
}
p_pca  <- dr_panel(pca_df,  "PCA",  sprintf("PC1 %.0f%% / PC2 %.0f%% var", ve[1], ve[2]))
p_umap <- dr_panel(um_df,   "UMAP", "uwot, 18 neighbours")
p_song <- dr_panel(song_df, "SONG", "songR::song()")
dr_all <- (p_pca | p_umap | p_song) +
  patchwork::plot_layout(guides = "collect") +
  patchwork::plot_annotation(
    title = "Three views of the same feature space",
    subtitle = "360 sentences (120 per author) in 13 prosody + emotion dimensions",
    theme = theme(plot.title = element_text(face = "bold", size = 14))) &
  theme(legend.position = "bottom")
save_plot(dr_all, "classics-dimreduction.png", w = 10, h = 4.4)

# ---- 4. Paint the three classics from their saved scores -----------------
for (a in c("shakespeare", "goethe", "balzac")) {
  sc <- readRDS(sprintf("data-raw/score_%s.rds", a))
  save_plot(syn_paint(sc), sprintf("classics-paint-%s.png", a), w = 5, h = 5)
}

cat(sprintf("\nPCA variance explained PC1..PC4: %s\n", paste(ve[1:4], collapse = " / ")))
cat("STEP C DONE\n")
