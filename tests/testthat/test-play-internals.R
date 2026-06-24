# Covers the deterministic internal synthesis/notation helpers in play.R and
# the staccato branch of syn_play, none of which require the optional gm/
# MuseScore backend.

test_that(".midi_to_freq matches the A4 = 440 Hz reference", {
  expect_equal(.midi_to_freq(69), 440)
  expect_equal(.midi_to_freq(81), 880) # one octave up
  expect_equal(.midi_to_freq(57), 220) # one octave down
})

test_that(".midi_to_name produces scientific pitch names", {
  expect_identical(.midi_to_name(60L), "C4")
  expect_identical(.midi_to_name(69L), "A4")
  expect_identical(.midi_to_name(61L), "C#4")
  expect_identical(.midi_to_name(72L), "C5")
})

test_that(".beats_to_gm maps beat durations to gm note values", {
  expect_identical(
    .beats_to_gm(c(2, 1, 0.5, 0.25)),
    c("half", "quarter", "eighth", "16th")
  )
  # boundary values land on the documented buckets
  expect_identical(.beats_to_gm(1.75), "half")
  expect_identical(.beats_to_gm(0.875), "quarter")
  expect_identical(.beats_to_gm(0.4), "eighth")
  expect_identical(.beats_to_gm(0.39), "16th")
})

test_that(".envelope ramps from zero at both ends and clamps short notes", {
  env <- .envelope(1000L, 44100L)
  expect_length(env, 1000L)
  expect_equal(env[1], 0)
  expect_equal(env[length(env)], 0)
  expect_lte(max(env), 1)
  # very short note: attack/release still defined and bounded
  short <- .envelope(3L, 44100L)
  expect_length(short, 3L)
  expect_true(all(short >= 0 & short <= 1))
})

test_that(".synth_note returns a velocity-scaled, enveloped segment", {
  seg <- .synth_note(440, 2000L, 127, 44100L)
  expect_length(seg, 2000L)
  quiet <- .synth_note(440, 2000L, 32, 44100L)
  # lower velocity yields a quieter peak
  expect_lt(max(abs(quiet)), max(abs(seg)))
})

test_that("syn_play exercises the staccato branch for punctuation-dense text", {
  staccato_txt <- paste(rep("Oh! Ah? Yes! No? Wow! Hmm?", 6), collapse = " ")
  sc_stac <- syn_score(syn_read_text(staccato_txt, lang = "en"))
  expect_true(isTRUE(.map_params(sc_stac)$music$staccato))
  w <- syn_play(sc_stac)
  expect_s4_class(w, "Wave")
  expect_true(length(w@left) > 0)
})

test_that("syn_play_gm aborts on an empty score when gm is available", {
  skip_if_not_installed("gm")
  sc <- syn_score(syn_read_text("", lang = "en"))
  expect_error(syn_play_gm(sc), "empty score")
})
