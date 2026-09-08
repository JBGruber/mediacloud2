#' Server version and connectivity check
#'
#' @description Returns the deployed version of the Media Cloud web app. This
#'   is the only endpoint that answers without a token, which makes it a good
#'   test of connectivity and a poor test of authentication — use
#'   [mc_profile()] for the latter.
#'
#' @param .token a token, or path to a saved token file, to use instead of the
#'   stored one.
#'
#' @returns A tibble with one row and the columns `version`, `git_rev` and
#'   `now` (server time).
#'
#' @examples
#' \dontrun{
#' mc_version()
#' }
#'
#' @export
mc_version <- function(.token = NULL) {
  body <- mc_get("version", .token = .token)
  out <- tibble::tibble(
    version = body$version %||% NA_character_,
    git_rev = body$GIT_REV %||% NA_character_,
    now = as.POSIXct(body$now %||% NA_real_, origin = "1970-01-01", tz = "UTC")
  )
  with_raw(out, attr(body, "response"))
}


#' Your account, roles and quota
#'
#' @description Returns the account the token belongs to. Since almost every
#'   other endpoint requires authentication, this is the call to make when you
#'   want to know whether a token works.
#'
#' @inheritParams mc_version
#'
#' @returns A tibble with one row: `id`, `username`, `is_staff`,
#'   `is_superuser`, `groups` (a list column), and the quota columns
#'   `quota_provider`, `quota_hits`, `quota_week` and `quota_limit`.
#'
#' @details Quota is counted per week and per provider. Endpoints do not all
#'   cost the same: a story list or count costs one hit, [mc_languages()] two,
#'   and [mc_words()], [mc_attention_by_source()] and [mc_count_by_source()]
#'   four.
#'
#' @examples
#' \dontrun{
#' mc_profile()
#' }
#'
#' @export
mc_profile <- function(.token = NULL) {
  body <- mc_get("auth/profile", .token = .token)
  quota <- body$quota
  out <- tibble::tibble(
    id = body$id %||% NA_integer_,
    username = body$username %||% NA_character_,
    is_staff = body$is_staff %||% NA,
    is_superuser = body$is_superuser %||% NA,
    groups = list(unlist(body$groups %||% list(), use.names = FALSE)),
    quota_provider = quota$provider %||% NA_character_,
    quota_hits = quota$hits %||% NA_integer_,
    quota_week = parse_date(quota$week %||% NA_character_),
    quota_limit = quota$limit %||% NA_integer_
  )
  with_raw(out, attr(body, "response"))
}
