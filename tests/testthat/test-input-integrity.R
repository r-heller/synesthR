test_that("missing text is rejected instead of becoming the word NA", {
  for (text in list(NA_character_, c("Hello.", NA_character_), data.frame(text=NA_character_))) {
    expect_error(syn_read_text(text,lang="en"), "missing values")
  }
  expect_equal(syn_read_text("NA is an abbreviation.",lang="en")$sentence,
               "NA is an abbreviation.")
})

test_that("seeds and sample rates are validated before integer conversion", {
  text <- syn_read_text("One calm sentence.",lang="en")
  score <- syn_score(text)
  for (bad in list(NA_real_,Inf,NaN,1.5,1e100,numeric(),"1")) {
    expect_error(syn_score(text,seed=bad), "single integer")
    expect_error(syn_play(score,sample_rate=bad), "positive integer")
  }
  expect_error(syn_play(score,sample_rate=0), "positive integer")
  expect_identical(syn_score(text,seed=12L),syn_score(text,seed=12))
})
