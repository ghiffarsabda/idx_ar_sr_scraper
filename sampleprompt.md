/agent-browser

Task: find annual report PDF download URLs for PT Asuransi Bina Dana Arta Tbk (ABDA).

WEBSITE: https://www.myoona.id/
YEARS: 2015 to 2025
TICKER: ABDA
DOWNLOAD_SCRIPT: /home/ghiffar-sabda/pratama/handoff/results/urls_temp.sh
PROGRESS_FILE: /home/ghiffar-sabda/pratama/handoff/progress.json

PROMPT MODIFIERS:
- STRICT MODE (--strict): Search ONLY on official website https://www.myoona.id/. Do NOT navigate to external sites (IDX, news, journals). If site does not respond within 30 seconds or loading loops, stop and mark skipped/failed.
- FLEX MODE (--flex): Allow matching files with similar names such as "Laporan Keuangan", "Laporan Keuangan Tahunan", "Financial Statement", "Laporan Tahunan & Keuangan".

Using the browser tool:
1. Navigate to the website
2. Find annual reports
3. Append curl commands to download script (/home/ghiffar-sabda/pratama/handoff/results/urls_temp.sh)
4. Update progress in /home/ghiffar-sabda/pratama/handoff/progress.json

RESULT: Write standardized JSON to /home/ghiffar-sabda/pratama/handoff/results/last-result.json in the following exact format:
{
  "ticker": "ABDA",
  "company_name": "PT Asuransi Bina Dana Arta Tbk",
  "website": "https://www.myoona.id/",
  "status": "completed",
  "reports_found": [
    {
      "year": 2024,
      "report_type": "Annual Report",
      "title": "Laporan Tahunan 2024",
      "url": "https://example.com/ar2024.pdf",
      "filename": "ABDA_AR_2024.pdf"
    }
  ],
  "years_found": [2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024],
  "years_missing": [2025],
  "curl_commands": [
    "curl -sL -o 'results/pdfs/ABDA_AR_2024.pdf' 'https://example.com/ar2024.pdf'"
  ]
}

When you are done, run /home/ghiffar-sabda/pratama/handoff/done.sh
