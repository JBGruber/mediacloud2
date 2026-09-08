test_that("search parameters use the names the API actually reads", {
  params <- mc_search_params(
    "klima", "2026-08-01", "2026-08-07",
    collection_id = 34412409, source_id = c(1, 2)
  )
  expect_equal(params$q, "klima")
  expect_equal(params$start, "2026-08-01")
  expect_equal(params$end, "2026-08-07")
  expect_equal(params$cs, "34412409")
  expect_equal(params$ss, "1,2")
  # the platform parameter is `p`; a parameter spelled `platform` is silently
  # ignored by the backend
  expect_equal(params$p, "onlinenews-mediacloud")
  expect_false("platform" %in% names(params))
})


test_that("search parameters accept Date objects", {
  params <- mc_search_params(
    "klima", as.Date("2026-08-01"), as.Date("2026-08-07"),
    collection_id = 34412409
  )
  expect_equal(params$start, "2026-08-01")
  expect_equal(params$end, "2026-08-07")
})


test_that("a search must be narrowed to a collection or source", {
  # the backend rejects an unnarrowed search for everyone but staff, so catch
  # it here rather than spending one of two requests per minute on it
  expect_error(
    mc_search_params("klima", "2026-08-01", "2026-08-07"),
    "at least one"
  )
  withr::with_options(
    list(mediacloud.allow_unrestricted_search = TRUE),
    expect_no_error(mc_search_params("klima", "2026-08-01", "2026-08-07"))
  )
})


test_that("an empty query is refused", {
  expect_error(
    mc_search_params("", "2026-08-01", "2026-08-07", collection_id = 1),
    "non-empty search string"
  )
})


test_that("an unknown platform is refused", {
  expect_error(
    mc_search_params("k", "2026-08-01", "2026-08-07",
                     collection_id = 1, platform = "twitter"),
    "twitter"
  )
})


test_that("mc_story_count returns matching and total counts", {
  local_fake_token()
  local_no_throttle()

  seen <- NULL
  out <- httr2::with_mocked_responses(
    function(req) {
      seen <<- req$url
      fixture_resp("total_count")
    },
    mc_story_count("klima", "2026-08-01", "2026-08-07", collection_id = 34412409)
  )
  expect_equal(nrow(out), 1L)
  expect_equal(out$relevant, 279L)
  expect_equal(out$total, 24071L)
  expect_match(seen, "/api/search/total-count\\?")
  expect_match(seen, "cs=34412409")
  expect_match(seen, "p=onlinenews-mediacloud")
})


test_that("mc_count_over_time returns a daily series with totals attached", {
  local_fake_token()
  local_no_throttle()

  out <- httr2::with_mocked_responses(
    mock_always(fixture_resp("count_over_time")),
    mc_count_over_time("klima", "2026-08-01", "2026-08-07",
                       collection_id = 34412409)
  )
  expect_s3_class(out$date, "Date")
  expect_true(all(c("count", "total_count", "ratio") %in% names(out)))
  expect_equal(attr(out, "total"), 279L)
  expect_equal(attr(out, "normalized_total"), 24071L)
})


test_that("mc_count_by_source unpacks the dashed result key", {
  local_fake_token()
  local_no_throttle()

  seen <- NULL
  out <- httr2::with_mocked_responses(
    function(req) {
      seen <<- req$url
      fixture_resp("count_by_source")
    },
    mc_count_by_source("klima", "2026-08-01", "2026-08-07",
                       collection_id = 34412409, interval = "week")
  )
  expect_true(all(c("media_name", "bucket", "matching_stories",
                    "total_stories", "ratio") %in% names(out)))
  expect_s3_class(out$bucket, "Date")
  expect_match(seen, "interval=week")
})


test_that("mc_count_by_source rejects an interval the server does not know", {
  expect_error(
    mc_count_by_source("k", "2026-08-01", "2026-08-07",
                       collection_id = 1, interval = "fortnight"),
    "fortnight"
  )
})


test_that("mc_story_list parses story dates", {
  local_fake_token()
  local_no_throttle()

  out <- httr2::with_mocked_responses(
    mock_always(fixture_resp("story_list")),
    mc_story_list("klima", "2026-08-01", "2026-08-07",
                  collection_id = 34412409, .token = NULL)
  )
  expect_true(all(c("id", "title", "url", "media_name") %in% names(out)))
  expect_s3_class(out$publish_date, "Date")
  expect_s3_class(out$indexed_date, "POSIXct")
})


