present_tool <- if (.Platform$OS.type == "windows") "where" else "ls"

test_that(".check_tool returns a path for a present tool", {
  skip_if(Sys.which(present_tool) == "")
  p <- .check_tool(present_tool)
  expect_true(nzchar(p))
})

test_that(".check_tool aborts cleanly for an absent tool", {
  expect_snapshot(.check_tool("definitely_not_a_real_binary_xyz"), error = TRUE)
})

test_that(".run_tool captures output for a present tool", {
  skip_if(Sys.which(present_tool) == "")
  out <- .run_tool(present_tool, args = if (.Platform$OS.type == "windows") "where" else ".")
  expect_type(out, "character")
})

test_that(".run_tool surfaces a non-zero exit status", {
  skip_if(Sys.which(present_tool) == "")
  # 'where' / 'ls' on a non-existent target returns non-zero
  bogus <- "this_path_does_not_exist_xyz"
  expect_error(.run_tool(present_tool, args = bogus))
})

test_that(".check_pymod aborts when reticulate is absent", {
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    expect_snapshot(.check_pymod("numpy"), error = TRUE)
  } else {
    expect_error(.check_pymod("a_module_that_is_not_installed_xyz"))
  }
})

test_that(".check_client validates package presence and probe", {
  # present package, passing probe
  expect_invisible(.check_client("cli", probe = function() TRUE))
  # present package, failing probe
  expect_error(.check_client("cli", probe = function() FALSE), "not reachable")
  # absent package
  expect_snapshot(.check_client("a_package_that_does_not_exist_xyz"), error = TRUE)
})

test_that("CORE BOUNDARY: core files never call rim helpers", {
  skip_if(!file.exists(test_path("..", "..", "R", "read.R")),
          "package source R/ not available (installed-package test run)")
  core <- c("read.R", "score.R", "score-class.R", "map.R",
            "paint.R", "play.R", "palette.R", "media.R")
  rim_fns <- c("\\.check_tool", "\\.check_pymod", "\\.check_client", "\\.run_tool")
  for (f in core) {
    path <- test_path("..", "..", "R", f)
    if (!file.exists(path)) next
    src <- paste(readLines(path, warn = FALSE), collapse = "\n")
    for (fn in rim_fns) {
      expect_false(grepl(fn, src),
                   info = paste0(f, " must not reference rim helper ", fn))
    }
  }
})
