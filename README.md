# Lighthouse CLI Audit Script Runner

Скрипт для автоматического запуска [Lighthouse](https://developers.google.com/web/tools/lighthouse) аудита сайтов с сохранением результатов в формате Excel.

## 📦 Быстрый старт

Скопируйте и выполните все команды ниже в терминале для установки зависимостей и запуска:

```bash
# Установка Zsh и установка его оболочкой по умолчанию
brew install zsh
chsh -s /bin/zsh

# Установка Node.js и npm
brew install node
brew install npm

# Установка Lighthouse глобально
npm install -g lighthouse

# Установка Google Chrome (необходим для Lighthouse)
brew install --cask google-chrome

# Установка утилиты для обработки JSON
brew install jq

# Установка npm-библиотек для работы с Excel
npm install xlsx
npm install exceljs

# Назначение прав на выполнение скрипта и запуск Lighthouse
chmod +x ./run_lighthouse.zsh
./run_lighthouse.zsh start
