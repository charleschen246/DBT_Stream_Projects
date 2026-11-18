"""
Loads the four Kaggle CSVs into BigQuery as the raw source tables.

Usage:
    python scripts/load_raw_data.py --project <gcp-project> --dataset Streaming_project --csv-dir <folder with the CSVs>

Authenticates with Application Default Credentials (`gcloud auth application-default login`).
Tables are replaced on every run, so it's safe to re-run.
"""
import argparse
from pathlib import Path

from google.cloud import bigquery

# csv file name -> table name expected by models/staging/streaming/_streaming__sources.yml
TABLES = {
    "amazon_prime_titles.csv": "src_amazon_prime_titles",
    "disney_plus_titles.csv": "disney_plus_titles",
    "hulu_titles.csv": "hulu_titles",
    "netflix_titles.csv": "src_netflix_titles",
}

# Explicit schema: keep raw values as text (staging does the typing), except release_year.
SCHEMA = [
    bigquery.SchemaField(name, "INT64" if name == "release_year" else "STRING")
    for name in [
        "show_id", "type", "title", "director", "cast", "country", "date_added",
        "release_year", "rating", "duration", "listed_in", "description",
    ]
]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project", required=True)
    parser.add_argument("--dataset", default="Streaming_project")
    parser.add_argument("--csv-dir", required=True, type=Path)
    parser.add_argument("--location", default="US")
    args = parser.parse_args()

    client = bigquery.Client(project=args.project)
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        schema=SCHEMA,
        skip_leading_rows=1,
        allow_quoted_newlines=True,  # some descriptions contain line breaks
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    for csv_name, table_name in TABLES.items():
        path = args.csv_dir / csv_name
        table_id = f"{args.project}.{args.dataset}.{table_name}"
        with path.open("rb") as f:
            job = client.load_table_from_file(f, table_id, job_config=job_config, location=args.location)
        job.result()
        print(f"Loaded {client.get_table(table_id).num_rows:>6,} rows  {csv_name} -> {table_id}")


if __name__ == "__main__":
    main()
