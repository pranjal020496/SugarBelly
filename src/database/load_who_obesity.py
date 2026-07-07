import pandas as pd
import psycopg2
from pathlib import Path
from io import StringIO


CLEAN_FILE = Path("data/interim/who_obesity_clean.csv")
DATABASE_NAME = "sugarbelly"
TABLE_NAME = "who_obesity"


COLUMNS = [
    "iso3",
    "year",
    "sex",
    "sex_code",
    "obesity_pct",
    "obesity_pct_low",
    "obesity_pct_high",
    "who_region",
    "who_region_code",
]


def load_clean_data() -> pd.DataFrame:
    """
    Load cleaned WHO obesity CSV from data/interim.
    """

    if not CLEAN_FILE.exists():
        raise FileNotFoundError(
            f"Clean file not found: {CLEAN_FILE}. "
            "Run src/cleaning/clean_who_obesity.py first."
        )

    df = pd.read_csv(CLEAN_FILE)

    missing_columns = [col for col in COLUMNS if col not in df.columns]
    if missing_columns:
        raise ValueError(f"Missing required columns: {missing_columns}")

    df = df[COLUMNS].copy()

# Keep only real ISO3 country codes.
# This removes aggregate rows such as GLOBAL.
    before_filter = len(df)

    df["iso3"] = df["iso3"].astype(str).str.upper().str.strip()
    df = df[df["iso3"].str.fullmatch(r"[A-Z]{3}", na=False)].copy()

    after_filter = len(df)
    removed_rows = before_filter - after_filter

    print("Loaded cleaned CSV.")
    print(f"Rows before ISO3 filter: {before_filter}")
    print(f"Rows after ISO3 filter: {after_filter}")
    print(f"Removed non-country/aggregate rows: {removed_rows}")
    print(f"Columns: {df.columns.tolist()}")

    return df


def load_to_postgres(df: pd.DataFrame) -> None:
    """
    Load cleaned WHO obesity data into PostgreSQL using COPY.
    """

    connection = psycopg2.connect(dbname=DATABASE_NAME)

    try:
        with connection:
            with connection.cursor() as cursor:
                print(f"Clearing existing rows from {TABLE_NAME}...")
                cursor.execute(f"TRUNCATE TABLE {TABLE_NAME};")

                print("Preparing CSV buffer...")
                buffer = StringIO()

                df.to_csv(
                    buffer,
                    index=False,
                    header=True,
                    na_rep="",
                )

                buffer.seek(0)

                print("Loading rows into PostgreSQL using COPY...")

                copy_sql = f"""
                    COPY {TABLE_NAME} (
                        iso3,
                        year,
                        sex,
                        sex_code,
                        obesity_pct,
                        obesity_pct_low,
                        obesity_pct_high,
                        who_region,
                        who_region_code
                    )
                    FROM STDIN
                    WITH CSV HEADER
                """

                cursor.copy_expert(copy_sql, buffer)

        print("Loaded WHO obesity data into PostgreSQL.")
        print(f"Rows loaded: {len(df)}")

    finally:
        connection.close()


def verify_load() -> None:
    """
    Verify that data was loaded correctly.
    """

    connection = psycopg2.connect(dbname=DATABASE_NAME)

    try:
        query = """
            SELECT
                sex,
                COUNT(*) AS row_count,
                MIN(year) AS min_year,
                MAX(year) AS max_year
            FROM who_obesity
            GROUP BY sex
            ORDER BY sex;
        """

        result = pd.read_sql(query, connection)

        print("\nVerification query result:")
        print(result)

    finally:
        connection.close()


if __name__ == "__main__":
    obesity_df = load_clean_data()
    load_to_postgres(obesity_df)
    verify_load()