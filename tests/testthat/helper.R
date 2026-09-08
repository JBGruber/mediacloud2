# Point the token machinery at a throwaway cache and prime the session cache,
# so no test can reach the user's real token or write to their real cache.
local_fake_token <- function(env = parent.frame()) {
  cache_dir <- withr::local_tempdir(.local_envir = env)
  withr::local_envvar(
    MC_TOKEN = "fake-token.rds",
    R_USER_CACHE_DIR = cache_dir,
    .local_envir = env
  )
  rlang::env_poke(the, "MC_TOKEN", "test")
  withr::defer(rlang::env_unbind(the, "MC_TOKEN"), envir = env)
  invisible(NULL)
}


# Build a response straight from JSON text. `response_json()` round-trips
# through jsonlite, which cannot express a null, so anything that needs a
# literal `null` on the wire has to be written out.
mock_json <- function(text, status = 200) {
  httr2::response(
    status,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(paste(text, collapse = "\n"))
  )
}


# Responses recorded from the live API, trimmed to a few records each. See
# NEWS.md for the backend commit they were captured against.
fixture <- function(name) {
  jsonlite::fromJSON(
    testthat::test_path("fixtures", paste0(name, ".json")),
    simplifyVector = FALSE
  )
}


# Served as the recorded bytes rather than re-encoded from a parsed object:
# a round trip through jsonlite turns a JSON `null` into `{}`, which is
# exactly the difference the paging code has to get right.
fixture_resp <- function(name, status = 200) {
  mock_json(
    readLines(
      testthat::test_path("fixtures", paste0(name, ".json")),
      warn = FALSE
    ),
    status = status
  )
}


# httr2 wants a function or a list, never a bare response: a function answers
# every request the same way, a list answers them in sequence.
mock_always <- function(resp) {
  function(req) resp
}


mock_sequence <- function(...) list(...)


# The search endpoints carry a 2/min throttle. Mocked requests must not sit in
# it, so tests that perform one turn it off.
local_no_throttle <- function(env = parent.frame()) {
  withr::local_options(mediacloud.rate = Inf, .local_envir = env)
}
