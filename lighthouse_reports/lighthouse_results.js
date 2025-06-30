const fs = require('fs');
const path = require('path');
const xlsx = require('xlsx');
const ExcelJS = require('exceljs');
const today = new Date();
const day = String(today.getDate()).padStart(2, '0');
const month = String(today.getMonth() + 1).padStart(2, '0');
const year = String(today.getFullYear()).slice(-2);
const reportFolderName = `${day}.${month}.${year}`;

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
  if (pageUrl === 'http://localhost:3000/') return 'main';
  //Карточка товара
  if (pageUrl.startsWith('http://localhost:3000/product')) return 'card';
  //Каталог 2-й уровень
  if (pageUrl.startsWith('http://localhost:3000/catalog/elektroinstrument-ctg-29290-29342/')) return 'catalogSecond';
  if (pageUrl.startsWith('http://localhost:3000/catalog/pribory-ucheta-i-kontrolya-ctg-29189-30568/')) return 'catalogSecond';
  if (pageUrl.startsWith('http://localhost:3000/catalog/oboi-ctg-29494-29512/')) return 'catalogSecond';
  //Каталог 3-й уровень
  if (pageUrl.startsWith('http://localhost:3000/catalog/plitka-dlya-vannoy-ctg-29360-29384-30292/')) return 'catalogThird';
  if (pageUrl.startsWith('http://localhost:3000/catalog/gipsokarton-ctg-29116-29129-29130/')) return 'catalogThird';
  if (pageUrl.startsWith('http://localhost:3000/catalog/lampy-e27-ctg-29670-29674-29682/')) return 'catalogThird';
  //Поиск
  if (pageUrl.startsWith('http://localhost:3000/search/?query=%D0%BA%D1%80%D0%B0%D0%BD%D1%8B')) return 'search';
  if (pageUrl.startsWith('http://localhost:3000/search/?query=%D1%81%D0%BA%D0%BE%D1%82%D1%87&sectionIds=30654,30656,32003&set_filter=y&arrFilter_5279_2644469059=Y&arrFilter_5279_2671857292=Y&arrFilter_5279_1439224407=Y')) return 'search';
  return '';
}

function resolveEntity(pageUrl) {
  //Карточка товара
  if (pageUrl.includes('/ogurets')) return 'simple';
  if (pageUrl.includes('/samorezy')) return 'tp';
  if (pageUrl.includes('/oboi-flizelinovye')) return 'visual';
  if (pageUrl.includes('/dver-mezhkomnatnaya')) return 'set';
  if (pageUrl.includes('/video')) return 'video'; // если появится такой паттерн
  //Каталог 2-й уровень
  if (pageUrl.includes('/elektroinstrument-ctg-29290-29342')) return 'full';
  if (pageUrl.includes('/pribory-ucheta-i-kontrolya-ctg-29189-30568/')) return 'usual';
  if (pageUrl.includes('/oboi-ctg-29494-29512/')) return 'products';
  //Каталог 3-й уровень
  if (pageUrl.includes('/plitka-dlya-vannoy-ctg-29360-29384-30292')) return 'collections';
  if (pageUrl.includes('/gipsokarton-ctg-29116-29129-29130/')) return 'usual';
  if (pageUrl.includes('/lampy-e27-ctg-29670-29674-29682/')) return 'full';
  //Поиск
  if (pageUrl.includes('/?query=%D0%BA%D1%80%D0%B0%D0%BD%D1%8B')) return 'usual';
  if (pageUrl.includes('/?query=%D1%81%D0%BA%D0%BE%D1%82%D1%87&sectionIds=30654,30656,32003&set_filter=y&arrFilter_5279_2644469059=Y&arrFilter_5279_2671857292=Y&arrFilter_5279_1439224407=Y')) return 'filters';
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
  let entity = resolveEntity(pageUrl);
  if (id === 'main') {
    entity = null;
  }
  const filename = path.basename(jsonPath).replace(/\.report\.json$/, '');
  const parts = filename.split('_');
  const platform = parts[parts.length - 2];
  const role = parts[parts.length - 1];

  return {
    id,
    entity,
    // page: pageUrl,
    platform,
    role,
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
const outputFile = path.join(xlsxDir, `lighthouse_report_${reportFolderName}.xlsx`);
workbook.xlsx.writeFile(outputFile).then(() => {
  console.log(`📊 XLSX отчет сохранён: ${outputFile}`);
});
