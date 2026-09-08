# List sources

Sources are the individual outlets — one row per domain.

## Usage

``` r
mc_sources(collection_id = NULL, name = NULL, max_results = Inf, .token = NULL)
```

## Arguments

- collection_id:

  restrict to sources in this collection. This is the usual way to use
  the function; see also
  [`mc_collection_sources()`](https://jbgruber.github.io/mediacloud2/reference/mc_collection_sources.md).

- name:

  search term, matched case-insensitively against the source name, its
  label and its alternative domains. Multiple words are combined with
  AND.

- max_results:

  maximum number of sources to return.

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row per source, including `id`, `name`, `label`,
`homepage`, `stories_per_week`, `last_story`, `pub_country`,
`pub_state`, `primary_language`, `media_type` and `collection_count`.

## Details

Sources come back sorted by `stories_per_week`, busiest first.
`last_story` is only reported to the month by this endpoint, so it is
returned as the first day of that month.

## Examples

``` r
if (FALSE) { # \dontrun{
mc_sources(collection_id = 34412409)
mc_sources(name = "spiegel")
} # }
```
