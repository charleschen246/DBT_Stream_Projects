"""
Builds a small DuckDB database shaped like the raw Kaggle tables, for CI.

The rows are synthetic, but each one exercises a real quirk of the source data:
durations typed into the rating column, trailing commas in list columns,
duplicate genres, leading spaces in dates, blank strings, missing dates,
rating aliases, and a rating code and a genre that aren't in the mapping seeds.

Usage: python ci/create_fixture_db.py ci/streaming.duckdb
"""
import sys

import duckdb

COLUMNS = (
    'show_id varchar, type varchar, title varchar, director varchar, "cast" varchar, '
    "country varchar, date_added varchar, release_year integer, rating varchar, "
    "duration varchar, listed_in varchar, description varchar"
)

TABLES = {
    "src_netflix_titles": [
        ("s1", "Movie", "Sample Documentary", "Director A", None, "United States", "September 25, 2021", 2020, "PG-13", "90 min", "Documentaries", "A documentary."),
        ("s2", "TV Show", "Sample Drama Series", None, "Actor A, Actor B", "South Africa", "September 24, 2021", 2021, "TV-MA", "2 Seasons", "International TV Shows, TV Dramas, TV Mysteries", "A drama."),
        ("s3", "Movie", "Sample Comedy Special", "Director B", "Actor C", "United States,", " April 4, 2017", 2017, "74 min", None, "Movies", "Duration typed into the rating column."),
        ("s4", "Movie", "Sample Foreign Film", "", None, "France, Belgium, ", "July 1, 2019", 1998, "UR", "101 min", "Dramas, Dramas, International Movies", "Duplicate genre, trailing comma."),
        ("s5", "TV Show", "Sample Kids Show", None, None, None, None, 1985, "TV-Y7-FV", "1 Season", "Kids' TV", "No date added."),
    ],
    "src_amazon_prime_titles": [
        ("s1", "Movie", "Sample Prime Comedy", "Director C", "Actor D", "Canada", "March 30, 2021", 2014, "13+", "113 min", "Comedy, Drama", "Prime rating code."),
        ("s2", "Movie", "Sample Prime Drama", "Director D", None, "India", None, 2018, "AGES_16_", "110 min", "Drama, International", "Rating alias."),
        ("s3", "TV Show", "Sample Prime Series", None, None, None, None, 2017, "NOT_RATE", "1 Season", "TV Shows", "Not rated alias."),
        ("s4", "Movie", "Sample Prime Thriller", None, None, None, None, 2016, "WEIRD-CODE", "88 min", "Suspense", "Unmapped rating code."),
    ],
    "disney_plus_titles": [
        ("s1", "Movie", "Sample Animated Short", "Director E", "Actor E", None, "November 26, 2021", 2016, "TV-G", "23 min", "Animation, Family", "Short film."),
        ("s2", "TV Show", "Sample Docuseries", None, None, "United States", "November 26, 2021", 2015, "TV-14", "2 Seasons", "Docuseries, Reality", "Docuseries."),
    ],
    "hulu_titles": [
        ("s1", "Movie", "Sample Stand-Up", None, None, None, "October 24, 2021", 2021, "TV-MA", None, "Comedy, Stand Up", "Missing duration."),
        ("s2", "TV Show", "Sample Horror Series", None, None, "United Kingdom", "October 23, 2021", 2020, "Unrated", "1 Season", "Horror", "Mixed-case rating."),
        ("s3", "Movie", "Sample Indie Film", None, None, None, "   ", 2010, "   ", "95 min", "Drama, Mockumentary", "Whitespace-only values; unmapped genre."),
    ],
}


def main(path: str) -> None:
    con = duckdb.connect(path)
    con.execute("create schema if not exists Streaming_project")
    for table, rows in TABLES.items():
        con.execute(f"create or replace table Streaming_project.{table} ({COLUMNS})")
        con.executemany(f"insert into Streaming_project.{table} values ({', '.join(['?'] * 12)})", rows)
    con.close()
    print(f"Created {path} with {sum(len(r) for r in TABLES.values())} rows across {len(TABLES)} tables")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "ci/streaming.duckdb")
