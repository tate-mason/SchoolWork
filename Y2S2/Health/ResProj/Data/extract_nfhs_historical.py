"""
extract_nfhs_historical.py
Extracts girls participation state-by-sport data from the scanned historical
NFHS PDF (hs_participation_survey_history_1969-2009.pdf) for school years
1993-94 through 2008-09.

All pages are images → requires pytesseract + pdf2image.

Output CSVs saved to nfhs_processed/:
  YYYY-YY_state_by_sport.csv        (girls only)
  YYYY-YY_totals_by_year.csv        historical national totals
  girls_by_state_historical.csv     consolidated girls state data
  girls_totals_historical.csv       consolidated girls national totals
"""

import re
import sys
from pathlib import Path
from difflib import get_close_matches

import pandas as pd
import pytesseract
from pdf2image import convert_from_path

# ── Config ─────────────────────────────────────────────────────────────────────

PDF_PATH = Path("nfhs_surveys/hs_participation_survey_history_1969-2009.pdf")
OUT_DIR  = Path("nfhs_processed")

# (survey_year_label, cover_page_1based, next_section_first_page_1based)
YEAR_SECTIONS = [
    ("1993-94", 236, 258),
    ("1994-95", 258, 280),
    ("1995-96", 280, 296),
    ("1996-97", 296, 313),
    ("1997-98", 313, 328),
    ("1998-99", 328, 344),
    ("1999-00", 344, 360),
    ("2000-01", 360, 369),
    ("2001-02", 369, 385),
    ("2002-03", 385, 401),
    ("2003-04", 401, 418),
    ("2004-05", 418, 435),
    ("2005-06", 435, 452),
    ("2006-07", 452, 469),
    ("2007-08", 469, 485),
    ("2008-09", 485, 501),
]

# Sport names per girls page, by era.
# Eras are determined by survey year; the lookup is (era, girls_page_index).
# "4page" era: 4 girls state-table pages per section (pre-2006)
# "5page" era: 5 girls state-table pages per section (2006-07 onward)
GIRLS_SPORTS = {
    "4page": [
        ["Basketball", "Competitive Spirit Squads", "Cross Country", "Field Hockey"],
        ["Golf", "Gymnastics", "Skiing Cross Country", "Skiing Alpine"],
        ["Soccer", "Softball Fast Pitch", "Softball Slow Pitch", "Swimming and Diving"],
        ["Tennis", "Track and Field Indoor", "Track and Field Outdoor", "Volleyball"],
    ],
    "5page": [
        ["Basketball", "Bowling", "Competitive Spirit Squads", "Cross Country"],
        ["Field Hockey", "Football 11-player", "Golf", "Gymnastics"],
        ["Ice Hockey", "Lacrosse", "Skiing Alpine", "Skiing Cross Country"],
        ["Soccer", "Softball Slow Pitch", "Softball Fast Pitch", "Swimming and Diving"],
        ["Tennis", "Track and Field Indoor", "Track and Field Outdoor", "Volleyball"],
    ],
}

def girls_era(survey_year):
    """Return '5page' for 2006-07+, '4page' otherwise."""
    try:
        start = int(survey_year[:4])
        return "5page" if start >= 2006 else "4page"
    except ValueError:
        return "4page"

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

YEAR_PAT  = re.compile(r'\b(\d{4}-\d{2})\b')
NUM_PAT   = re.compile(r'\b(\d[\d,]{3,})\b')
PER_SPORT = re.compile(r'\bSPORT\b.{0,40}\bSTATE\b', re.IGNORECASE | re.DOTALL)


# ── Utilities ──────────────────────────────────────────────────────────────────

def clean_num(text):
    if not isinstance(text, str):
        return None
    t = (text.replace(',', '').replace('.', '')
             .replace('O', '0').replace('o', '0').strip())
    t = re.sub(r'[^\d]', '', t)
    return int(t) if t and 2 <= len(t) <= 7 else None


def match_state(raw):
    raw = raw.strip()
    if not raw or len(raw) < 3:
        return None
    if raw in US_STATES:
        return raw
    titled = raw.title()
    if titled in US_STATES:
        return titled
    hits = get_close_matches(titled, US_STATES, n=1, cutoff=0.72)
    return hits[0] if hits else None


# ── Page classification ───────────────────────────────────────────────────────

