test_that("syn_run_app aborts cleanly when shiny is absent", {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    expect_snapshot(syn_run_app(), error = TRUE)
  } else {
    skip("shiny present; app launch not exercised in tests")
  }
})

test_that("the bundled app sources without error into an app object", {
  skip_if_not_installed("shiny")
  app_dir <- system.file("shiny", "synesthR", package = "synesthR")
  # During dev (load_all) system.file resolves to inst/; fall back if needed.
  app_file <- file.path(app_dir, "app.R")
  if (!file.exists(app_file)) {
    app_file <- testthat::test_path("..", "..", "inst", "shiny", "synesthR", "app.R")
  }
  skip_if(!file.exists(app_file), "bundled app not found in this run")
  app <- source(app_file, local = new.env())$value
  expect_s3_class(app, "shiny.appobj")
})


test_that("app validates seed and cleans session audio", {
  skip_if_not_installed("shiny")
  env <- new.env()
  source(system.file("shiny", "synesthR", "app.R", package = "synesthR"), local = env)
  rendered <- NULL
  shiny::testServer(env$server, {
    session$setInputs(text = "A calm happy morning.", lang = "en", seed = 1, go = 1)
    expect_s3_class(score(), "prosody_score")
    rendered <<- wav_path()
    expect_true(file.exists(rendered))
    expect_false(grepl(session$token, basename(rendered), fixed = TRUE))
    expect_match(as.character(output$audio$html), "\\?v=[a-f0-9]{32}")
    session$setInputs(seed = 1.5, go = 2)
    expect_error(score(), class = "shiny.silent.error")
  })
  expect_false(file.exists(rendered))
})
