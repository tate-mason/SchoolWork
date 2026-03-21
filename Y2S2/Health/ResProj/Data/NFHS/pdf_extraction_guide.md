# Extracting Data from PDFs in Python
### A Practical Guide — From Text PDFs to Scanned Images

This guide walks through the techniques used to extract structured data from NFHS high school participation survey PDFs. The surveys came in two forms: modern text-based PDFs (2009–2019) and a 500-page fully scanned historical PDF (1969–2009). The challenge escalated from simple text parsing to full OCR with coordinate-based column detection.

---

## Part 1 — Foundations

### 1.1 File Paths with `pathlib`

Always use `pathlib.Path` instead of raw strings for file paths. It handles OS differences automatically and provides useful methods.

```python
from pathlib import Path

# Create a path object
survey_dir = Path("nfhs_surveys")

# Glob for files matching a pattern
pdfs = sorted(survey_dir.glob("*.pdf"))

# Filter by name pattern
import re
pdfs = [p for p in pdfs if re.match(r"^\d{4}-\d{2}_", p.name)]

# Extract parts of a filename
path = Path("nfhs_surveys/2009-10_participation_survey.pdf")
print(path.stem)    # "2009-10_participation_survey"
print(path.suffix)  # ".pdf"
print(path.name)    # "2009-10_participation_survey.pdf"

# Get a piece of the stem
survey_year = path.stem.split("_")[0]   # "2009-10"

# Create output directory
out_dir = Path("nfhs_processed")
out_dir.mkdir(exist_ok=True)   # won't crash if it already exists
```

### 1.2 Regex Basics

Regex (regular expressions) lets you search for patterns inside strings. Python's `re` module is the standard library.

```python
import re

# Match a year range like "2009-10"
year_pat = re.compile(r"^\d{4}-\d{2}$")
print(year_pat.match("2009-10"))   # Match object (truthy)
print(year_pat.match("football"))  # None (falsy)

# Find all year tokens in a line of text
line = "In 2001-02, girls participation grew from 2000-01 levels."
years = re.findall(r"\b\d{4}-\d{2}\b", line)
print(years)   # ['2001-02', '2000-01']

# Find numbers with commas (like "1,234,567")
nums = re.findall(r"[\d,]+", "Schools: 1,234  Participants: 45,678")
print(nums)   # ['1,234', '45,678']

# Strip non-digit characters from a string
dirty = "1,2O4"    # OCR sometimes renders 0 as O
clean = re.sub(r"[^\d]", "", dirty.replace("O", "0"))
print(clean)   # "1204"

# Case-insensitive flag
pat = re.compile(r"girls participation", re.IGNORECASE)
```

**Key regex syntax:**
| Pattern | Meaning |
|---------|---------|
| `\d` | Any digit (0–9) |
| `\w` | Any word character (letter, digit, underscore) |
| `\b` | Word boundary |
| `+` | One or more |
| `*` | Zero or more |
| `{4}` | Exactly 4 |
| `^` | Start of string |
| `$` | End of string |
| `[abc]` | Any of a, b, c |
| `[^\d]` | Any character that is NOT a digit |

### 1.3 Cleaning Numeric Strings

Survey PDFs often contain numbers formatted with commas. A simple cleaning function:

```python
def clean_num(s):
    """'1,234' -> 1234,  '' or non-numeric -> None"""
    s = s.replace(",", "").strip()
    return int(s) if s.isdigit() else None

print(clean_num("1,234"))   # 1234
print(clean_num(""))        # None
print(clean_num("N/A"))     # None
```

For OCR output with additional noise:

```python
def clean_num_ocr(text):
    """Handle OCR artifacts: O->0, remove non-digits, reject implausible lengths."""
    if not isinstance(text, str):
        return None
    t = (text.replace(",", "")
             .replace(".", "")
             .replace("O", "0")   # capital O misread as zero
             .replace("o", "0")
             .strip())
    t = re.sub(r"[^\d]", "", t)
    return int(t) if t and 2 <= len(t) <= 7 else None
```

