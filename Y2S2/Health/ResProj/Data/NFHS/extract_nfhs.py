"""
extract_nfhs.py
Extracts from NFHS participation survey PDFs:
  1. Historical totals table (boys/girls/total by year)
  2. State-by-sport tables (boys pages 4-8, girls pages 10-14)

Output: two CSVs
  - nfhs_totals_by_year.csv
  - nfhs_state_by_sport.csv
"""

import re
import sys
from pathlib import Path
import pdfplumber
import pandas as pd

# ---------------------------------------------------------------------------
# Sports per page, relative to boys_start / girls_start offsets (0-based).
# Each entry: (relative_offset, gender, [sport1, sport2, sport3, sport4])
# ---------------------------------------------------------------------------
BOYS_PAGES = [
    (0, "Boys", ["Baseball", "Basketball", "Bowling", "Competitive Spirit Squads"]),
    (1, "Boys", ["Cross Country", "Football 11-player", "Golf", "Gymnastics"]),
    (2, "Boys", ["Ice Hockey", "Lacrosse", "Riflery", "Skiing Cross Country"]),
    (3, "Boys", ["Skiing Alpine", "Soccer", "Swimming and Diving", "Tennis"]),
    (4, "Boys", ["Track and Field Indoor", "Track and Field Outdoor", "Volleyball", "Wrestling"]),
]
GIRLS_PAGES = [
    (0, "Girls", ["Basketball", "Bowling", "Competitive Spirit Squads", "Cross Country"]),
    (1, "Girls", ["Field Hockey", "Football 11-player", "Golf", "Gymnastics"]),
    (2, "Girls", ["Ice Hockey", "Lacrosse", "Skiing Alpine", "Skiing Cross Country"]),
    (3, "Girls", ["Soccer", "Softball Slow Pitch", "Softball Fast Pitch", "Swimming and Diving"]),
    (4, "Girls", ["Tennis", "Track and Field Indoor", "Track and Field Outdoor", "Volleyball"]),
]


def get_page_config(n_pages):
    """Return (totals_idx, boys_start, girls_start) based on PDF size.

    Layout variants observed across NFHS survey PDFs:
      16 pages  (2009-10 – 2011-12): totals=1, boys=3, girls=9
      19 pages  (2012-13 – 2016-17): totals=2, boys=4, girls=11
      22 pages  (2017-18):           totals=4, boys=6, girls=13
      23 pages  (2018-19):           totals=4, boys=6, girls=14
    """
    if n_pages <= 16:
        return 1, 3, 9
    elif n_pages <= 20:
        return 2, 4, 11
    elif n_pages == 22:
        return 4, 6, 13
    else:  # 23+
        return 4, 6, 14

US_STATES = {
    "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
    "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia",
    "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky",
    "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota",
    "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire",
    "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota",
    "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
    "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont",
    "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming",
}

def clean_num(s):
    """'1,234' -> 1234, '' -> None"""
    s = s.replace(",", "").strip()
    return int(s) if s.isdigit() else None

