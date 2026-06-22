test_that("syn_read_text splits a string into a tidy tibble", {
  out <- syn_read_text("First sentence. Second one! And a third?", lang = "en")
  expect_s3_class(out, "tbl_df")
  expect_named(out, c("sentence_id", "sentence", "lang"))
  expect_type(out$sentence_id, "integer")
  expect_equal(nrow(out), 3L)
  expect_identical(attr(out, "lang"), "en")
  expect_true(all(out$lang == "en"))
})

test_that("syn_read_text is type-stable on empty and single-sentence input", {
  empty <- syn_read_text("", lang = "en")
  expect_s3_class(empty, "tbl_df")
  expect_named(empty, c("sentence_id", "sentence", "lang"))
  expect_equal(nrow(empty), 0L)
  expect_type(empty$sentence_id, "integer")

  one <- syn_read_text("Only one sentence here.", lang = "en")
  expect_equal(nrow(one), 1L)
})

test_that("syn_read_text accepts a data frame with a text column", {
  df <- tibble::tibble(text = c("Alpha beta. Gamma delta."))
  out <- syn_read_text(df, lang = "en")
  expect_equal(nrow(out), 2L)

  df2 <- tibble::tibble(body = "One. Two.")
  out2 <- syn_read_text(df2, lang = "en", text_col = "body")
  expect_equal(nrow(out2), 2L)
})

test_that("syn_read_text reads from a file path", {
  tmp <- withr::local_tempfile(fileext = ".txt")
  writeLines("Sentence from a file. Another one.", tmp)
  out <- syn_read_text(tmp, lang = "en")
  expect_equal(nrow(out), 2L)
})

test_that("syn_read_text errors on a missing text column", {
  expect_snapshot(
    syn_read_text(tibble::tibble(nope = "hi"), lang = "en"),
    error = TRUE
  )
})

test_that("syn_read_text errors on unsupported input type", {
  expect_snapshot(syn_read_text(42L, lang = "en"), error = TRUE)
})

test_that(".detect_lang validates an explicit lang", {
  expect_identical(.detect_lang("text", "fr"), "fr")
  expect_snapshot(.detect_lang("text", "xx"), error = TRUE)
})

test_that("auto-detect path: present uses cld3, absent aborts", {
  if (requireNamespace("cld3", quietly = TRUE)) {
    # present-path: a clearly English sentence detects as a supported language
    out <- syn_read_text("This is an unambiguously English sentence about cats.")
    expect_true(attr(out, "lang") %in% c("de", "en", "fr"))
  } else {
    # absent-path: NULL lang with no cld3 must abort informatively
    expect_snapshot(syn_read_text("some text", lang = NULL), error = TRUE)
  }
})

test_that("syn_example_text returns a non-empty string for each language", {
  for (lg in c("en", "de", "fr")) {
    txt <- syn_example_text(lg)
    expect_type(txt, "character")
    expect_length(txt, 1L)
    expect_true(nchar(txt) > 50)
  }
})
