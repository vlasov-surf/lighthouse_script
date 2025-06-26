#!/bin/zsh

# Дата и время
report_name="$(date +'%d.%m.%y')"
current_date=$(date +'%d.%m.%y')
current_time=$(date +'%H-%M-%S')

# Папка для отчётов
report_dir="./lighthouse_reports/$current_date"
logs_dir="$report_dir/logs"  # Папка для логов

# Создаем папки для отчетов и логов
mkdir -p "$logs_dir"

# Аккаунты:
#89081412294 - студийный номер (смс падают в Пачку в чат sms-code-from-services ) (ДЛЯ ПРОФИ)
#89521078905 - симка у Бабайцева Саши  (ДЛЯ БОНУСА)

# Список cookies
guestKld="authorization=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI4OGM3NGU1Yy01MjUyLTExZjAtODZjYS0wY2M0N2EzNDQ0M2MiLCJsb2MiOjExMDAzNTg1ODUsImV4cCI6MTc1MzUwOTQ4OCwicm9sZSI6Imd1ZXN0In0.5Hck6GHWBmAcxUe2io5iKBdFruc_qvaY4FUZH3OLcYg"
guestMsk="authorization=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJmNWIzNzBiZS01MjRjLTExZjAtYWQ1Yi1jYWI1Y2FjMzBlMGIiLCJsb2MiOjExMDA0NjgxODIsImV4cCI6MTc1MzUwNzA5NCwicm9sZSI6Imd1ZXN0In0.c3aMFfQgCZfgLNOepxm36iIEGdEhmRzmfUCLQuu1apQ"
commonKld="authorization=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI1ZWM5YWQ5Ni01Mjc3LTExZjAtYTVmMy0wMjQyNjcyMjZmNjQiLCJsb2MiOjExMDAzNTg1ODUsImV4cCI6MTc1MzUyNTQwMywicm9sZSI6ImNvbW1vbiIsInN1YiI6Mjk4NTQ2MywidGVsIjoiNzk1MjEwNzg5MDUiLCJsY2kiOiIzOTQ0MDQwMjM3IiwibGN0IjoiYm9udXMifQ.859kAohNL8CDWrOPvF2OjOHz2VvtZ-Mi449COeANri8"
commonMsk="authorization=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI1ZWM5YWQ5Ni01Mjc3LTExZjAtYTVmMy0wMjQyNjcyMjZmNjQiLCJsb2MiOjExMDA0NjgxODIsImV4cCI6MTc1MzUyNTMyNywicm9sZSI6ImNvbW1vbiIsInN1YiI6Mjk4NTQ2MywidGVsIjoiNzk1MjEwNzg5MDUiLCJsY2kiOiIzOTQ0MDQwMjM3IiwibGN0IjoiYm9udXMifQ.V0LRhH3ngMSWR5NafGE-RE1KZ8PMjuRsyjmEmD3K-lI"
profiKld="authorization="
profiMsk="authorization="

# Парсинг роли из JWT-токена с учётом паддинга
parse_jwt_role() {
  local jwt=$1
  local payload=$(echo "$jwt" | cut -d '.' -f2)
  local padded=$(printf '%s' "$payload" | sed -e 's/-/+/g' -e 's/_/\//g')

  local mod=$(( ${#padded} % 4 ))
  if [[ $mod -eq 2 ]]; then
    padded="${padded}=="
  elif [[ $mod -eq 3 ]]; then
    padded="${padded}="
  fi

  local decoded
  if ! decoded=$(echo "$padded" | base64 -d 2>/dev/null); then
    echo "⚠️ Ошибка при декодировании токена"
    return 1
  fi

  echo "🔍 Декодированный payload JWT:"
  echo "$decoded"

  local role=$(echo "$decoded" | grep -o '"role":"[^"]*"' | cut -d':' -f2 | tr -d '"')
  if [[ -z "$role" ]]; then
    echo "⚠️ Роль не найдена в токене."
    return 1
  fi

  echo "🔐 Роль из токена: $role"
  printf '%s' "$role"
}

# Сценарии
# Можешь откомментить чтобы запустить другие урлы
scenarios=(
  "https://baucenter.ru/|mobile|guestKld"
#  "https://baucenter.ru/|mobile|guestMsk"
#  "https://baucenter.ru/|mobile|profiMsk"
#  "https://baucenter.ru/|mobile|commonKld"
#  "https://baucenter.ru/|desktop|guestKld"
#  "https://baucenter.ru/|desktop|guestMsk"
#  "https://baucenter.ru/|desktop|profiMsk"
  "https://baucenter.ru/|desktop|commonMsk"
#  "https://baucenter.ru/personal/cart/|desktop|commonMsk"
)

# Прогон по сценариям
for scenario in "${scenarios[@]}"; do
  IFS="|" read -r url form_factor cookie_var <<< "$scenario"
  cookie=$(eval echo "\$$cookie_var")
  token=${cookie#*=}
  parse_jwt_role "$token"

  url_slug=$(echo "$url" | sed -E 's~https?://([^/]+).*~\1~')
  base_name="${current_date}_${current_time}_${url_slug}_${form_factor}_${cookie_var}"
  tmp_headers_file=$(mktemp)

  # Запись cookie и токена авторизации в файл заголовков
  echo "{
    \"Cookie\": \"$cookie\",
    \"Authorization\": \"Bearer $token\"
  }" > "$tmp_headers_file"

  echo "🔍 Содержимое заголовков:"
  cat "$tmp_headers_file"
  echo "🌐 $url | 📱 $form_factor | 🍪 $cookie_var"

  # Цикл для типа вёрстки
  if [[ "$form_factor" == "mobile" ]]; then
    window_size="375,667"
    emu_flags=(--emulated-form-factor=mobile)
  else
    window_size="1920,1080"
    emu_flags=(--emulated-form-factor=desktop --preset=desktop)
  fi

  # Путь для логов в папке logs
  log_path="$logs_dir/${base_name}"

  # Запуск Lighthouse
    lighthouse "${url}" \
      "${emu_flags[@]}" \
      --output=json,html \
      --output-path="${log_path}.json" \
      --extra-headers="${tmp_headers_file}" \
      --disable-storage-reset \
      --throttling-method=provided \
      --chrome-flags="--headless --no-sandbox --disable-gpu --window-size=${window_size}"

  # Добавление путей к результатам для дальнейшей обработки
  json_results+=("$log_path.json")
  html_results+=("$log_path.html")

  rm -f "$tmp_headers_file"
  sleep 5
done

# 📊 Генерация XLSX отчета
echo "📈 Генерация .xlsx отчета..."
node lighthouse_reports/lighthouse_results.js
echo "✅ Завершено!"
