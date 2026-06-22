test_that("syn_score returns a valid prosody_score with required features", {
  txt <- syn_read_text("A calm sentence. A second, busier sentence!", lang = "en")
  sc <- syn_score(txt)
  expect_true(is_prosody_score(sc))
  expect_true(all(c("sentence_id", "valence", "length", "lex_diversity",
                    "punct_density") %in% names(sc$features)))
  expect_equal(nrow(sc$features), 2L)
  expect_equal(length(sc$arc), 2L)
  expect_identical(sc$lang, "en")
  expect_identical(sc$seed, 1L)
})

test_that("syn_score is deterministic across runs", {
  txt <- syn_read_text(syn_example_text("en"), lang = "en")
  a <- syn_score(txt, seed = 42L)
  b <- syn_score(txt, seed = 42L)
  expect_identical(a$features, b$features)
  expect_identical(a$arc, b$arc)
})

test_that("syn_score is type-stable on empty input", {
  empty <- syn_read_text("", lang = "en")
  sc <- syn_score(empty)
  expect_true(is_prosody_score(sc))
  expect_equal(nrow(sc$features), 0L)
  expect_type(sc$features$length, "integer")
  expect_equal(length(sc$arc), 0L)
})

test_that("syn_score rejects non-read_text input", {
  expect_snapshot(syn_score(list(a = 1)), error = TRUE)
})

test_that("feature metrics are computed correctly", {
  txt <- syn_read_text("Cats cats cats dogs.", lang = "en")
  sc <- syn_score(txt)
  # 4 words, 2 unique stems -> ttr = 2/4
  expect_equal(sc$features$length, 4L)
  expect_equal(sc$features$lex_diversity, 0.5)
  expect_true(sc$features$punct_density > 0)
})

test_that("golden snapshot of the en sample feature tibble (reproducibility contract)", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  expect_snapshot(as.data.frame(round_df(sc$features)))
  expect_snapshot(round(sc$arc, 4))
})

test_that("summary.prosody_score returns a one-row tibble", {
  sc <- syn_score(syn_read_text("One. Two. Three.", lang = "en"))
  s <- summary(sc)
  expect_s3_class(s, "tbl_df")
  expect_equal(nrow(s), 1L)
  expect_true(all(c("n_sentences", "mean_valence", "arc_start", "arc_end") %in% names(s)))
})
