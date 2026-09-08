# Providers the backend knows about (settings.AVAILABLE_PROVIDERS).
mc_platforms <- c("onlinenews-mediacloud", "onlinenews-waybackmachine")


#' Assemble the parameters shared by every search endpoint
#'
#' `q`, `start` and `end` are all mandatory server side, and non-staff accounts
#' must additionally narrow the search with at least one collection or source.
#' Checking that here turns a wasted request — against a budget of two per
#' minute — into an immediate error.
#'
#' @noRd
mc_search_params <- function(query,
                             start_date,
                             end_date,
                             collection_id = NULL,
                             source_id = NULL,
                             platform = mc_platforms,
                             call = rlang::caller_env()) {
  if (!rlang::is_string(query) || !nzchar(query)) {
    cli::cli_abort(
      c(
        "{.arg query} must be a non-empty search string.",
        "i" = "Use {.str *} to match everything."
      ),
      call = call
    )
  }
  platform <- rlang::arg_match(platform, mc_platforms, error_call = call)

  cs <- fmt_ids(collection_id)
  ss <- fmt_ids(source_id)
  if (is.null(cs) && is.null(ss) &&
        !isTRUE(getOption("mediacloud.allow_unrestricted_search", FALSE))) {
    cli::cli_abort(
      c(
        "A search needs at least one {.arg collection_id} or {.arg source_id}.",
        "i" = "{.run mediacloud2::mc_collections(\"Germany\")} finds collection ids.",
        "i" = paste(
          "Staff accounts may search the whole archive; they can set",
          "{.code options(mediacloud.allow_unrestricted_search = TRUE)}."
        )
      ),
      call = call
    )
  }

  list(
    q = query,
    start = fmt_date(start_date, arg = "start_date", call = call),
    end = fmt_date(end_date, arg = "end_date", call = call),
    cs = cs,
    ss = ss,
    p = platform
  )
}


#' Count stories matching a query
#'
#' @param query the search string, in Elasticsearch/Lucene syntax. `"*"`
#'   matches everything.
#' @param start_date,end_date the period to search, as `Date` objects or
#'   `"YYYY-MM-DD"` strings. Both are required.
#' @param collection_id,source_id ids to search within, as returned by
#'   [mc_collections()] and [mc_sources()]. At least one of the two is
#'   required. Vectors are allowed.
#' @param platform which archive to query. `"onlinenews-mediacloud"` is the
#'   Media Cloud index; `"onlinenews-waybackmachine"` searches the Wayback
#'   Machine instead.
#' @inheritParams mc_version
#'
#' @returns A tibble with one row and two columns: `relevant`, the number of
#'   stories matching `query`, and `total`, the number of stories held for the
#'   same sources and period. The ratio of the two is the "attention" measure
#'   Media Cloud reports.
#'
#' @examples
#' \dontrun{
#' mc_story_count("klima", "2026-08-01", "2026-08-07", collection_id = 34412409)
#' }
#'
#' @export
mc_story_count <- function(query,
                           start_date,
                           end_date,
                           collection_id = NULL,
                           source_id = NULL,
                           platform = mc_platforms,
                           .token = NULL) {
  params <- mc_search_params(
    query, start_date, end_date, collection_id, source_id, platform
  )
  body <- mc_perform(rlang::inject(
    mc_req("search/total-count", !!!params, .token = .token)
  ))
  out <- tibble::tibble(
    relevant = body$count$relevant %||% NA_integer_,
    total = body$count$total %||% NA_integer_
  )
  with_raw(out, attr(body, "response"))
}


#' Count matching stories over time
#'
#' @inheritParams mc_story_count
#'
#' @returns A tibble with one row per day: `date`, `count` (matching stories),
#'   `total_count` (all stories that day) and `ratio`. The overall totals are
#'   attached as the attributes `total` and `normalized_total`.
#'
#' @examples
#' \dontrun{
#' mc_count_over_time("klima", "2026-08-01", "2026-08-07", collection_id = 34412409)
#' }
#'
#' @export
mc_count_over_time <- function(query,
                               start_date,
                               end_date,
                               collection_id = NULL,
                               source_id = NULL,
                               platform = mc_platforms,
                               .token = NULL) {
  params <- mc_search_params(
    query, start_date, end_date, collection_id, source_id, platform
  )
  body <- mc_perform(rlang::inject(
    mc_req("search/count-over-time", !!!params, .token = .token)
  ))
  cot <- body$count_over_time
  out <- mc_dates(as_tbl(cot$counts))
  attr(out, "total") <- cot$total
  attr(out, "normalized_total") <- cot$normalized_total
  with_raw(out, attr(body, "response"))
}


