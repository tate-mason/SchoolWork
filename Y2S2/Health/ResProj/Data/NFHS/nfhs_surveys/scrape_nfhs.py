#!/usr/bin/env python3
"""
Scrape NFHS girls participation by state for:
  basketball, cross country, soccer, track & field (indoor + outdoor combined)

Sources:
  - hs_truncated.pdf (1993-94 through 2008-09)
  - 2009-10 through 2018-19 annual participation PDFs
Output:
  master_scraped.csv  (year, state, basketball, cross_country, soccer, track_field)
"""

import pytesseract
from pytesseract import Output
import pandas as pd
import numpy as np
from pdf2image import convert_from_path
import re
import os
import sys

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

STATES = [
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
    'Connecticut', 'Delaware', 'District of Columbia', 'Florida', 'Georgia',
    'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky',
    'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
    'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire',
    'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota',
    'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina',
    'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia',
    'Washington', 'West Virginia', 'Wisconsin', 'Wyoming',
]
STATES_SET = set(STATES)

# Two-word state prefixes
TWO_WORD_STATES = {
    'New': {'Hampshire', 'Jersey', 'Mexico', 'York'},
    'North': {'Carolina', 'Dakota'},
    'South': {'Carolina', 'Dakota'},
    'Rhode': {'Island'},
    'West': {'Virginia'},
}

# State abbreviation → full name (for years where hs_truncated.pdf uses 2-letter codes)
STATE_ABBREVS = {
    'AL': 'Alabama', 'AK': 'Alaska', 'AZ': 'Arizona', 'AR': 'Arkansas',
    'CA': 'California', 'CO': 'Colorado', 'CT': 'Connecticut', 'DE': 'Delaware',
    'DC': 'District of Columbia', 'FL': 'Florida', 'GA': 'Georgia', 'HI': 'Hawaii',
    'ID': 'Idaho', 'IL': 'Illinois', 'IN': 'Indiana', 'IA': 'Iowa', 'KS': 'Kansas',
    'KY': 'Kentucky', 'LA': 'Louisiana', 'ME': 'Maine', 'MD': 'Maryland',
    'MA': 'Massachusetts', 'MI': 'Michigan', 'MN': 'Minnesota', 'MS': 'Mississippi',
    'MO': 'Missouri', 'MT': 'Montana', 'NE': 'Nebraska', 'NV': 'Nevada',
    'NH': 'New Hampshire', 'NJ': 'New Jersey', 'NM': 'New Mexico', 'NY': 'New York',
    'NC': 'North Carolina', 'ND': 'North Dakota', 'OH': 'Ohio', 'OK': 'Oklahoma',
    'OR': 'Oregon', 'PA': 'Pennsylvania', 'RI': 'Rhode Island', 'SC': 'South Carolina',
    'SD': 'South Dakota', 'TN': 'Tennessee', 'TX': 'Texas', 'UT': 'Utah',
    'VT': 'Vermont', 'VA': 'Virginia', 'WA': 'Washington', 'WV': 'West Virginia',
    'WI': 'Wisconsin', 'WY': 'Wyoming',
    # Common OCR errors for abbreviations
    'BC': 'District of Columbia',  # OCR error: DC → BC
    'ST': None,  # header row marker, not a state
}

# Common OCR errors for state first words
OCR_FIXES = {
    # Alaska variants
    'laska': 'Alaska', 'Mlaska': 'Alaska', 'Maska': 'Alaska', 'daska': 'Alaska',
    '\\laska': 'Alaska', 'Nlaska': 'Alaska',
    # Illinois variants
    'Hlinois': 'Illinois', 'Mlinois': 'Illinois', 'Minois': 'Illinois',
    'Hllinois': 'Illinois', 'Ilinois': 'Illinois', 'llinois': 'Illinois',
    # Iowa variants (missing leading I)
    'lowa': 'Iowa', 'owa': 'Iowa',
    # Missouri variants
    'Atssouri': 'Missouri', '/lissouri': 'Missouri', 'Missourt': 'Missouri',
    'flissouri': 'Missouri', 'Alissouri': 'Missouri',
    # Indiana variants (missing leading I)
    'ndiana': 'Indiana',
    # Idaho variants (missing leading I)
    'daho': 'Idaho',
    # Maine variants (missing leading M or OCR error)
    'jaine': 'Maine', 'Alaine': 'Maine', 'Aaine': 'Maine',
    # Maryland (missing leading M)
    'aryland': 'Maryland',
    # Massachusetts (missing leading M)
    'assachusetts': 'Massachusetts',
    # Michigan (missing leading M)
    'ichigan': 'Michigan',
    # Minnesota (missing leading M)
    'innesota': 'Minnesota',
    # Mississippi (missing leading M)
    'ississippi': 'Mississippi',
    # New * states (missing leading N)
    'ew': 'New',
    # North * states (missing leading N)
    'orth': 'North',
    # Other common fixes
    'Connecticul': 'Connecticut', 'Calitornia': 'California',
    'Pennsyivania': 'Pennsylvania', 'Pennsylvanta': 'Pennsylvania',
}