def classify(text):
    upper = text.upper()
    tags  = set()
    if "GIRLS PARTICIPATION" in upper:
        tags.add("girls")
    if "BOYS PARTICIPATION" in upper:
        tags.add("boys")
    has_schools  = "SCHOOLS" in upper
    has_particip = "PARTICIP" in upper
    year_toks    = YEAR_PAT.findall(text)
    if has_schools and has_particip:
        head = '\n'.join(l.strip() for l in text.split('\n') if l.strip())[:200]
        if PER_SPORT.search(head):
            tags.add("per_sport")
        else:
            tags.add("state_table")
    if len(year_toks) >= 8 and ("SUMMARY" in upper or not has_schools):
        tags.add("totals")
    return tags


# ── OCR ───────────────────────────────────────────────────────────────────────

def ocr_words(img, conf=25):
    tsv  = pytesseract.image_to_data(img, output_type=pytesseract.Output.DATAFRAME)
    mask = (tsv['conf'] >= conf) & (tsv['text'].str.strip() != '')
    return [(int(r['left']), int(r['top']), str(r['text']))
            for _, r in tsv[mask].iterrows()]


def load_page(page_num, dpi):
    return convert_from_path(str(PDF_PATH),
                             first_page=page_num, last_page=page_num,
                             dpi=dpi)[0]


# ── Column detection ──────────────────────────────────────────────────────────

def detect_columns(word_list, sport_names):
    """
    Find the 'State | Schools | Particip.' header row and build column
    definitions using the provided sport_names list (in left-to-right order).

    Key fix: after finding header_y via the first bin that has State+Schools,
    we search ALL words within ±35px of header_y to collect every Schools and
    Particip. position (they can be slightly misaligned in y due to OCR).

    Returns (col_defs, header_y) or ([], None).
    col_defs = [{sport, sl, sr, pl, pr}, ...]
    """
    # Bin words by y (8-px buckets)
    y_bins = {}
    for x, y, t in word_list:
        yb = round(y / 8) * 8
        y_bins.setdefault(yb, []).append((x, t))

    # Pass 1: find the header row.
    # Look for a y-bin containing 'state' where 'schools' appears within ±16px.
    # This tolerates the slight y-misalignment common in scanned-page OCR.
    def _is_schools(t):
        return re.sub(r'[^\w.]', '', t.lower()) in ('schools', 'sch')
    def _is_state(t):
        return re.sub(r'[^\w]', '', t.lower()) in ('state', 'states')

    header_y = None
    for yb in sorted(y_bins.keys()):
        if not any(_is_state(t) for _, t in y_bins[yb]):
            continue
        # Check for 'schools' in a ±16px band around this bin
        if any(_is_schools(t)
               for yb2, ws2 in y_bins.items() if abs(yb2 - yb) <= 16
               for _, t in ws2):
            header_y = yb
            break

    if header_y is None:
        return [], None

    # Pass 2: collect ALL Schools and Particip xs within ±35px of header_y.
    # Strip leading/trailing quote OCR artifacts (e.g. "'Schools") before matching.
    schools_xs = []
    particip_xs = []
    for yb, ws in y_bins.items():
        if abs(yb - header_y) > 36:
            continue
        for x, t in ws:
            tl = re.sub(r'[^\w.]', '', t.lower())  # keep only alnum + dot
            if tl in ('schools', 'sch'):
                schools_xs.append(x)
            elif 'particip' in tl:
                particip_xs.append(x)

    schools_xs = sorted(set(schools_xs))
    particip_xs = sorted(set(particip_xs))

    if not schools_xs:
        return [], None

    n_cols = min(len(schools_xs), len(sport_names))
    schools_xs = schools_xs[:n_cols]

    # Smart pairing: for each schools_x, find the nearest particip_x that lies
    # between this sx and the next sx (i.e., within the same column).
    # Falls back to sx+130 estimate when no particip header was detected for a col.
    def find_particip(i, sx):
        next_sx = schools_xs[i + 1] if i + 1 < n_cols else sx + 500
        within = [px for px in particip_xs if sx < px < next_sx]
        return min(within, key=lambda px: px - sx) if within else sx + 130

    col_defs = []
    for i, sx in enumerate(schools_xs):
        px   = find_particip(i, sx)
        sport = sport_names[i]
        col_defs.append({
            'sport': sport,
            'sl': sx - 15,
            'sr': sx + 100,   # wider: header is ~60px left of data
            'pl': px - 15,
            'pr': px + 95,
        })

    return col_defs, header_y


