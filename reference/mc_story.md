# Look up a single story

Look up a single story

## Usage

``` r
mc_story(id, platform = mc_platforms, .token = NULL)
```

## Arguments

- id:

  a story id, as returned in the `id` column of
  [`mc_story_list()`](https://jbgruber.github.io/mediacloud2/reference/mc_story_list.md).

- platform:

  which archive to query. `"onlinenews-mediacloud"` is the Media Cloud
  index; `"onlinenews-waybackmachine"` searches the Wayback Machine
  instead.

- .token:

  a token, or path to a saved token file, to use instead of the stored
  one.

## Value

A tibble with one row. Non-staff accounts do not receive the article
text; the `text` column is stripped server side.

## Examples

``` r
if (FALSE) { # \dontrun{
stories <- mc_story_list("klima", "2026-08-01", "2026-08-07",
                         collection_id = 34412409, max_results = 1)
mc_story(stories$id[1])
} # }
```
