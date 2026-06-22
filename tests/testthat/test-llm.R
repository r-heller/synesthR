test_that("assist functions validate their score argument", {
  expect_error(syn_interpret(list()), class = "rlang_error")
  expect_error(syn_suggest(list()), class = "rlang_error")
})

test_that("syn_interpret dual path: absent ellmer aborts cleanly", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    expect_snapshot(syn_interpret(sc), error = TRUE)
  } else {
    skip("ellmer present; live backend not exercised in tests")
  }
})

test_that("syn_suggest dual path: absent ellmer aborts; target validated", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  expect_error(syn_suggest(sc, target = "nonsense"))
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    expect_error(syn_suggest(sc, target = "palette"), class = "rlang_error")
  }
})

test_that("syn_llm_condense requires a read_text tibble", {
  expect_error(syn_llm_condense(42L), "syn_read_text")
})

test_that("the feature brief is source-free and well-formed", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  brief <- .feature_brief(sc)
  expect_type(brief, "character")
  expect_match(brief, "valence")
  # must NOT contain the raw source sentences
  expect_false(grepl("morning broke", brief, fixed = TRUE))
})
