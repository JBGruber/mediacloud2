# List the RSS feeds of a source

List the RSS feeds of a source

## Usage

``` r
mc_feeds(
  source_id,
  modified_since = NULL,
  modified_before = NULL,
  details = FALSE,
  max_results = Inf,
  .token = NULL
)
```

## Arguments

- source_id:

  the source whose feeds you want.

- modified_since, modified_before:

  only return feeds modified in this window. Accepts `Date`, `POSIXct`
  or epoch seconds.

- details:

  if `TRUE`, ask the RSS fetcher for its view of the feeds (fetch state,
  error counts) instead of the stored records. This is a different,
  unpaginated endpoint with a different set of columns.

- max_results:

  maximum number of feeds to return. Ignored when `details = TRUE`.

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row per feed: `id`, `url`, `name`, `source`,
`admin_rss_enabled`, `created_at` and `modified_at`.

## Examples

``` r
if (FALSE) { # \dontrun{
mc_feeds(source_id = 1752)
} # }
```
