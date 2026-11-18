"""
Builds the static dashboard (site/dashboard.html) from dbt Semantic Layer metrics.

Every number on the dashboard comes from a MetricFlow query against the governed
metric definitions in models/semantic/sem_streaming.yml, so the dashboard and any
other consumer of the semantic layer always agree.

Usage (after `dbt build` against the warehouse):
    python scripts/build_dashboard.py

Requires `mf` (dbt-metricflow) on PATH and a working dbt profile.
"""
import csv
import json
import shutil
import subprocess
import sys
import tempfile
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = ROOT / "scripts" / "dashboard_template.html"
OUTPUT = ROOT / "site" / "dashboard.html"

QUERIES = {
    "overall": {
        "metrics": ["total_titles", "movies", "tv_shows", "movie_share", "avg_years_from_release_to_platform"],
        "group_by": [],
    },
    "by_platform": {
        "metrics": [
            "total_titles", "movies", "tv_shows", "movie_share",
            "avg_movie_runtime_minutes", "avg_seasons_per_show", "avg_years_from_release_to_platform",
        ],
        "group_by": ["platform__platform_name"],
    },
    "added_by_year": {
        "metrics": ["titles_added"],
        "group_by": ["metric_time__year", "platform__platform_name"],
        "extra": ["--start-time", "2015-01-01", "--end-time", "2021-12-31"],
    },
    "audience_mix": {
        "metrics": ["total_titles"],
        "group_by": ["rating__audience_group", "platform__platform_name"],
    },
    "genre_groups": {
        "metrics": ["genre_tagged_titles"],
        "group_by": ["title_genre__genre_group", "platform__platform_name"],
    },
}


def run_query(name: str, spec: dict, workdir: Path) -> list[dict]:
    out = workdir / f"{name}.csv"
    # Look next to the running interpreter first (a venv's Scripts/bin folder), then on PATH.
    mf = (
        shutil.which("mf", path=str(Path(sys.executable).parent))
        or shutil.which("mf")
        or sys.exit("`mf` not found. pip install dbt-metricflow")
    )
    cmd = [mf, "query", "--metrics", ",".join(spec["metrics"]), "--csv", str(out)]
    if spec["group_by"]:
        cmd += ["--group-by", ",".join(spec["group_by"])]
    cmd += spec.get("extra", [])
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    if result.returncode != 0 or not out.exists():
        sys.exit(f"Query '{name}' failed:\n{result.stdout}\n{result.stderr}")
    with out.open(newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    print(f"{name:<14} {len(rows):>3} rows")
    return [{k: _coerce(v) for k, v in row.items()} for row in rows]


def _coerce(value: str):
    if value in ("", None):
        return None
    try:
        number = float(value)
        return int(number) if number.is_integer() and "." not in value else number
    except ValueError:
        return value[:4] if value[:4].isdigit() and "T00:00:00" in value else value


def main() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        data = {name: run_query(name, spec, Path(tmp)) for name, spec in QUERIES.items()}
    data["generated_on"] = date.today().isoformat()

    html = TEMPLATE.read_text(encoding="utf-8").replace("__DASHBOARD_DATA__", json.dumps(data, separators=(",", ":")))
    OUTPUT.parent.mkdir(exist_ok=True)
    OUTPUT.write_text(html, encoding="utf-8")
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
