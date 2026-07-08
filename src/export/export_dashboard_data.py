from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine


DATABASE_URL = "postgresql+psycopg2:///sugarbelly"

OUTPUT_DIR = Path("reports")

EXPORTS = {
    "dashboard_latest.csv": """
        SELECT *
        FROM v_sugar_obesity_latest;
    """,
    "dashboard_country_year.csv": """
        SELECT *
        FROM v_sugar_obesity_country_year;
    """,
    "dashboard_region_summary.csv": """
        SELECT *
        FROM v_sugar_obesity_region_summary;
    """,
    "dashboard_country_change.csv": """
        SELECT *
        FROM v_sugar_obesity_country_change;
    """,
}


def export_dashboard_data() -> None:
    """
    Export dashboard-ready PostgreSQL views to CSV files.

    These CSV files allow the hosted Streamlit app to run for free
    without needing a live PostgreSQL database connection.

    Local workflow:
    PostgreSQL tables -> SQL views -> CSV exports -> Streamlit dashboard
    """

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    engine = create_engine(DATABASE_URL)

    for filename, query in EXPORTS.items():
        output_path = OUTPUT_DIR / filename

        print(f"Exporting {filename}...")

        df = pd.read_sql(query, engine)
        df.to_csv(output_path, index=False)

        print(f"Saved {output_path} | Rows: {len(df):,}")

    print("\nDashboard export complete.")
    print("The hosted Streamlit app can now read these CSV files from reports/.")


if __name__ == "__main__":
    export_dashboard_data()