test_that("text round-trips through as_syn_media", {
  m <- as_syn_media("hello world")
  expect_true(is_syn_media(m))
  expect_identical(media_type(m), "text")
  expect_identical(media_content(m), "hello world")
})

test_that("prosody_score round-trips and carries lang meta", {
  sc <- syn_score(syn_read_text("A line here.", lang = "en"))
  m <- as_syn_media(sc)
  expect_identical(media_type(m), "score")
  expect_identical(m$meta$lang, "en")
})

test_that("Wave round-trips and carries sample rate", {
  w <- tuneR::sine(440, duration = 4000, samp.rate = 8000, bit = 16, pcm = TRUE)
  m <- as_syn_media(w)
  expect_identical(media_type(m), "audio")
  expect_equal(m$meta$sample_rate, 8000L)
})

test_that("syn_media is idempotent under coercion", {
  m <- as_syn_media("text")
  expect_identical(as_syn_media(m), m)
})

test_that("unsupported types abort cleanly", {
  expect_snapshot(as_syn_media(42L), error = TRUE)
})

test_that("accessors validate their input", {
  expect_snapshot(media_type(list()), error = TRUE)
})

test_that("print.syn_media is stable", {
  expect_snapshot(print(as_syn_media("some text")))
  sc <- syn_score(syn_read_text("Hi.", lang = "en"))
  expect_snapshot(print(as_syn_media(sc)))
})
