test_that("syn_py_features validates its input", {
  expect_error(syn_py_features(list()), class = "rlang_error")
})

test_that("enrichment never alters the deterministic core mapping (contract)", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  before <- .map_params(sc)
  # simulate an enrichment slot as syn_py_features would add
  sc2 <- sc
  sc2$enrichment <- list(py_features = tibble::tibble(
    sentence_id = sc$features$sentence_id, valence_gradient = 0
  ))
  expect_identical(.map_params(sc2), before)
  # core features and arc are untouched
  expect_identical(sc2$features, sc$features)
  expect_identical(sc2$arc, sc$arc)
})

test_that("syn_py_features dual path: present enriches, absent aborts cleanly", {
  sc <- syn_score(syn_read_text(syn_example_text("en"), lang = "en"))
  has_py <- requireNamespace("reticulate", quietly = TRUE) &&
    tryCatch(reticulate::py_module_available("numpy"), error = function(e) FALSE)
  if (has_py) {
    out <- syn_py_features(sc)
    expect_true(is_prosody_score(out))
    expect_true(!is.null(out$enrichment$py_features))
    expect_named(out$enrichment$py_features,
                 c("sentence_id", "valence_gradient", "valence_cumulative"))
    # core mapping still identical
    expect_identical(.map_params(out), .map_params(sc))
  } else {
    expect_snapshot(syn_py_features(sc), error = TRUE)
  }
})
