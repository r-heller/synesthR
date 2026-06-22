test_that("package namespace loads", {
  expect_true("synesthR" %in% loadedNamespaces())
})

test_that(".check_string accepts a single string and returns it invisibly", {
  expect_invisible(.check_string("hello"))
  expect_identical(.check_string("hello"), "hello")
})

test_that(".check_string rejects non-strings", {
  expect_snapshot(.check_string(1L), error = TRUE)
  expect_snapshot(.check_string(c("a", "b")), error = TRUE)
  expect_snapshot(.check_string(NA_character_), error = TRUE)
})

test_that(".check_flag accepts a single logical and returns it invisibly", {
  expect_invisible(.check_flag(TRUE))
  expect_identical(.check_flag(FALSE), FALSE)
})

test_that(".check_flag rejects non-flags", {
  expect_snapshot(.check_flag("yes"), error = TRUE)
  expect_snapshot(.check_flag(c(TRUE, FALSE)), error = TRUE)
  expect_snapshot(.check_flag(NA), error = TRUE)
})

test_that(".check_class validates inheritance", {
  x <- structure(list(), class = "prosody_score")
  expect_invisible(.check_class(x, "prosody_score"))
  expect_snapshot(.check_class(list(), "prosody_score"), error = TRUE)
})

test_that(".check_choice validates and normalises a fixed choice", {
  expect_identical(.check_choice("de", c("de", "en", "fr")), "de")
  expect_snapshot(.check_choice("xx", c("de", "en", "fr")), error = TRUE)
})
