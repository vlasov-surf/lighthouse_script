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

# Сценарии
petrovich=(
  "https://rf.petrovich.ru/"
  "https://rf.petrovich.ru/product/1083317/"
  "https://rf.petrovich.ru/catalog/1579/"
  "https://rf.petrovich.ru/catalog/258316641/?sort=popularity_desc"
  "https://rf.petrovich.ru/search/?q=краны"
  "https://rf.petrovich.ru/cabinet/estimates/"
  "https://rf.petrovich.ru/cart/pre-order/rf/"
)
lemana=(
  "https://lemanapro.ru/"
  "https://lemanapro.ru/product/oboi-flizelinovye-victoria-stenova-dubai-serye-106-m-vs281067-83616599/"
  "https://lemanapro.ru/catalogue/oboi-dlya-sten-i-potolka/"
  "https://lemanapro.ru/catalogue/dekorativnye-oboi/"
  "https://lemanapro.ru/search/?q=краны&suggest=true"
  "https://lemanapro.ru/shopping-list/"
  "https://lemanapro.ru/basket/"
)
wildberries=(
  "https://www.wildberries.ru/"
  "https://www.wildberries.ru/catalog/409875904/detail.aspx/"
  "https://www.wildberries.ru/catalog/dlya-remonta/krepezh/"
  "https://www.wildberries.ru/catalog/dlya-remonta/krepezh/samorezy-i-shurupy/"
  "https://www.wildberries.ru/catalog/0/search.aspx?search=%D0%BA%D1%80%D0%B0%D0%BD%D1%8B"
  "https://www.wildberries.ru/lk/favorites"
  "https://www.wildberries.ru/lk/basket"
)
ozon=(
  "https://www.ozon.ru/"
  "https://www.ozon.ru/product/semena-ogurtsy-severnyy-potok-f1-nabor-semyan-ogurtsov-2-upakovki-1841230238/?at=99trJzEggt2v88qlFyEMPrJcxQYJLlU2EOVlDSRn3J9R"
  "https://www.ozon.ru/category/tsvety-i-rasteniya-14884/"
  "https://www.ozon.ru/category/krany-dlya-santehniki-10319/?category_was_predicted=true&deny_category_prediction=true&from_global=true&text=краны"
  "https://www.ozon.ru/my/favorites"
  "https://www.ozon.ru/cart"
)
all_instruments=(
  "https://www.vseinstrumenti.ru/"
  "https://www.vseinstrumenti.ru/product/samorez-dobroga-gkd-3-5x35-mm-oksidirovannyj-50-sht-tsb-00029203-12316793/"
  "https://www.vseinstrumenti.ru/category/metizy-170301/"
  "https://www.vseinstrumenti.ru/category/samorezy-3373/"
  "https://www.vseinstrumenti.ru/search/?what=краны"
  "https://www.vseinstrumenti.ru/user/favorites/"
  "https://www.vseinstrumenti.ru/cart-checkout-v3/"
)

#Тест-сеты
scenarios=()

# Цикл по страницам
for url in "${petrovich[@]}"; do
    scenarios+=("${url}|desktop")
    scenarios+=("${url}|mobile")
done

for url in "${lemana[@]}"; do
    scenarios+=("${url}|desktop")
    scenarios+=("${url}|mobile")
done

for url in "${wildberries[@]}"; do
    scenarios+=("${url}|desktop")
    scenarios+=("${url}|mobile")
done

for url in "${ozon[@]}"; do
    scenarios+=("${url}|desktop")
done

for url in "${all_instruments[@]}"; do
    scenarios+=("${url}|desktop")
done