---

## Part 2 — Reading Text-Based PDFs

### 2.1 `pdfplumber` Overview

`pdfplumber` extracts text and word positions from PDFs whose content is stored as actual text (not images).

```bash
pip install pdfplumber
```

```python
import pdfplumber

with pdfplumber.open("2009-10_participation_survey.pdf") as pdf:
    print(f"Pages: {len(pdf.pages)}")

    page = pdf.pages[0]
    text = page.extract_text()   # full text as one string
    print(text[:500])

    words = page.extract_words()   # list of word dicts
    print(words[0])
    # {'text': 'Boys', 'x0': 72.0, 'top': 120.5, 'x1': 92.4, 'bottom': 131.2}
```

Each word dict has:
- `text` — the word string
- `x0` — left edge (pixels from left margin)
- `top` — top edge (pixels from top of page)
- `x1`, `bottom` — right and bottom edges

### 2.2 Extracting a Table Row by Row

The key insight for structured table extraction: **words on the same row have the same `top` value** (within a small tolerance). Group words by their y-position:

```python
def group_words_by_row(words, tolerance=2):
    """Group words into rows by rounding their y-position."""
    rows = {}
    for w in words:
        y = round(w["top"] / tolerance) * tolerance   # bin to nearest 2px
        rows.setdefault(y, []).append(w)
    return dict(sorted(rows.items()))   # sorted top-to-bottom

rows = group_words_by_row(page.extract_words())

for y, row_words in rows.items():
    row_words.sort(key=lambda w: w["x0"])   # sort left to right
    texts = [w["text"] for w in row_words]
    print(y, texts)
```

### 2.3 Finding a Header Row

Before extracting data, locate the column header row. Headers contain keywords like "State" and "Schools":

```python
def find_header_row(rows):
    """Return the y-key of the header row containing 'State' and 'Schools'."""
    for y, words in rows.items():
        text_set = {w["text"] for w in words}
        # Handle both 'State' (older PDFs) and 'STATE' (newer PDFs)
        has_state  = "State"  in text_set or "STATE"  in text_set
        has_schools = "Schools" in text_set
        if has_state and has_schools:
            return y
    return None
```

Once the header y is found, all rows below it are data rows.

### 2.4 Column Detection from Header Positions

In tables with multiple sport columns (e.g., four sports side-by-side on one page), the header row labels where each column lives. Read the x-positions of the header words to define column boundaries:

```python
def get_column_positions(rows, header_y):
    """
    Extract x-positions of 'Schools' and 'Particip.' labels in the header row.
    Returns (schools_xs, particip_xs) — one x per sport column.
    """
    header_words = rows[header_y]
    schools_xs  = [w["x0"] for w in header_words if w["text"] == "Schools"]
    particip_xs = [w["x0"] for w in header_words
                   if w["text"] in ("Particip.", "Participants")]
    return schools_xs, particip_xs

# Build extraction windows: data lands slightly to the right of the header label
def build_col_defs(schools_xs, particip_xs, sport_names):
    col_defs = []
    for i, sx in enumerate(schools_xs):
        px = particip_xs[i] if i < len(particip_xs) else sx + 60
        col_defs.append({
            "sport":  sport_names[i],
            "sl": sx - 5,   "sr": sx + 30,    # schools window
            "pl": px - 5,   "pr": px + 60,    # participants window
        })
    return col_defs
```

### 2.5 Extracting State Data Rows

With column definitions in hand, scan each data row and extract values:

```python
US_STATES = {
    "Alabama", "Alaska", "Arizona", ..., "Wyoming"
}

def extract_state_rows(rows, header_y, col_defs):
    results = []
    current_state = None

    for y, words in rows.items():
        if y <= header_y:
            continue

        words.sort(key=lambda w: w["x0"])
        texts_x = [(w["text"], w["x0"]) for w in words]

        # Detect state name in the left column (x < 130px)
        left_words = [t for t, x in texts_x if x < 130]
        candidate = " ".join(left_words)
        if candidate in US_STATES:
            current_state = candidate

        if current_state is None:
            continue

        # Extract values for each sport column
        for cd in col_defs:
            school_vals = [t for t, x in texts_x if cd["sl"] <= x <= cd["sr"]]
            parts_vals  = [t for t, x in texts_x if cd["pl"] <= x <= cd["pr"]]

            schools      = clean_num(school_vals[0]) if school_vals else None
            participants = clean_num(parts_vals[0])  if parts_vals  else None

            if schools is not None or participants is not None:
                results.append({
                    "state":        current_state,
                    "sport":        cd["sport"],
                    "schools":      schools,
                    "participants": participants,
                })

    return results
```

---

## Part 3 — Working with pandas

### 3.1 Creating and Saving DataFrames

```python
import pandas as pd

rows = [
    {"state": "Alabama", "sport": "Soccer", "schools": 166, "participants": 3229},
    {"state": "Alaska",  "sport": "Soccer", "schools": 32,  "participants": 920},
]

df = pd.DataFrame(rows)
print(df)
#      state   sport  schools  participants
# 0  Alabama  Soccer      166          3229
# 1   Alaska  Soccer       32           920

# Add a column at position 0
df.insert(0, "survey_year", "2008-09")

# Remove duplicates
df = df.drop_duplicates(subset=["state", "sport"])

# Save to CSV
df.to_csv("nfhs_processed/2008-09_state_by_sport.csv", index=False)
```

### 3.2 Concatenating DataFrames Across Files

When processing multiple PDFs, collect each result and concatenate at the end:

```python
all_frames = []

for pdf_path in pdf_paths:
    df = process_one_pdf(pdf_path)
    all_frames.append(df)

# Combine into a single DataFrame
combined = pd.concat(all_frames, ignore_index=True)
combined.to_csv("girls_by_state_all_surveys.csv", index=False)
```

### 3.3 Filtering and Selecting

```python
# Select only girls rows
girls = combined[combined["gender"] == "Girls"]

# Select specific columns
girls = combined[["survey_year", "gender", "state", "sport", "schools", "participants"]]

# Filter by sport and year
soccer_2009 = combined[
    (combined["sport"] == "Soccer") &
    (combined["survey_year"] == "2008-09")
]
```

---

## Part 4 — Handling PDF Layout Variants

Real-world PDFs rarely have a single consistent layout. The NFHS surveys changed their format over the years. The solution: detect the layout dynamically from the number of pages.

### 4.1 Dynamic Page Layout Detection

```python
def get_page_config(n_pages):
    """
    Return (totals_idx, boys_start, girls_start) based on PDF page count.

    Layout variants observed across NFHS survey PDFs:
      16 pages  (2009-10 – 2011-12): totals=1, boys=3,  girls=9
      19 pages  (2012-13 – 2016-17): totals=2, boys=4,  girls=11
      22 pages  (2017-18):           totals=4, boys=6,  girls=13
      23 pages  (2018-19):           totals=4, boys=6,  girls=14
    """
    if n_pages <= 16:
        return 1, 3, 9
    elif n_pages <= 20:
        return 2, 4, 11
    elif n_pages == 22:
        return 4, 6, 13
    else:
        return 4, 6, 14

with pdfplumber.open(pdf_path) as pdf:
    n_pages = len(pdf.pages)
    totals_idx, boys_start, girls_start = get_page_config(n_pages)
```

### 4.2 Guarding Against Empty or Missing Data

Always check before accessing `.iloc[0]` or column names that may not exist:

