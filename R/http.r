# Base URL of the v4 API. The endpoints live under the search web app, not
# under the retired api.mediacloud.org host.
mc_base_url <- function() {
  getOption("mediacloud.base_url", "https://search.mediacloud.org/api/")
}


mc_user_agent <- function() {
  paste0(
    "mediacloud2/",
    utils::packageVersion("mediacloud2"),
    " (https://github.com/JBGruber/mediacloud2)"
  )
}


#' Build a request against the Media Cloud API
#'
#' @param .endpoint path below the API root. Trailing slashes are significant
#'   on the directory endpoints and must be kept; the search endpoints have
#'   none. Dot-prefixed because the search endpoints take a parameter called
#'   `end`, which R would otherwise partially match onto an `endpoint` formal.
#' @param ... query parameters. `NULL` parameters are dropped.
#' @param .token optional token, or path to a token file, used instead of the
#'   stored one.
#' @noRd
mc_req <- function(.endpoint, ..., .token = NULL) {
  req <- httr2::request(mc_base_url())
  req <- httr2::req_url_path_append(req, .endpoint)
  req <- req_token(req, .token = .token)
  req <- httr2::req_headers(req, Accept = "application/json")
  req <- httr2::req_user_agent(req, mc_user_agent())
  req <- httr2::req_error(req, body = mc_error_body)
  req <- httr2::req_retry(
    req,
    max_tries = getOption("mediacloud.max_tries", 3L),
    is_transient = mc_is_transient,
    backoff = function(i) min(60, 5 * 2^i)
  )
  req <- mc_throttle(req, .endpoint)

  params <- rlang::list2(...)
  params <- params[!vapply(params, is.null, logical(1))]
  if (length(params) > 0L) {
    req <- httr2::req_url_query(req, !!!params, .multi = "comma")
  }
  req
}


# Only /api/search/* is rate limited server side: `query_rate()` in the backend
# returns 2/m for ordinary token users and 100/m for staff. The directory
# endpoints carry no limit, so throttling them would only slow things down.
mc_throttle <- function(req, .endpoint) {
  if (!grepl("^search/", .endpoint)) {
    return(req)
  }
  rate <- getOption("mediacloud.rate", 2)
  if (is.null(rate) || !is.finite(rate) || rate <= 0) {
    return(req)
  }
  httr2::req_throttle(
    req,
    capacity = rate,
    fill_time_s = 60,
    realm = "mediacloud-search"
  )
}


# 429 and 5xx are the obvious ones. The backend also answers some transient
# upstream failures with 400 plus `"temporary": true`, so honour that flag.
mc_is_transient <- function(resp) {
  status <- httr2::resp_status(resp)
  if (status == 429 || status >= 500) {
    return(TRUE)
  }
  isTRUE(mc_body_json(resp)$temporary)
}


# Body parsed defensively: error bodies are not always JSON, and a mistyped
# endpoint is answered by the front end catch-all with an HTML page.
mc_body_json <- function(resp) {
  tryCatch(
    httr2::resp_body_json(resp, check_type = FALSE),
    error = function(e) NULL
  )
}


# Error payloads come in four shapes, depending on which part of the backend
# answered: `note` (search views), `message` and `error` (auth views) and
# `detail` (Django REST framework).
mc_error_body <- function(resp) {
  body <- mc_body_json(resp)
  if (is.null(body)) {
    return(NULL)
  }
  msg <- body$note %||% body$message %||% body$detail %||% body$error
  if (is.null(msg)) {
    return(NULL)
  }
  # plain text, no cli markup: httr2 passes these lines through as they are,
  # so anything like {.run ...} would reach the user unrendered
  info <- paste(as.character(msg), collapse = " ")
  status <- httr2::resp_status(resp)
  if (status == 403L) {
    info <- c(info, "Check that your token is valid with `mc_profile()`.")
  }
  if (status == 429L) {
    info <- c(info, paste(
      "The API allows 2 search requests per minute;",
      "set `options(mediacloud.rate = )` if your key is allowed more."
    ))
  }
  info
}


#' Perform a request and return the parsed JSON body
#'
#' Unknown paths are swallowed by the web app's catch-all route, which answers
#' 200 with an HTML page rather than 404, so the content type is checked
#' instead of trusted.
#'
#' @noRd
mc_perform <- function(req) {
  resp <- httr2::req_perform(req)
  type <- httr2::resp_content_type(resp)
  if (!identical(type, "application/json")) {
    cli::cli_abort(c(
      "The API did not return JSON.",
      "x" = "{.url {req$url}} answered with {.val {type %||% 'no content type'}}.",
      "i" = "This usually means the endpoint does not exist."
    ))
  }
  body <- httr2::resp_body_json(resp)
  attr(body, "response") <- resp
  body
}