#' Attention per source over time
#'
#' @description Splits the matching stories by source and by time bucket, which
#'   is what the "attention over time by source" view of the web app shows.
#'
#' @param interval size of the time buckets: `"day"`, `"week"`, `"month"` or
#'   `"year"`.
#' @inheritParams mc_story_count
#'
#' @returns A tibble with one row per source and bucket: `media_name`,
#'   `interval`, `bucket`, `matching_stories`, `total_stories` and `ratio`.
#'
#' @details The server refuses queries whose number of sources times number of
#'   buckets is too large, so narrow the period or use a coarser `interval`
#'   when searching a big collection. This endpoint costs four quota hits.
#'
#' @examples
#' \dontrun{
#' mc_count_by_source("klima", "2026-08-01", "2026-08-31",
#'                    collection_id = 34412409, interval = "week")
#' }
#'
#' @export
mc_count_by_source <- function(query,
                               start_date,
                               end_date,
                               collection_id = NULL,
                               source_id = NULL,
                               interval = c("week", "day", "month", "year"),
                               platform = mc_platforms,
                               .token = NULL) {
  interval <- rlang::arg_match(interval)
  params <- mc_search_params(
    query, start_date, end_date, collection_id, source_id, platform
  )
  body <- mc_perform(rlang::inject(mc_req(
    "search/count-by-source-over-interval",
    !!!params,
    interval = interval,
    .token = .token
  )))
  out <- mc_dates(as_tbl(body[["source-interval-attention"]]))
  with_raw(out, attr(body, "response"))
}


#' Fetch matching stories
#'
#' @description Returns the story metadata matching a query. Paging is handled
#'   internally: the endpoint hands back a `pagination_token` which is fed back
#'   until the archive is exhausted or `max_results` is reached.
#'
#' @param max_results how many stories to fetch. Defaults to all of them, which
#'   for a broad query can be a very long pull at two requests per minute — set
#'   a limit when exploring.
#' @param page_size how many stories to ask for per request.
#' @param sort_order `"desc"` (newest indexed first, the default) or `"asc"`.
#' @param expanded if `TRUE`, request the full story text. This is restricted
#'   to staff accounts and will fail with "You are not permitted to fetch
#'   `expanded` stories" for everyone else.
#' @param randomize if `TRUE`, sample pages at random rather than in order.
#'   Also staff only.
#' @inheritParams mc_story_count
#'
#' @returns A tibble with one row per story: `id`, `title`, `url`,
#'   `publish_date` (a `Date`), `indexed_date` (a `POSIXct`), `language`,
#'   `media_name` and `media_url`.
#'
#' @examples
#' \dontrun{
#' mc_story_list("klima", "2026-08-01", "2026-08-07",
#'               collection_id = 34412409, max_results = 200)
#' }
#'
#' @export
mc_story_list <- function(query,
                          start_date,
                          end_date,
                          collection_id = NULL,
                          source_id = NULL,
                          max_results = Inf,
                          page_size = NULL,
                          sort_order = NULL,
                          expanded = FALSE,
                          randomize = FALSE,
                          platform = mc_platforms,
                          .token = NULL) {
  params <- mc_search_params(
    query, start_date, end_date, collection_id, source_id, platform
  )
  res <- rlang::inject(mc_page_token(
    "search/story-list",
    !!!params,
    page_size = page_size,
    sort_order = sort_order,
    # the server compares these against the string "1"
    expanded = if (isTRUE(expanded)) "1",
    randomize = if (isTRUE(randomize)) "1",
    max_results = max_results,
    .token = .token
  ))
  mc_dates(as_tbl(res))
}


#' Fetch a sample of matching stories
#'
#' @description A single unordered page of matching stories, cheaper than
#'   paging through the whole result set when you only want a feel for what a
#'   query matches.
#'
#' @inheritParams mc_story_count
#'
#' @returns A tibble with one row per story, with the same columns as
#'   [mc_story_list()].
#'
#' @examples
#' \dontrun{
#' mc_story_sample("klima", "2026-08-01", "2026-08-07", collection_id = 34412409)
#' }
#'
#' @export
mc_story_sample <- function(query,
                            start_date,
                            end_date,
                            collection_id = NULL,
                            source_id = NULL,
                            platform = mc_platforms,
                            .token = NULL) {
  params <- mc_search_params(
    query, start_date, end_date, collection_id, source_id, platform
  )
  body <- mc_perform(rlang::inject(
    mc_req("search/sample", !!!params, .token = .token)
  ))
  with_raw(mc_dates(as_tbl(body$sample)), attr(body, "response"))
}


