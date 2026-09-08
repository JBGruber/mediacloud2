# mediacloud2 0.0.0.9000

## Provenance

Media Cloud publishes no OpenAPI spec and no reference documentation for the
v4 API, and the backend serves no schema endpoint — `/api/schema/`,
`/api/docs/`, `/api/openapi.json` and the rest all fall through to the web
app's catch-all route and answer 200 with an HTML page.

The endpoint list, parameter names and response shapes in this package were
therefore read off the backend's own source, and checked against the live
server. The reference is
[mediacloud/web-search](https://github.com/mediacloud/web-search) at commit
`cffc27db9f70eb9309e77bb0617990e48d81a0de` (`version` reports `3.1.11`), which
is the revision `GET /api/version` reported as deployed when this was written.
`mc_version()` returns the currently deployed `git_rev`, so drift from that
commit is checkable at any time.

The test fixtures under `tests/testthat/fixtures/` are responses recorded from
the live API at that revision, trimmed to a few records each. The account
details in `profile.json` are a stand-in, not a real account.

## Initial features

* `mc_auth()` and token storage, encrypted under `tools::R_user_dir()`.
* Meta: `mc_version()`, `mc_profile()`.
* Directory: `mc_collections()`, `mc_collection()`, `mc_sources()`,
  `mc_source()`, `mc_feeds()`, with offset paging handled internally.
* Search: `mc_story_count()`, `mc_count_over_time()`, `mc_count_by_source()`,
  `mc_story_list()`, `mc_story_sample()`, `mc_story()`, `mc_words()`,
  `mc_attention_by_source()`, `mc_languages()`, with token paging handled
  internally.
* Convenience: `mc_find_collections()`, `mc_collection_sources()`.
