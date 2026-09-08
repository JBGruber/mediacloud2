the <- new.env()

`%||%` <- function(x, y) if (is.null(x)) y else x


#' Turn a list of API records into a tibble
#'
#' The API returns lists of records with occasionally missing keys and `null`
#' values. Columns that are scalar in every record become atomic vectors,
#' everything else stays a list column.
#'
#' @param x a list of records, or a single named record.
#' @noRd
as_tbl <- function(x) {
  if (is.null(x) || length(x) == 0L) {
    return(tibble::tibble())
  }
  # a single record arrives as a named list; wrap it so it becomes one row
  if (!is.null(names(x))) {
    x <- list(x)
  }
  nms <- unique(unlist(lapply(x, names), use.names = FALSE))
  if (is.null(nms)) {
    return(tibble::tibble(value = simplify_col(x)))
  }
  cols <- lapply(nms, function(n) {
    simplify_col(lapply(x, function(rec) rec[[n]] %||% NA))
  })
  names(cols) <- nms
  tibble::new_tibble(cols, nrow = length(x))
}


# one column's worth of values: atomic when every row holds a scalar, a list
# column otherwise
simplify_col <- function(vals) {
  scalar <- vapply(
    vals,
    function(v) is.atomic(v) && length(v) == 1L,
    logical(1)
  )
  if (!all(scalar)) {
    return(vals)
  }
  tryCatch(vctrs::vec_c(!!!vals), error = function(e) vals)
}


# The API spells dates in three ways, and which one you get depends on the
# endpoint rather than on the field, so conversion happens by name.
# Timestamps are UTC throughout, but the separator is not consistent: the
# directory endpoints send "2026-03-07T02:23:46.048704Z" and the search
# endpoints "2026-08-31 10:22:32.862178+00:00".
parse_dttm <- function(x) {
  if (!is.character(x)) {
    return(x)
  }
  as.POSIXct(sub("T", " ", x, fixed = TRUE),
             format = "%Y-%m-%d %H:%M:%OS", tz = "UTC")
}


parse_date <- function(x) {
  if (!is.character(x)) {
    return(x)
  }
  as.Date(substr(x, 1L, 10L), format = "%Y-%m-%d")
}


# `last_story` comes back as "MM/YYYY" from the source list and retrieve
# endpoints, but as a full timestamp elsewhere; anchor both to the first of
# the month
parse_month <- function(x) {
  if (!is.character(x)) {
    return(x)
  }
  out <- as.Date(rep(NA_character_, length(x)))
  short <- !is.na(x) & nchar(x) == 7L & grepl("/", x, fixed = TRUE)
  out[short] <- as.Date(paste0("01/", x[short]), format = "%d/%m/%Y")
  out[!short] <- parse_date(x[!short])
  out
}


mc_dttm_cols <- c("modified_at", "created_at", "last_rescraped", "indexed_date")
mc_date_cols <- c("publish_date", "week", "bucket")


# convert the date-ish columns of a parsed response in place
mc_dates <- function(x) {
  for (n in intersect(mc_dttm_cols, names(x))) {
    x[[n]] <- parse_dttm(x[[n]])
  }
  for (n in intersect(mc_date_cols, names(x))) {
    x[[n]] <- parse_date(x[[n]])
  }
  if ("last_story" %in% names(x)) {
    x[["last_story"]] <- parse_month(x[["last_story"]])
  }
  if ("date" %in% names(x)) {
    x[["date"]] <- parse_date(x[["date"]])
  }
  x
}


# dates go out as YYYY-MM-DD; the server also accepts MM/DD/YYYY, but there is
# no reason to send the ambiguous one
fmt_date <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (is.null(x)) {
    return(NULL)
  }
  if (inherits(x, c("Date", "POSIXt"))) {
    return(format(as.Date(x), "%Y-%m-%d"))
  }
  x <- as.character(x)
  parsed <- as.Date(x, format = "%Y-%m-%d")
  if (anyNA(parsed)) {
    cli::cli_abort(
      "{.arg {arg}} must be a {.cls Date} or a {.str YYYY-MM-DD} string.",
      call = call
    )
  }
  format(parsed, "%Y-%m-%d")
}


# feed modification filters are epoch seconds, not ISO dates
fmt_epoch <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (is.numeric(x)) {
    return(format(x, scientific = FALSE))
  }
  if (inherits(x, "Date")) {
    x <- as.POSIXct(as.character(x), tz = "UTC")
  }
  format(as.numeric(as.POSIXct(x)), scientific = FALSE)
}


# `cs` and `ss` are comma separated, and R users will pass vectors
fmt_ids <- function(x) {
  if (is.null(x) || length(x) == 0L) {
    return(NULL)
  }
  paste(format(x, scientific = FALSE, trim = TRUE), collapse = ",")
}


# Attach the raw response so users can escape the tibble when they need to.
# Only the single-request functions carry one: a paged result is assembled from
# many responses, and attaching just the last would invite people to trust it
# as "the" response for the whole call.
with_raw <- function(x, raw) {
  attr(x, "response") <- raw
  x
}
