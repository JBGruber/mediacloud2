# Server version and connectivity check

Returns the deployed version of the Media Cloud web app. This is the
only endpoint that answers without a token, which makes it a good test
of connectivity and a poor test of authentication — use
[`mc_profile()`](https://jbgruber.github.io/mediacloud2/reference/mc_profile.md)
for the latter.

## Usage

``` r
mc_version(.token = NULL)
```

## Arguments

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row and the columns `version`, `git_rev` and `now`
(server time).

## Examples

``` r
if (FALSE) { # \dontrun{
mc_version()
} # }
```