# ── State-row extraction ──────────────────────────────────────────────────────

def extract_state_rows(word_list, col_defs, header_y):
    """Return [{state, sport, schools, participants}] from word positions."""
    y_bins = {}
    for x, y, t in word_list:
        yb = round(y / 8) * 8
        y_bins.setdefault(yb, []).append((x, t))

    results = []
    current_state = None
    state_x_max = 600   # state names are in the left ~35% at 200 DPI

    for yb in sorted(y_bins.keys()):
        if yb <= header_y + 8:
            continue

        ws = sorted(y_bins[yb], key=lambda w: w[0])
        texts_x = [(t, x) for x, t in ws]

        # Check for state name in left column
        left_text = ' '.join(t for t, x in texts_x if x < state_x_max)
        state_hit = match_state(left_text)
        if state_hit:
            current_state = state_hit

        if current_state is None:
            continue

        for cd in col_defs:
            sv = [clean_num(t) for t, x in texts_x if cd['sl'] <= x <= cd['sr']]
            pv = [clean_num(t) for t, x in texts_x if cd['pl'] <= x <= cd['pr']]
            schools = next((v for v in sv if v is not None), None)
            parts   = next((v for v in pv if v is not None), None)
            if schools is not None or parts is not None:
                results.append({
                    'state':        current_state,
                    'sport':        cd['sport'],
                    'schools':      schools,
                    'participants': parts,
                })

    return results


# ── Historical totals extraction ──────────────────────────────────────────────

def extract_totals(img):
    text    = pytesseract.image_to_string(img)
    results = []
    for line in text.split('\n'):
        years = YEAR_PAT.findall(line)
        if not years:
            continue
        nums = [int(n.replace(',', '')) for n in NUM_PAT.findall(line)]
        yr = years[0]
        if len(nums) >= 3:
            results.append({'year': yr, 'boys': nums[0],
                             'girls': nums[1], 'total': nums[2]})
        elif len(nums) == 2:
            results.append({'year': yr, 'boys': nums[0],
                             'girls': nums[1], 'total': None})
        elif len(nums) == 1:
            results.append({'year': yr, 'boys': None,
                             'girls': nums[0], 'total': None})
    return results


# ── Per-year processing ───────────────────────────────────────────────────────

