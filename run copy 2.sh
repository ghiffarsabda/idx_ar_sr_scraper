#!/usr/bin/env bash
python3 - << 'PYEOF'
import csv
import json
import os
import subprocess

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
COMPANY_LIST_PATH = os.path.join(BASE_DIR, "companylist.csv")
PROGRESS_PATH = os.path.join(BASE_DIR, "progress.json")
RESULTS_DIR = os.path.join(BASE_DIR, "results")
DOWNLOAD_SCRIPT = os.path.join(RESULTS_DIR, "download_reports.sh")
LAST_RESULT = os.path.join(RESULTS_DIR, "last-result.json")

os.makedirs(RESULTS_DIR, exist_ok=True)

# Load progress if present
progress = {}
if os.path.exists(PROGRESS_PATH):
    try:
        with open(PROGRESS_PATH, "r", encoding="utf-8") as f:
            progress = json.load(f)
    except Exception:
        progress = {}

# Read company list
if not os.path.exists(COMPANY_LIST_PATH):
    print(f"Error: {COMPANY_LIST_PATH} not found.")
    exit(1)

with open(COMPANY_LIST_PATH, "r", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    companies = list(reader)

for company in companies:
    ticker = company["ticker"].strip()
    company_name = company["company_name"].strip()
    website = company["website"].strip()

    if progress.get(ticker, {}).get("status") == "completed":
        print(f"[{ticker}] Already completed. Skipping.")
        continue

    print(f"[{ticker}] Processing {company_name} ({website})...")

    # Single-line prompt formatted dynamically
    prompt = (
        f"/agent-browser Task: find annual report PDF download URLs for {company_name} ({ticker}). "
        f"WEBSITE: {website} YEARS: 2015 to 2025 TICKER: {ticker} "
        f"DOWNLOAD_SCRIPT: {DOWNLOAD_SCRIPT} PROGRESS_FILE: {PROGRESS_PATH} "
        f"Using the browser tool: 1. Navigate to the website 2. Find annual reports "
        f"3. Append curl commands to download script 4. Update progress "
        f"RESULT: write to {LAST_RESULT}"
    )

    # Launch gnome-terminal running cmd --yolo prompt directly (interactive TUI)
    cmd_args = ["gnome-terminal", "--wait", "--", "cmd", "--yolo", prompt]
    subprocess.run(cmd_args)

print("All tickers processed.")
PYEOF