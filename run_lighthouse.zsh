#!/bin/zsh

# 📅 Дата и время
report_name="$(date +'%d.%m.%y')"
current_date=$(date +'%d.%m.%y')
current_time=$(date +'%H-%M-%S')

# 📁 Папка для отчётов
report_dir="./lighthouse_reports/$current_date"
mkdir -p "$report_dir/html" "$report_dir/json"

# 🔗 URL-ы для анализа
urls=(
  "https://baucenter.ru/product/gipsovaya-shtukaturka-knauf-rotband-25-kg-ctg-29116-29171-29180-511000304/"
  "https://baucenter.ru/"
  "https://baucenter.ru/personal/cart/"
  "https://baucenter.ru/personal/list/5509688/"
  "https://baucenter.ru/catalog/shtukaturki-ctg-29116-29171-29180/"
  "https://baucenter.ru/search/?query=%D0%BA%D1%80%D0%B0%D0%BD%D1%8B"
)

# 🍪 Актуальные куки для авторизации
cookies="cookieInformed=false; authorization=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJhMTJjZmI2Ni00NmExLTExZjAtOGY4YS0wMjQyNjcyMjZmNjQiLCJsb2MiOjExMDAzNTg1ODUsImV4cCI6MTc1MjIyNDA0NSwicm9sZSI6InByb2ZpIiwic3ViIjoyNDAwMzQ0LCJ0ZWwiOiI3OTAzNjUzMDAwNyIsImxjaSI6IjM5NDQwMzE2ODUiLCJsY3QiOiJib251cyJ9.PuOOAaQWFv_PbVIiAuUplAlCz7Wyp0JbQf4b9LSnJAs"

# 🔁 Прогон по каждой конфигурации
for url in "${urls[@]}"
do
  base_name=$(basename "$url" | tr -d '?=/:%')

  echo "🌐 Страница: $url"

for form_factor in "mobile" "desktop"; do
  for auth in "NoAuth" "Auth"; do

    base_filename="${current_date}_${current_time}_${form_factor}_${auth}_${base_name}"
    report_path_json="${report_dir}/json/${base_filename}"

    chrome_flags="--headless --no-sandbox --disable-gpu"

    if [ "$form_factor" = "mobile" ]; then
      emulated_form_factor="mobile"
      chrome_flags="$chrome_flags --window-size=375,667"
    else
      emulated_form_factor="desktop"
      chrome_flags="$chrome_flags --window-size=1600,900"
    fi

    extra_headers=""
    if [ "$auth" = "Auth" ]; then
      extra_headers="--extra-headers '{\"Cookie\": \"$cookies\"}'"
    fi

    echo "🚀 Lighthouse: $form_factor / $auth"

    lighthouse "$url" \
      --output html \
      --output json \
      --output-path="$report_path_json" \
      --emulated-form-factor=$emulated_form_factor \
      --chrome-flags="$chrome_flags" \
      --disable-storage-reset \
      --throttling-method=provided \
      $extra_headers

    mv "${report_dir}/json/${base_filename}.report.html" "${report_dir}/html/"
    sleep 5

  done
done

done

# 📂 Перемещаем .html из json/ в html/
echo "📂 Перемещаем .html → html/"
for file in "$report_dir/json/"*.html; do
  mv "$file" "$report_dir/html/"
done

# 📊 Генерация XLSX отчета
echo "📈 Генерация .xlsx отчета..."
node lighthouse_reports/lighthouse_results.js
echo "✅ Завершено!"
