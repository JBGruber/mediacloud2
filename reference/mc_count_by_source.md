# Attention per source over time

Splits the matching stories by source and by time bucket, which is what
the "attention over time by source" view of the web app shows.

## Usage

``` r
mc_count_by_source(
  query,
  start_date,
  end_date,
  collection_id = NULL,
  source_id = NULL,
  interval = c("week", "day", "month", "year"),
  platform = mc_platforms,
  .token = NULL
)
```

## Arguments

- query:

  the search string, in Elasticsearch/Lucene syntax. `"*"` matches
  everything.

- start_date, end_date:

  the period to search, as `Date` objects or `"YYYY-MM-DD"` strings.
  Both are required.

- collection_id, source_id:

  ids to search within, as returned by
  [`mc_collections()`](https://jbgruber.github.io/mediacloud2/reference/mc_collections.md)
  and
  [`mc_sources()`](https://jbgruber.github.io/mediacloud2/reference/mc_sources.md).
  At least one of the two is required. Vectors are allowed.

- interval:

  size of the time buckets: `"day"`, `"week"`, `"month"` or `"year"`.

- platform:

  which archive to query. `"onlinenews-mediacloud"` is the Media Cloud
  index; `"onlinenews-waybackmachine"` searches the Wayback Machine
  instead.

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row per source and bucket: `media_name`, `interval`,
`bucket`, `matching_stories`, `total_stories` and `ratio`.

## Details

The server refuses queries whose number of sources times number of
buckets is too large, so narrow the period or use a coarser `interval`
when searching a big collection. This endpoint costs four quota hits.

## Examples

``` r
if (FALSE) { # \dontrun{
mc_count_by_source("klima", "2026-08-01", "2026-08-31",
                   collection_id = 34412409, interval = "week")
} # }
```