test_that("mc_story_list sends the staff-only flags as the server spells them", {
  local_fake_token()
  local_no_throttle()

  seen <- NULL
  httr2::with_mocked_responses(
    function(req) {
      seen <<- req$url
      fixture_resp("story_list")
    },
    mc_story_list("klima", "2026-08-01", "2026-08-07", collection_id = 1,
                  expanded = TRUE, randomize = TRUE, page_size = 50,
                  sort_order = "asc")
  )
  # the backend compares these against the string "1"
  expect_match(seen, "expanded=1")
  expect_match(seen, "randomize=1")
  expect_match(seen, "page_size=50")
  expect_match(seen, "sort_order=asc")
})


test_that("mc_story_list omits the flags when they are off", {
  local_fake_token()
  local_no_throttle()

  seen <- NULL
  httr2::with_mocked_responses(
    function(req) {
      seen <<- req$url
      fixture_resp("story_list")
    },
    mc_story_list("klima", "2026-08-01", "2026-08-07", collection_id = 1)
  )
  expect_no_match(seen, "expanded")
  expect_no_match(seen, "randomize")
})


test_that("mc_words passes a limit through", {
  local_fake_token()
  local_no_throttle()

  seen <- NULL
  out <- httr2::with_mocked_responses(
    function(req) {
      seen <<- req$url
      fixture_resp("words")
    },
    mc_words("klima", "2026-08-01", "2026-08-07",
             collection_id = 34412409, limit = 5)
  )
  expect_true(all(c("term", "term_count", "doc_count") %in% names(out)))
  expect_match(seen, "limit=5")
})


test_that("mc_languages and mc_attention_by_source return tibbles", {
  local_fake_token()
  local_no_throttle()

  langs <- httr2::with_mocked_responses(
    mock_always(fixture_resp("languages")),
    mc_languages("klima", "2026-08-01", "2026-08-07", collection_id = 1)
  )
  expect_true(all(c("language", "value", "ratio") %in% names(langs)))

  srcs <- httr2::with_mocked_responses(
    mock_always(fixture_resp("search_sources")),
    mc_attention_by_source("klima", "2026-08-01", "2026-08-07", collection_id = 1)
  )
  expect_true(all(c("source", "count") %in% names(srcs)))
})


test_that("mc_story_sample returns story rows", {
  local_fake_token()
  local_no_throttle()

  out <- httr2::with_mocked_responses(
    mock_always(fixture_resp("sample")),
    mc_story_sample("klima", "2026-08-01", "2026-08-07", collection_id = 1)
  )
  expect_s3_class(out$publish_date, "Date")
  expect_true("title" %in% names(out))
})


test_that("mc_story looks a story up by id, without a query or dates", {
  local_fake_token()
  local_no_throttle()

  seen <- NULL
  resp <- httr2::response_json(200, body = list(
    story = list(id = "abc", title = "A story", publish_date = "2026-08-04")
  ))
  out <- httr2::with_mocked_responses(
    function(req) {
      seen <<- req$url
      resp
    },
    mc_story("abc")
  )
  expect_equal(nrow(out), 1L)
  expect_s3_class(out$publish_date, "Date")
  expect_match(seen, "/api/search/story\\?")
  expect_match(seen, "storyId=abc")
  # this endpoint reads `platform`, not `p`, because it does not go through
  # the shared search-parameter parser
  expect_match(seen, "platform=onlinenews-mediacloud")
  expect_no_match(seen, "[?&]q=")
})


test_that("server-side validation errors are surfaced", {
  local_fake_token()
  local_no_throttle()

  httr2::with_mocked_responses(
    mock_always(fixture_resp("error_422", status = 422)),
    expect_error(
      mc_story_count("klima", "2026-08-01", "2026-08-07",
                     collection_id = 34412409),
      "Must have at least one"
    )
  )
})


test_that("the staff-only refusal is surfaced with its own message", {
  local_fake_token()
  local_no_throttle()

  httr2::with_mocked_responses(
    mock_always(fixture_resp("error_403", status = 403)),
    expect_error(
      mc_story_list("klima", "2026-08-01", "2026-08-07",
                    collection_id = 1, expanded = TRUE),
      "not permitted to fetch"
    )
  )
})
