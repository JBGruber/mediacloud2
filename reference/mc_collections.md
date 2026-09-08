# List collections

Collections are named groups of sources — mostly countries and regions,
e.g. "Germany - National". Their ids are what you pass to the search
functions.

## Usage

``` r
mc_collections(name = NULL, source_id = NULL, max_results = Inf, .token = NULL)
```

## Arguments

- name:

  search term. Multiple words are combined with AND and matched
  case-insensitively against the collection name, so `"Germany State"`
  finds "Germany - State & Local".

- source_id:

  restrict to collections that contain this source.

- max_results:

  maximum number of collections to return. Defaults to all of them.

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row per collection: `id`, `name`, `notes`, `platform`,
`source_count`, `public`, `featured`, `managed`, `modified_at`,
`featured_rank` and `monitored`.

## Details

The API only holds online news collections, and returns them sorted by
number of sources, largest first. Unless your account is staff, only
public collections are visible.

## Examples

``` r
if (FALSE) { # \dontrun{
mc_collections("Germany")
} # }
```
