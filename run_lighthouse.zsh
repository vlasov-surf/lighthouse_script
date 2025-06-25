#!/bin/zsh

# 📅 Дата и время
report_name="$(date +'%d.%m.%y')"
current_date=$(date +'%d.%m.%y')
current_time=$(date +'%H-%M-%S')

# 📁 Папка для отчётов
report_dir="./lighthouse_reports/$current_date"

# Аккаунты:
#89081412294 - студийный номер (смс падают в Пачку в чат sms-code-from-services ) (ДЛЯ ПРОФИ)
#89521078905 - симка у Бабайцева Саши  (ДЛЯ БОНУСА)

# 🍪 Cookies
guestKld="authorization=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJiNGU5N2IyOC00ZmY0LTExZjAtOTM0ZS1jYWI1Y2FjMzBlMGIiLCJsb2MiOjExMDAzNTg1ODUsImV4cCI6MTc1MzM1OTA0Nywicm9sZSI6Imd1ZXN0In0.53HbuTb0n3jvTeK1QCZemX4WCoLkeXuoXzglz0T2m8o"
guestMsk="authorization=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJiNGU5N2IyOC00ZmY0LTExZjAtOTM0ZS1jYWI1Y2FjMzBlMGIiLCJsb2MiOjExMDA0NjgxODIsImV4cCI6MTc1MzI0OTI4Nywicm9sZSI6Imd1ZXN0In0.MQtSY18qDzmnkzmuWgGGKT5G_laS67Dh2VZqyuNv4Tk"
commonKld="authorization=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI1OWNkODJjMi01MWEwLTExZjAtYmU2NS0wMjQyNjcyMjZmNjQiLCJsb2MiOjExMDAzNTg1ODUsImV4cCI6MTc1MzQzMzIxOCwicm9sZSI6ImNvbW1vbiIsInN1YiI6Mjk4NTQ2MywidGVsIjoiNzk1MjEwNzg5MDUiLCJsY2kiOiIzOTQ0MDQwMjM3IiwibGN0IjoiYm9udXMifQ.LbFC7UenbaPccHvbPNOdZsiWHyB5YnuEaNbkn_45kC8"
commonMsk="authorization=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI1OWNkODJjMi01MWEwLTExZjAtYmU2NS0wMjQyNjcyMjZmNjQiLCJsb2MiOjExMDA0NjgxODIsImV4cCI6MTc1MzQzMzMzNSwicm9sZSI6ImNvbW1vbiIsInN1YiI6Mjk4NTQ2MywidGVsIjoiNzk1MjEwNzg5MDUiLCJsY2kiOiIzOTQ0MDQwMjM3IiwibGN0IjoiYm9udXMifQ.nPeGHDFrW-PkOrNbNJLIzHmGIKTfO4UYWkn0ETIfDMM"
profiKld="authorization="
profiMsk="authorization="

# 🔗 URL-ы
urls=(
#  "https://baucenter.ru/|mobile|guestKld"
#  "https://baucenter.ru/|mobile|guestMsk"
#  "https://baucenter.ru/|mobile|profiMsk"
#  "https://baucenter.ru/|mobile|commonKld"
#  "https://baucenter.ru/|desktop|guestKld"
#  "https://baucenter.ru/|desktop|guestMsk"
#  "https://baucenter.ru/|desktop|profiMsk"
#  "https://baucenter.ru/|desktop|commonMsk"
  "https://baucenter.ru/personal/cart/|desktop|commonMsk"
#  "https://baucenter.ru/personal/list/5858600/|desktop|commonMsk"
)

# 🔁 Прогон по сценариям
mkdir -p "$report_dir/json" "$report_dir/html"

for urls in "${urls[@]}"; do
  IFS="|" read -r url form_factor cookie_var <<< "$urls"

  cookie=$(eval echo "\$$cookie_var")
  token=$(echo "$cookie" | cut -d= -f2-)

  url_slug=$(echo "$url" | sed -E 's~https?://([^/]+).*~\1~')
  base_name="${current_date}_${current_time}_${url_slug}_${form_factor}_${cookie_var}"

  tmp_headers_file=$(mktemp)

  echo "{
    \"Cookie\": \"$cookie\",
    \"Authorization\": \"Bearer $token\"
  }" > "$tmp_headers_file"
  echo "🔍 Содержимое заголовков:"
  cat "$tmp_headers_file"


  echo "🌐 $url | 📱 $form_factor | 🍪 $cookie_var"

  if [[ "$form_factor" == "mobile" ]]; then
    window_size="375,667"
  else
    window_size="1920,1080"
  fi

  # Путь для логов
  json_path="$report_dir/json/${base_name}.json"
  html_path="$report_dir/html/${base_name}.html"

    # JSON
    lighthouse "$url" \
      --emulated-form-factor="$form_factor" \
      --output json \
      --output-path="$json_path" \
      --extra-headers="$tmp_headers_file" \
      --disable-storage-reset \
      --throttling-method=provided \
      --chrome-flags="--headless --no-sandbox --disable-gpu --window-size=$window_size"

    # HTML
    lighthouse "$url" \
      --emulated-form-factor="$form_factor" \
      --output html \
      --output-path="$html_path" \
      --extra-headers="$tmp_headers_file" \
      --disable-storage-reset \
      --throttling-method=provided \
      --chrome-flags="--headless --no-sandbox --disable-gpu --window-size=$window_size"

  rm -f "$tmp_headers_file"
  sleep 5
done

# 📊 Генерация XLSX отчета
echo "📈 Генерация .xlsx отчета..."
node lighthouse_reports/lighthouse_results.js
echo "✅ Завершено!"



