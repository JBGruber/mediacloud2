# Top words in matching stories

Top words in matching stories

## Usage

``` r
mc_words(
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

  how many terms to return.

- platform:

  which archive to query. `"onlinenews-mediacloud"` is the Media Cloud
  index; `"onlinenews-waybackmachine"` searches the Wayback Machine
  instead.

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row per term: `term`, `term_count`, `term_ratio`,
`doc_count`, `doc_ratio` and `sample_size`. Counts are taken from a
sample of the matching stories, not from all of them.

## Details

Costs four quota hits.

## Examples

``` r
if (FALSE) { # \dontrun{
mc_words("klima", "2026-08-01", "2026-08-07", collection_id = 34412409)
} # }
```
