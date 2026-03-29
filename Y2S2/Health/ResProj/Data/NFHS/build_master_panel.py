"""
build_master_panel.py
Assembles master_participation.csv — a long-format panel of girls' HS sports
participation by state and year for 1993-94 through 2015-16.

Sports: Basketball, Soccer, Track and Field Indoor,
        Track and Field Outdoor, Cross Country

Output: ../master_participation.csv
Columns: state, survey_year, year_start, sport, participants, schools
"""

import pandas as pd
from pathlib import Path

TARGET_SPORTS = [
    "Basketball",
    "Soccer",
    "Track and Field Indoor",
    "Track and Field Outdoor",
    "Cross Country",
]

SURVEY_YEARS = [
    "1993-94", "1994-95", "1995-96", "1996-97", "1997-98", "1998-99",
    "1999-00", "2000-01", "2001-02", "2002-03", "2003-04", "2004-05",
    "2005-06", "2006-07", "2007-08", "2008-09", "2009-10", "2010-11",
    "2011-12", "2012-13", "2013-14", "2014-15", "2015-16",
]

IN_DIR  = Path("nfhs_processed")
OUT_DIR = Path("..") / "data"
OUT_DIR.mkdir(exist_ok=True)


def load_year(survey_year: str) -> pd.DataFrame:
    path = IN_DIR / f"{survey_year}_state_by_sport.csv"
    df = pd.read_csv(path)
    girls = df[df["gender"] == "Girls"].copy()
    return girls[girls["sport"].isin(TARGET_SPORTS)]


def main():
    frames = []
    for yr in SURVEY_YEARS:
        df = load_year(yr)
        frames.append(df)

    panel = pd.concat(frames, ignore_index=True)

    # Derive integer year_start from survey_year label
    panel["year_start"] = panel["survey_year"].str[:4].astype(int)

    # Keep only relevant columns, consistent ordering
    panel = panel[["state", "survey_year", "year_start", "sport", "participants", "schools"]]
    panel = panel.sort_values(["state", "year_start", "sport"]).reset_index(drop=True)

    # ── Coverage report ──────────────────────────────────────────────────────
    all_states  = sorted(panel["state"].unique())
    n_states    = len(all_states)
    n_years     = len(SURVEY_YEARS)
    n_sports    = len(TARGET_SPORTS)
    total_cells = n_states * n_years * n_sports
    have_data   = panel["participants"].notna().sum()

    print(f"\n{'='*60}")
    print(f"  States : {n_states}")
    print(f"  Years  : {n_years}  ({SURVEY_YEARS[0]} – {SURVEY_YEARS[-1]})")
    print(f"  Sports : {n_sports}")
    print(f"  Cells with participants data: {have_data:,} / {total_cells:,} "
          f"({100*have_data/total_cells:.1f}%)")
    print(f"{'='*60}")

    print("\nParticipants coverage by sport (% of state-year cells):")
    for sp in TARGET_SPORTS:
        sub  = panel[panel["sport"] == sp]
        pct  = 100 * sub["participants"].notna().sum() / (n_states * n_years)
        print(f"  {sp:<35} {pct:.1f}%")

    print("\nParticipants coverage by year (% of state-sport cells):")
    for yr in SURVEY_YEARS:
        sub = panel[panel["survey_year"] == yr]
        pct = 100 * sub["participants"].notna().sum() / (n_states * n_sports)
        print(f"  {yr}  {pct:.1f}%")

    # ── Missing-state summary ────────────────────────────────────────────────
    expected = pd.MultiIndex.from_product(
        [all_states, SURVEY_YEARS, TARGET_SPORTS],
        names=["state", "survey_year", "sport"],
    )
    full = pd.DataFrame(index=expected).reset_index()
    merged = full.merge(
        panel[["state", "survey_year", "sport", "participants"]],
        on=["state", "survey_year", "sport"],
        how="left",
    )
    missing = merged[merged["participants"].isna()]

    print(f"\nMissing observations (no participants data): {len(missing):,}")
    bad_years = missing.groupby("survey_year").size().sort_values(ascending=False).head(10)
    print("\nTop years by missing count:")
    print(bad_years.to_string())

    # ── Save ─────────────────────────────────────────────────────────────────
    out_path = OUT_DIR / "master_participation.csv"
    panel.to_csv(out_path, index=False)
    print(f"\nSaved {len(panel):,} rows → {out_path}")
    print("\nSample (first 10 rows):")
    print(panel.head(10).to_string(index=False))


if __name__ == "__main__":
    main()