#' Look up a single story
#'
#' @param id a story id, as returned in the `id` column of [mc_story_list()].
#' @inheritParams mc_story_count
#'
#' @returns A tibble with one row. Non-staff accounts do not receive the
#'   article text; the `text` column is stripped server side.
#'
#' @examples
#' \dontrun{
#' stories <- mc_story_list("klima", "2026-08-01", "2026-08-07",
#'                          collection_id = 34412409, max_results = 1)
#' mc_story(stories$id[1])
#' }
#'
#' @export
mc_story <- function(id, platform = mc_platforms, .token = NULL) {
  if (!rlang::is_string(id)) {
    cli::cli_abort("{.arg id} must be a single story id.")
  }
  platform <- rlang::arg_match(platform, mc_platforms)
  # this endpoint looks a story up directly, so it takes neither a query nor
  # a date range
  body <- mc_get(
    "search/story",
    storyId = id,
    platform = platform,
    .token = .token
  )
  with_raw(mc_dates(as_tbl(body$story)), attr(body, "response"))
}


#' Top words in matching stories
#'
#' @param limit how many terms to return.
#' @inheritParams mc_story_count
#'
#' @returns A tibble with one row per term: `term`, `term_count`, `term_ratio`,
#'   `doc_count`, `doc_ratio` and `sample_size`. Counts are taken from a sample
#'   of the matching stories, not from all of them.
#'
#' @details Costs four quota hits.
#'
#' @examples
#' \dontrun{
#' mc_words("klima", "2026-08-01", "2026-08-07", collection_id = 34412409)
#' }
#'
#' @export
mc_words <- function(query,
                     start_date,
                     end_date,
                     collection_id = NULL,
                     source_id = NULL,
                     limit = NULL,
                     platform = mc_platforms,
                     .token = NULL) {
  params <- mc_search_params(
    query, start_date, end_date, collection_id, source_id, platform
  )
  body <- mc_perform(rlang::inject(
    mc_req("search/words", !!!params, limit = limit, .token = .token)
  ))
  with_raw(as_tbl(body$words), attr(body, "response"))
}


#' Which sources carried the matching stories
#'
#' @inheritParams mc_story_count
#'
#' @returns A tibble with one row per source, with the source name and the
#'   number of matching stories it carried.
#'
#' @details How many sources come back is decided by the server, which passes
#'   its own value positionally; there is no `limit` argument to set. Costs
#'   four quota hits.
#'
#' @examples
#' \dontrun{
#' mc_attention_by_source("klima", "2026-08-01", "2026-08-07",
#'                        collection_id = 34412409)
#' }
#'
#' @export
mc_attention_by_source <- function(query,
                                   start_date,
                                   end_date,
                                   collection_id = NULL,
                                   source_id = NULL,
                                   platform = mc_platforms,
                                   .token = NULL) {
  params <- mc_search_params(
    query, start_date, end_date, collection_id, source_id, platform
  )
  body <- mc_perform(rlang::inject(
    mc_req("search/sources", !!!params, .token = .token)
  ))
  with_raw(as_tbl(body$sources), attr(body, "response"))
}


#' Languages of the matching stories
#'
#' @param limit how many languages to return.
#' @inheritParams mc_story_count
#'
#' @returns A tibble with one row per language.
#'
#' @details Costs two quota hits.
#'
#' @examples
#' \dontrun{
#' mc_languages("klima", "2026-08-01", "2026-08-07", collection_id = 34412409)
#' }
#'
#' @export
mc_languages <- function(query,
                         start_date,
                         end_date,
                         collection_id = NULL,
                         source_id = NULL,
                         limit = NULL,
                         platform = mc_platforms,
                         .token = NULL) {
  params <- mc_search_params(
    query, start_date, end_date, collection_id, source_id, platform
  )
  body <- mc_perform(rlang::inject(
    mc_req("search/languages", !!!params, limit = limit, .token = .token)
  ))
  with_raw(as_tbl(body$languages), attr(body, "response"))
}
