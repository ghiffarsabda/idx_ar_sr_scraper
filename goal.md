# Goal

Scrape annual and sustainability report PDFs for every company in companylist.csv.

## How it works

1. `run.sh` reads companylist.csv, picks the next pending ticker from progress.json.
2. It opens a **new terminal window** running `cmd --yolo` with the agent-browser prompt.
3. Cmd navigates the company website, finds AR/SR PDFs, appends curl commands to `results/download_reports.sh`.
4. When the terminal closes, `run.sh` moves to the next ticker.
5. Repeat until all tickers are processed.
6. Run `bash results/download_reports.sh` to download all PDFs to `results/pdfs/`.
