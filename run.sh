#!/usr/bin/env bash
python3 - "$@" << 'PYEOF'
import csv
import json
import os
import subprocess
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
COMPANY_LIST_PATH = os.path.join(BASE_DIR, "companylist.csv")
PROGRESS_PATH = os.path.join(BASE_DIR, "progress.json")
RESULTS_DIR = os.path.join(BASE_DIR, "results")
DOWNLOAD_SCRIPT = os.path.join(RESULTS_DIR, "download_reports.sh")
LAST_RESULT = os.path.join(RESULTS_DIR, "last-result.json")
URLS_TEMP = os.path.join(RESULTS_DIR, "urls_temp.sh")
RESULT_LOG = os.path.join(RESULTS_DIR, "result-log.json")
DONE_SCRIPT = os.path.join(BASE_DIR, "done.sh")
CLEAR_SCRIPT = os.path.join(BASE_DIR, "clear.sh")

# Check for --fresh or -f flag to clear outputs before starting
if "--fresh" in sys.argv or "-f" in sys.argv:
    print("Flag --fresh detected. Resetting previous outputs...")
    if os.path.exists(CLEAR_SCRIPT):
        subprocess.run(["bash", CLEAR_SCRIPT])
    else:
        # Fallback manual reset
        if os.path.exists(PROGRESS_PATH):
            os.remove(PROGRESS_PATH)
        if os.path.exists(LAST_RESULT):
            os.remove(LAST_RESULT)

os.makedirs(RESULTS_DIR, exist_ok=True)

# Read company list
if not os.path.exists(COMPANY_LIST_PATH):
    print(f"Error: {COMPANY_LIST_PATH} not found.")
    exit(1)

with open(COMPANY_LIST_PATH, "r", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    companies = [r for r in reader if r.get("ticker", "").strip()]

if not companies:
    print("No companies found in CSV.")
    exit(0)

last_ticker_in_csv = companies[-1]["ticker"].strip()

for company in companies:
    ticker = company["ticker"].strip()
    company_name = company["company_name"].strip()
    website = company["website"].strip()

    # Re-read progress.json dynamically before processing ticker
    progress = {}
    if os.path.exists(PROGRESS_PATH):
        try:
            with open(PROGRESS_PATH, "r", encoding="utf-8") as f:
                progress = json.load(f)
        except Exception:
            progress = {}

    ticker_data = progress.get(ticker, {})
    if ticker_data.get("completed") is True or ticker_data.get("status") == "completed":
        print(f"[{ticker}] Already completed. Skipping.")
        if ticker == last_ticker_in_csv:
            print(f"[{ticker}] Last ticker reached. Stopping loop.")
            break
        continue

    print(f"[{ticker}] Processing {company_name} ({website})...")

    # Single-line prompt formatted dynamically with instructions to run done.sh upon completion
    prompt = (
        f"/agent-browser Task: find annual report PDF download URLs for {company_name} ({ticker}). "
        f"WEBSITE: {website} YEARS: 2015 to 2025 TICKER: {ticker} "
        f"URLS_TEMP: {URLS_TEMP} PROGRESS_FILE: {PROGRESS_PATH} "
        f"Using the browser tool: 1. Navigate to the website 2. Find annual reports "
        f"3. Write ONLY the new curl commands for {ticker} to {URLS_TEMP} "
        f"(a fresh file you create with your curl lines, no need to read existing files). "
        f"4. Update progress file. "
        f"5. Write your structured result to {LAST_RESULT}. "
        f"Do NOT touch download_reports.sh or any other aggregate file. "
        f"When you are done, run {DONE_SCRIPT}"
    )

    # Launch gnome-terminal running cmd --yolo prompt directly (interactive TUI)
    cmd_args = ["gnome-terminal", "--wait", "--", "cmd", "--yolo", prompt]
    subprocess.run(cmd_args)

    # After agent finishes, append urls_temp.sh -> download_reports.sh
    # and merge last-result.json -> result-log.json, then clear temp files.
    if os.path.exists(URLS_TEMP):
        with open(URLS_TEMP, "r", encoding="utf-8") as in_f:
            new_urls = in_f.read()
        with open(DOWNLOAD_SCRIPT, "a", encoding="utf-8") as out_f:
            out_f.write(f"\n# {ticker}\n{new_urls}")
        os.remove(URLS_TEMP)
        print(f"[{ticker}] Appended URLs to {DOWNLOAD_SCRIPT}")
    else:
        print(f"[{ticker}] No urls_temp.sh found, skipping append.")

    if os.path.exists(LAST_RESULT):
        try:
            with open(LAST_RESULT, "r", encoding="utf-8") as f:
                entry = json.load(f)
            log = []
            if os.path.exists(RESULT_LOG):
                try:
                    with open(RESULT_LOG, "r", encoding="utf-8") as f:
                        existing = json.load(f)
                        log = existing if isinstance(existing, list) else [existing]
                except Exception:
                    log = []
            log.append(entry)
            with open(RESULT_LOG, "w", encoding="utf-8") as f:
                json.dump(log, f, indent=2, ensure_ascii=False)
            print(f"[{ticker}] Merged result into {RESULT_LOG}")
        except Exception as e:
            print(f"[{ticker}] Failed to merge last-result.json: {e}")
    else:
        print(f"[{ticker}] No last-result.json found, skipping merge.")

    # Check if last ticker was reached
    if ticker == last_ticker_in_csv:
        print(f"[{ticker}] Processed the last ticker in companylist.csv. Stopping loop.")
        break

print("All tickers processed.")
PYEOF