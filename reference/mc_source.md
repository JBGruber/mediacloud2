# Look up one source by id

Look up one source by id

## Usage

``` r
mc_source(id, .token = NULL)
```

## Arguments

- id:

  a source id.

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row. See
[`mc_sources()`](https://jbgruber.github.io/mediacloud2/reference/mc_sources.md)
for the columns.

## Examples

``` r
if (FALSE) { # \dontrun{
mc_source(1752)
} # }
```
