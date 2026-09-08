# Languages of the matching stories

Languages of the matching stories

## Usage

``` r
mc_languages(
  query,
  start_date,
  end_date,
  collection_id = NULL,
  source_id = NULL,
  limit = NULL,
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

- limit:

  how many languages to return.

- platform:

  which archive to query. `"onlinenews-mediacloud"` is the Media Cloud
  index; `"onlinenews-waybackmachine"` searches the Wayback Machine
  instead.

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row per language.

## Details

Costs two quota hits.

## Examples

``` r
if (FALSE) { # \dontrun{
mc_languages("klima", "2026-08-01", "2026-08-07", collection_id = 34412409)
} # }
```
