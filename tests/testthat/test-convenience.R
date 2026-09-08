test_that("mc_find_collections trims to the useful columns", {
  local_fake_token()

  out <- httr2::with_mocked_responses(
    mock_always(fixture_resp("collections")),
    mc_find_collections("Germany")
  )
  expect_equal(names(out), c("id", "name", "source_count", "monitored"))
  expect_error(mc_find_collections(c("a", "b")), "single string")
})


test_that("mc_collection_sources takes an id straight through", {
  local_fake_token()

  seen <- character()
  out <- httr2::with_mocked_responses(
    function(req) {
      seen <<- c(seen, req$url)
      fixture_resp("sources")
    },
    mc_collection_sources(34412409, max_results = 3)
  )
  # an id needs no lookup, so only the sources endpoint is touched
  expect_length(seen, 1L)
  expect_match(seen, "/api/sources/sources/\\?collection_id=34412409")
  expect_s3_class(out, "tbl_df")
})


test_that("mc_collection_sources resolves an exact collection name", {
  local_fake_token()

  seen <- character()
  httr2::with_mocked_responses(
    function(req) {
      seen <<- c(seen, req$url)
      if (grepl("collections", req$url)) {
        fixture_resp("collections")
      } else {
        fixture_resp("sources")
      }
    },
    mc_collection_sources("Germany - National", max_results = 3)
  )
  expect_length(seen, 2L)
  expect_match(seen[1], "/api/sources/collections/\\?name=Germany")
  expect_match(seen[2], "collection_id=34412409")
})


test_that("an ambiguous collection name is refused, with the candidates", {
  local_fake_token()

  # picking one of several silently would make a script's results depend on
  # which collections happened to exist when it ran
  expect_error(
    httr2::with_mocked_responses(
      mock_always(fixture_resp("collections")),
      mc_collection_sources("Germany")
    ),
    "matches 20 collections"
  )
})


test_that("a name that matches nothing is refused", {
  local_fake_token()

  empty <- mock_json('{"count": 0, "next": null, "previous": null, "results": []}')
  expect_error(
    httr2::with_mocked_responses(
      mock_always(empty),
      mc_collection_sources("Atlantis")
    ),
    "No collection matches"
  )
})


test_that("a single match is used even without an exact name", {
  local_fake_token()

  one <- mock_json(paste0(
    '{"count": 1, "next": null, "previous": null, "results": [',
    '{"id": 34412409, "name": "Germany - National", "source_count": 61}]}'
  ))
  seen <- character()
  httr2::with_mocked_responses(
    function(req) {
      seen <<- c(seen, req$url)
      if (grepl("collections", req$url)) one else fixture_resp("sources")
    },
    mc_collection_sources("Germany - Nat")
  )
  expect_match(seen[2], "collection_id=34412409")
})
