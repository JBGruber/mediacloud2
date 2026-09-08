#' Find the collection ids for a country
#'
#' @description A trimmed-down [mc_collections()] for the job people actually
#'   need it for: turning a country name into the ids to search with.
#'
#' @param country a country or region name, e.g. `"Germany"`.
#' @inheritParams mc_collections
#'
#' @returns A tibble with the columns `id`, `name`, `source_count` and
#'   `monitored`, largest collection first.
#'
#' @examples
#' \dontrun{
#' mc_find_collections("Germany")
#' }
#'
#' @export
mc_find_collections <- function(country, max_results = Inf, .token = NULL) {
  if (!rlang::is_string(country)) {
    cli::cli_abort("{.arg country} must be a single string.")
  }
  res <- mc_collections(
    name = country,
    max_results = max_results,
    .token = .token
  )
  keep <- intersect(c("id", "name", "source_count", "monitored"), names(res))
  res[keep]
}


#' Every source in a collection
#'
#' @description The "give me every German newspaper" call. Takes a collection
#'   id, or a collection name to look up, and returns all its sources with
#'   paging handled.
#'
#' @param collection a collection id, or the exact name of a collection.
#' @param max_results maximum number of sources to return.
#' @inheritParams mc_version
#'
#' @returns A tibble with one row per source, as [mc_sources()].
#'
#' @examples
#' \dontrun{
#' mc_collection_sources(34412409)
#' mc_collection_sources("Germany - National")
#' }
#'
#' @export
mc_collection_sources <- function(collection, max_results = Inf, .token = NULL) {
  id <- resolve_collection(collection, .token = .token)
  mc_sources(
    collection_id = id,
    max_results = max_results,
    .token = .token
  )
}


# A name is only accepted when it identifies exactly one collection: picking
# one of several silently would make a script's results depend on which
# collections happened to exist when it ran.
resolve_collection <- function(collection,
                               .token = NULL,
                               arg = rlang::caller_arg(collection),
                               call = rlang::caller_env()) {
  if (length(collection) != 1L || is.na(collection)) {
    cli::cli_abort("{.arg {arg}} must be a single id or name.", call = call)
  }
  if (is.numeric(collection)) {
    return(collection)
  }
  if (!is.character(collection)) {
    cli::cli_abort(
      "{.arg {arg}} must be a collection id or name.",
      call = call
    )
  }

  found <- mc_collections(name = collection, .token = .token)
  if (nrow(found) == 0L) {
    cli::cli_abort(
      c(
        "No collection matches {.val {collection}}.",
        "i" = "Search for one with {.code mc_find_collections()}."
      ),
      call = call
    )
  }
  exact <- which(tolower(found$name) == tolower(collection))
  if (length(exact) == 1L) {
    return(found$id[exact])
  }
  if (nrow(found) == 1L) {
    return(found$id[1L])
  }

  candidates <- utils::head(found[order(-found$source_count), ], 5L)
  cli::cli_abort(
    c(
      "{.val {collection}} matches {nrow(found)} collections.",
      "i" = "Pass one of these ids instead:",
      stats::setNames(
        paste0(candidates$name, " ({.val ", candidates$id, "})"),
        rep("*", nrow(candidates))
      )
    ),
    call = call
  )
}
