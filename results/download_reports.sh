#!/usr/bin/env bash

#!/usr/bin/env bash
# ABDA annual reports - extracted from https://www.myoona.id/ Tata Kelola Perusahaan > Laporan Keuangan > Tahunan
set -euo pipefail
OUT_DIR="${OUT_DIR:-/home/ghiffar-sabda/pratama/handoff/results/pdfs}"
mkdir -p "$OUT_DIR"

declare -A URLS=(
  [2015]="https://myoona.id/content/dam/oona/content-fragments/id/id/about-us-corporate/laporan-keuangan/tahunan/2015/2015%20-%20ANNUAL%20REPORT.pdf"
  [2016]="https://myoona.id/content/dam/oona/content-fragments/id/id/about-us-corporate/laporan-keuangan/tahunan/2016/2016%20-%20ANNUAL%20REPORT.pdf"
  [2017]="https://myoona.id/content/dam/oona/content-fragments/id/id/about-us-corporate/laporan-keuangan/tahunan/2017/2017%20-%20ANNUAL%20REPORT.pdf"
  [2018]="https://myoona.id/content/dam/oona/content-fragments/id/id/about-us-corporate/laporan-keuangan/tahunan/2018/2018%20-%20Published%20Financial%20Report.pdf"
  [2019]="https://myoona.id/content/dam/oona/content-fragments/id/id/about-us-corporate/laporan-keuangan/tahunan/2019/2019%20-%20Published%20Financial%20Report.pdf"
  [2020]="https://myoona.id/content/dam/oona/content-fragments/id/id/about-us-corporate/laporan-keuangan/tahunan/2020/2020%20-%20Published%20Financial%20Report.pdf"
  [2021]="https://myoona.id/content/dam/oona/content-fragments/id/id/about-us-corporate/laporan-keuangan/tahunan/2021/2021%20-%20ANNUAL%20REPORT.pdf"
  [2022]="https://myoona.id/content/dam/oona/content-fragments/id/id/about-us-corporate/laporan-keuangan/tahunan/2022/2022%20-%20ANNUAL%20REPORT.pdf"
  [2023]="https://myoona.id/content/dam/oona/content-fragments/id/id/about-us-corporate/laporan-keuangan/tahunan/2023/Annual%20Report%20SR%202023%20OONA.pdf"
  [2024]="https://myoona.id/content/dam/oona/content-fragments/id/id/about-us-corporate/laporan-keuangan/tahunan/2024/Annual%20Report%20SR%202024%20OONA.pdf"
  [2025]="https://myoona.id/content/dam/oona/content-fragments/id/id/about-us-corporate/laporan-keuangan/tahunan/2025/Annual%20Report%20and%20Sustainability%20Report%202025.pdf"
)

for year in 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025; do
  echo "Downloading ABDA $year..."
  curl -fsSL -o "$OUT_DIR/ABDA_${year}.pdf" "${URLS[$year]}"
done

echo "Done. Files in $OUT_DIR"

#!/usr/bin/env bash
curl -L --fail --retry 3 -o "AADI_2024_Annual_Report.pdf" "https://adaroindonesia.com/app/webroot/upload/files/Laporan%20Tahunan/AADI%20Annual%20Report%202024.pdf"
curl -L --fail --retry 3 -o "AADI_2025_Annual_Report.pdf" "https://adaroindonesia.com/app/webroot/upload/files/Laporan%20Tahunan/AADI%20Annual%20Report%202025.pdf"