def extract_state_rows(page, sports):
    """
    Given a pdfplumber page and list of 4 sport names,
    return list of dicts: {state, sport, gender(set by caller), schools, participants}
    """
    words = page.extract_words()
    # Group words by y-row (±2px tolerance)
    rows = {}
    for w in words:
        y = round(w["top"] / 2) * 2  # bin to nearest 2px
        rows.setdefault(y, []).append(w)

    # Sort rows by y
    sorted_rows = sorted(rows.items())

    # Find the header row to set data start y
    # Handles both "State"/"Schools"/"Particip." (older PDFs)
    # and "STATE"/"Schools"/"Participants" (2017-18+ PDFs)
    header_y = None
    for y, ws in sorted_rows:
        texts = [w["text"] for w in ws]
        texts_set = set(texts)
        if ("State" in texts_set or "STATE" in texts_set) and "Schools" in texts_set:
            header_y = y
            break

    if header_y is None:
        return []

    # Determine actual column x positions from header row
    # Handles both "Particip." (older) and "Participants" (2017-18+)
    header_words = rows[header_y]
    schools_xs = [w["x0"] for w in header_words if w["text"] == "Schools"]
    particip_xs = [w["x0"] for w in header_words
                   if w["text"] in ("Particip.", "Participants")]

    if len(schools_xs) < 4 or len(particip_xs) < 4:
        # fallback: use fixed offsets
        schools_xs = [180, 264, 342, 426]
        particip_xs = [220, 304, 382, 466]

    # Build column boundaries: [left, schools_x, particip_x, right] per sport
    col_defs = []
    for i in range(min(4, len(sports))):
        sx = schools_xs[i]
        px = particip_xs[i]
        col_defs.append((sx - 5, sx + 30, px - 5, px + 60))
        # (schools_left, schools_right, particip_left, particip_right)

    results = []
    current_state = None

    for y, ws in sorted_rows:
        if y <= header_y:
            continue

        # Sort words left to right
        ws_sorted = sorted(ws, key=lambda w: w["x0"])
        texts_x = [(w["text"], w["x0"]) for w in ws_sorted]

        # Check if leftmost word is a state name
        leftmost = ws_sorted[0] if ws_sorted else None
        if leftmost and leftmost["x0"] < 130:
            candidate = leftmost["text"]
            # Handle multi-word states: grab adjacent words also on the left
            state_words = [w["text"] for w in ws_sorted if w["x0"] < 130]
            candidate_full = " ".join(state_words)
            if candidate_full in US_STATES:
                current_state = candidate_full
            elif candidate in US_STATES:
                current_state = candidate

        if current_state is None:
            continue

        # Extract Schools and Particip values for each sport column
        for i, sport in enumerate(sports):
            if i >= len(col_defs):
                break
            sl, sr, pl, pr = col_defs[i]

            school_vals = [t for t, x in texts_x if sl <= x <= sr]
            particip_vals = [t for t, x in texts_x if pl <= x <= pr]

            schools = clean_num(school_vals[0]) if school_vals else None
            participants = clean_num(particip_vals[0]) if particip_vals else None

            if schools is not None or participants is not None:
                results.append({
                    "state": current_state,
                    "sport": sport,
                    "schools": schools,
                    "participants": participants,
                })

    return results


def extract_totals_by_year(page):
    """
    Extract the historical totals table from page 2 (index 1).
    The table is split into two side-by-side columns on the page.
    Left column: x < 310. Right column: x >= 310.
    Each row has: year, boys_participants, girls_participants, total
    """
    words = page.extract_words()
    year_pat = re.compile(r"^\d{4}-\d{2}$")

    # Separate words into left/right halves
    left, right = [], []
    for w in words:
        (left if w["x0"] < 310 else right).append(w)

    def parse_half(word_list):
        rows = {}
        for w in word_list:
            y = round(w["top"] / 2) * 2
            rows.setdefault(y, []).append(w)

        results = []
        for y, ws in sorted(rows.items()):
            ws_sorted = sorted(ws, key=lambda w: w["x0"])
            texts = [w["text"] for w in ws_sorted]
            year_tok = next((t for t in texts if year_pat.match(t)), None)
            if year_tok is None:
                continue
            # Numbers with commas = participant counts
            nums = [t for t in texts if re.match(r"[\d,]+$", t) and len(t) >= 4]
            if len(nums) >= 3:
                results.append({
                    "year": year_tok,
                    "boys": clean_num(nums[0]),
                    "girls": clean_num(nums[1]),
                    "total": clean_num(nums[2]),
                })
            elif len(nums) == 2:
                results.append({
                    "year": year_tok,
                    "boys": clean_num(nums[0]),
                    "girls": clean_num(nums[1]),
                    "total": None,
                })
        return results

    return parse_half(left) + parse_half(right)


