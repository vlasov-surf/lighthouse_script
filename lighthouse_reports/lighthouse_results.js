const fs = require('fs');
const path = require('path');
const xlsx = require('xlsx');
const ExcelJS = require('exceljs');
const today = new Date();
const day = String(today.getDate()).padStart(2, '0');
const month = String(today.getMonth() + 1).padStart(2, '0');
const year = String(today.getFullYear()).slice(-2);
const reportFolderName = `${day}.${month}.${year}`;
const role = 'guest';
const environment = 'non-local';
const entity = ''

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

function resolveId(pageUrl) {
  //Главная
  if (pageUrl === 'https://rf.petrovich.ru/') return 'main';
  if (pageUrl === 'https://lemanapro.ru/') return 'main';
  if (pageUrl === 'https://www.wildberries.ru/') return 'main';
  if (pageUrl === 'https://www.ozon.ru/?__rr=1&abt_att=1') return 'main';
  if (pageUrl === 'https://www.vseinstrumenti.ru/') return 'main';
  //Карточка товара
  if (pageUrl.includes('/product/1083317/')) return 'card';
  if (pageUrl.includes('/product/oboi-flizelinovye-victoria-stenova-dubai-serye-106-m-vs281067-83616599/')) return 'card';
  if (pageUrl.includes('/409875904/detail.aspx/')) return 'card';
  if (pageUrl.includes('/semena-ogurtsy-severnyy-potok-f1-nabor-semyan-ogurtsov-2-upakovki-1841230238/?at=99trJzEggt2v88qlFyEMPrJcxQYJLlU2EOVlDSRn3J9R')) return 'card';
  if (pageUrl.includes('/product/samorez-dobroga-gkd-3-5x35-mm-oksidirovannyj-50-sht-tsb-00029203-12316793/')) return 'card';
  //Каталог 2-й уровень
  if (pageUrl.includes('/catalog/1579/')) return 'catalogSecond';
  if (pageUrl.includes('/oboi-dlya-sten-i-potolka/')) return 'catalogSecond';
  if (pageUrl === 'https://www.wildberries.ru/catalog/dlya-remonta/krepezh/') return 'catalogSecond';
  if (pageUrl.includes('/category/tsvety-i-rasteniya-14884/')) return 'catalogSecond';
  if (pageUrl.includes('/category/metizy-170301/')) return 'catalogSecond';
  //Каталог 3-й уровень
  if (pageUrl.includes('/?sort=popularity_desc')) return 'catalogThird';
  if (pageUrl.includes('/catalogue/dekorativnye-oboi/')) return 'catalogThird';
  if (pageUrl.includes('/catalog/dlya-remonta/krepezh/samorezy-i-shurupy/')) return 'catalogThird';
  if (pageUrl.includes('/category/samorezy-3373/')) return 'catalogThird';
  //Поиск
  if (pageUrl.includes('/search/?q=краны')) return 'search';
  if (pageUrl.includes('/search/?q=краны&suggest=true')) return 'search';
  if (pageUrl.includes('/search.aspx?search=%D0%BA%D1%80%D0%B0%D0%BD%D1%8B')) return 'search';
  if (pageUrl.includes('/category/krany-dlya-santehniki-10319/?category_was_predicted=true&deny_category_prediction=true&from_global=true&text=краны')) return 'search';
  if (pageUrl.includes('/search/?what=краны')) return 'search';
  //Списки покупок
  if (pageUrl.includes('/cabinet/estimates/')) return 'lists';
  if (pageUrl.includes('/shopping-list/')) return 'lists';
  if (pageUrl.includes('/favorites/')) return 'lists';
  if (pageUrl.includes('/my/favorites/')) return 'lists';
  if (pageUrl.includes('/user/favorites/')) return 'lists';
  //Корзина
  if (pageUrl === 'https://rf.petrovich.ru/cart/pre-order/rf/') return 'cart';
  if (pageUrl === 'https://lemanapro.ru/basket/') return 'cart';
  if (pageUrl === 'https://www.wildberries.ru/lk/basket') return 'cart';
  if (pageUrl === 'https://www.wildberries.ru/lk/basket') return 'cart';
  if (pageUrl.includes('ozon.ru/cart')) return 'cart';
  if (pageUrl.includes('/cart-checkout-v3/')) return 'cart';
  return '';
}

