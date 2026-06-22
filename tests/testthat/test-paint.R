test_that("syn_paint returns a ggplot object", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  p <- syn_paint(sc)
  expect_s3_class(p, "ggplot")
})

test_that("syn_paint renders on all three sample languages without error", {
  for (lg in c("en", "de", "fr")) {
    sc <- syn_score(syn_read_text(syn_example_text(lg), lang = lg))
    p <- syn_paint(sc)
    expect_s3_class(p, "ggplot")
    expect_no_error(ggplot2::ggplot_build(p))
  }
})

test_that("syn_paint handles an empty score", {
  sc <- syn_score(syn_read_text("", lang = "en"))
  p <- syn_paint(sc)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("syn_paint rejects non-score input", {
  expect_snapshot(syn_paint(list()), error = TRUE)
})

test_that("syn_animate dual path: present builds, absent aborts", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  if (requireNamespace("gganimate", quietly = TRUE)) {
    expect_no_error(syn_animate(sc))
  } else {
    expect_snapshot(syn_animate(sc), error = TRUE)
  }
})
