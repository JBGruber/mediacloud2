test_that("requests are built against the right URL", {
  local_fake_token()

  req <- mc_req("sources/collections/", name = "Germany", limit = 100)
  expect_equal(
    req$url,
    "https://search.mediacloud.org/api/sources/collections/?name=Germany&limit=100"
  )
})


test_that("trailing slashes are preserved and absent where they should be", {
  local_fake_token()

  # DRF routes the directory endpoints with a trailing slash ...
  expect_match(mc_req("sources/sources/")$url, "/api/sources/sources/$")
  # ... while the search endpoints are plain paths with none
  expect_match(mc_req("search/total-count", q = "x")$url, "/api/search/total-count\\?")
})


test_that("an `end` parameter is not swallowed by the endpoint formal", {
  local_fake_token()

  # regression: `end` partially matches an `endpoint` formal, which silently
  # stole the parameter and pushed the path into `...`
  req <- mc_req("search/total-count", q = "klima", start = "2026-08-01",
                end = "2026-08-07")
  expect_match(req$url, "/api/search/total-count\\?")
  expect_match(req$url, "end=2026-08-07")
  expect_match(req$url, "start=2026-08-01")
})


test_that("NULL parameters are dropped", {
  local_fake_token()

  req <- mc_req("search/total-count", q = "x", cs = NULL, ss = NULL)
  expect_equal(req$url, "https://search.mediacloud.org/api/search/total-count?q=x")
})


test_that("only the search endpoints are throttled", {
  local_fake_token()

  # the backend rate limits /api/search/* to 2/min and leaves the directory
  # endpoints alone
  expect_false(is.null(mc_req("search/words", q = "x")$policies$throttle))
  expect_null(mc_req("sources/collections/")$policies$throttle)
})


test_that("the throttle can be turned off or raised", {
  local_fake_token()

  withr::local_options(mediacloud.rate = Inf)
  expect_null(mc_req("search/words", q = "x")$policies$throttle)
})


test_that("mc_perform rejects non-JSON answers", {
  local_fake_token()

  # an unknown path is swallowed by the web app's catch-all route, which
  # answers 200 with an HTML page instead of 404
  resp <- httr2::response(
    200,
    headers = list(`Content-Type` = "text/html; charset=utf-8"),
    body = charToRaw("<!DOCTYPE html>")
  )
  httr2::with_mocked_responses(mock_always(resp), {
    expect_error(mc_get("sources/nope/"), "did not return JSON")
  })
})


test_that("error messages are lifted out of the body", {
  local_fake_token()

  # search views answer with `note`
  search_err <- httr2::response_json(
    422,
    body = list(status = "error", note = "Missing 'q' parameter value")
  )
  httr2::with_mocked_responses(mock_always(search_err), {
    expect_error(mc_get("search/total-count"), "Missing 'q' parameter value")
  })

  # auth views answer with `message`
  auth_err <- httr2::response_json(403, body = list(message = "User Not Found"))
  httr2::with_mocked_responses(mock_always(auth_err), {
    expect_error(mc_get("auth/profile"), "User Not Found")
  })

  # Django REST framework answers with `detail`
  drf_err <- httr2::response_json(
    404,
    body = list(detail = "No Collection matches the given query.")
  )
  httr2::with_mocked_responses(mock_always(drf_err), {
    expect_error(mc_get("sources/collections/1/"), "No Collection matches")
  })
})


test_that("429 and 5xx are treated as transient, 422 is not", {
  expect_true(mc_is_transient(httr2::response(429)))
  expect_true(mc_is_transient(httr2::response(503)))
  expect_false(mc_is_transient(httr2::response_json(422, body = list(note = "bad"))))
  # the backend flags transient upstream failures with 400 plus `temporary`
  expect_true(mc_is_transient(
    httr2::response_json(400, body = list(note = "unavailable", temporary = TRUE))
  ))
})


test_that("offset paging follows `next` until it is null", {
  local_fake_token()

  page1 <- httr2::response_json(200, body = list(
    count = 3,
    `next` = "https://search.mediacloud.org/api/sources/sources/?limit=2&offset=2",
    previous = NULL,
    results = list(list(id = 1L), list(id = 2L))
  ))
  page2 <- mock_json(
    '{"count": 3, "next": null, "previous": "x", "results": [{"id": 3}]}'
  )

  httr2::with_mocked_responses(mock_sequence(page1, page2), {
    out <- mc_page_offset("sources/sources/", .progress = FALSE)
    expect_equal(length(out), 3L)
    expect_equal(vapply(out, function(x) x$id, integer(1)), 1:3)
  })
})


test_that("offset paging stops at max_results", {
  local_fake_token()

  page <- httr2::response_json(200, body = list(
    count = 100,
    `next` = "https://search.mediacloud.org/api/sources/sources/?limit=2&offset=2",
    previous = NULL,
    results = list(list(id = 1L), list(id = 2L))
  ))
  httr2::with_mocked_responses(mock_always(page), {
    out <- mc_page_offset("sources/sources/", max_results = 3, .progress = FALSE)
    expect_equal(length(out), 3L)
  })
})


test_that("token paging feeds the token back and stops on null", {
  local_fake_token()

  page1 <- httr2::response_json(200, body = list(
    stories = list(list(id = "a"), list(id = "b")),
    pagination_token = "tok1"
  ))
  page2 <- mock_json('{"stories": [{"id": "c"}], "pagination_token": null}')
  httr2::with_mocked_responses(mock_sequence(page1, page2), {
    out <- mc_page_token("search/story-list", q = "x", .progress = FALSE)
    expect_equal(vapply(out, function(x) x$id, character(1)), c("a", "b", "c"))
  })
})


test_that("token paging stops on an empty page even if a token comes back", {
  local_fake_token()

  # a server that kept handing back a token would otherwise loop forever
  page <- httr2::response_json(200, body = list(
    stories = list(),
    pagination_token = "never-ends"
  ))
  httr2::with_mocked_responses(mock_always(page), {
    out <- mc_page_token("search/story-list", q = "x", .progress = FALSE)
    expect_equal(length(out), 0L)
  })
})
