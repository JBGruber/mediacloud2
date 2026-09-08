test_that("mc_auth works", {
  # keep the token cache inside the session's temp directory
  cache_dir <- withr::local_tempdir()
  withr::local_envvar(
    MC_TOKEN = "fake-token.rds",
    R_USER_CACHE_DIR = cache_dir
  )
  withr::defer(rlang::env_unbind(the, "MC_TOKEN"))

  # set token
  mc_auth(token = "test")
  expect_true(file.exists(file.path(
    tools::R_user_dir("mediacloud2", "cache"),
    "fake-token.rds"
  )))
  # get token
  expect_equal(get_token(), "test")

  # add token to request
  req <- httr2::request("exampl.com") |>
    req_token()
  expect_all_equal(
    httr2::req_get_headers(req, redacted = "reveal"),
    list(Authorization = "Token test")
  )
})


test_that("a supplied token replaces the stored one", {
  cache_dir <- withr::local_tempdir()
  withr::local_envvar(
    MC_TOKEN = "fake-token.rds",
    R_USER_CACHE_DIR = cache_dir
  )
  withr::defer(rlang::env_unbind(the, "MC_TOKEN"))

  mc_auth(token = "first")
  mc_auth(token = "second")

  # drop the session cache, so the value has to come back off disk
  rlang::env_unbind(the, "MC_TOKEN")
  expect_equal(get_token(), "second")
})


test_that("empty tokens are rejected", {
  cache_dir <- withr::local_tempdir()
  withr::local_envvar(
    MC_TOKEN = "fake-token.rds",
    R_USER_CACHE_DIR = cache_dir
  )
  withr::defer(rlang::env_unbind(the, "MC_TOKEN"))

  expect_error(mc_auth(token = ""), "Unable to retrieve or obtain token")
  expect_false(file.exists(file.path(
    tools::R_user_dir("mediacloud2", "cache"),
    "fake-token.rds"
  )))
})


test_that("requests without a token fail loudly", {
  cache_dir <- withr::local_tempdir()
  withr::local_envvar(
    MC_TOKEN = "missing-token.rds",
    R_USER_CACHE_DIR = cache_dir
  )
  rlang::env_unbind(the, "MC_TOKEN")

  expect_null(get_token())
  expect_error(
    req_token(httr2::request("exampl.com")),
    "No 'MediaCloud' token found"
  )
  expect_error(req_token("not a request"), "must be a httr2 request")
})
