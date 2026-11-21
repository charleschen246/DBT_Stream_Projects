# Streaming catalogs: Netflix, Prime Video, Disney+, Hulu

[![dbt CI](https://github.com/charleschen246/DBT_Stream_Projects/actions/workflows/dbt_ci.yml/badge.svg)](https://github.com/charleschen246/DBT_Stream_Projects/actions/workflows/dbt_ci.yml)

A dbt project on BigQuery that combines the catalogs of four streaming services (about 23,000 titles,
from the public Kaggle datasets) into one tested star schema, with a dbt Semantic Layer on top.

- Dashboard: https://charleschen246.github.io/DBT_Stream_Projects/dashboard.html
- dbt docs and lineage: https://charleschen246.github.io/DBT_Stream_Projects/

## What was wrong with the data

The four files share the same columns, but the values don't line up, and some rows are wrong.

- `show_id` restarts at `s1` in every file, so it isn't a key once the platforms are combined. Titles are keyed on platform + show_id.
- Every platform uses its own rating system (MPA, US TV, Amazon's `16+`/`AGES_16_`, plus `UR`, `UNRATED`, `NOT_RATE` for the same thing). A seed maps all 27 codes to one rating and an audience group, so the platforms can be compared.
- Genre labels differ too (Netflix "Dramas", Hulu "Drama", Disney+ "Action-Adventure"). A second seed rolls 121 labels into 27 groups.
- Amazon has a genre called "Arts, Entertainment, and Culture". Splitting the genre list on commas turns it into three fake genres, so all three pieces map to the same group.
- 62 Hulu titles are labeled "Movie" but last "1 Season" or "2 Seasons", with the duration typed into the rating column (Blippi, Brassic, All Saints...). They're reclassified as TV shows. The original value is kept in `source_content_type`.
- 98% of Amazon titles have no date added, so Amazon is left out of anything over time.
- 26% of Hulu titles have no rating at all.

## Layout

```
models/
  staging/streaming/   one view per source file: rename, trim, cast
  intermediate/        union the platforms, parse durations, map ratings and genres, fix bad rows
  marts/core/          fct_titles, dim_platforms, dim_ratings, dim_dates, dim_genres, dim_countries, two bridge tables
  marts/reporting/     obt_titles, everything flattened into one table for BI
  semantic/            semantic models and metrics
seeds/                 platforms, rating_mappings, genre_mappings
tests/                 singular tests (reconciliation, business rules)
macros/                two cross-database macros and two custom generic tests
scripts/               load the CSVs, build the dashboard, publish the site
```

The marts are `public` with enforced contracts; staging is `private` to the project's group.

## Tests

`dbt build` runs about 160 data tests and 3 unit tests. Most are the usual keys and relationships checks.
The ones worth looking at:

- `metric_reconciles` ([macros/tests](macros/tests/test_metric_reconciles.sql)) is a custom generic test that compares an aggregate between two models, optionally per group. It's used to check that counts, durations and genre tags in the marts match staging for every platform and content type.
- [`assert_title_metrics_match_from_staging_to_marts`](tests/reconciliation/assert_title_metrics_match_from_staging_to_marts.sql) recomputes counts, distinct IDs and a release-year checksum from the four staging models and compares them with the marts, without going through the intermediate layer.
- The unit tests in [`_int_titles__models.yml`](models/intermediate/_int_titles__models.yml) cover duration parsing and the Hulu fix.
- Two warn-only tests flag rating codes and genre labels that aren't in the seeds yet.

CI runs the whole build on every pull request against a small DuckDB database ([ci/create_fixture_db.py](ci/create_fixture_db.py)) that has the same problems as the real data. Date parsing and list splitting differ between BigQuery and DuckDB, so those two live in dispatch macros in `macros/cross_db/`.

## Semantic layer

12 metrics in [models/semantic/sem_streaming.yml](models/semantic/sem_streaming.yml), including movie share, average age when added, titles added per year, a running total, and year-over-year growth. The dashboard is built from these with `scripts/build_dashboard.py`.

```bash
mf query --metrics total_titles,movie_share --group-by platform__platform_name
mf query --metrics titles_added --group-by metric_time__year,platform__platform_name
```

## Why I did it this way

Fixing the Hulu rows instead of dropping them. Dropping 62 titles would make Hulu's counts wrong, and the rows
are fine except for the type. "2 Seasons" only makes sense for a series, and the same rows also have the duration
in the wrong column, so the "Movie" label looks like the mistake, not the duration. I kept the original value
so anyone can see what was changed.

Testing staging against the marts directly. Each model can pass its own tests and the pipeline can still be wrong,
for example a join in the middle that drops some rows. Keys are still unique, nothing is null, but titles are missing.
Comparing the final tables with staging catches that. The reconciliation tests skip the intermediate layer
on purpose, so a bug there can't hide itself.

Star schema and one big table. Genres and countries are many-to-many with titles, so the star schema needs bridge
tables. That's flexible but people have to know how to join it without double counting. `obt_titles` is for BI tools
and quick questions: one row per title, genres and countries as lists. Both are tested to give the same totals.

A static dashboard instead of Looker Studio. The BigQuery sandbox deletes tables after 60 days, and a Looker Studio
report would break when that happens. The static page is built from the semantic layer metrics, so the numbers
come from the same definitions, and it stays online for free.

If the data refreshed every day. This is a one-time download from 2021, so a full rebuild is fine. With daily data
I would make `fct_titles` incremental, add a snapshot on the source to see when titles leave a platform
(right now there is no way to know), add source freshness checks, and schedule the build instead of running it by hand.

## Running it

Locally, without a warehouse:

```bash
pip install -r requirements.txt
python ci/create_fixture_db.py ci/streaming.duckdb
export DBT_PROFILES_DIR=ci
dbt deps
dbt build --vars '{source_database: streaming}'
```

On BigQuery: download the four CSVs from Kaggle ([Netflix](https://www.kaggle.com/datasets/shivamb/netflix-shows), [Prime Video](https://www.kaggle.com/datasets/shivamb/amazon-prime-movies-and-tv-shows), [Disney+](https://www.kaggle.com/datasets/shivamb/disney-movies-and-tv-shows), [Hulu](https://www.kaggle.com/datasets/shivamb/hulu-movies-and-tv-shows)), add a `streaming_analytics` BigQuery profile, then:

```bash
gcloud auth application-default login
python scripts/load_raw_data.py --project <gcp-project> --csv-dir <folder>
dbt deps
dbt build --vars '{source_database: <gcp-project>}'
bash scripts/publish_site.sh      # optional: rebuild the docs and dashboard on GitHub Pages
```

The project runs on the BigQuery free tier, which deletes tables after 60 days. The dashboard and docs are
static pages, so they stay up; re-run the loader and `dbt build` to bring the tables back.