# Sport keyword patterns (order matters: more specific first)
SPORT_PATTERNS = [
    ('track_outdoor', ['outdoor']),
    ('track_indoor',  ['indoor']),
    ('soccer',        ['soccer']),
    ('basketball',    ['basketb']),
    ('cross_country', ['cross', 'country']),
]

# ---------------------------------------------------------------------------
# Image / OCR helpers
# ---------------------------------------------------------------------------

def get_words(img):
    """Return DataFrame of words with position data from image."""
    d = pytesseract.image_to_data(img, output_type=Output.DATAFRAME)
    d = d[d.conf > 0].copy()
    d = d[d.text.str.strip().str.len() > 0].copy()
    d['xm'] = (d['left'] + d['width'] / 2).astype(int)
    d['ym'] = (d['top'] + d['height'] / 2).astype(int)
    return d


def parse_num(text):
    """Parse a number from OCR text (handles commas, asterisks, spaces)."""
    cleaned = re.sub(r'[*\s,~]', '', text)
    if re.match(r'^\d+$', cleaned):
        return int(cleaned)
    return None


def fix_state_word(word):
    return OCR_FIXES.get(word, word)


def has_girls_participation_header(words, img_height, top_frac=0.20):
    """
    Return True if page has a prominent 'GIRLS PARTICIPATION' section header.
    Requires both words to appear in the top top_frac of the page AND
    on approximately the same line (within 50px y) AND within 400px x of each other.
    """
    top_words = words[words['top'] < img_height * top_frac].copy()
    if top_words.empty:
        return False

    girls_words = top_words[top_words['text'].str.upper() == 'GIRLS']
    part_words  = top_words[top_words['text'].str.upper().str.startswith('PARTICIP')]

    if girls_words.empty or part_words.empty:
        return False

    for _, gw in girls_words.iterrows():
        for _, pw in part_words.iterrows():
            same_line  = abs(gw['ym'] - pw['ym']) < 30
            close_x    = abs(gw['xm'] - pw['xm']) < 400
            girls_left = gw['xm'] < pw['xm']   # GIRLS comes before PARTICIPATION
            if same_line and close_x and girls_left:
                return True
    return False


def match_state(row_words):
    """
    Try to match beginning of a row to a state name.
    Returns (state_name, num_words_consumed) or None.
    row_words: list of word dicts (with 'text' key).
    """
    if not row_words:
        return None
    raw0 = row_words[0]['text'].strip()
    # Strip trailing non-alpha characters (OCR artifacts like apostrophes, quotes)
    raw0_clean = re.sub(r"[^A-Za-z]+$", "", raw0)
    w0 = fix_state_word(raw0_clean if raw0_clean else raw0)

    # Two-letter abbreviation (some hs_truncated.pdf years use state codes)
    if len(raw0) == 2 and raw0.upper() == raw0:
        full = STATE_ABBREVS.get(raw0.upper())
        if full is None:
            return None   # 'ST' header or unknown code
        return full, 1

    # Three-word: District of Columbia
    if w0 == 'District' and len(row_words) >= 3:
        w1 = row_words[1]['text'].strip()
        w2 = row_words[2]['text'].strip()
        if w1.lower() == 'of' and w2 == 'Columbia':
            return 'District of Columbia', 3

    # Two-word states
    if w0 in TWO_WORD_STATES and len(row_words) >= 2:
        w1 = row_words[1]['text'].strip()
        if w1 in TWO_WORD_STATES[w0]:
            return f'{w0} {w1}', 2

    # Single-word states
    if w0 in STATES_SET:
        return w0, 1

    return None


