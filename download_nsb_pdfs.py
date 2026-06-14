#!/usr/bin/env python3
"""Download all middle-school NSB sample question PDFs from the DOE website.

Discovers PDF links programmatically from the official MS sample questions page
(and fallbacks if URLs move). Saves rounds under NSB_PDFs/_By_Set/ and mirrors
subject-specific PDFs (e.g. Energy) into subject folders when identifiable.
"""

from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path
from urllib.parse import urljoin, urlparse

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print("Install dependencies: pip install requests beautifulsoup4", file=sys.stderr)
    sys.exit(1)

BASE_URL = "https://science.osti.gov"
CANDIDATE_PAGES = [
    "/wdts/nsb/Regional-Competitions/Resources/MS-Sample-Questions",
    "/wdts/nsb/Regional-and-National-Competitions/Resources/Middle-School-Sample-Questions",
    "/wdts/nsb/Regional-Competitions/Resources/Middle-School-Sample-Questions",
]

SUBJECT_DIRS = ("Biology", "Chemistry", "Earth_and_Space", "Math", "Physics")
USER_AGENT = "TossUp-NSB-Downloader/1.0 (+local developer tool)"


def subject_for_pdf(url: str, link_text: str) -> str | None:
    """Return a subject folder name when the PDF is clearly subject-specific."""
    blob = f"{url} {link_text}".lower()
    if "energy" in blob and "category" in blob:
        return "Physics"
    return None


def set_name_from_url(url: str) -> str:
    parts = urlparse(url).path.split("/")
    for i, part in enumerate(parts):
        if part.lower().startswith("sample-set") or part.lower().startswith("sample_set"):
            return part.replace(" ", "-")
        if part == "MS-Sample-Questions" and i + 1 < len(parts):
            return parts[i + 1].replace(" ", "-")
    return "Unknown-Set"


def discover_page_url(session: requests.Session) -> tuple[str, str]:
    for path in CANDIDATE_PAGES:
        url = urljoin(BASE_URL, path)
        try:
            resp = session.get(url, timeout=45)
        except requests.RequestException as exc:
            print(f"  fetch failed {url}: {exc}")
            continue
        if resp.status_code == 200 and "Page Not Found" not in resp.text[:2000]:
            print(f"Using index page: {url}")
            return url, resp.text
        print(f"  skip ({resp.status_code}): {url}")
    raise SystemExit("Could not find a working MS sample questions page on science.osti.gov")


def discover_pdf_links(html: str, page_url: str) -> list[dict]:
    soup = BeautifulSoup(html, "html.parser")
    seen: set[str] = set()
    links: list[dict] = []

    for anchor in soup.find_all("a", href=True):
        href = anchor["href"].strip()
        if not href.lower().endswith(".pdf"):
            continue
        abs_url = urljoin(page_url, href)
        if "/MS-Sample-Questions/" not in abs_url and "/ms-sample-questions/" not in abs_url.lower():
            continue
        if abs_url in seen:
            continue
        seen.add(abs_url)
        text = anchor.get_text(" ", strip=True)
        links.append(
            {
                "url": abs_url,
                "filename": Path(urlparse(abs_url).path).name,
                "set": set_name_from_url(abs_url),
                "link_text": text,
                "subject": subject_for_pdf(abs_url, text),
            }
        )

    # Regex fallback for PDFs embedded without standard anchors
    for match in re.finditer(r'href="(/-/media/wdts/nsb/pdf/MS-Sample-Questions/[^"]+\.pdf)"', html, re.I):
        abs_url = urljoin(BASE_URL, match.group(1))
        if abs_url in seen:
            continue
        seen.add(abs_url)
        links.append(
            {
                "url": abs_url,
                "filename": Path(urlparse(abs_url).path).name,
                "set": set_name_from_url(abs_url),
                "link_text": "",
                "subject": subject_for_pdf(abs_url, ""),
            }
        )

    links.sort(key=lambda item: (item["set"].lower(), item["filename"].lower()))
    return links


def download_pdf(session: requests.Session, url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    with session.get(url, stream=True, timeout=120) as resp:
        resp.raise_for_status()
        with dest.open("wb") as handle:
            for chunk in resp.iter_content(chunk_size=65536):
                if chunk:
                    handle.write(chunk)


def main() -> None:
    root = Path(__file__).resolve().parent
    out_dir = root / "NSB_PDFs"
    by_set = out_dir / "_By_Set"
    out_dir.mkdir(parents=True, exist_ok=True)
    by_set.mkdir(parents=True, exist_ok=True)
    for name in SUBJECT_DIRS:
        (out_dir / name).mkdir(parents=True, exist_ok=True)

    session = requests.Session()
    session.headers.update({"User-Agent": USER_AGENT})

    page_url, html = discover_page_url(session)
    pdfs = discover_pdf_links(html, page_url)
    print(f"Found {len(pdfs)} PDF link(s)")

    downloaded = 0
    skipped = 0
    failures: list[str] = []

    for item in pdfs:
        set_dir = by_set / item["set"]
        primary_dest = set_dir / item["filename"]
        targets = [primary_dest]
        if item["subject"]:
            targets.append(out_dir / item["subject"] / item["filename"])

        if all(t.exists() and t.stat().st_size > 0 for t in targets):
            skipped += 1
            continue

        try:
            download_pdf(session, item["url"], primary_dest)
            downloaded += 1
            print(f"  ✓ {item['set']}/{item['filename']}")
            for extra in targets[1:]:
                extra.write_bytes(primary_dest.read_bytes())
            time.sleep(0.15)
        except requests.RequestException as exc:
            failures.append(f"{item['filename']}: {exc}")
            print(f"  ✗ {item['filename']} — {exc}", file=sys.stderr)

    manifest = {
        "source_page": page_url,
        "total_found": len(pdfs),
        "downloaded": downloaded,
        "skipped_existing": skipped,
        "failures": failures,
        "pdfs": pdfs,
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    print()
    print(f"Total found:     {len(pdfs)}")
    print(f"Downloaded:      {downloaded}")
    print(f"Skipped (exist): {skipped}")
    print(f"Failures:        {len(failures)}")
    if failures:
        for line in failures:
            print(f"  - {line}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
