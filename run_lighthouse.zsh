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
#89081412294 - profi - студийный номер (смс падают в Пачку в чат sms-code-from-services ) (ДЛЯ ПРОФИ)
#89521078905 - common - симка у Бабайцева Саши  (ДЛЯ БОНУСА)

# Список cookies
#истечёт 24.10.2025
guestKld="authorization=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI4OGM3NGU1Yy01MjUyLTExZjAtODZjYS0wY2M0N2EzNDQ0M2MiLCJsb2MiOjExMDAzNTg1ODUsImV4cCI6MTc1MzUwOTQ4OCwicm9sZSI6Imd1ZXN0In0.5Hck6GHWBmAcxUe2io5iKBdFruc_qvaY4FUZH3OLcYg"
#истечёт 24.10.2025
guestMsk="authorization=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJmNWIzNzBiZS01MjRjLTExZjAtYWQ1Yi1jYWI1Y2FjMzBlMGIiLCJsb2MiOjExMDA0NjgxODIsImV4cCI6MTc1MzUwNzA5NCwicm9sZSI6Imd1ZXN0In0.c3aMFfQgCZfgLNOepxm36iIEGdEhmRzmfUCLQuu1apQ"
#истечёт 24.10.2025
commonKld="authorization=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI1ZWM5YWQ5Ni01Mjc3LTExZjAtYTVmMy0wMjQyNjcyMjZmNjQiLCJsb2MiOjExMDAzNTg1ODUsImV4cCI6MTc1MzUyNTQwMywicm9sZSI6ImNvbW1vbiIsInN1YiI6Mjk4NTQ2MywidGVsIjoiNzk1MjEwNzg5MDUiLCJsY2kiOiIzOTQ0MDQwMjM3IiwibGN0IjoiYm9udXMifQ.859kAohNL8CDWrOPvF2OjOHz2VvtZ-Mi449COeANri8"
#истечёт 24.09.2025
profiMsk="authorization=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJiYjY3MGMxNi01MzFiLTExZjAtOTU1OC0wY2M0N2EzNDQ0M2MiLCJsb2MiOjExMDA0NjgxODIsImV4cCI6MTc1MzYwOTkyOCwicm9sZSI6InByb2ZpIiwic3ViIjoyOTg1NDQ4LCJ0ZWwiOiI3OTA4MTQxMjI5NCIsImxjaSI6IjM5MjE2MDg2MjMiLCJsY3QiOiJwcm9maSJ9.L5kI-XDtjAjVu9-bKLltP_pXjMOBbX_klzzaDKdNQFc"

# Парсинг роли из JWT-токена
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

# Роли
roles=("guestKld" "guestMsk" "commonKld" "profiMsk")

# Сценарии
main_pages=(
  "http://localhost:3000/"
)
card_simple_pages=(
  "http://localhost:3000/product/ogurets-vostochnyy-ekspress-f1-a-ctg-29705-29775-31112-935003269/"
)
#card_visual_pages=(
#  "http://localhost:3000/product/oboi-flizelinovye-10kh1-06-m-elysium-rustika-e52126-ctg-29494-29512-29518-301017540/"
#)
#card_set_pages=(
#  "http://localhost:3000/product/dver-mezhkomnatnaya-osteklennaya-2000kh800-mm-en2-seraya-ctg-29559-29563-29566-609006577/"
#)
#card_video_pages=(
#  "http://localhost:3000/product/dver-mezhkomnatnaya-osteklennaya-2000kh800-mm-en2-seraya-ctg-29559-29563-29566-609006577/"
#)
card_tp_pages=(
  "http://localhost:3000/product/samorezy-po-metallu-dlya-gipsokartona-fixberg-3-5kh25-mm-250-sht-ctg-29320-29325-32231-720005964/"
)
catalogSecond_full=(
  "http://localhost:3000/catalog/elektroinstrument-ctg-29290-29342/"
)
#catalogSecond_usual=(
#  "http://localhost:3000/catalog/pribory-ucheta-i-kontrolya-ctg-29189-30568/"
#)
#catalogSecond_products=(
#  "http://localhost:3000/catalog/oboi-ctg-29494-29512/"
#)
catalogThird_collections=(
  "http://localhost:3000/catalog/plitka-dlya-vannoy-ctg-29360-29384-30292/"
)
#catalogThird_usual=(
#  "http://localhost:3000/catalog/gipsokarton-ctg-29116-29129-29130/"
#)
#catalogThird_full=(
#  "http://localhost:3000/catalog/lampy-e27-ctg-29670-29674-29682/"
#)
search_usual=(
  "http://localhost:3000/search/?query=%D0%BA%D1%80%D0%B0%D0%BD%D1%8B"
)
#search_filters=(
#  "http://localhost:3000/search/?query=%D1%81%D0%BA%D0%BE%D1%82%D1%87&sectionIds=30654,30656,32003&set_filter=y&arrFilter_5279_2644469059=Y&arrFilter_5279_2671857292=Y&arrFilter_5279_1439224407=Y"
#)

#Тест-сеты
scenarios=()

#Главная
for url in "${main_pages[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

#Карточка товара-simple
for url in "${card_simple_pages[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

#Карточка товара-visual
for url in "${card_visual_pages[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

#Карточка товара-set
for url in "${card_set_pages[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

#Карточка товара-video
for url in "${card_video_pages[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

#Карточка товара-tp
for url in "${card_tp_pages[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

#Каталог (2-й уровень)-full
for url in "${catalogSecond_full[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

#Каталог (2-й уровень)-usual
for url in "${catalogSecond_usual[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

#Каталог (2-й уровень)-products
for url in "${catalogSecond_products[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

#Каталог (3-й уровень)-collections
for url in "${catalogThird_collections[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

#Каталог (3-й уровень)-usual
for url in "${catalogThird_usual[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

#Каталог (3-й уровень)-full
for url in "${catalogThird_full[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

#Поиск-usual
for url in "${search_usual[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

#Поиск-filters
for url in "${search_filters[@]}"; do
  for role in "${roles[@]}"; do
    scenarios+=("${url}|desktop|${role}")
    scenarios+=("${url}|mobile|${role}")
  done
done

# Прогон
for scenario in "${scenarios[@]}"; do
  IFS="|" read -r url form_factor cookie_var <<< "$scenario"
  if [[ -z "$url" ]]; then
      echo "⚠️ Пропускаю пустой URL"
      continue
    fi
  cookie=$(eval echo "\$$cookie_var")
  token=${cookie#*=}
  parse_jwt_role "$token"

  url_slug=$(echo "$url" | sed -E 's~https?://~~' | tr '/:?=&' '_')
  base_name="${current_date}_${current_time}_${url_slug}_${form_factor}_${cookie_var}"
  tmp_headers_file=$(mktemp)

  # Запись cookie и токена авторизации в файл заголовков
cat <<EOF > "$tmp_headers_file"
{
  "Cookie": "$cookie",
  "Authorization": "Bearer $token"
}
EOF

  echo "🔍 Содержимое заголовков:"
  cat "$tmp_headers_file"
  echo "🌐 Сценарий: $url | 📱 Верстка: $form_factor | Роль: 🍪 $cookie_var"

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
