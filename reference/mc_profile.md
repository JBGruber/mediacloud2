# Your account, roles and quota

Returns the account the token belongs to. Since almost every other
endpoint requires authentication, this is the call to make when you want
to know whether a token works.

## Usage

``` r
mc_profile(.token = NULL)
```

## Arguments

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row: `id`, `username`, `is_staff`, `is_superuser`,
`groups` (a list column), and the quota columns `quota_provider`,
`quota_hits`, `quota_week` and `quota_limit`.

## Details

Quota is counted per week and per provider. Endpoints do not all cost
the same: a story list or count costs one hit,
[`mc_languages()`](https://jbgruber.github.io/mediacloud2/reference/mc_languages.md)
two, and
[`mc_words()`](https://jbgruber.github.io/mediacloud2/reference/mc_words.md),
[`mc_attention_by_source()`](https://jbgruber.github.io/mediacloud2/reference/mc_attention_by_source.md)
and
[`mc_count_by_source()`](https://jbgruber.github.io/mediacloud2/reference/mc_count_by_source.md)
four.

## Examples

``` r
if (FALSE) { # \dontrun{
mc_profile()
} # }
```
