test_that("validate_prosody_score rejects missing feature columns", {
  bad <- new_prosody_score(features = tibble::tibble(sentence_id = 1L))
  expect_snapshot(validate_prosody_score(bad), error = TRUE)
})

test_that("is_prosody_score discriminates", {
  sc <- syn_score(syn_read_text("Hi there.", lang = "en"))
  expect_true(is_prosody_score(sc))
  expect_false(is_prosody_score(list()))
})

test_that("print.prosody_score is stable", {
  sc <- syn_score(syn_read_text("One sentence here. Two now.", lang = "en"))
  expect_snapshot(print(sc))
})