def group_rows(words, y_tol=14):  # y_tol=14 for OCR pixels; use ~5 for pdfplumber points
    """Group word dicts into rows by top coordinate. Returns list of lists."""
    if words.empty:
        return []
    words_sorted = words.sort_values('top')
    rows = []
    cur_row = []
    cur_top = None
    for _, w in words_sorted.iterrows():
        y = w['top']
        if cur_top is None or abs(y - cur_top) <= y_tol:
            cur_row.append(w.to_dict())
            n = len(cur_row)
            cur_top = y if cur_top is None else (cur_top * (n - 1) + y) / n
        else:
            rows.append(sorted(cur_row, key=lambda x: x['left']))
            cur_row = [w.to_dict()]
            cur_top = y
    if cur_row:
        rows.append(sorted(cur_row, key=lambda x: x['left']))
    return rows


# ---------------------------------------------------------------------------
# Column detection
# ---------------------------------------------------------------------------

def detect_sport_cols(words, img_height, debug=False):
    """
    Detect x-positions of Participants columns for target sports.
    Returns (col_map, header_end_y):
      col_map: {sport_name: particip_x}
      header_end_y: y-coordinate (pixels) where header rows end
    Only returns sports actually found on this page.
    """
    # Header area: top 40% of page (sport headers can be deep in some formats)
    header_thresh = img_height * 0.40
    hwords = words[words['top'] < header_thresh]

    if hwords.empty:
        return {}, 0

    # All "Particip." positions in header
    particip_rows = hwords[hwords['text'].str.lower().str.contains(r'particip', regex=True)]
    if particip_rows.empty:
        return {}, 0
    particip_xs = sorted(particip_rows['xm'].values)
    header_end_y = int(particip_rows['top'].max()) + 5  # last header row bottom

    if debug:
        print(f"  Particip. xs: {particip_xs}, header_end_y={header_end_y}")

    col_map = {}
    text_lower = ' '.join(hwords['text'].str.lower())

    # Check each sport pattern
    for sport, keywords in SPORT_PATTERNS:
        # Only consider if all keywords present
        if not all(kw in text_lower for kw in keywords):
            continue

        # Cross country exclusion: if "alpine" is in the header, any "Cross Country"
        # is Skiing – Cross Country, not girls running cross country
        if sport == 'cross_country' and 'alpine' in text_lower:
            continue

        # Find keyword x-positions
        kw_xs = []
        for kw in keywords:
            matches = hwords[hwords['text'].str.lower().str.contains(kw, regex=False)]
            if not matches.empty:
                kw_xs.append(matches['xm'].mean())

        if not kw_xs:
            continue

        sport_x = np.mean(kw_xs)

        # Match to nearest Particip. column (within 350px)
        candidates = [(abs(px - sport_x), px) for px in particip_xs]
        if not candidates:
            continue
        best_dist, best_px = min(candidates, key=lambda c: c[0])

        if debug:
            print(f"  Sport {sport}: kw_x={sport_x:.0f}, best_particip={best_px:.0f}, dist={best_dist:.0f}")

        if best_dist < 350:
            col_map[sport] = best_px

    return col_map, header_end_y


# ---------------------------------------------------------------------------
# State data extraction
# ---------------------------------------------------------------------------

def extract_state_data(words, col_map, header_end_y, y_tol=14):
    """
    Extract participation numbers per state per sport.
    Returns dict: {state: {sport: participants}}
    col_map: {sport: particip_x}
    header_end_y: coordinate where header ends (data starts below this)
    y_tol: row-grouping tolerance (14px for OCR, ~5 for PDF points)
    """
    if not col_map:
        return {}

    # Data starts just after header ends; use a small buffer
    data_thresh = max(header_end_y, 10)
    dwords = words[words['top'] > data_thresh]

    rows = group_rows(dwords, y_tol=y_tol)
    results = {}

    for row in rows:
        if not row:
            continue

        m = match_state(row)
        if m is None:
            continue

        state, n_consumed = m

        # Collect numbers after state name
        state_right_edge = row[n_consumed - 1]['xm'] + 50  # 50px buffer
        numbers = []
        for w in row[n_consumed:]:
            if w['xm'] > state_right_edge:
                num = parse_num(w['text'])
                if num is not None:
                    numbers.append((w['xm'], num))

        if not numbers:
            continue

        # Assign numbers to sport columns
        state_data = {}
        for sport, col_x in col_map.items():
            # Find number closest to col_x (within 90px)
            candidates = [(abs(nx - col_x), num) for nx, num in numbers
                          if abs(nx - col_x) < 90]
            if candidates:
                _, num = min(candidates, key=lambda c: c[0])
                state_data[sport] = num

        if state_data:
            # Merge (don't overwrite existing values from earlier pages)
            if state not in results:
                results[state] = {}
            for k, v in state_data.items():
                if k not in results[state]:
                    results[state][k] = v

    return results


