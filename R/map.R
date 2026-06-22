# ---------------------------------------------------------------------------
# THE MAPPING CORE. This is the conceptual heart of synesthR: a single,
# fully deterministic, seeded function from the prosody features to the
# visual and musical parameters that the renderers consume.
#
# The mapping (implemented faithfully below; aesthetic tuning is a later,
# snapshot-guarded pass):
#
#   Feature           -> Visual                         -> Musical
#   valence (mean)        colour temperature (warm/cool)   mode (major/minor)
#   valence arc shape     composition flow / gradient      melodic contour
#   sentence-length       element spacing / size variance  note durations
#   lexical diversity     palette richness / saturation    harmonic complexity
#   punctuation density   texture density / mark count     tempo + staccato
#   total length          canvas extent / element count    piece duration
#
# It performs no I/O, depends on no Suggests package, and uses RNG only via a
# locally scoped, restored seed taken from the score. The output is the
# package's reproducibility contract: the golden snapshots fix it exactly.
# ---------------------------------------------------------------------------

# Deterministic features -> visual + musical parameter lists.
.map_params <- function(score) {
  f <- score$features
  seed <- score$seed %||% 1L
  n <- nrow(f)

  if (n == 0L) {
    return(list(
      visual = list(
        temperature = 0, hue_base = 210, saturation = 0.5, richness = 0,
        n_elements = 0L, size_mean = 1, size_var = 0, spacing = 1,
        gradient_direction = "flat", arc = numeric(),
        elements = .empty_elements(), seed = seed
      ),
      music = list(
        key = "C", root = 60L, mode = "major", tempo_bpm = 90L,
        staccato = FALSE, harmonic_complexity = 0,
        notes = .empty_notes(), duration_sec = 0
      )
    ))
  }

  mean_val    <- mean(f$valence)
  temperature <- tanh(mean_val)                      # -1 (cool) .. 1 (warm)
  hue_base    <- (220 - (temperature + 1) / 2 * 190) %% 360  # cool ~220, warm ~30
  lex         <- mean(f$lex_diversity)
  punct       <- mean(f$punct_density)
  lengths     <- f$length
  total_length <- sum(lengths)
  arc         <- score$arc
  arc_norm    <- .rescale01(arc)
  size_var    <- stats::sd(lengths)
  if (is.na(size_var)) size_var <- 0
  slope <- arc[length(arc)] - arc[1]
  gradient_direction <- if (slope > 0) "up" else if (slope < 0) "down" else "flat"

  # ---------------------------- music ------------------------------------
  mode  <- if (mean_val >= 0) "major" else "minor"
  keys  <- c("C", "G", "D", "A", "E", "F", "Bb")
  roots <- c(C = 60L, G = 67L, D = 62L, A = 69L, E = 64L, F = 65L, Bb = 70L)
  key   <- keys[(seed %% length(keys)) + 1L]
  root  <- unname(roots[key])
  intervals <- if (mode == "major") c(0, 2, 4, 5, 7, 9, 11) else c(0, 2, 3, 5, 7, 8, 10)
  scale <- c(root + intervals, root + 12L + intervals)   # two octaves

  deg_idx  <- 1L + round(arc_norm * (length(scale) - 1L))   # contour follows arc
  pitch    <- as.integer(scale[deg_idx])
  len_norm <- .rescale01(lengths)
  duration <- round(0.5 + 1.5 * len_norm, 4)               # beats, from rhythm
  vmax     <- max(abs(f$valence)); if (vmax == 0) vmax <- 1
  velocity <- as.integer(round(50 + 70 * (abs(f$valence) / vmax)))
  notes <- tibble::tibble(
    sentence_id = as.integer(f$sentence_id),
    pitch = pitch, duration = duration, velocity = velocity
  )
  tempo_bpm <- as.integer(round(min(160, max(50, 70 + 600 * punct))))
  staccato  <- punct > 0.04
  harmonic_complexity <- round(lex, 4)
  duration_sec <- round(sum(duration) * 60 / tempo_bpm, 4)

  # ---------------------------- visual -----------------------------------
  n_elements <- as.integer(min(400L, max(12L, total_length)))
  elements <- .gen_elements(n_elements, f, arc_norm, hue_base, lex, size_var, seed)

  list(
    visual = list(
      temperature = round(temperature, 4),
      hue_base = round(hue_base, 2),
      saturation = round(0.35 + 0.5 * lex, 4),
      richness = round(lex, 4),
      n_elements = n_elements,
      size_mean = round(mean(lengths), 4),
      size_var = round(size_var, 4),
      spacing = round(1 / (1 + punct * 10), 4),
      gradient_direction = gradient_direction,
      arc = round(arc_norm, 4),
      elements = elements,
      seed = seed
    ),
    music = list(
      key = key, root = root, mode = mode, tempo_bpm = tempo_bpm,
      staccato = staccato, harmonic_complexity = harmonic_complexity,
      notes = notes, duration_sec = duration_sec
    )
  )
}

# Generate the deterministic visual element cloud (seeded, restored RNG).
.gen_elements <- function(n, f, arc_norm, hue_base, lex, size_var, seed) {
  nse <- nrow(f)
  sentidx <- 1L + floor((seq_len(n) - 1) / n * nse)
  scale_div <- max(f$length) + 1
  .with_seed(seed, {
    x   <- stats::runif(n)
    y   <- stats::runif(n)
    hue <- (hue_base + stats::runif(n, -1, 1) * 60 * lex) %% 360
    size <- pmax(0.2, stats::rnorm(n, 1, size_var / scale_div))
    tibble::tibble(
      x = round(x, 4), y = round(y, 4),
      sentence_id = as.integer(f$sentence_id[sentidx]),
      hue = round(hue, 2),
      value = round(arc_norm[sentidx], 4),
      size = round(size, 4)
    )
  })
}

.empty_elements <- function() {
  tibble::tibble(x = numeric(), y = numeric(), sentence_id = integer(),
                 hue = numeric(), value = numeric(), size = numeric())
}

.empty_notes <- function() {
  tibble::tibble(sentence_id = integer(), pitch = integer(),
                 duration = numeric(), velocity = integer())
}

# Rescale a numeric vector to [0, 1]; constant vectors map to 0.5.
.rescale01 <- function(v) {
  if (length(v) == 0L) return(numeric())
  r <- range(v)
  if (diff(r) == 0) return(rep(0.5, length(v)))
  (v - r[1]) / diff(r)
}

# Evaluate `expr` with a fixed RNG seed, restoring the global RNG state after.
.with_seed <- function(seed, expr) {
  has_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (has_seed) {
    old <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
    on.exit(assign(".Random.seed", old, envir = globalenv()), add = TRUE)
  } else {
    on.exit(suppressWarnings(rm(list = ".Random.seed", envir = globalenv())), add = TRUE)
  }
  set.seed(seed)
  force(expr)
}