mc_get <- function(.endpoint, ..., .token = NULL) {
  mc_perform(mc_req(.endpoint, ..., .token = .token))
}


#' Page through an offset-paginated directory endpoint
#'
#' The directory endpoints use DRF's `LimitOffsetPagination` with a server page
#' size of 100 and always answer `{count, next, previous, results}`. Rather
#' than recomputing offsets, follow the `next` URL the server hands back and
#' stop when it is `null`.
#'
#' @noRd
mc_page_offset <- function(.endpoint,
                           ...,
                           max_results = Inf,
                           .token = NULL,
                           .key = "results",
                           .progress = TRUE) {
  limit <- if (is.finite(max_results)) min(100L, max_results) else 100L
  req <- mc_req(.endpoint, ..., limit = limit, .token = .token)

  out <- list()
  n <- 0L
  total <- NA_integer_
  id <- NULL
  repeat {
    body <- mc_perform(req)
    page <- body[[.key]] %||% list()
    out <- c(out, page)
    n <- length(out)

    if (is.null(id) && isTRUE(.progress)) {
      total <- body$count %||% NA_integer_
      # only worth a progress bar if there is more than one page to fetch
      if (!is.na(total) && total > length(page)) {
        id <- cli::cli_progress_bar(
          "Fetching {min(total, max_results)} record{?s}",
          total = min(total, max_results)
        )
      } else {
        id <- NA
      }
    }
    if (!is.null(id) && !is.na(id)) {
      # a server page can overshoot max_results, and a bar set past its total
      # errors rather than just looking odd
      cli::cli_progress_update(
        set = min(n, min(total, max_results, na.rm = TRUE)),
        id = id
      )
    }

    nxt <- body[["next"]]
    # `length()` rather than `is.null()`, for the same reason as the
    # pagination token below: an empty JSON object or array parses to an empty
    # list, which is not NULL and would keep the loop going forever
    if (length(nxt) == 0L || n >= max_results) {
      break
    }
    req <- mc_next_req(req, nxt)
  }
  if (!is.null(id) && !is.na(id)) {
    cli::cli_progress_done(id = id)
  }

  if (n > max_results) {
    out <- out[seq_len(max_results)]
  }
  out
}


# Reuse the configured request (token, retries, throttle) but point it at the
# absolute `next` URL the server returned.
mc_next_req <- function(req, url) {
  req$url <- url
  req
}


#' Page through a token-paginated search endpoint
#'
#' `search/story-list` hands back a `pagination_token` that has to be fed into
#' the next call, and returns it as `null` on the last page.
#'
#' @noRd
mc_page_token <- function(.endpoint,
                          ...,
                          max_results = Inf,
                          .token = NULL,
                          .key = "stories",
                          .progress = TRUE) {
  params <- rlang::list2(...)
  out <- list()
  token <- NULL
  id <- NULL
  if (isTRUE(.progress) && !is.finite(max_results)) {
    id <- cli::cli_progress_bar(
      "Fetching stories",
      total = NA
    )
  } else if (isTRUE(.progress)) {
    id <- cli::cli_progress_bar(
      "Fetching {max_results} stor{?y/ies}",
      total = max_results
    )
  }

  repeat {
    body <- mc_perform(rlang::inject(mc_req(
      .endpoint,
      !!!params,
      pagination_token = token,
      .token = .token
    )))
    page <- body[[.key]] %||% list()
    out <- c(out, page)

    if (!is.null(id)) {
      cli::cli_progress_update(
        set = min(length(out), max_results),
        id = id
      )
    }

    token <- body$pagination_token
    # `length(token) == 0` rather than `is.null()`: the last page reports the
    # token as JSON null, which parses to NULL, but an empty JSON object or
    # array would parse to an empty list and slip past an is.null() check. An
    # empty page also means "done", so a server that kept handing back a token
    # cannot spin here forever.
    if (length(token) == 0L || length(page) == 0L || length(out) >= max_results) {
      break
    }
  }
  if (!is.null(id)) {
    cli::cli_progress_done(id = id)
  }

  if (length(out) > max_results) {
    out <- out[seq_len(max_results)]
  }
  out
}
