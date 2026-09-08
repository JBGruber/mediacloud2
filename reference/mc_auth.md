# Authenticate for the 'MediaCloud' API

Get your 'MediaCloud' API token and save the token permanently. Opens
<https://search.mediacloud.org/account> by default, then requests the
token from the user (unless a token is supplied).

## Usage

``` r
mc_auth(token = NULL, overwrite = FALSE)
```

## Arguments

- token:

  A token, if you already have one. Supplying one always replaces the
  stored token. If missing, you are guided through obtaining one.

- overwrite:

  If TRUE, ignores the stored token and asks for a new one, replacing
  what is currently saved.

## Value

An authentication token (invisible)

## Details

After requesting the token, it is saved in the location returned by
`file.path(tools::R_user_dir("mediacloud2", "cache"), Sys.getenv("MC_TOKEN", unset = "token.rds"))`.
If you have multiple tokens, you can use
`Sys.setenv(MC_TOKEN = "filename.rds")` to save/load the token with a
different name.

## Examples

``` r
if (FALSE) { # \dontrun{
# request a token
mc_auth() # this will guide you through all steps

# the token is stored in the location returned by this command
file.path(tools::R_user_dir("mediacloud2", "cache"),
          Sys.getenv("MC_TOKEN", unset = "token.rds"))

# to use a different than the default file name for the token, set MC_TOKEN
Sys.setenv(MC_TOKEN = "identity-2.rds")

# now either rename your token file or request a new token
mc_auth()

# the cache now contains two tokens
list.files(tools::R_user_dir("mediacloud2", "cache"))

# functions that interact with the API also take a .token argument with the
# path. For example:
tok_path <- file.path(tools::R_user_dir("mediacloud2", "cache"), "identity-2.rds")
mc_collection_sources(34412409, .token = tok_path)
} # }
```
