# Exercises the live-backend bodies of the optional LLM assist layer without a
# real Ollama server by mocking ellmer::chat_ollama. These cover the success
# paths of syn_interpret / syn_suggest / syn_llm_condense and the advisory
# error-fallback in syn_suggest, none of which the dual-path tests reach when
# ellmer is installed but no backend is running.

skip_if_not_installed("ellmer")

# A minimal stand-in for an ellmer chat object: a list with a $chat() method.
fake_chat <- function(reply = "A short interpretation.") {
  list(chat = function(prompt, ...) reply)
}

test_that("syn_interpret returns the model's prose on the mocked backend", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  testthat::local_mocked_bindings(
    chat_ollama = function(model, ...) fake_chat("Interpreted reading."),
    .package = "ellmer"
  )
  out <- syn_interpret(sc)
  expect_identical(out, "Interpreted reading.")
})

test_that("syn_suggest returns an advisory, non-applied suggestion", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  testthat::local_mocked_bindings(
    chat_ollama = function(model, ...) fake_chat("Cool the palette slightly."),
    .package = "ellmer"
  )
  res <- syn_suggest(sc, target = "palette")
  expect_type(res, "list")
  expect_identical(res$target, "palette")
  expect_identical(res$suggestion, "Cool the palette slightly.")
  expect_false(res$applied)
})

test_that("syn_suggest falls back to NA when the chat call errors", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  failing_chat <- list(chat = function(prompt, ...) stop("backend exploded"))
  testthat::local_mocked_bindings(
    chat_ollama = function(model, ...) failing_chat,
    .package = "ellmer"
  )
  res <- syn_suggest(sc, target = "tempo")
  expect_identical(res$target, "tempo")
  expect_true(is.na(res$suggestion))
  expect_false(res$applied)
})

test_that("syn_llm_condense round-trips through read_text on a mocked backend", {
  txt <- syn_read_text(
    "One sentence here. Another sentence follows. A third one too.",
    lang = "en"
  )
  testthat::local_mocked_bindings(
    chat_ollama = function(model, ...) fake_chat("A condensed passage. It stays brief."),
    .package = "ellmer"
  )
  out <- syn_llm_condense(txt)
  expect_s3_class(out, "tbl_df")
  expect_named(out, c("sentence_id", "sentence", "lang"))
  expect_identical(attr(out, "lang"), "en")
  expect_equal(nrow(out), 2L)
})

test_that("the mocked probe success path lets .ollama_chat construct a chat", {
  sc <- syn_score(syn_read_text(syn_example_text("fr"), lang = "fr"))
  testthat::local_mocked_bindings(
    chat_ollama = function(model, ...) fake_chat("Lecture."),
    .package = "ellmer"
  )
  expect_no_error(syn_interpret(sc))
})
