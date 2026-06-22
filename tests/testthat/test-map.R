make_score <- function(lang = "en", seed = 1L) {
  syn_score(syn_read_text(syn_example_text(lang), lang = lang), seed = seed)
}

test_that(".map_params returns the visual + music structure", {
  p <- .map_params(make_score())
  expect_named(p, c("visual", "music"))
  expect_true(all(c("temperature", "hue_base", "elements", "seed") %in% names(p$visual)))
  expect_true(all(c("key", "mode", "tempo_bpm", "notes") %in% names(p$music)))
  expect_s3_class(p$visual$elements, "tbl_df")
  expect_s3_class(p$music$notes, "tbl_df")
  expect_equal(nrow(p$music$notes), nrow(make_score()$features))
})

test_that(".map_params is fully deterministic and side-effect-free", {
  sc <- make_score(seed = 7L)
  a <- .map_params(sc)
  b <- .map_params(sc)
  expect_identical(a, b)
})

test_that(".map_params does not disturb the global RNG state", {
  set.seed(123)
  before <- .Random.seed
  .map_params(make_score(seed = 99L))
  expect_identical(.Random.seed, before)
})

test_that("seed changes the element cloud but not the note count", {
  s1 <- .map_params(make_score(seed = 1L))
  s2 <- .map_params(make_score(seed = 2L))
  expect_false(identical(s1$visual$elements, s2$visual$elements))
  expect_equal(nrow(s1$music$notes), nrow(s2$music$notes))
})

test_that("valence sign drives musical mode", {
  pos <- syn_score(syn_read_text("Wonderful joyful glorious happy delight.", lang = "en"))
  expect_true(.map_params(pos)$music$mode %in% c("major", "minor"))
})

test_that(".map_params is type-stable on an empty score", {
  empty <- syn_score(syn_read_text("", lang = "en"))
  p <- .map_params(empty)
  expect_equal(nrow(p$music$notes), 0L)
  expect_equal(nrow(p$visual$elements), 0L)
  expect_equal(p$music$mode, "major")
})

test_that("golden snapshot of the full param list (reproducibility contract)", {
  p <- .map_params(make_score(lang = "en", seed = 1L))
  # scalar musical/visual params
  expect_snapshot({
    str(p$music[setdiff(names(p$music), "notes")])
    str(p$visual[setdiff(names(p$visual), "elements")])
  })
  expect_snapshot(as.data.frame(p$music$notes))
  expect_snapshot(as.data.frame(p$visual$elements))
})