def process_pdf(pdf_path: Path):
    """Extract totals and state-by-sport tables from a single PDF.
    Returns (df_totals, df_state) with a 'survey_year' column added."""
    stem = pdf_path.stem          # e.g. "2009-10_participation_survey"
    survey_year = stem.split("_")[0]   # e.g. "2009-10"

    print(f"\nOpening {pdf_path.name} ...")
    with pdfplumber.open(pdf_path) as pdf:
        n_pages = len(pdf.pages)
        totals_idx, boys_start, girls_start = get_page_config(n_pages)
        print(f"  {n_pages} pages  (totals=pg{totals_idx}, boys=pg{boys_start}+, girls=pg{girls_start}+)")

        # Historical totals
        totals = extract_totals_by_year(pdf.pages[totals_idx])
        raw = pd.DataFrame(totals)
        if raw.empty or "year" not in raw.columns:
            print(f"  WARNING: no totals rows extracted from page {totals_idx}")
            df_totals = pd.DataFrame(columns=["survey_year", "year", "boys", "girls", "total"])
        else:
            df_totals = raw.drop_duplicates("year").sort_values("year")
            df_totals.insert(0, "survey_year", survey_year)
            print(f"  Totals: {len(df_totals)} year rows")

        # Build absolute page indices from relative offsets
        state_pages = (
            [(boys_start + rel, gender, sports) for rel, gender, sports in BOYS_PAGES] +
            [(girls_start + rel, gender, sports) for rel, gender, sports in GIRLS_PAGES]
        )

        # State-by-sport tables
        all_rows = []
        for page_idx, gender, sports in state_pages:
            if page_idx >= n_pages:
                print(f"  WARNING: page {page_idx} not in PDF, skipping")
                continue
            rows = extract_state_rows(pdf.pages[page_idx], sports)
            for r in rows:
                r["gender"] = gender
            all_rows.extend(rows)
            print(f"  Page {page_idx} ({gender}): {len(rows)} rows")

        if all_rows:
            df_state = pd.DataFrame(all_rows)[["gender", "state", "sport", "schools", "participants"]]
            df_state = df_state.drop_duplicates(subset=["gender", "state", "sport"])
        else:
            df_state = pd.DataFrame(columns=["gender", "state", "sport", "schools", "participants"])
        df_state.insert(0, "survey_year", survey_year)
        print(f"  State-sport rows: {len(df_state)}")

    return df_totals, df_state


def main(pdf_path: str):
    """Process a single PDF (legacy entry point)."""
    pdf_path = Path(pdf_path)
    df_totals, df_state = process_pdf(pdf_path)

    out_dir = Path("nfhs_processed")
    out_dir.mkdir(exist_ok=True)
    survey_year = df_totals["survey_year"].iloc[0]

    df_totals.to_csv(out_dir / f"{survey_year}_totals_by_year.csv", index=False)
    df_state.to_csv(out_dir / f"{survey_year}_state_by_sport.csv", index=False)
    print(f"Saved per-year CSVs to {out_dir}/")


def batch_main(survey_dir: str = "nfhs_surveys"):
    """Process all PDFs in survey_dir and write consolidated girls CSVs to nfhs_processed/."""
    survey_dir = Path(survey_dir)
    # Only process annual participation survey files (e.g. "2009-10_participation_survey.pdf")
    import re as _re
    pdfs = sorted(
        p for p in survey_dir.glob("*.pdf")
        if _re.match(r"^\d{4}-\d{2}_", p.name)
    )
    if not pdfs:
        print(f"No PDFs found in {survey_dir}/")
        return

    out_dir = Path("nfhs_processed")
    out_dir.mkdir(exist_ok=True)

    all_totals = []
    all_state  = []

    for pdf in pdfs:
        df_t, df_s = process_pdf(pdf)
        all_totals.append(df_t)
        all_state.append(df_s)

        # Per-year CSVs
        sy = df_t["survey_year"].iloc[0]
        df_t.to_csv(out_dir / f"{sy}_totals_by_year.csv", index=False)
        df_s.to_csv(out_dir / f"{sy}_state_by_sport.csv", index=False)

    # Consolidated girls totals (one row per survey-year × historical-year)
    df_all_totals = pd.concat(all_totals, ignore_index=True)
    girls_totals = df_all_totals[["survey_year", "year", "girls"]].copy()
    girls_totals.to_csv(out_dir / "girls_totals_all_surveys.csv", index=False)
    print(f"\nWrote girls_totals_all_surveys.csv  ({len(girls_totals)} rows)")

    # Consolidated girls state-by-sport
    df_all_state = pd.concat(all_state, ignore_index=True)
    girls_state = df_all_state[df_all_state["gender"] == "Girls"].copy()
    girls_state.to_csv(out_dir / "girls_by_state_all_surveys.csv", index=False)
    print(f"Wrote girls_by_state_all_surveys.csv ({len(girls_state)} rows)")

    print(f"\nAll CSVs saved to {out_dir}/")
    print("\nSample — girls totals (last 5 rows of final survey):")
    last = girls_totals[girls_totals["survey_year"] == girls_totals["survey_year"].max()]
    print(last.tail(5).to_string(index=False))
    print("\nSample — girls state rows (Soccer, most recent survey):")
    mask = (girls_state["sport"] == "Soccer") & \
           (girls_state["survey_year"] == girls_state["survey_year"].max())
    print(girls_state[mask].head(10).to_string(index=False))


if __name__ == "__main__":
    if len(sys.argv) > 1:
        main(sys.argv[1])
    else:
        batch_main("nfhs_surveys")