function resolveProject(pageUrl) {
  //Петрович
  if (pageUrl.includes('rf.petrovich.ru')) return 'petrovich';
  //Лемана
  if (pageUrl.includes('lemanapro.ru/')) return 'lemana';
  //ВБ
  if (pageUrl.includes('wildberries.ru/')) return 'wildberries';
  //Озон
  if (pageUrl.includes('ozon.ru/')) return 'ozon';
  //Все инструменты
  if (pageUrl.includes('vseinstrumenti.ru/')) return 'ozon';
  return '';
}

function extractSeconds(val) {
  if (!val || typeof val.numericValue !== 'number') return '';
  return (val.numericValue / 1000).toFixed(1); // например: 1005.321 → "1.0"
}

function extractTtfb(audits) {
  try {
    const lcpPhases = audits['lcp-phases-insight']?.details?.items;
    if (!lcpPhases || !Array.isArray(lcpPhases)) return '';
    for (const block of lcpPhases) {
      if (Array.isArray(block.items)) {
        const ttfbItem = block.items.find(i => i.phase === 'timeToFirstByte');
        if (ttfbItem?.duration) {
          return (ttfbItem.duration / 1000).toFixed(1); // мс → сек
        }
      }
    }
    return '';
  } catch {
    return '';
  }
}

function extractTbt(val) {
  if (!val || typeof val.numericValue !== 'number') return '';
  return Math.round(val.numericValue); // например: 168.489 → 168
}

function extractCls(val) {
  if (!val || typeof val.numericValue !== 'number') return '';
  return val.numericValue.toFixed(2); // например: 0.661356 → "0.66"
}

function extractMetrics(jsonPath) {
  const content = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));
  const audits = content.audits || {};
  const categories = content.categories || {};
  const pageUrl = content.finalUrl || '';
  const id = resolveId(pageUrl);
  const project = resolveProject(pageUrl);
  const filename = path.basename(jsonPath).replace(/\.report\.json$/, '');
  const parts = filename.split('_');
  const platform = parts.pop();

  return {
    id,
    entity,
    // page: pageUrl,
    platform,
    role,
    project,
    environment,
    entity,
    timestamp: content.fetchTime || '',
    fcp: extractSeconds(audits['first-contentful-paint']),
    lcp: extractSeconds(audits['largest-contentful-paint']),
    tti: extractSeconds(audits['interactive']),
    si: extractSeconds(audits['speed-index']),
    tbt: extractTbt(audits['total-blocking-time']),
    cls: extractCls(audits['cumulative-layout-shift']),
    performance: categories['performance']?.score ? Math.round(categories['performance'].score * 100) : 0,
    ttfb: extractTtfb(audits)
  };
}

function walkJsonReports(baseDir) {
  const entries = fs.readdirSync(baseDir);
  for (const entry of entries) {
    const fullPath = path.join(baseDir, entry);
    if (fs.statSync(fullPath).isDirectory()) {
      walkJsonReports(fullPath);
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
  process.exit(0);
}

// Создаём Excel-файл с ExcelJS
const workbook = new ExcelJS.Workbook();
const worksheet = workbook.addWorksheet('Lighthouse Results');

// Заголовки
const headers = [
  'timestamp',
  'project',
  'environment',
  'id',
  'platform',
  'role',
  'entity',
  'fcp',
  'lcp',
  'tti',
  'si',
  'tbt',
  'cls',
  'ttfb',
  'performance'
];

// Установка колонок с заголовками
worksheet.columns = headers.map(header => ({
  header,
  key: header,
  width: header.length + 2 // временная ширина
}));

// Добавляем строки
result.forEach(row => {
  worksheet.addRow(row);
});

// Жирный шрифт для заголовков
worksheet.getRow(1).font = { bold: true };

// Автоширина
worksheet.columns.forEach(column => {
  let maxLength = column.header.length;
  column.eachCell({ includeEmpty: true }, cell => {
    const len = String(cell.value || '').length;
    if (len > maxLength) maxLength = len;
  });
  column.width = maxLength + 2;
});

// Создание папки для xlsx
const xlsxDir = path.join(targetDir, 'xlsx');
if (!fs.existsSync(xlsxDir)) fs.mkdirSync(xlsxDir);

// Сохранение
const outputFile = path.join(xlsxDir, `competitors_lighthouse_report_${reportFolderName}.xlsx`);
workbook.xlsx.writeFile(outputFile).then(() => {
  console.log(`📊 XLSX отчет сохранён: ${outputFile}`);
});
