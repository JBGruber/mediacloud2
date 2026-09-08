#' List collections
#'
#' @description Collections are named groups of sources — mostly countries and
#'   regions, e.g. "Germany - National". Their ids are what you pass to the
#'   search functions.
#'
#' @param name search term. Multiple words are combined with AND and matched
#'   case-insensitively against the collection name, so `"Germany State"`
#'   finds "Germany - State & Local".
#' @param source_id restrict to collections that contain this source.
#' @param max_results maximum number of collections to return. Defaults to all
#'   of them.
#' @inheritParams mc_version
#'
#' @returns A tibble with one row per collection: `id`, `name`, `notes`,
#'   `platform`, `source_count`, `public`, `featured`, `managed`,
#'   `modified_at`, `featured_rank` and `monitored`.
#'
#' @details The API only holds online news collections, and returns them
#'   sorted by number of sources, largest first. Unless your account is staff,
#'   only public collections are visible.
#'
#' @examples
#' \dontrun{
#' mc_collections("Germany")
#' }
#'
#' @export
mc_collections <- function(name = NULL,
                           source_id = NULL,
                           max_results = Inf,
                           .token = NULL) {
  res <- mc_page_offset(
    "sources/collections/",
    name = name,
    source_id = source_id,
    max_results = max_results,
    .token = .token
  )
  mc_dates(as_tbl(res))
}


#' Look up one collection by id
#'
#' @param id a collection id.
#' @inheritParams mc_version
#'
#' @returns A tibble with one row. See [mc_collections()] for the columns.
#'
#' @examples
#' \dontrun{
#' # United States - National
#' mc_collection(34412234)
#' }
#'
#' @export
mc_collection <- function(id, .token = NULL) {
  id <- check_id(id)
  body <- mc_get(paste0("sources/collections/", id, "/"), .token = .token)
  with_raw(mc_dates(as_tbl(body)), attr(body, "response"))
}


#' List sources
#'
#' @description Sources are the individual outlets — one row per domain.
#'
#' @param collection_id restrict to sources in this collection. This is the
#'   usual way to use the function; see also [mc_collection_sources()].
#' @param name search term, matched case-insensitively against the source
#'   name, its label and its alternative domains. Multiple words are combined
#'   with AND.
#' @param max_results maximum number of sources to return.
#' @inheritParams mc_version
#'
#' @returns A tibble with one row per source, including `id`, `name`,
#'   `label`, `homepage`, `stories_per_week`, `last_story`, `pub_country`,
#'   `pub_state`, `primary_language`, `media_type` and `collection_count`.
#'
#' @details Sources come back sorted by `stories_per_week`, busiest first.
#'   `last_story` is only reported to the month by this endpoint, so it is
#'   returned as the first day of that month.
#'
#' @examples
#' \dontrun{
#' mc_sources(collection_id = 34412409)
#' mc_sources(name = "spiegel")
#' }
#'
#' @export
mc_sources <- function(collection_id = NULL,
                       name = NULL,
                       max_results = Inf,
                       .token = NULL) {
  res <- mc_page_offset(
    "sources/sources/",
    collection_id = collection_id,
    name = name,
    max_results = max_results,
    .token = .token
  )
  mc_dates(as_tbl(res))
}


#' Look up one source by id
#'
#' @param id a source id.
#' @inheritParams mc_version
#'
#' @returns A tibble with one row. See [mc_sources()] for the columns.
#'
#' @examples
#' \dontrun{
#' mc_source(1752)
#' }
#'
#' @export
mc_source <- function(id, .token = NULL) {
  id <- check_id(id)
  body <- mc_get(paste0("sources/sources/", id, "/"), .token = .token)
  with_raw(mc_dates(as_tbl(body)), attr(body, "response"))
}


#' List the RSS feeds of a source
#'
#' @param source_id the source whose feeds you want.
#' @param modified_since,modified_before only return feeds modified in this
#'   window. Accepts `Date`, `POSIXct` or epoch seconds.
#' @param details if `TRUE`, ask the RSS fetcher for its view of the feeds
#'   (fetch state, error counts) instead of the stored records. This is a
#'   different, unpaginated endpoint with a different set of columns.
#' @param max_results maximum number of feeds to return. Ignored when
#'   `details = TRUE`.
#' @inheritParams mc_version
#'
#' @returns A tibble with one row per feed: `id`, `url`, `name`, `source`,
#'   `admin_rss_enabled`, `created_at` and `modified_at`.
#'
#' @examples
#' \dontrun{
#' mc_feeds(source_id = 1752)
#' }
#'
#' @export
mc_feeds <- function(source_id,
                     modified_since = NULL,
                     modified_before = NULL,
                     details = FALSE,
                     max_results = Inf,
                     .token = NULL) {
  source_id <- check_id(source_id)
  if (isTRUE(details)) {
    # this endpoint proxies the RSS fetcher and nests its payload under
    # "feeds" rather than paginating
    body <- mc_get(
      "sources/feeds/details/",
      source_id = source_id,
      .token = .token
    )
    return(with_raw(mc_dates(as_tbl(body$feeds)), attr(body, "response")))
  }
  res <- mc_page_offset(
    "sources/feeds/",
    source_id = source_id,
    modified_since = fmt_epoch(modified_since),
    modified_before = fmt_epoch(modified_before),
    max_results = max_results,
    .token = .token
  )
  mc_dates(as_tbl(res))
}


check_id <- function(id, arg = rlang::caller_arg(id), call = rlang::caller_env()) {
  if (length(id) != 1L || is.na(id)) {
    cli::cli_abort("{.arg {arg}} must be a single id.", call = call)
  }
  if (is.character(id)) {
    return(id)
  }
  if (!is.numeric(id)) {
    cli::cli_abort("{.arg {arg}} must be a number.", call = call)
  }
  format(id, scientific = FALSE, trim = TRUE)
}
