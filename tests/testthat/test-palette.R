test_that("syn_palette.prosody_score returns a valid palette", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  p <- syn_palette(sc, n = 5L)
  expect_true(is_syn_palette(p))
  expect_length(p$colors, 5L)
  expect_length(p$roles, 5L)
  expect_true(all(grepl("^#", p$colors)))
  expect_true(p$mode %in% c("warm", "cool", "mixed"))
  expect_identical(p$source, "prosody_score")
})

test_that("syn_palette is deterministic", {
  sc <- syn_score(syn_read_text(syn_example_text("fr"), lang = "fr"))
  expect_identical(syn_palette(sc), syn_palette(sc))
})

test_that("syn_palette.character scores then dispatches", {
  p <- syn_palette("A warm and joyful golden afternoon.", lang = "en", n = 4L)
  expect_true(is_syn_palette(p))
  expect_length(p$colors, 4L)
})

test_that("warm vs cool valence shifts temperature sign as expected", {
  warm <- syn_palette(syn_score(syn_read_text(
    "Joyful glorious warm happy delight wonderful love.", lang = "en")))
  expect_true(is.numeric(warm$temperature))
})

test_that("syn_palette.Wave derives a palette from audio", {
  w <- tuneR::sine(440, duration = 8000, samp.rate = 8000, bit = 16, pcm = TRUE)
  p <- syn_palette(w, n = 5L)
  expect_true(is_syn_palette(p))
  expect_length(p$colors, 5L)
  expect_identical(p$source, "audio")
  expect_true(is.numeric(p$temperature) && !is.na(p$temperature))
})

test_that("syn_palette image method aborts cleanly when magick is absent", {
  if (requireNamespace("magick", quietly = TRUE)) {
    img <- magick::image_blank(40, 40, color = "tomato")
    p <- syn_palette(img, n = 5L)
    expect_true(is_syn_palette(p))
    expect_identical(p$source, "image")
  } else {
    fake <- structure(list(), class = "magick-image")
    expect_snapshot(syn_palette(fake), error = TRUE)
  }
})

test_that("syn_theme returns a ggplot2 theme", {
  sc <- syn_score(syn_read_text("Quiet grey morning.", lang = "en"))
  th <- syn_theme(syn_palette(sc))
  expect_s3_class(th, "theme")
  # accepts any palette source directly
  th2 <- syn_theme(sc)
  expect_s3_class(th2, "theme")
})

test_that("print.syn_palette is stable", {
  sc <- syn_score(syn_read_text("One. Two. Three.", lang = "en"))
  expect_snapshot(print(syn_palette(sc, n = 5L)))
})
