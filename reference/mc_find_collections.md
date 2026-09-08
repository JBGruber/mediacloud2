# Find the collection ids for a country

A trimmed-down
[`mc_collections()`](https://jbgruber.github.io/mediacloud2/reference/mc_collections.md)
for the job people actually need it for: turning a country name into the
ids to search with.

## Usage

``` r
mc_find_collections(country, max_results = Inf, .token = NULL)
```

## Arguments

- country:

  a country or region name, e.g. `"Germany"`.

- max_results:

  maximum number of collections to return. Defaults to all of them.

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with the columns `id`, `name`, `source_count` and `monitored`,
largest collection first.

## Examples

``` r
if (FALSE) { # \dontrun{
mc_find_collections("Germany")
} # }
```