# ---------------------------------------------------------------------------
# Process hs_truncated.pdf
# ---------------------------------------------------------------------------

# Year boundaries in hs_truncated.pdf (1-indexed page numbers, inclusive)
HIST_YEAR_RANGES = {
    '1993-94': (1,   23),
    '1994-95': (24,  45),
    '1995-96': (46,  61),
    '1996-97': (62,  78),
    '1997-98': (79,  93),
    '1998-99': (94,  109),
    '1999-00': (110, 125),
    '2000-01': (126, 134),
    '2001-02': (135, 150),
    '2002-03': (151, 166),
    '2003-04': (167, 183),
    '2004-05': (184, 200),
    '2005-06': (201, 217),
    '2006-07': (218, 234),
    '2007-08': (235, 250),
    '2008-09': (251, 266),
}

TARGET_SPORTS = {'basketball', 'cross_country', 'soccer', 'track_indoor', 'track_outdoor'}


def process_historical(pdf_path, dpi=200, verbose=True):
    """Process hs_truncated.pdf. Returns list of row dicts."""
    if verbose:
        print(f"Loading {pdf_path} ...")
    imgs = convert_from_path(pdf_path, dpi=dpi)
    results = []

    for year, (pg_start, pg_end) in HIST_YEAR_RANGES.items():
        if verbose:
            print(f"\n=== Year {year} (pages {pg_start}-{pg_end}) ===")
        year_data = {}   # {state: {sport: value}}
        in_girls = False

        for pg_num in range(pg_start, pg_end + 1):
            idx = pg_num - 1
            if idx >= len(imgs):
                break

            img = imgs[idx]
            words = get_words(img)
            all_text = ' '.join(words['text'].str.upper())

            # Detect girls section start
            if has_girls_participation_header(words, img.height):
                in_girls = True
                if verbose:
                    print(f"  Page {pg_num}: GIRLS PARTICIPATION header found")

            # Stop if we hit the boys section again (shouldn't happen, but safety)
            if in_girls and 'BOYS' in all_text and pg_num > pg_start + 5:
                # Could be a false positive; check if "BOYS PARTICIPATION" is prominent
                bwords = words[words['top'] < img.height * 0.25]
                btext = ' '.join(bwords['text'].str.upper())
                if 'BOYS PARTICIPATION' in btext or 'BOYS' in btext.split()[:5]:
                    if verbose:
                        print(f"  Page {pg_num}: BOYS section, stopping girls extraction")
                    break

            if not in_girls:
                continue

            # Skip pages that are clearly not sport tables (e.g. "SPORT State ...")
            # These are the minor/special sport pages
            first_col_text = ' '.join(words[words['xm'] < 400]['text'].str.upper())
            if 'SPORT' in first_col_text[:200] and 'BASKETBALL' not in all_text:
                if verbose:
                    print(f"  Page {pg_num}: minor sports page, skipping")
                continue

            # Detect columns
            col_map, header_end_y = detect_sport_cols(words, img.height, debug=False)
            target_cols = {k: v for k, v in col_map.items() if k in TARGET_SPORTS}

            if not target_cols:
                if verbose:
                    print(f"  Page {pg_num}: no target sports detected")
                continue

            if verbose:
                print(f"  Page {pg_num}: found sports: {list(target_cols.keys())}")

            page_data = extract_state_data(words, target_cols, header_end_y)

            for state, sports in page_data.items():
                if state not in year_data:
                    year_data[state] = {}
                for k, v in sports.items():
                    if k not in year_data[state]:
                        year_data[state][k] = v

        # Compile year results
        for state in STATES:
            row = {'year': year, 'state': state}
            d = year_data.get(state, {})
            row['basketball']   = d.get('basketball')
            row['cross_country'] = d.get('cross_country')
            row['soccer']       = d.get('soccer')
            tf_in  = d.get('track_indoor',  0) or 0
            tf_out = d.get('track_outdoor', 0) or 0
            row['track_field']  = (tf_in + tf_out) if (tf_in or tf_out) else None
            results.append(row)

        if verbose:
            n_states = sum(1 for r in results if r['year'] == year and r['basketball'] is not None)
            print(f"  → {n_states} states with basketball data")

    return results


# ---------------------------------------------------------------------------
# Process annual participation surveys using pdfplumber (text-based PDFs)
# ---------------------------------------------------------------------------

