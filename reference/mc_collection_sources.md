# Every source in a collection

The "give me every German newspaper" call. Takes a collection id, or a
collection name to look up, and returns all its sources with paging
handled.

## Usage

``` r
mc_collection_sources(collection, max_results = Inf, .token = NULL)
```

## Arguments

- collection:

  a collection id, or the exact name of a collection.

- max_results:

  maximum number of sources to return.

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row per source, as
[`mc_sources()`](https://jbgruber.github.io/mediacloud2/reference/mc_sources.md).

## Examples

``` r
if (FALSE) { # \dontrun{
mc_collection_sources(34412409)
mc_collection_sources("Germany - National")
} # }
```
