#!/usr/bin/env bash
python3 -u - "$@" << 'PYEOF'
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
ASKPASS_PATH = os.path.join(BASE_DIR, ".git_askpass.sh")

# Ensure SSH askpass script exists to autofill SSH key passphrase
if not os.path.exists(ASKPASS_PATH):
    with open(ASKPASS_PATH, "w", encoding="utf-8") as f:
        f.write('#!/bin/sh\necho "cangcut"\n')
    os.chmod(ASKPASS_PATH, 0o755)

# Parse command line flags
is_fresh = "--fresh" in sys.argv or "-f" in sys.argv
is_strict = "--strict" in sys.argv
is_flex = "--flex" in sys.argv

# Check for --fresh or -f flag to clear outputs before starting
if is_fresh:
    print("Flag --fresh detected. Resetting previous outputs...")
    if os.path.exists(CLEAR_SCRIPT):
        subprocess.run(["bash", CLEAR_SCRIPT])
    else:
        # Fallback manual reset
        if os.path.exists(PROGRESS_PATH):
            os.remove(PROGRESS_PATH)
        if os.path.exists(LAST_RESULT):
            os.remove(LAST_RESULT)
        if os.path.exists(RESULT_LOG):
            os.remove(RESULT_LOG)

if is_strict:
    print("Flag --strict enabled: Restricting domain search strictly to official company website (30s timeout).")
if is_flex:
    print("Flag --flex enabled: Allowing flexible matching for report titles (e.g. Laporan Keuangan).")

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

def get_completed_tickers():
    completed = set()
    
    # 1. Check result-log.json
    if os.path.exists(RESULT_LOG):
        try:
            with open(RESULT_LOG, "r", encoding="utf-8") as f:
                log_data = json.load(f)
                if isinstance(log_data, list):
                    for entry in log_data:
                        if isinstance(entry, dict) and entry.get("ticker"):
                            st = str(entry.get("status", "")).lower()
                            if st in ("completed", "done", "success") or entry.get("completed") is True:
                                completed.add(entry["ticker"].strip())
        except Exception:
            pass

    # 2. Check progress.json
    if os.path.exists(PROGRESS_PATH):
        try:
            with open(PROGRESS_PATH, "r", encoding="utf-8") as f:
                prog_data = json.load(f)
                if isinstance(prog_data, dict):
                    if prog_data.get("ticker"):
                        st = str(prog_data.get("status", "")).lower()
                        if st in ("completed", "done", "success") or prog_data.get("completed") is True:
                            completed.add(str(prog_data["ticker"]).strip())
                    for k, v in prog_data.items():
                        if isinstance(v, dict):
                            st = str(v.get("status", "")).lower()
                            if st in ("completed", "done", "success") or v.get("completed") is True:
                                completed.add(k.strip())
                elif isinstance(prog_data, list):
                    for entry in prog_data:
                        if isinstance(entry, dict) and entry.get("ticker"):
                            st = str(entry.get("status", "")).lower()
                            if st in ("completed", "done", "success") or entry.get("completed") is True:
                                completed.add(str(entry["ticker"]).strip())
        except Exception:
            pass
            
    return completed

