test_that("syn_play returns a tuneR Wave", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  w <- syn_play(sc)
  expect_s4_class(w, "Wave")
  expect_equal(w@samp.rate, 44100L)
  expect_true(length(w@left) > 0)
})

test_that("syn_play is deterministic", {
  sc <- syn_score(syn_read_text(syn_example_text("de"), lang = "de"))
  expect_identical(syn_play(sc)@left, syn_play(sc)@left)
})

test_that("syn_play handles an empty score", {
  sc <- syn_score(syn_read_text("", lang = "en"))
  w <- syn_play(sc)
  expect_s4_class(w, "Wave")
})

test_that("envelope removes clicks (start and end near zero)", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  left <- syn_play(sc)@left
  expect_lt(abs(left[1]), 2000)
  expect_lt(abs(left[length(left)]), 2000)
  expect_lte(max(abs(left)), 32767)
})

test_that("syn_write_wav round-trips in tempdir", {
  sc <- syn_score(syn_read_text("A short tune here.", lang = "en"))
  path <- withr::local_tempfile(fileext = ".wav")
  res <- syn_write_wav(sc, path)
  expect_true(is_prosody_score(res))
  expect_true(file.exists(path))
  back <- tuneR::readWave(path)
  expect_s4_class(back, "Wave")
})

test_that("syn_write_wav guards against overwrite", {
  sc <- syn_score(syn_read_text("Hi there now.", lang = "en"))
  path <- withr::local_tempfile(fileext = ".wav")
  syn_write_wav(sc, path)
  expect_error(syn_write_wav(sc, path), "already exists")
  expect_invisible(syn_write_wav(sc, path, overwrite = TRUE))
})

test_that("syn_play_gm dual path: present builds a Music object, absent aborts", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  if (!requireNamespace("gm", quietly = TRUE)) {
    expect_snapshot(syn_play_gm(sc), error = TRUE)
  } else {
    out <- syn_play_gm(sc)
    expect_true(inherits(out, "Music"))
  }
})
