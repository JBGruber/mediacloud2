test_that("as_tbl turns records into a tibble", {
  recs <- list(
    list(id = 1L, name = "a"),
    list(id = 2L, name = "b")
  )
  out <- as_tbl(recs)
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
  expect_equal(out$id, c(1L, 2L))
  expect_equal(out$name, c("a", "b"))
})


test_that("as_tbl fills in missing keys and nulls", {
  recs <- list(
    list(id = 1L, name = "a"),
    list(id = 2L),
    list(id = 3L, name = NULL, extra = TRUE)
  )
  out <- as_tbl(recs)
  expect_equal(nrow(out), 3L)
  expect_equal(out$name, c("a", NA, NA))
  expect_equal(out$extra, c(NA, NA, TRUE))
})


test_that("as_tbl keeps nested values in a list column", {
  recs <- list(
    list(id = 1L, tags = list("x", "y")),
    list(id = 2L, tags = list())
  )
  out <- as_tbl(recs)
  expect_type(out$tags, "list")
  expect_equal(out$tags[[1]], list("x", "y"))
})


test_that("as_tbl handles a single record and empty input", {
  expect_equal(nrow(as_tbl(list(id = 1L, name = "a"))), 1L)
  expect_equal(nrow(as_tbl(list())), 0L)
  expect_equal(nrow(as_tbl(NULL)), 0L)
})


test_that("timestamps parse from both separators the API uses", {
  # directory endpoints
  expect_equal(
    parse_dttm("2026-03-07T02:23:46.048704Z"),
    as.POSIXct("2026-03-07 02:23:46", tz = "UTC"),
    tolerance = 1e-3
  )
  # search endpoints
  expect_equal(
    parse_dttm("2026-08-31 10:22:32.862178+00:00"),
    as.POSIXct("2026-08-31 10:22:32", tz = "UTC"),
    tolerance = 1e-3
  )
})


test_that("last_story parses from both the month and the full form", {
  expect_equal(parse_month("09/2026"), as.Date("2026-09-01"))
  expect_equal(parse_month("2026-09-04"), as.Date("2026-09-04"))
  expect_equal(parse_month(NA_character_), as.Date(NA))
})


test_that("mc_dates converts by column name", {
  x <- tibble::tibble(
    publish_date = "2026-08-04",
    indexed_date = "2026-08-31 10:22:32.862178+00:00",
    last_story = "09/2026",
    title = "not a date"
  )
  out <- mc_dates(x)
  expect_s3_class(out$publish_date, "Date")
  expect_s3_class(out$indexed_date, "POSIXct")
  expect_s3_class(out$last_story, "Date")
  expect_type(out$title, "character")
})


test_that("outgoing dates are formatted, and bad ones rejected", {
  expect_equal(fmt_date(as.Date("2026-08-01")), "2026-08-01")
  expect_equal(fmt_date("2026-08-01"), "2026-08-01")
  expect_null(fmt_date(NULL))
  # the API also accepts MM/DD/YYYY, but sending an ambiguous date is a bug
  # waiting to happen
  expect_error(fmt_date("01/08/2026"), "must be a")
  expect_error(fmt_date("not a date"), "must be a")
})


test_that("feed filters are converted to epoch seconds", {
  expect_equal(fmt_epoch(as.POSIXct("2026-01-01", tz = "UTC")), "1767225600")
  expect_equal(fmt_epoch(1767225600), "1767225600")
  expect_null(fmt_epoch(NULL))
  # must not come out in scientific notation
  expect_false(grepl("e", fmt_epoch(as.Date("2026-01-01"))))
})


test_that("id vectors are collapsed the way the API expects", {
  expect_equal(fmt_ids(c(1, 2, 3)), "1,2,3")
  expect_equal(fmt_ids(34412409), "34412409")
  expect_null(fmt_ids(NULL))
  # large ids must not be mangled into scientific notation
  expect_equal(fmt_ids(262985213), "262985213")
})


test_that("check_id accepts one id and rejects the rest", {
  expect_equal(check_id(1752), "1752")
  expect_equal(check_id("1752"), "1752")
  expect_error(check_id(c(1, 2)), "must be a single id")
  expect_error(check_id(NA), "must be a single id")
  expect_error(check_id(TRUE), "must be a number")
})
