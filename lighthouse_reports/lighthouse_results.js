const fs = require('fs');
const path = require('path');
const xlsx = require('xlsx');

// 📅 Получаем сегодняшнюю дату (dd.mm.yy)
const today = new Date();
const day = String(today.getDate()).padStart(2, '0');
const month = String(today.getMonth() + 1).padStart(2, '0');
const year = String(today.getFullYear()).slice(-2);
const reportFolderName = `${day}.${month}.${year}`;

// 🔍 Определяем корень проекта (где находится lighthouse_reports)
function findReportsRootDir() {
  let dir = process.cwd();
  while (!fs.existsSync(path.join(dir, 'lighthouse_reports'))) {
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  const fullPath = path.join(dir, 'lighthouse_reports');
  if (!fs.existsSync(fullPath)) {
    console.error('❌ Папка lighthouse_reports не найдена');
    process.exit(1);
  }
  return fullPath;
}

const reportsRootDir = findReportsRootDir();
const targetDir = path.join(reportsRootDir, reportFolderName);

if (!fs.existsSync(targetDir)) {
  console.error(`❌ Папка с отчетами за сегодня не найдена: ${targetDir}`);
  process.exit(1);
}

console.log(`📂 Чтение отчетов из: ${targetDir}`);

const result = [];

const scenarioMap = {
  'https://baucenter.ru/product/gipsovaya-shtukaturka-knauf-rotband-25-kg-ctg-29116-29171-29180-511000304/': 'OLD Карточка товара',
  'https://baucenter.ru/': 'OLD Главная',
  'https://baucenter.ru/personal/cart/': 'OLD Корзина',
  'https://baucenter.ru/personal/list/5509688/': 'OLD Список покупок',
  'https://baucenter.ru/catalog/shtukaturki-ctg-29116-29171-29180/': 'OLD Каталог',
  'https://baucenter.ru/search/?query=%D0%BA%D1%80%D0%B0%D0%BD%D1%8B': 'OLD Поиск по слову "краны"'
};

function extractMetrics(jsonPath) {
  const content = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));
  const audits = content.audits || {};
  const categories = content.categories || {};
  const pageUrl = content.finalUrl || '';
  const scenario = scenarioMap[pageUrl] || '(unknown)';
  const filename = path.basename(jsonPath).replace('.json', '');
  const parts = filename.split('_');
  const platform = parts[parts.length - 2]; // adaptive или desktop
  const rawRole = parts[parts.length - 1];  // Auth.report или NoAuth.report
  const role = rawRole.startsWith('NoAuth') ? 'NoAuth' : 'Auth';

  return {
    scenario: scenario,
    page: content.finalUrl || '',
    platform: platform,
    role: role,
    timestamp: content.fetchTime || '',
    fcp: +(audits['first-contentful-paint']?.numericValue / 1000).toFixed(2) || 0,
    lcp: +(audits['largest-contentful-paint']?.numericValue / 1000).toFixed(2) || 0,
    tti: +(audits['interactive']?.numericValue / 1000).toFixed(2) || 0,
    si: +(audits['speed-index']?.numericValue / 1000).toFixed(2) || 0,
    tbt: +(audits['total-blocking-time']?.numericValue).toFixed(2) || 0,
    cls: +(audits['cumulative-layout-shift']?.numericValue).toFixed(2) || 0,
    performance: categories['performance']?.score ? categories['performance'].score * 100 : 0
  };
}

function walkJsonReports(baseDir) {
  const entries = fs.readdirSync(baseDir);
  for (const entry of entries) {
    const fullPath = path.join(baseDir, entry);
    if (fs.statSync(fullPath).isDirectory()) {
      walkJsonReports(fullPath); // рекурсивно
    } else if (entry.endsWith('.json')) {
      try {
        const metrics = extractMetrics(fullPath);
        result.push(metrics);
        console.log(`✅ Обработан: ${entry}`);
      } catch (e) {
        console.warn(`⚠️ Ошибка в файле ${entry}: ${e.message}`);
      }
    }
  }
}

walkJsonReports(targetDir);

if (result.length === 0) {
  console.warn('⚠️ Не найдено валидных .json отчетов.');
} else {
  const worksheet = xlsx.utils.json_to_sheet(result, {
    header: [
      'timestamp',
      'page',
      'scenario',
      'role',
      'platform',
      'fcp',
      'lcp',
      'tti',
      'si',
      'tbt',
      'cls',
      'performance',
    ]
  });

const workbook = xlsx.utils.book_new();
xlsx.utils.book_append_sheet(workbook, worksheet, 'Lighthouse Results');

// 📁 Создаём подкаталог xlsx/, если нужно
const xlsxDir = path.join(targetDir, 'xlsx');
if (!fs.existsSync(xlsxDir)) fs.mkdirSync(xlsxDir);

// 💾 Путь к файлу
const outputFile = path.join(xlsxDir, `lighthouse_report_${reportFolderName}.xlsx`);

// 📤 Сохраняем файл
xlsx.writeFile(workbook, outputFile);

console.log(`📊 XLSX отчет сохранён: ${outputFile}`);
}