```python
raw = pd.DataFrame(totals_rows)

if raw.empty or "year" not in raw.columns:
    print(f"WARNING: no totals found on page {totals_idx}")
    df_totals = pd.DataFrame(columns=["survey_year", "year", "boys", "girls", "total"])
else:
    df_totals = raw.drop_duplicates("year").sort_values("year")

# Guard before building a DataFrame with specific columns
if all_rows:
    df_state = pd.DataFrame(all_rows)[["gender", "state", "sport", "schools", "participants"]]
else:
    df_state = pd.DataFrame(columns=["gender", "state", "sport", "schools", "participants"])
```

---

## Part 5 — OCR for Scanned PDFs

When a PDF contains images rather than text (fully scanned), `pdfplumber` returns nothing. You need **OCR** (Optical Character Recognition).

### 5.1 Required Libraries

```bash
brew install tesseract        # OCR engine (macOS)
pip install pytesseract pdf2image
```

- **`pdf2image`** — converts PDF pages to PIL Image objects
- **`pytesseract`** — Python wrapper around Tesseract OCR

### 5.2 Converting a PDF Page to an Image

```python
from pdf2image import convert_from_path

# Convert page 381 (1-indexed) at 200 DPI
images = convert_from_path("historical.pdf",
                            first_page=381, last_page=381,
                            dpi=200)
img = images[0]   # PIL Image object
```

**DPI trade-off:**
- **Low DPI (80)** — fast, good enough to read text for classification
- **High DPI (200)** — slower, needed for accurate coordinate extraction

### 5.3 Getting Text from an Image

```python
import pytesseract

# Simple string output
text = pytesseract.image_to_string(img)
print(text)
```

### 5.4 Word-Level Bounding Boxes (TSV mode)

