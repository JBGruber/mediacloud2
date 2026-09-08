# Count matching stories over time

Count matching stories over time

## Usage

``` r
mc_count_over_time(
  query,
  start_date,
  end_date,
  collection_id = NULL,
  source_id = NULL,
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

- platform:

  which archive to query. `"onlinenews-mediacloud"` is the Media Cloud
  index; `"onlinenews-waybackmachine"` searches the Wayback Machine
  instead.

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row per day: `date`, `count` (matching stories),
`total_count` (all stories that day) and `ratio`. The overall totals are
attached as the attributes `total` and `normalized_total`.

## Examples

``` r
if (FALSE) { # \dontrun{
mc_count_over_time("klima", "2026-08-01", "2026-08-07", collection_id = 34412409)
} # }
```