def get_words_plumber(pg):
    """
    Extract word positions from a pdfplumber page.
    Returns a DataFrame compatible with detect_sport_cols / extract_state_data,
    using PDF point coordinates (72 pts = 1 inch).
    """
    import pdfplumber as _plumber  # local import avoids requiring it globally
    raw = pg.extract_words(keep_blank_chars=False, use_text_flow=False)
    if not raw:
        return pd.DataFrame(columns=['left', 'top', 'width', 'xm', 'ym', 'text'])
    rows = []
    for w in raw:
        xm = (w['x0'] + w['x1']) / 2
        rows.append({
            'left':  w['x0'],
            'top':   w['top'],
            'width': w['x1'] - w['x0'],
            'xm':    xm,
            'ym':    w['top'],   # single-line, so ym ≈ top
            'text':  w['text'],
        })
    return pd.DataFrame(rows)


def process_annual(pdf_path, year_label, verbose=True):
    """
    Process a single annual survey PDF using pdfplumber (text-based).
    Returns list of row dicts.
    """
    import pdfplumber
    if verbose:
        print(f"\n=== {year_label}: {pdf_path} ===")

    year_data = {}
    in_girls = False

    with pdfplumber.open(pdf_path) as pdf:
        for pg_idx, pg in enumerate(pdf.pages):
            words = get_words_plumber(pg)
            if words.empty:
                continue

            pg_height = pg.height

            # Detect girls section start (strict header match)
            if has_girls_participation_header(words, pg_height):
                in_girls = True
                if verbose:
                    print(f"  Page {pg_idx+1}: GIRLS PARTICIPATION header")

            if not in_girls:
                continue

            # Detect target sport columns (use small y_tol since PDF pts are small)
            col_map, header_end_y = detect_sport_cols(words, pg_height, debug=False)
            target_cols = {k: v for k, v in col_map.items() if k in TARGET_SPORTS}

            if not target_cols:
                continue

            if verbose:
                print(f"  Page {pg_idx+1}: sports {list(target_cols.keys())}")

            # Extract with tight y-tolerance for PDF points
            page_data = extract_state_data(words, target_cols, header_end_y, y_tol=5)

            for state, sports in page_data.items():
                if state not in year_data:
                    year_data[state] = {}
                for k, v in sports.items():
                    if k not in year_data[state]:
                        year_data[state][k] = v

    # Compile results
    results = []
    for state in STATES:
        row = {'year': year_label, 'state': state}
        d = year_data.get(state, {})
        row['basketball']    = d.get('basketball')
        row['cross_country'] = d.get('cross_country')
        row['soccer']        = d.get('soccer')
        tf_in  = d.get('track_indoor',  0) or 0
        tf_out = d.get('track_outdoor', 0) or 0
        row['track_field']   = (tf_in + tf_out) if (tf_in or tf_out) else None
        results.append(row)

    n = sum(1 for r in results if r['basketball'] is not None)
    if verbose:
        print(f"  → {n} states with basketball data")

    return results


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    all_results = []

    # 1. Historical PDF
    hist_pdf = 'hs_truncated.pdf'
    if os.path.exists(hist_pdf):
        hist_data = process_historical(hist_pdf, dpi=200)
        all_results.extend(hist_data)
    else:
        print(f"WARNING: {hist_pdf} not found", file=sys.stderr)

    # 2. Annual PDFs (2009-10 through 2018-19)
    annual_files = sorted([
        f for f in os.listdir('.')
        if re.match(r'\d{4}-\d{2}_participation_survey\.pdf$', f)
    ])

    for fname in annual_files:
        year_label = fname.split('_')[0]  # e.g. "2009-10"
        ann_data = process_annual(fname, year_label)
        all_results.extend(ann_data)

    # Build DataFrame
    df = pd.DataFrame(all_results, columns=['year', 'state', 'basketball',
                                             'cross_country', 'soccer', 'track_field'])

    # Replace zeros with NaN — state-level participation of exactly 0 is always an OCR artifact
    sport_cols = ['basketball', 'cross_country', 'soccer', 'track_field']
    for col in sport_cols:
        df[col] = df[col].replace(0, pd.NA)

    out_path = os.path.join(os.path.dirname(script_dir), 'master_scraped.csv')
    df.to_csv(out_path, index=False)
    print(f"\nSaved {len(df)} rows to {out_path}")
    print(df.head(10).to_string(index=False))


if __name__ == '__main__':
    main()