For coordinate-based extraction (equivalent to `pdfplumber`'s word dicts), use TSV output:

```python
import pytesseract
import pandas as pd

tsv = pytesseract.image_to_data(img, output_type=pytesseract.Output.DATAFRAME)

# Filter out low-confidence and empty words
tsv = tsv[(tsv["conf"] >= 25) & (tsv["text"].str.strip() != "")]

# Each row is one word with position info:
# left, top, width, height — pixel coordinates
# conf — OCR confidence (0–100)
# text — the recognized string

# Convert to a simple list of (x, y, text) tuples
words = [(int(r["left"]), int(r["top"]), str(r["text"]))
         for _, r in tsv.iterrows()]
```

**Column meanings:**
| Column | Meaning |
|--------|---------|
| `left` | x-position of word's left edge |
| `top` | y-position of word's top edge |
| `conf` | OCR confidence score (0–100; -1 = non-word) |
| `text` | Recognized text |

---

## Part 6 — Coordinate-Based Extraction from OCR Output

OCR gives you word positions in pixels. The same logic used for `pdfplumber` applies, but with a key complication: **OCR y-coordinates have more noise** than a text PDF.

### 6.1 Y-Binning for Row Grouping

Two words on the same printed line may have slightly different `top` values due to OCR imprecision. Bin y-values into buckets:

```python
def group_by_y(word_list, bin_size=8):
    """Group (x, y, text) tuples into rows using y-bins of `bin_size` pixels."""
    y_bins = {}
    for x, y, t in word_list:
        yb = round(y / bin_size) * bin_size
        y_bins.setdefault(yb, []).append((x, t))
    return y_bins
```

**Why binning works:**
Words at y=203 and y=205 land in different bins with 2px precision, but both land in bin `200` with 8px precision (`round(203/8)*8 = 200`, `round(205/8)*8 = 208`... actually `round(205/8)*8 = 208`).

> **Python rounding note:** Python uses *banker's rounding* — `round(0.5) = 0`, `round(1.5) = 2`. So `round(204/8)*8 = round(25.5)*8 = 26*8 = 208` in some cases. When this matters, consider using `int(y / bin_size) * bin_size` (floor) for consistent behavior.

### 6.2 The Critical Bug: Headers Across Multiple Y-Bins

In scanned PDFs, a row of column headers like:

```
State  Schools  Particip.  Schools  Particip.  Schools  Particip.  Schools  Particip.
```

may be OCR'd with each word at a slightly different y:
- "State" at y=145 → bin 144
- "Schools" (col 1) at y=147 → bin 144
- "Schools" (col 2) at y=148 → bin 144
- "Schools" (col 3) at y=150 → **bin 152** ← different bin!
- "Schools" (col 4) at y=152 → bin 152

If you only look at the bin containing "State" (bin 144), you find only 2 of 4 "Schools" labels — and build only 2 of 4 column definitions. **The solution: search a wider ±35px window around the header bin.**

```python
def detect_columns(word_list, sport_names):
    y_bins = {}
    for x, y, t in word_list:
        yb = round(y / 8) * 8
        y_bins.setdefault(yb, []).append((x, t))

    # Pass 1: find the bin containing both 'state' and 'schools'
    # Use ±16px window — 'State' and first 'Schools' may not be in the exact same bin
    def _is_schools(t):
        return re.sub(r"[^\w.]", "", t.lower()) in ("schools", "sch")
    def _is_state(t):
        return re.sub(r"[^\w]", "", t.lower()) in ("state", "states")

    header_y = None
    for yb in sorted(y_bins.keys()):
        if not any(_is_state(t) for _, t in y_bins[yb]):
            continue
        # Check if 'schools' appears anywhere within ±16px
        if any(_is_schools(t)
               for yb2, ws2 in y_bins.items() if abs(yb2 - yb) <= 16
               for _, t in ws2):
            header_y = yb
            break

    if header_y is None:
        return [], None

    # Pass 2: collect ALL 'Schools' and 'Particip.' x-positions within ±35px
    schools_xs = []
    particip_xs = []
    for yb, ws in y_bins.items():
        if abs(yb - header_y) > 35:
            continue
        for x, t in ws:
            tl = re.sub(r"[^\w.]", "", t.lower())   # strip OCR artifacts
            if tl in ("schools", "sch"):
                schools_xs.append(x)
            elif "particip" in tl:
                particip_xs.append(x)

    schools_xs = sorted(set(schools_xs))
    particip_xs = sorted(set(particip_xs))
    ...
```

> **Why `re.sub(r"[^\w.]", "", t.lower())`?**
> OCR sometimes adds stray characters before a word — e.g., `'Schools` (with a leading curly quote or apostrophe). Stripping all non-alphanumeric, non-dot characters makes matching robust against these artifacts.

### 6.3 Smart Column Pairing

Another OCR problem: the "Particip." header for column 1 may not be detected (low OCR confidence), leaving 4 "Schools" positions but only 3 "Particip." positions. Pairing by index (`schools_xs[0]` with `particip_xs[0]`) gives the wrong result.

**Solution:** pair each `schools_x` with the nearest `particip_x` that falls *within the same column* — i.e., between this `schools_x` and the next one.

```python
n_cols = min(len(schools_xs), len(sport_names))
schools_xs = schools_xs[:n_cols]

def find_particip(i, sx):
    """Find the particip_x that belongs to column i."""
    next_sx = schools_xs[i + 1] if i + 1 < n_cols else sx + 500
    within = [px for px in particip_xs if sx < px < next_sx]
    if within:
        return min(within, key=lambda px: px - sx)
    return sx + 130   # fallback: estimate ~130px to the right

col_defs = []
for i, sx in enumerate(schools_xs):
    px = find_particip(i, sx)
    sport = sport_names[i]
    col_defs.append({
        "sport": sport,
        "sl": sx - 15,  "sr": sx + 100,   # wider: OCR header ~60px left of data
        "pl": px - 15,  "pr": px + 95,
    })
```

---

## Part 7 — Page Classification

When processing a large PDF, you need to know what's on each page before spending time on high-DPI OCR. Use a fast low-DPI pass first.

### 7.1 Two-Pass Strategy

```python
# Pass 1: cheap low-DPI scan to identify page types
low_dpi_imgs = convert_from_path(pdf_path, first_page=start, last_page=end, dpi=80)

for offset, img in enumerate(low_dpi_imgs):
    text = pytesseract.image_to_string(img)
    page_type = classify(text)
    ...

# Pass 2: expensive high-DPI OCR only for relevant pages
if page_type == "girls_state_table":
    hi_img = convert_from_path(pdf_path,
                               first_page=start + offset,
                               last_page=start + offset,
                               dpi=200)[0]
    words = get_word_positions(hi_img)
    data  = extract_state_rows(words, col_defs, header_y)
```

### 7.2 Classifying Pages by Content

```python
import re

YEAR_PAT  = re.compile(r"\b(\d{4}-\d{2})\b")
PER_SPORT = re.compile(r"\bSPORT\b.{0,40}\bSTATE\b", re.IGNORECASE | re.DOTALL)

def classify(text):
    """Return a set of tags describing what this page contains."""
    upper = text.upper()
    tags  = set()

    if "GIRLS PARTICIPATION" in upper:
        tags.add("girls")
    if "BOYS PARTICIPATION" in upper:
        tags.add("boys")

    has_schools  = "SCHOOLS"  in upper
    has_particip = "PARTICIP" in upper
    year_toks    = YEAR_PAT.findall(text)

    if has_schools and has_particip:
        head = "\n".join(l.strip() for l in text.split("\n") if l.strip())[:200]
        tags.add("per_sport" if PER_SPORT.search(head) else "state_table")

    if len(year_toks) >= 8 and ("SUMMARY" in upper or not has_schools):
        tags.add("totals")

    return tags

# Usage
tags = classify(pytesseract.image_to_string(img))
if "girls" in tags and "state_table" in tags:
    # This is a girls state-by-state data page
    ...
```

---

## Part 8 — Fuzzy String Matching

OCR output is noisy. State names may appear as "Calitornia", "Alobama", or "N. Carolina". Use `difflib` for fuzzy matching:

```python
from difflib import get_close_matches

US_STATES = {
    "Alabama", "Alaska", ..., "Wyoming"
}

def match_state(raw_text):
    """Match an OCR-detected string to a known US state name."""
    raw = raw_text.strip()
    if not raw or len(raw) < 3:
        return None

    # Exact match first (fastest)
    if raw in US_STATES:
        return raw

    # Try title-casing (OCR may return all-caps)
    titled = raw.title()
    if titled in US_STATES:
        return titled

    # Fuzzy match with 72% similarity threshold
    hits = get_close_matches(titled, US_STATES, n=1, cutoff=0.72)
    return hits[0] if hits else None

# Examples
print(match_state("ALABAMA"))     # "Alabama"
print(match_state("Calitornia"))  # "California"
print(match_state("N. Carolina")) # "North Carolina" (hopefully)
print(match_state("xyz"))         # None
```

**Choosing the cutoff:** 0.72 catches common OCR errors (1–2 wrong characters in a 8+ character name) without matching completely different words.

---

## Part 9 — Putting It All Together

### 9.1 Full Processing Pipeline

```python
def process_section(survey_year, pdf_path, start_page, end_page):
    """
    Process one year's section of the historical scanned PDF.
    Returns (df_totals, df_state_girls).
    """
    era          = "5page" if int(survey_year[:4]) >= 2006 else "4page"
    sports_table = GIRLS_SPORTS[era]   # list of sport-name lists per page

    # ── Pass 1: low-DPI scan to find girls page offsets ──────────────────────
    imgs = convert_from_path(pdf_path, first_page=start_page,
                             last_page=end_page, dpi=80)
    girls_start = None
    for offset, img in enumerate(imgs):
        tags = classify(pytesseract.image_to_string(img))
        if "girls" in tags and "state_table" in tags:
            girls_start = offset
            break

    if girls_start is None:
        return empty_frames()

    girl_offsets = list(range(girls_start, girls_start + len(sports_table)))

    # ── Pass 2: high-DPI extraction for each girls page ───────────────────────
    all_rows     = []
    girls_pg_idx = 0

    for offset in girl_offsets:
        pg_num = start_page + offset
        hi_img = convert_from_path(pdf_path,
                                   first_page=pg_num, last_page=pg_num,
                                   dpi=200)[0]
        words  = ocr_words(hi_img)   # returns [(x, y, text), ...]

        expected_sports = sports_table[girls_pg_idx]
        col_defs, header_y = detect_columns(words, expected_sports)

        if not col_defs:
            print(f"  pg{pg_num}: no header detected → skip")
            continue

        rows = extract_state_rows(words, col_defs, header_y)
        all_rows.extend(rows)
        girls_pg_idx += 1

    # ── Build DataFrame ───────────────────────────────────────────────────────
    if all_rows:
        df = pd.DataFrame(all_rows)
        df = df.drop_duplicates(subset=["state", "sport"])
        df.insert(0, "gender", "Girls")
        df.insert(0, "survey_year", survey_year)
        return df
    else:
        return empty_frame()
```

### 9.2 Batch Processing and Consolidation

```python
def batch_main():
    out_dir = Path("nfhs_processed")
    out_dir.mkdir(exist_ok=True)

    all_state = []

    for survey_year, start_pg, next_pg in YEAR_SECTIONS:
        df_state = process_section(survey_year, PDF_PATH, start_pg, next_pg - 1)
        df_state.to_csv(out_dir / f"{survey_year}_state_by_sport.csv", index=False)
        all_state.append(df_state)
        print(f"  {survey_year}: {len(df_state)} rows")

    # Consolidated output
    combined = pd.concat(all_state, ignore_index=True)
    combined.to_csv(out_dir / "girls_by_state_historical.csv", index=False)
    print(f"\nTotal rows: {len(combined)}")
```

---

## Summary: Decision Tree for PDF Extraction

```
Is the PDF text-based or scanned?
│
├─ Text-based → use pdfplumber
│   ├─ pdfplumber.open(path) → pdf.pages[i] → page.extract_words()
│   ├─ Group words by y-position (round to 2px)
│   ├─ Find header row (contains "State" + "Schools")
│   ├─ Read column x-positions from header
│   └─ Scan data rows, extract values by x-window
│
└─ Scanned (image-only) → use pytesseract + pdf2image
    ├─ Low-DPI pass (80 dpi) to classify pages cheaply
    ├─ High-DPI pass (200 dpi) for data extraction
    ├─ image_to_data() for word bounding boxes
    ├─ Group by y-bin (8px) — wider tolerance needed
    ├─ Find header with ±16px State+Schools window
    ├─ Collect all column positions in ±35px band
    ├─ Smart-pair Schools↔Particip. xs by column proximity
    └─ Fuzzy-match state names with difflib
```

## Common Pitfalls

| Problem | Symptom | Fix |
|---------|---------|-----|
| Y-bin too tight | Headers split across bins, columns missed | Widen to 8px; use ±16px window for Pass 1 |
| OCR character artifacts | `'Schools` not matched | Strip with `re.sub(r"[^\w.]", "", t.lower())` |
| Index-based column pairing | Wrong sport gets wrong data | Pair by proximity within column width |
| Header too narrow | Data at x=589 missed by window ending at x=581 | Use `sr = sx + 100` (header is left of data) |
| Wrong page accessed | Empty or wrong data | Use dynamic page detection from page count |
| Low OCR confidence | State names dropped | Tune `conf` threshold; use fuzzy matching |
| 0 being OCR'd as O | Numbers parse as `None` | Replace `"O"` → `"0"` before `int()` |