def process_section(survey_year, cover_pg, next_pg,
                    dpi_scan=80, dpi_extract=200):
    end_pg  = min(next_pg - 1, 500)
    n_pages = end_pg - cover_pg + 1
    era     = girls_era(survey_year)
    sports_table = GIRLS_SPORTS[era]

    print(f"\n{'─'*64}")
    print(f"  {survey_year}  (pg {cover_pg}–{end_pg},  {n_pages} pages,  era={era})")

    # ── Pass 1: low-DPI scan to identify girls page offsets ──────────────────
    low_imgs = convert_from_path(str(PDF_PATH),
                                 first_page=cover_pg, last_page=end_pg,
                                 dpi=dpi_scan)

    totals_offset = None
    girls_start   = None
    girls_end     = None

    for offset, img in enumerate(low_imgs):
        txt  = pytesseract.image_to_string(img)
        tags = classify(txt)
        upper = txt.upper()

        if totals_offset is None and 'totals' in tags and offset >= 1:
            totals_offset = offset

        if girls_start is None:
            if ('girls' in tags and 'state_table' in tags):
                girls_start = offset
            elif ('girls' in tags and 'per_sport' not in tags
                  and 'boys' not in tags and offset > 2):
                girls_start = offset
        else:
            if 'per_sport' in tags:
                girls_end = offset
                break
            if 'boys' in tags and 'girls' not in tags:
                girls_end = offset
                break

    if girls_start is None:
        print("    WARNING: no girls section detected")
        df_t = pd.DataFrame(columns=['survey_year','year','boys','girls','total'])
        df_s = pd.DataFrame(columns=['survey_year','gender','state','sport',
                                     'schools','participants'])
        return df_t, df_s

    girl_offsets = list(range(girls_start,
                              girls_end if girls_end is not None else n_pages))
    print(f"    totals_offset={totals_offset},  "
          f"girls offsets: {girl_offsets[0]}–{girl_offsets[-1]}")

    # ── Extract totals ────────────────────────────────────────────────────────
    df_totals = pd.DataFrame(columns=['survey_year','year','boys','girls','total'])
    if totals_offset is not None:
        hi   = load_page(cover_pg + totals_offset, dpi_extract)
        rows = extract_totals(hi)
        if rows:
            df_totals = (pd.DataFrame(rows)
                           .drop_duplicates('year')
                           .sort_values('year'))
            df_totals.insert(0, 'survey_year', survey_year)
            print(f"    Totals: {len(df_totals)} historical year rows")

    # ── Extract girls state tables ────────────────────────────────────────────
    all_rows   = []
    girls_pg_idx = 0   # which element of sports_table we're on

    for offset in girl_offsets:
        pg_num = cover_pg + offset

        # High-DPI OCR
        hi   = load_page(pg_num, dpi_extract)
        img_w = hi.size[0]
        quick = pytesseract.image_to_string(hi)
        qtags = classify(quick)

        if 'per_sport' in qtags:
            print(f"    pg{pg_num} +{offset}: per-sport page → stop girls scan")
            break
        if 'boys' in qtags and 'girls' not in qtags:
            print(f"    pg{pg_num} +{offset}: boys page → skip")
            continue

        # Determine expected sports for this page
        if girls_pg_idx >= len(sports_table):
            print(f"    pg{pg_num} +{offset}: beyond expected sport pages → skip")
            continue
        expected_sports = sports_table[girls_pg_idx]

        words = ocr_words(hi)
        col_defs, header_y = detect_columns(words, expected_sports)

        if not col_defs:
            # Try to proceed anyway — maybe it's a continuation page with same sports
            print(f"    pg{pg_num} +{offset}: no header detected → skip")
            continue

        rows = extract_state_rows(words, col_defs, header_y)
        detected_sports = [cd['sport'] for cd in col_defs]
        print(f"    pg{pg_num} +{offset}: sports={detected_sports}  rows={len(rows)}")

        all_rows.extend(rows)
        girls_pg_idx += 1

    # Build girls state DataFrame
    if all_rows:
        df_state = pd.DataFrame(all_rows)
        df_state = df_state[['state', 'sport', 'schools', 'participants']]
        df_state = df_state.drop_duplicates(subset=['state', 'sport'])
        df_state.insert(0, 'gender', 'Girls')
        df_state.insert(0, 'survey_year', survey_year)
    else:
        df_state = pd.DataFrame(columns=['survey_year','gender','state','sport',
                                          'schools','participants'])

    print(f"    Girls state rows total: {len(df_state)}")
    return df_totals, df_state


# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    OUT_DIR.mkdir(exist_ok=True)

    target = sys.argv[1] if len(sys.argv) > 1 else None

    all_totals = []
    all_state  = []

    for survey_year, cover_pg, next_pg in YEAR_SECTIONS:
        if target and survey_year != target:
            continue
        df_t, df_s = process_section(survey_year, cover_pg, next_pg)

        df_t.to_csv(OUT_DIR / f"{survey_year}_totals_by_year.csv", index=False)
        df_s.to_csv(OUT_DIR / f"{survey_year}_state_by_sport.csv", index=False)

        all_totals.append(df_t)
        all_state.append(df_s)

    if not target:
        gt = pd.concat(all_totals, ignore_index=True)
        gt = gt[['survey_year','year','girls']].dropna(subset=['girls'])
        gt.to_csv(OUT_DIR / "girls_totals_historical.csv", index=False)
        print(f"\nWrote girls_totals_historical.csv  ({len(gt)} rows)")

        gs = pd.concat(all_state, ignore_index=True)
        gs.to_csv(OUT_DIR / "girls_by_state_historical.csv", index=False)
        print(f"Wrote girls_by_state_historical.csv ({len(gs)} rows)")

        print(f"\nAll CSVs in {OUT_DIR}/")
        if len(gs):
            print("\nSample — girls Soccer 2008-09:")
            mask = (gs['sport'] == 'Soccer') & (gs['survey_year'] == '2008-09')
            print(gs[mask].head(8).to_string(index=False))


if __name__ == "__main__":
    main()
