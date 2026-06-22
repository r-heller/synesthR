# Synthesis constants. The tuneR path is fully self-contained: no external
# software is ever required. Timbre (sine + soft harmonics) and the short
# attack/release envelope are fixed here so the audio is reproducible.
.SAMPLE_RATE  <- 44100L
.ATTACK_SEC   <- 0.01
.RELEASE_SEC  <- 0.02
.STACCATO_GAP <- 0.04

#' Render a prosody_score as a synchronized audio waveform
#'
#' Synthesizes a \pkg{tuneR} `Wave` from the musical parameters mapped from the
#' score. Each note is a sine tone with soft harmonics and a short
#' attack/release envelope (to avoid clicks); notes are concatenated into one
#' Wave. Fully self-contained — no external software required. A richer engraved
#' backend is available via [syn_play_gm()].
#'
#' @param score A `prosody_score` from [syn_score()].
#' @param sample_rate Samples per second. Default `44100`.
#' @return A [tuneR::Wave] object (16-bit PCM, mono).
#' @family rendering functions
#' @seealso [syn_paint()] for the visual view, [syn_write_wav()] to save.
#' @examples
#' w <- syn_play(syn_score(syn_read_text("A short calm line.", lang = "en")))
#' @export
syn_play <- function(score, sample_rate = .SAMPLE_RATE) {
  .check_class(score, "prosody_score")
  sr <- as.integer(sample_rate)
  m <- .map_params(score)$music
  notes <- m$notes

  if (nrow(notes) == 0L) {
    return(tuneR::Wave(left = rep(0L, round(sr * 0.1)),
                       samp.rate = sr, bit = 16, pcm = TRUE))
  }

  secs_per_beat <- 60 / m$tempo_bpm
  gap_n <- if (isTRUE(m$staccato)) round(.STACCATO_GAP * sr) else 0L
  segs <- vector("list", nrow(notes))
  for (i in seq_len(nrow(notes))) {
    dur_sec <- notes$duration[i] * secs_per_beat
    nsamp <- max(2L, as.integer(round(dur_sec * sr)))
    seg <- .synth_note(.midi_to_freq(notes$pitch[i]), nsamp, notes$velocity[i], sr)
    if (gap_n > 0L) seg <- c(seg, numeric(gap_n))
    segs[[i]] <- seg
  }
  sig <- unlist(segs, use.names = FALSE)
  peak <- max(abs(sig))
  if (peak > 0) sig <- sig / peak * 0.95
  tuneR::Wave(left = round(sig * 32767), samp.rate = sr, bit = 16, pcm = TRUE)
}

# MIDI note number -> frequency in Hz (A4 = 69 = 440 Hz).
.midi_to_freq <- function(m) 440 * 2^((m - 69) / 12)

# One note: sine + soft harmonics, scaled by velocity, with an envelope.
.synth_note <- function(freq, n, velocity, sr) {
  t <- seq_len(n) / sr
  wave <- sin(2 * pi * freq * t) +
    0.3 * sin(2 * pi * 2 * freq * t) +
    0.15 * sin(2 * pi * 3 * freq * t)
  wave <- wave / 1.45
  (velocity / 127) * wave * .envelope(n, sr)
}

# Linear attack/release envelope; clamps to the available length.
.envelope <- function(n, sr, attack = .ATTACK_SEC, release = .RELEASE_SEC) {
  env <- rep(1, n)
  a <- min(n %/% 2L, max(1L, round(attack * sr)))
  r <- min(n - a, max(1L, round(release * sr)))
  env[seq_len(a)] <- seq(0, 1, length.out = a)
  env[(n - r + 1L):n] <- seq(1, 0, length.out = r)
  env
}

#' Write a prosody_score's audio to a .wav file
#'
#' @param score A `prosody_score`.
#' @param path Output path ending in `.wav`.
#' @param overwrite Overwrite an existing file? Default `FALSE`.
#' @param sample_rate Samples per second. Default `44100`.
#' @return The `score`, invisibly.
#' @family rendering functions
#' @examples
#' wav <- tempfile(fileext = ".wav")
#' syn_write_wav(syn_score(syn_read_text("Two words.", lang = "en")), wav)
#' @export
syn_write_wav <- function(score, path, overwrite = FALSE, sample_rate = .SAMPLE_RATE) {
  .check_class(score, "prosody_score")
  .check_flag(overwrite)
  if (file.exists(path) && !overwrite) {
    cli::cli_abort(c(
      "{.path {path}} already exists.",
      "i" = "Set {.code overwrite = TRUE} to replace it."
    ))
  }
  wave <- syn_play(score, sample_rate = sample_rate)
  tuneR::writeWave(wave, filename = path)
  invisible(score)
}

#' Optional richer score/audio via the gm + MuseScore backend
#'
#' Builds a \pkg{gm} music object (engraved score / richer playback) from the
#' score's notes. Requires the \pkg{gm} package and a MuseScore installation.
#' The self-contained [syn_play()] backend needs neither.
#'
#' @param score A `prosody_score`.
#' @param ... Reserved for future use; must be empty.
#' @return A \pkg{gm} `Music` object (engrave/play it with [gm::show()], which
#'   requires MuseScore). Requires \pkg{gm}.
#' @family rendering functions
#' @export
syn_play_gm <- function(score, ...) {
  rlang::check_dots_empty()
  .check_class(score, "prosody_score")
  if (!requireNamespace("gm", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.fn syn_play_gm} requires the {.pkg gm} package.",
      "i" = "Use {.fn syn_play} for the self-contained {.pkg tuneR} backend."
    ))
  }
  m <- .map_params(score)$music
  notes <- m$notes
  if (nrow(notes) == 0L) {
    cli::cli_abort("Cannot engrave an empty score.")
  }
  pitches <- as.list(vapply(notes$pitch, .midi_to_name, character(1)))
  durations <- as.list(.beats_to_gm(notes$duration))
  gm::Music() +
    gm::Meter(4, 4) +
    gm::Line(pitches = pitches, durations = durations) +
    gm::Tempo(m$tempo_bpm)
}

# MIDI number -> scientific pitch name (e.g. 60 -> "C4"). Sharps only.
.midi_to_name <- function(m) {
  names12 <- c("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B")
  octave <- (m %/% 12L) - 1L
  paste0(names12[(m %% 12L) + 1L], octave)
}

# Map beat durations to gm note-value strings (quarter = 1 beat).
.beats_to_gm <- function(beats) {
  vapply(beats, function(b) {
    if (b >= 1.75) "half"
    else if (b >= 0.875) "quarter"
    else if (b >= 0.4) "eighth"
    else "16th"
  }, character(1))
}
