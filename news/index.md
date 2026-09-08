# Changelog

## mediacloud2 0.0.0.9000

### Provenance

Media Cloud publishes no OpenAPI spec and no reference documentation for
the v4 API, and the backend serves no schema endpoint — `/api/schema/`,
`/api/docs/`, `/api/openapi.json` and the rest all fall through to the
web app’s catch-all route and answer 200 with an HTML page.

The endpoint list, parameter names and response shapes in this package
were therefore read off the backend’s own source, and checked against
the live server. The reference is
[mediacloud/web-search](https://github.com/mediacloud/web-search) at
commit `cffc27db9f70eb9309e77bb0617990e48d81a0de` (`version` reports
`3.1.11`), which is the revision `GET /api/version` reported as deployed
when this was written.
[`mc_version()`](https://jbgruber.github.io/mediacloud2/reference/mc_version.md)
returns the currently deployed `git_rev`, so drift from that commit is
checkable at any time.

The test fixtures under `tests/testthat/fixtures/` are responses
recorded from the live API at that revision, trimmed to a few records
each. The account details in `profile.json` are a stand-in, not a real
account.

### Initial features

- [`mc_auth()`](https://jbgruber.github.io/mediacloud2/reference/mc_auth.md)
  and token storage, encrypted under
  [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).
- Meta:
  [`mc_version()`](https://jbgruber.github.io/mediacloud2/reference/mc_version.md),
  [`mc_profile()`](https://jbgruber.github.io/mediacloud2/reference/mc_profile.md).
- Directory:
  [`mc_collections()`](https://jbgruber.github.io/mediacloud2/reference/mc_collections.md),
  [`mc_collection()`](https://jbgruber.github.io/mediacloud2/reference/mc_collection.md),
  [`mc_sources()`](https://jbgruber.github.io/mediacloud2/reference/mc_sources.md),
  [`mc_source()`](https://jbgruber.github.io/mediacloud2/reference/mc_source.md),
  [`mc_feeds()`](https://jbgruber.github.io/mediacloud2/reference/mc_feeds.md),
  with offset paging handled internally.
- Search:
  [`mc_story_count()`](https://jbgruber.github.io/mediacloud2/reference/mc_story_count.md),
  [`mc_count_over_time()`](https://jbgruber.github.io/mediacloud2/reference/mc_count_over_time.md),
  [`mc_count_by_source()`](https://jbgruber.github.io/mediacloud2/reference/mc_count_by_source.md),
  [`mc_story_list()`](https://jbgruber.github.io/mediacloud2/reference/mc_story_list.md),
  [`mc_story_sample()`](https://jbgruber.github.io/mediacloud2/reference/mc_story_sample.md),
  [`mc_story()`](https://jbgruber.github.io/mediacloud2/reference/mc_story.md),
  [`mc_words()`](https://jbgruber.github.io/mediacloud2/reference/mc_words.md),
  [`mc_attention_by_source()`](https://jbgruber.github.io/mediacloud2/reference/mc_attention_by_source.md),
  [`mc_languages()`](https://jbgruber.github.io/mediacloud2/reference/mc_languages.md),
  with token paging handled internally.
- Convenience:
  [`mc_find_collections()`](https://jbgruber.github.io/mediacloud2/reference/mc_find_collections.md),
  [`mc_collection_sources()`](https://jbgruber.github.io/mediacloud2/reference/mc_collection_sources.md).
