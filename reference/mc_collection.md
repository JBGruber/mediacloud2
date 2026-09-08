# Look up one collection by id

Look up one collection by id

## Usage

``` r
mc_collection(id, .token = NULL)
```

## Arguments

- id:

  a collection id.

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row. See
[`mc_collections()`](https://jbgruber.github.io/mediacloud2/reference/mc_collections.md)
for the columns.

## Examples

``` r
if (FALSE) { # \dontrun{
# United States - National
mc_collection(34412234)
} # }
```
