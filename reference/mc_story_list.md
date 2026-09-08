# Fetch matching stories

Returns the story metadata matching a query. Paging is handled
internally: the endpoint hands back a `pagination_token` which is fed
back until the archive is exhausted or `max_results` is reached.

## Usage

``` r
mc_story_list(
  query,
  start_date,
  end_date,
  collection_id = NULL,
  source_id = NULL,
  max_results = Inf,
  page_size = NULL,
  sort_order = NULL,
  expanded = FALSE,
  randomize = FALSE,
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

- max_results:

  how many stories to fetch. Defaults to all of them, which for a broad
  query can be a very long pull at two requests per minute — set a limit
  when exploring.

- page_size:

  how many stories to ask for per request.

- sort_order:

  `"desc"` (newest indexed first, the default) or `"asc"`.

- expanded:

  if `TRUE`, request the full story text. This is restricted to staff
  accounts and will fail with "You are not permitted to fetch `expanded`
  stories" for everyone else.

- randomize:

  if `TRUE`, sample pages at random rather than in order. Also staff
  only.

- platform:

  which archive to query. `"onlinenews-mediacloud"` is the Media Cloud
  index; `"onlinenews-waybackmachine"` searches the Wayback Machine
  instead.

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row per story: `id`, `title`, `url`, `publish_date` (a
`Date`), `indexed_date` (a `POSIXct`), `language`, `media_name` and
`media_url`.

## Examples

``` r
if (FALSE) { # \dontrun{
mc_story_list("klima", "2026-08-01", "2026-08-07",
              collection_id = 34412409, max_results = 200)
} # }
```
