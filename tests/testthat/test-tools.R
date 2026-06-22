test_that("syn_export_video validates its score", {
  expect_error(syn_export_video(list(), tempfile()), class = "rlang_error")
})

test_that("syn_export_video signals 'reserved for a future release' either way", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  # Regardless of whether ffmpeg is installed, v0.1 must refuse clearly.
  expect_error(syn_export_video(sc, tempfile(fileext = ".mp4")),
               "future")
})

test_that("ffmpeg detection branch is exercised when present", {
  skip_if(Sys.which("ffmpeg") == "")
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  expect_error(syn_export_video(sc, tempfile(fileext = ".mp4")), "not enabled")
})
