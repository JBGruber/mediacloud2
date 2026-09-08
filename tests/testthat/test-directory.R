test_that("mc_version parses the version payload", {
  local_fake_token()

  httr2::with_mocked_responses(mock_always(fixture_resp("version")), {
    out <- mc_version()
  })
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 1L)
  expect_equal(out$version, "3.1.11")
  expect_s3_class(out$now, "POSIXct")
})


test_that("mc_profile flattens the nested quota", {
  local_fake_token()

  httr2::with_mocked_responses(mock_always(fixture_resp("profile")), {
    out <- mc_profile()
  })
  expect_equal(out$username, "example_user")
  expect_false(out$is_staff)
  expect_equal(out$groups[[1]], "api_access")
  expect_equal(out$quota_provider, "onlinenews-mediacloud")
  expect_equal(out$quota_hits, 42L)
  expect_s3_class(out$quota_week, "Date")
})


test_that("mc_collections returns a tibble with parsed dates", {
  local_fake_token()

  httr2::with_mocked_responses(mock_always(fixture_resp("collections")), {
    out <- mc_collections("Germany", max_results = 3)
  })
  expect_s3_class(out, "tbl_df")
  expect_true(all(c("id", "name", "source_count", "platform") %in% names(out)))
  expect_s3_class(out$modified_at, "POSIXct")
  expect_true(all(out$platform == "online_news"))
})


test_that("mc_collections asks for the right URL", {
  local_fake_token()

  seen <- NULL
  httr2::with_mocked_responses(
    function(req) {
      seen <<- req$url
      fixture_resp("collections")
    },
    mc_collections(name = "Germany", source_id = 1752, max_results = 3)
  )
  expect_match(seen, "/api/sources/collections/\\?")
  expect_match(seen, "name=Germany")
  expect_match(seen, "source_id=1752")
  # max_results below the server page size is passed on as the limit
  expect_match(seen, "limit=3")
})


test_that("mc_collection returns a single row", {
  local_fake_token()

  seen <- NULL
  out <- httr2::with_mocked_responses(
    function(req) {
      seen <<- req$url
      fixture_resp("collection")
    },
    mc_collection(34412409)
  )
  expect_equal(nrow(out), 1L)
  expect_equal(out$id, 34412409L)
  expect_match(seen, "/api/sources/collections/34412409/$")
})


test_that("large ids are not sent in scientific notation", {
  local_fake_token()

  seen <- NULL
  httr2::with_mocked_responses(
    function(req) {
      seen <<- req$url
      fixture_resp("collection")
    },
    mc_collection(262985213)
  )
  expect_match(seen, "/262985213/$")
})


test_that("mc_sources parses the month-only last_story", {
  local_fake_token()

  httr2::with_mocked_responses(mock_always(fixture_resp("sources")), {
    out <- mc_sources(collection_id = 34412409, max_results = 3)
  })
  expect_s3_class(out, "tbl_df")
  expect_s3_class(out$last_story, "Date")
  # this endpoint only reports the month, so every date is a first
  expect_true(all(is.na(out$last_story) |
                    format(out$last_story, "%d") == "01"))
  expect_s3_class(out$created_at, "POSIXct")
  expect_type(out$alternative_domains, "list")
})


test_that("mc_source returns a single row", {
  local_fake_token()

  seen <- NULL
  out <- httr2::with_mocked_responses(
    function(req) {
      seen <<- req$url
      fixture_resp("source")
    },
    mc_source(1752)
  )
  expect_equal(nrow(out), 1L)
  expect_match(seen, "/api/sources/sources/1752/$")
})


test_that("mc_feeds converts its filters to epoch seconds", {
  local_fake_token()

  seen <- NULL
  httr2::with_mocked_responses(
    function(req) {
      seen <<- req$url
      fixture_resp("feeds")
    },
    mc_feeds(1752, modified_since = as.Date("2026-01-01"), max_results = 3)
  )
  expect_match(seen, "/api/sources/feeds/\\?")
  expect_match(seen, "source_id=1752")
  # the API wants epoch seconds here, not an ISO date
  expect_match(seen, "modified_since=1767225600")
})


test_that("mc_feeds(details = TRUE) reads the nested payload", {
  local_fake_token()

  # this endpoint proxies the RSS fetcher and nests under "feeds" instead of
  # paginating with "results"
  resp <- httr2::response_json(200, body = list(
    feeds = list(
      list(id = 1L, url = "https://a.example/rss", last_fetch_success = TRUE),
      list(id = 2L, url = "https://b.example/rss", last_fetch_success = FALSE)
    )
  ))
  seen <- NULL
  out <- httr2::with_mocked_responses(
    function(req) {
      seen <<- req$url
      resp
    },
    mc_feeds(1752, details = TRUE)
  )
  expect_equal(nrow(out), 2L)
  expect_equal(out$last_fetch_success, c(TRUE, FALSE))
  expect_match(seen, "/api/sources/feeds/details/\\?source_id=1752$")
})