# Прогон
json_results=()
html_results=()

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

  # Если это сайт lemana, создаем файл с cookie
  if [[ "$url" == *"lemanapro.ru"* ]]; then
    echo "Применяю cookie для $url"
  cat > "$headers_file" <<EOF
{
  "Cookie": "st_uid=47e7ae5f0a8c71f708b23320f4952e0e; cookie_accepted=true; qrator_jsid2=v2.0.1751445212.753.d5817fcfs7SVbMUx|aCg9TDy4UoPuJKan|ZfiDG36GOc2biImIJbKIY9JVQEbvy54LDduQ+WDETZweigyEnAlkg33dYwEorqGw4ew7FUlELCFQQJNGwnOS/vEno5Uh2nBJMqxNEH8CQ4KKt4jpPcbTULLDdhJBpSbnegrI81ibGQMo9H80hrbHqw==-3dk9srD/TKiBSrodjZTuiARv2k4="
}
EOF
    headers_flag="--headers=$headers_file"
  else
    headers_flag=""
  fi

    # Если это сайт "Все инструменты", создаем файл с cookie
  elif [[ "$url" == *"lemanapro.ru"* ]]; then
    echo "Применяю cookie для $url"
  cat > "$headers_file" <<EOF
{
  "Cookie": "spjs=1751449409244_11ac4d11_0134ff91_009ba1e626ecd8e072c6559021713978_acTY93PLvu+aQPW02fj+bhblIzJehxvvhsq2g9+V8QRB/Gg7moIHorYUnfgUnSERnoNfboefPG4W4rQE4oCNfBiR9WHf1Zjspc6ywg6C/l4A+CxoibG2hgduqsp7jMBQfbV5D4O+I8O8A3emUwkcbQpXI3eDy734wQ1k4Ug2ygpnnzY8iJBFgLRqm/s6BqfgPcRNaaUdonKuN+s+Z5jJCTmhdVaiClqP7lnAwDlQ2RxzqaEg3sAi54Lkjo7ZwBIxxj/avRFJIBHMpvur0dqmVo0kMdHkCY/pD6ey8pIDbX0kyocT2Ac7+5G47PqocCRiBs576o32Zccp0bhZBT7Dgi+meqNnDno6WIPzY8e+7mhhmUWULBQ93xJqBnYO8KRUYCl8zttiNuGmUZ28cZxBMS63mhu2rH9vGkJ0BrKJrD0YyHfSD4c66pRN8oHZ0q5chSw5eBkj5UXGb655fV6TNDmUrwyErRfHzWOh8bHf61855yPA0IyZGxdP0vSIE42cJWykWS11QCDATcsqf/ZiNb9DTa3weOd2y5VYHLL8/ZsIVlEDx295zNjP4qMKpprqM813ga+XFLSAWe3tGSL2dkPrXwiUzCHBvVbqjlULExC79WAAA6oejttA9gRTJ+29APqHEn3mK7p3SRy7e+GlVWMqf8+rk2DxfFXZrtYIERVak06QlXw2zor1g1Onfno+E1mVEDYGKsC1XHAspfge53PJfA1ZIXT0kEfqqqWs8ujd5Pkq9Lwv/5niNiZTCbztGsB2o9yHOeqV7bEhXAS8aBdLfAs6ITVogVn3TEmPoW4O1Psa1Y6w5JxHd6JTDx45PpOgAYaIPWuQSrUubh25eRxMYCbbkxfr0lvcbfnU4zM5MH14IljG16uziYhzLO7PaeCgY0f/q64UgBxcoPlFleo9YoRMJcdvk7v1LtuJtZcZOP6KwUkkBNlzz75TXmdnPVWhMfUbHI0WkEWv8GZrZx0aMHHVgdyqG5tMpktzFtaQSHytCIA74G1G6KLmGZoRDeU4h4WcOehcENWk8X5qO1HZsfHspjhOhczRgWh1QZFkDCwpT2cGBpLD7KxRyODzueFtzKBIbe0fVfGglFt/aQwkAOeNg+y90FszpHtSXi5E7SgNeIYi4peOrqiLHXFmSCFNL4O7poYKFbWiNV2ZWI83l7bwTU29s/hl4Ftz701gDtBKrdUSUAUL36sPNud3mdEoKeDIUnfeQs7OYhjsSUmhMBb3qj+qyzxl8dgFGuoF3WEwzJQn8zWKfL97ATpM3agtJPknYqMWTfampf2RYJKOPgYjhjQ16fF8rF8IS5q2fv7uQX11+BVCYV0JInoWDblhXMTwL5ODNugvVS3R4S3ESafHhP77nbRVBdEJvG2XzXMgXoAZSUtGSNQdUIRcptzyIk3UOv/ZCrRoct66ZlmA==; spsc=1751449409244_6412ac31100b7c664ce7cc7fbf755b1e_Ct32TGs2WwOl2YMN9kQ3fj6qZEhyA4Kf-CbdzDh1HDAZ; spid=1751449409244_1b7efe0285173849638d6569d4c6f4cd_9kvt4cs65ppwj6aj; ab_exps=%7B%22243%22%3A4%2C%22362%22%3A1%2C%22380%22%3A1%2C%22511%22%3A0%2C%22565%22%3A0%2C%22595%22%3A2%2C%22607%22%3A3%2C%22619%22%3A2%2C%22771%22%3A1%2C%22777%22%3A0%2C%22818%22%3A3%2C%22879%22%3A0%2C%22885%22%3A3%2C%22897%22%3A3%2C%22920%22%3A0%2C%22938%22%3A2%2C%22956%22%3A1%2C%22968%22%3A2%2C%22980%22%3A0%2C%221028%22%3A2%2C%221046%22%3A2%2C%221052%22%3A2%2C%221082%22%3A1%2C%221088%22%3A2%2C%221178%22%3A3%2C%221190%22%3A2%2C%221310%22%3A1%2C%221316%22%3A0%2C%221324%22%3A2%2C%221343%22%3A3%2C%221346%22%3A0%2C%221351%22%3A1%2C%221387%22%3A1%2C%221417%22%3A1%2C%221423%22%3A1%2C%221435%22%3A1%2C%221441%22%3A1%2C%221451%22%3A7%2C%221463%22%3A2%2C%221481%22%3A0%2C%221487%22%3A0%2C%221511%22%3A0%2C%221535%22%3A0%2C%221571%22%3A3%2C%221577%22%3A1%2C%221594%22%3A4%2C%221624%22%3A1%2C%221636%22%3A3%2C%221648%22%3A11%2C%221685%22%3A1%2C%221709%22%3A1%2C%221727%22%3A2%2C%221733%22%3A1%2C%221739%22%3A0%2C%221745%22%3A0%2C%221751%22%3A2%2C%221787%22%3A2%2C%221793%22%3A4%2C%221799%22%3A2%2C%221823%22%3A1%2C%221830%22%3A1%2C%221848%22%3A2%2C%221854%22%3A3%2C%221866%22%3A4%2C%221872%22%3A5%2C%221893%22%3A4%2C%221899%22%3A3%2C%221905%22%3A1%2C%221923%22%3A0%2C%221929%22%3A3%2C%221941%22%3A2%2C%222001%22%3A1%2C%222019%22%3A3%2C%222037%22%3A1%2C%222070%22%3A0%2C%222073%22%3A0%7D; vi_features=%7B%22video-reviews%22%3A%221%22%2C%22franchise-disabled%22%3A%221%22%2C%22new-price-block%22%3A%221%22%2C%22investors-header%22%3A%221%22%2C%22business-landing-new%22%3A%221%22%2C%22leasing-pay-juristic%22%3A%221%22%2C%22affiliate-offer%22%3A%221%22%2C%22loyalty-program%22%3A%221%22%2C%22b-two-g-laws%22%3A%220%22%2C%22is-dashboard-faq%22%3A%220%22%2C%22most-useful-review%22%3A%221%22%2C%22loyalty-program-mvp%22%3A%220%22%7D; vi_represent_id=36; vi_represent_type=common; acctoken=eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ2aXRlY2giLCJhdWQiOiJ2c2VpbnN0cnVtZW50aS5ydSIsImRldmlkIjoiNjA1YTUxZWItMTMyNC01YzYwLTlmNTMtMGU5M2Q5NDcyZTQ2IiwidGlkIjoiNjY5MzA3ODMtZDg1Yi00MGM3LWIzZmMtMTNmYjE4ZWIzYTVhIiwiaWF0IjoxNzUxNDQ5NDEwLCJleHAiOjE3NTE1MzU4MTB9.jVeSdqBbjlSdLBH208HkGcKp9Ry2fDT6SYY9DSMj-4ZYG5p5zAuIxEvzBIq2rJgamV_Hbbc2lMLKwyWQHy2WTg; reftoken=eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ2aXRlY2giLCJhdWQiOiJ2c2VpbnN0cnVtZW50aS5ydSIsImRldmlkIjoiNjA1YTUxZWItMTMyNC01YzYwLTlmNTMtMGU5M2Q5NDcyZTQ2IiwidGlkIjoiNjY5MzA3ODMtZDg1Yi00MGM3LWIzZmMtMTNmYjE4ZWIzYTVhIiwiaWF0IjoxNzUxNDQ5NDEwLCJleHAiOjE3NjAwODk0MTB9.vzWc6Am6lutxz4U3FDl-Ac-qejuQjm7X-YRO0hNGSc7VH8SAISNstTfPPggoSghb03SdwV-12Y78NhbpszChTw; vi_rr_id=e1572fd7-9412-4626-8328-e5f0489aff64; cartToken=4a5e3df6-2b1e-47a6-838b-4a0070985f64; devid=605a51eb-1324-5c60-9f53-0e93d9472e46; _ym_uid=1751445467103351177; _ym_d=1751449411; _sp_ses.2a71=*; tmr_lvid=cd505a717a66c161ab2698750c61f73a; tmr_lvidTS=1751445466682; _sp_id.2a71=5375c319-c142-4263-948e-eb1a2a5469c1.1751449411.1.1751449411..20b07d9e-319f-4da1-88b7-edcecef54d2d..bb6dad11-69d9-4b43-8506-9de14bc38d6c.1751449411047.4; adrcid=A0Tv8cDP6_3V15FcAJPa5TQ; _ym_isad=2; advcake_track_id=d5ed948c-531d-dda7-d4d5-e1ed347d89bb; advcake_session_id=42434025-f357-b9b9-8753-0b4bc120a703; gdeslon.ru.__arc_domain=gdeslon.ru; gdeslon.ru.user_id=df56654a-5e4c-4306-8769-bf625709aa21; advcake_track_url=%3D20250113E1LpIwR2cpbyVKoSz5rhDbC%2BSEpEUxhjqOAD3HMgd6nvalJo1x5nZJWiIHuxW3qUa9j9tjeq4lbqYXiqc3wSPdmblaOgTsN5pUdg6%2BPRgD0gpKElPegjmI%2FLfzNQ8dNh1oML%2FNgZhoD2EakbasytlnXlhlYdfOvfmOqmt6EfKmMRYoFZgJzbgDmRzjf4Ex2HMNvHVCzfz9S3GECKoLjvlHsTZiTddA7%2Br%2FJRUeQVOpPQK6Xpw4XL03QZqcmT7GiKme1TTGUri6AAInslKdv%2FUHwJAOsY9P4Sxcrhg0dLDjbrfdoyMCpQYmeShcpn7gGZTxa4gsZBMLLOQ24ZoY6d5Xz8uEqP7SsMzubBpM6QkGEszd2SNxqfqApE%2FryL7hBAeZsA8%2F89yR93X4v1xtI0T4193z3RYWwD8I%2BWc79Ci5%2Fb5Es5OYYn8mrny68AbNB0wRgMcc%2B6frMvsgpmBrEXXnsqeQrHpPLlGC46goD7AeQBLYlpZNYbq8o0l5ik6wMBbyYIhgD2OF4PGt9TRVaQUd%2BapYaUgjeGPbtLx0USaIliJYYvkt0a9A1aUsVBL1iqPxuBO6rzd%2FG8l0fKJMcxab12NgbIq%2FM%2FEWSxKh0QDYzPwfSDVA3cU4U7yeJe6knMKc%2FkzOzEk8oMaU0%2B2VbI%2FGGqGPWlLJL%2BaFWPixdkysXTUFRWfPj0PS4%3D; UniqAnalyticsId=1751449411576445; analytic_id=1751449411701895; popmechanic_sbjs_migrations=popmechanic_1418474375998%3D1%7C%7C%7C1471519752600%3D1%7C%7C%7C1471519752605%3D1; mindboxDeviceUUID=ffa0d851-19a9-4e82-b5a1-9edcf476a636; directCrm-session=%7B%22deviceGuid%22%3A%22ffa0d851-19a9-4e82-b5a1-9edcf476a636%22%7D; pages_viewed=2"
}
EOF
    headers_flag="--headers=$headers_file"
  else
    headers_flag=""
  fi

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
    --disable-storage-reset \
    --throttling-method=provided \
  --chrome-flags="\
--headless \
--no-sandbox \
--disable-gpu \
--window-size=${window_size} \
--user-data-dir=${tmp_profile}"

  # Проверим, успешно ли отработал
  if [[ $? -ne 0 ]]; then
    echo "❌ Lighthouse вернул ошибку для $url | $form_factor"
  fi

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
