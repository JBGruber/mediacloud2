#' Authenticate for the 'MediaCloud' API
#'
#' @description Get your 'MediaCloud' API token and save the token permanently.
#' Opens <https://search.mediacloud.org/account> by default, then requests the
#' token from the user (unless a token is supplied).
#'
#' @param token A token, if you already have one. Supplying one always replaces
#'   the stored token. If missing, you are guided through obtaining one.
#' @param overwrite If TRUE, ignores the stored token and asks for a new one,
#'   replacing what is currently saved.
#'
#' @returns An authentication token (invisible)
#'
#' @details After requesting the token, it is saved in the location returned by
#'   `file.path(tools::R_user_dir("mediacloud2", "cache"), Sys.getenv("MC_TOKEN",
#'   unset = "token.rds"))`. If you have multiple tokens, you can use
#'   `Sys.setenv(MC_TOKEN = "filename.rds")` to save/load the token with a
#'   different name.
#'
#' @examples
#' \dontrun{
#' # request a token
#' mc_auth() # this will guide you through all steps
#'
#' # the token is stored in the location returned by this command
#' file.path(tools::R_user_dir("mediacloud2", "cache"),
#'           Sys.getenv("MC_TOKEN", unset = "token.rds"))
#'
#' # to use a different than the default file name for the token, set MC_TOKEN
#' Sys.setenv(MC_TOKEN = "identity-2.rds")
#'
#' # now either rename your token file or request a new token
#' mc_auth()
#'
#' # the cache now contains two tokens
#' list.files(tools::R_user_dir("mediacloud2", "cache"))
#'
#' # functions that interact with the API also take a .token argument with the
#' # path. For example:
#' tok_path <- file.path(tools::R_user_dir("mediacloud2", "cache"), "identity-2.rds")
#' mc_collection_sources(34412409, .token = tok_path)
#' }
#'
#' @export
mc_auth <- function(
  token = NULL,
  overwrite = FALSE
) {
  # a token the user hands over or types is new and should replace whatever is
  # on disk; one we read back from the cache is already stored
  new_token <- !is.null(token)
  if (is.null(token)) {
    if (!overwrite) {
      token <- get_token()
    }
    if (is.null(token)) {
      utils::browseURL("https://search.mediacloud.org/account")
      rlang::check_installed("askpass")
      token <- askpass::askpass(
        "Please enter your token"
      )
      new_token <- TRUE
    }
  }
  if (!rlang::is_string(token) || !nzchar(token)) {
    cli::cli_abort("Unable to retrieve or obtain token. See {.help mc_auth}")
  }
  save_token(token = token, overwrite = overwrite || new_token)
  rlang::env_poke(env = the, nm = "MC_TOKEN", value = token, create = TRUE)
  cli::cli_alert_success("succesfully authenticated!")
  invisible(token)
}


save_token <- function(token, overwrite = FALSE) {
  path <- token_path()
  if (!file.exists(path) || overwrite) {
    dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
    httr2::secret_write_rds(
      x = token,
      path = path,
      key = I(rlang::hash("informationshouldbefree"))
    )
  }
}


req_token <- function(req, .token = NULL) {
  if (!inherits(req, "httr2_request")) {
    cli::cli_abort("{.code req} must be a httr2 request")
  }
  token <- get_token(.token = .token)
  if (is.null(token)) {
    cli::cli_abort(c(
      "No 'MediaCloud' token found.",
      "i" = "Run {.run mediacloud2::mc_auth()} to store one."
    ))
  }
  httr2::req_headers_redacted(req, Authorization = paste("Token", token))
}


#' @param .token a token, or the path to a saved token file, to use instead of
#'   the stored one. Lets a script switch between identities without touching
#'   the `MC_TOKEN` environment variable.
#' @noRd
get_token <- function(.token = NULL) {
  if (!is.null(.token)) {
    if (!rlang::is_string(.token)) {
      cli::cli_abort("{.arg .token} must be a single string.")
    }
    if (file.exists(.token)) {
      return(invisible(read_token(.token)))
    }
    return(invisible(.token))
  }

  f <- token_path()

  if (rlang::env_has(the, nms = "MC_TOKEN")) {
    token <- rlang::env_get(the, nm = "MC_TOKEN")
  } else if (file.exists(f)) {
    token <- read_token(f)
  } else if (!is.null(getOption("httr2_mock", NULL))) {
    token <- "toks"
  } else {
    token <- NULL
  }
  invisible(token)
}


read_token <- function(f) {
  httr2::secret_read_rds(f, I(rlang::hash("informationshouldbefree")))
}


token_path <- function() {
  file.path(
    tools::R_user_dir("mediacloud2", "cache"),
    Sys.getenv("MC_TOKEN", unset = "token.rds")
  )
}
