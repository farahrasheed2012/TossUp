# TossUp — NSB practice app for Soha

Official DOE middle-school sample questions, parsed locally from PDFs. No network in the app.

## Quick start

### 1. Download PDFs (one-time)

```bash
cd TossUp
pip install requests beautifulsoup4
python3 download_nsb_pdfs.py
```

This discovers **250 PDFs** from the DOE page ([MS Sample Questions](https://science.osti.gov/wdts/nsb/Regional-Competitions/Resources/MS-Sample-Questions)) and saves them under `NSB_PDFs/_By_Set/`. Subject-specific files (e.g. Energy) are also mirrored into `NSB_PDFs/Physics/`.

> Note: Round PDFs contain mixed subjects; the app tags each **question** by subject during parsing.

### 2. PDFs in Xcode

The Xcode project includes `NSB_PDFs/` at the repo root as a **folder reference** (blue folder). After running the download script, rebuild — all ~250 round PDFs ship with the app automatically.

> First launch parses all PDFs into a local cache (~1–2 min). Use **Settings → Re-parse PDFs** if you add new downloads.

### 3. Build & run

- **macOS 14+** (native SwiftUI, `NavigationSplitView`, keyboard shortcuts)
- **iOS 16+** (tab bar)

```bash
xcodebuild -scheme TossUp -destination 'platform=macOS' build
xcodebuild -scheme TossUp -destination 'platform=macOS' test
```

## App tabs

| Tab | Purpose |
|-----|---------|
| **Study** | Browse/filter questions by subject |
| **Quiz** | Timed sessions — MC (W/X/Y/Z) and short answer |
| **Progress** | Accuracy, streak, weakest subject |
| **Settings** | Timer presets (5s MC / 20s SA), subjects, reset |

## Mac shortcuts

- **Space** — submit answer / continue
- **← →** — next question after feedback
- **⌘N** — new quiz session (menu)

## Parser cache

First launch parses bundled PDFs into `~/Library/Application Support/TossUp/questions_cache.json`. Re-parses only when PDF fingerprints change. Parse errors append to `parse_errors.log` in the same folder.

## Project layout

```
TossUp/
  download_nsb_pdfs.py      # Phase 1 — PDF downloader
  NSB_PDFs/                 # Downloaded PDFs (not all committed)
  TossUp/
    Models/NSBQuestion.swift
    Services/PDFParser.swift
    ViewModels/QuizViewModel.swift
    Views/…
  TossUpTests/ParserTests.swift
```

## Requirements

- Xcode 15+
- Python 3.9+ (download script only)
- SwiftData (macOS 14+ / iOS 16+)