for company in companies:
    ticker = company["ticker"].strip()
    company_name = company["company_name"].strip()
    website = company["website"].strip()

    # Get set of already completed tickers from result-log.json and progress.json
    completed_tickers = get_completed_tickers()

    if ticker in completed_tickers:
        print(f"[{ticker}] Already completed in result-log.json / progress.json. Skipping.")
        if ticker == last_ticker_in_csv:
            print(f"[{ticker}] Last ticker reached. Stopping loop.")
            break
        continue

    print(f"[{ticker}] Processing {company_name} ({website})...", flush=True)
    sys.stdout.flush()

    # Clear urls_temp.sh prior to running current ticker
    if os.path.exists(TEMP_DOWNLOAD_SCRIPT):
        os.remove(TEMP_DOWNLOAD_SCRIPT)

    # Dynamic prompt variations based on --strict and --flex tags
    strict_instruction = (
        f"STRICT DOMAIN MODE: You MUST search ONLY on official website {website} and nowhere else (do NOT visit IDX, news, or external portals). If {website} fails to respond within 30 seconds or hangs loading, stop and mark as skipped/failed."
        if is_strict else
        f"SOURCE GUIDANCE: Primary target is {website}. If {website} is down or inaccessible, you may search official disclosure sources or IDX."
    )

    flex_instruction = (
        "FLEXIBLE FILE MATCHING: Include reports with similar titles such as 'Laporan Keuangan', 'Laporan Keuangan Tahunan', 'Financial Statement', 'Laporan Tahunan & Keuangan', or similar variants."
        if is_flex else
        "STANDARD FILE MATCHING: Focus on Annual Reports (Laporan Tahunan) and Sustainability Reports (Laporan Keberlanjutan)."
    )

    # Standardized prompt formatted dynamically
    prompt = (
        f"/agent-browser Task: find annual report PDF download URLs for {company_name} ({ticker}). "
        f"WEBSITE: {website} YEARS: 2015 to 2025 TICKER: {ticker} "
        f"DOWNLOAD_SCRIPT: {TEMP_DOWNLOAD_SCRIPT} PROGRESS_FILE: {PROGRESS_PATH} "
        f"{strict_instruction} {flex_instruction} "
        f"Using the browser tool: 1. Navigate to website 2. Find annual reports "
        f"3. Append curl commands (curl -sL -o 'results/pdfs/{ticker}_AR_YYYY.pdf' 'URL') to {TEMP_DOWNLOAD_SCRIPT} "
        f"4. Update {PROGRESS_PATH} "
        f"RESULT: Write standardized JSON to {LAST_RESULT} with schema: "
        f'{{"ticker": "{ticker}", "company_name": "{company_name}", "website": "{website}", "status": "completed", '
        f'"reports_found": [{{"year": 2024, "report_type": "Annual Report", "title": "...", "url": "...", "filename": "{ticker}_AR_2024.pdf"}}], '
        f'"years_found": [2015, 2016], "years_missing": [], "curl_commands": ["curl -sL -o \'results/pdfs/{ticker}_AR_2024.pdf\' \'URL\'"]}} '
        f"When you are done, run {DONE_SCRIPT}"
    )

    # Launch cmd directly in live TUI mode attached to controlling /dev/tty
    cmd_args = ["cmd", "--yolo", prompt]
    sys.stdout.flush()
    try:
        with open("/dev/tty", "r") as tty:
            subprocess.run(cmd_args, stdin=tty)
    except Exception:
        subprocess.run(cmd_args)
    sys.stdout.flush()

    # 1. Merge urls_temp.sh into main download_reports.sh
    if os.path.exists(TEMP_DOWNLOAD_SCRIPT):
        with open(TEMP_DOWNLOAD_SCRIPT, "r", encoding="utf-8") as tf:
            temp_urls = tf.read().strip()
        if temp_urls:
            with open(DOWNLOAD_SCRIPT, "a", encoding="utf-8") as df:
                df.write("\n" + temp_urls + "\n")
            print(f"[{ticker}] Appended urls_temp.sh to download_reports.sh.")
        os.remove(TEMP_DOWNLOAD_SCRIPT)

    # 2. Append last-result.json to result-log.json (avoiding duplicate entries for same ticker)
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
            
            # Remove any existing entry for this ticker before appending updated one
            log_list = [e for e in log_list if isinstance(e, dict) and e.get("ticker") != ticker]
            log_list.append(last_res_data)
            
            with open(RESULT_LOG, "w", encoding="utf-8") as lf:
                json.dump(log_list, lf, indent=2)
            print(f"[{ticker}] Appended last-result.json to result-log.json.")

    # 3. Git add, commit, and push for this ticker
    print(f"[{ticker}] Running git add, commit, and push...")
    subprocess.run(["git", "add", "."], cwd=BASE_DIR, check=False)
    subprocess.run(["git", "commit", "-m", f"added {ticker}"], cwd=BASE_DIR, check=False)
    print(f"[{ticker}] Pushing to remote repository...")
    git_env = os.environ.copy()
    git_env["SSH_ASKPASS"] = ASKPASS_PATH
    git_env["SSH_ASKPASS_REQUIRE"] = "force"
    if not git_env.get("DISPLAY"):
        git_env["DISPLAY"] = ":0"
    subprocess.run(["git", "push"], cwd=BASE_DIR, check=False, env=git_env)
    print(f"[{ticker}] Git push completed.")

    # Check if last ticker was reached
    if ticker == last_ticker_in_csv:
        print(f"[{ticker}] Processed the last ticker in companylist.csv. Stopping loop.")
        break

print("All tickers processed.")
PYEOF