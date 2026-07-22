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
TEMP_DOWNLOAD_SCRIPT = os.path.join(RESULTS_DIR, "urls_temp.sh")
LAST_RESULT = os.path.join(RESULTS_DIR, "last-result.json")
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

    # Clear urls_temp.sh prior to running current ticker
    if os.path.exists(TEMP_DOWNLOAD_SCRIPT):
        os.remove(TEMP_DOWNLOAD_SCRIPT)

    # Standardized prompt formatted dynamically
    prompt = (
        f"/agent-browser Task: find annual report PDF download URLs for {company_name} ({ticker}). "
        f"WEBSITE: {website} YEARS: 2015 to 2025 TICKER: {ticker} "
        f"DOWNLOAD_SCRIPT: {TEMP_DOWNLOAD_SCRIPT} PROGRESS_FILE: {PROGRESS_PATH} "
        f"Using the browser tool: 1. Navigate to website 2. Find annual reports "
        f"3. Append curl commands (curl -sL -o 'results/pdfs/{ticker}_AR_YYYY.pdf' 'URL') to {TEMP_DOWNLOAD_SCRIPT} "
        f"4. Update {PROGRESS_PATH} "
        f"RESULT: Write standardized JSON to {LAST_RESULT} with schema: "
        f'{{"ticker": "{ticker}", "company_name": "{company_name}", "website": "{website}", "status": "completed", '
        f'"reports_found": [{{"year": 2024, "report_type": "Annual Report", "title": "...", "url": "...", "filename": "{ticker}_AR_2024.pdf"}}], '
        f'"years_found": [2015, 2016], "years_missing": [], "curl_commands": ["curl -sL -o \'results/pdfs/{ticker}_AR_2024.pdf\' \'URL\'"]}} '
        f"When you are done, run {DONE_SCRIPT}"
    )

    # Launch gnome-terminal running cmd --yolo prompt directly (interactive TUI)
    cmd_args = ["gnome-terminal", "--wait", "--", "cmd", "--yolo", prompt]
    subprocess.run(cmd_args)

    # 1. Merge urls_temp.sh into main download_reports.sh
    if os.path.exists(TEMP_DOWNLOAD_SCRIPT):
        with open(TEMP_DOWNLOAD_SCRIPT, "r", encoding="utf-8") as tf:
            temp_urls = tf.read().strip()
        if temp_urls:
            with open(DOWNLOAD_SCRIPT, "a", encoding="utf-8") as df:
                df.write("\n" + temp_urls + "\n")
            print(f"[{ticker}] Appended urls_temp.sh to download_reports.sh.")
        os.remove(TEMP_DOWNLOAD_SCRIPT)

    # 2. Append last-result.json to result-log.json
    if os.path.exists(LAST_RESULT):
        try:
            with open(LAST_RESULT, "r", encoding="utf-8") as rf:
                last_res_data = json.load(rf)
        except Exception:
            last_res_data = None

        if last_res_data:
            log_list = []
            if os.path.exists(RESULT_LOG):
                try:
                    with open(RESULT_LOG, "r", encoding="utf-8") as lf:
                        log_list = json.load(lf)
                        if not isinstance(log_list, list):
                            log_list = [log_list]
                except Exception:
                    log_list = []
            log_list.append(last_res_data)
            with open(RESULT_LOG, "w", encoding="utf-8") as lf:
                json.dump(log_list, lf, indent=2)
            print(f"[{ticker}] Appended last-result.json to result-log.json.")

    # 3. Git add, commit, and push for this ticker
    print(f"[{ticker}] Running git add, commit, and push...")
    subprocess.run(["git", "add", "."], cwd=BASE_DIR, check=False)
    subprocess.run(["git", "commit", "-m", f"added {ticker}"], cwd=BASE_DIR, check=False)
    print(f"[{ticker}] Pushing to remote repository...")
    subprocess.run(["git", "push"], cwd=BASE_DIR, check=False)
    print(f"[{ticker}] Git push completed.")

    # Check if last ticker was reached
    if ticker == last_ticker_in_csv:
        print(f"[{ticker}] Processed the last ticker in companylist.csv. Stopping loop.")
        break

print("All tickers processed.")
PYEOF