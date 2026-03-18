import requests
from pathlib import Path

OUTPUT_DIR = Path("../Data/nfhs_surveys")
OUTPUT_DIR.mkdir(exist_ok=True)

# Known confirmed URLs from search results
KNOWN_URLS = {
    "2009-10": "https://assets.nfhs.org/umbraco/media/1020197/2009-10_hs_participation_survey.pdf",
    "2010-11": "https://assets.nfhs.org/umbraco/media/1020198/2010-11_hs_participation_survey.pdf",
    "2011-12": "https://assets.nfhs.org/umbraco/media/1020199/2011-12_hs_participation_survey.pdf",
    "2012-13": "https://assets.nfhs.org/umbraco/media/1020201/2012-13_hs_participation_survey.pdf",
    "2013-14": "https://assets.nfhs.org/umbraco/media/1020200/2013-14_hs_participation_survey.pdf",
    "2014-15": "https://assets.nfhs.org/umbraco/media/1020202/2014-15_hs_participation_survey.pdf",
    "2015-16": "https://assets.nfhs.org/umbraco/media/1020203/2015-16_hs_participation_survey.pdf",
    "2016-17": "https://assets.nfhs.org/umbraco/media/1020204/2016-17_hs_participation_survey.pdf",
    "2017-18": "https://assets.nfhs.org/umbraco/media/1020205/2017-18_hs_participation_survey.pdf",
    "2018-19": "https://assets.nfhs.org/umbraco/media/1020412/2018-19_participation_survey.pdf",
}

def download(url: str, dest: Path) -> bool:
    if dest.exists():
        print(f"  already exists: {dest.name}")
        return True
    try:
        r = requests.get(url, timeout=30, headers={"User-Agent": "Mozilla/5.0"})
        if r.status_code == 200 and r.headers.get("Content-Type", "").startswith("application/pdf"):
            dest.write_bytes(r.content)
            print(f"  ✓ saved {dest.name}  ({len(r.content)//1024} KB)")
            return True
        else:
            print(f"  ✗ {r.status_code} — {url}")
            return False
    except Exception as e:
        print(f"  ✗ error — {e}")
        return False

# --- Download confirmed URLs ---
print("=== Known URLs ===")
for label, url in sorted(KNOWN_URLS.items()):
    dest = OUTPUT_DIR / f"{label}_participation_survey.pdf"
    print(f"{label}:")
    download(url, dest)

