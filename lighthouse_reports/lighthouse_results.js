const fs = require('fs');
const path = require('path');
const xlsx = require('xlsx');
const ExcelJS = require('exceljs');
const today = new Date();
const day = String(today.getDate()).padStart(2, '0');
const month = String(today.getMonth() + 1).padStart(2, '0');
const year = String(today.getFullYear()).slice(-2);
const project = 'baucenter';

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
const targetDir = path.join(reportsRootDir, 'baucenter', 'logs');

if (!fs.existsSync(targetDir)) {
  console.error(`❌ Папка с отчетами за сегодня не найдена: ${targetDir}`);
  process.exit(1);
}

console.log(`📂 Чтение отчетов из: ${targetDir}`);

const result = [];

function resolveId(pageUrl) {
  //Главная
  if (pageUrl === 'http://localhost:3000/') return 'main';
  if (pageUrl === 'https://baucenter.ru/') return 'main';
  //Карточка товара
  if (pageUrl.includes('/product')) return 'card';
  //Каталог 2-й уровень
  if (pageUrl.includes('/elektroinstrument-ctg-29290-29342/')) return 'catalogSecond';
  if (pageUrl.includes('/pribory-ucheta-i-kontrolya-ctg-29189-30568/')) return 'catalogSecond';
  if (pageUrl.includes('/oboi-ctg-29494-29512/')) return 'catalogSecond';
  //Каталог 3-й уровень
  if (pageUrl.includes('/plitka-dlya-vannoy-ctg-29360-29384-30292/')) return 'catalogThird';
  if (pageUrl.includes('/gipsokarton-ctg-29116-29129-29130/')) return 'catalogThird';
  if (pageUrl.includes('/lampy-e27-ctg-29670-29674-29682/')) return 'catalogThird';
  //Поиск
  if (pageUrl.includes('/?query=%D0%BA%D1%80%D0%B0%D0%BD%D1%8B')) return 'search';
  if (pageUrl.includes('/?query=%D1%81%D0%BA%D0%BE%D1%82%D1%87&sectionIds=30654,30656,32003&set_filter=y&arrFilter_5279_2644469059=Y&arrFilter_5279_2671857292=Y&arrFilter_5279_1439224407=Y')) return 'search';
  //Списки покупок
  if (pageUrl.includes('/personal/list/')) return 'lists';
  //Детали списка покупок
  if (pageUrl.includes('/personal/list/5865373/')) return 'listDetail';
  if (pageUrl.includes('/personal/list/5865817/')) return 'listDetail';
  //Корзина
  if (pageUrl.includes('/personal/cart/')) return 'cart';
  //Оформление заказа
  if (pageUrl.includes('/personal/order/')) return 'order';
  return '';
}

function resolveEntity(pageUrl, role) {
  //Карточка товара
  if (pageUrl.includes('/ogurets')) return 'simple';
  if (pageUrl.includes('/samorezy')) return 'tp';
  if (pageUrl.includes('/oboi-flizelinovye')) return 'visual';
  if (pageUrl.includes('/dver-mezhkomnatnaya')) return 'set';
  if (pageUrl.includes('/shtukaturka-dekorativnaya-dufa-creative-microcement')) return 'video';
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
  //Списки покупок
  if (pageUrl.includes('/personal/list/')) {
    return role === 'commonKld' ? 'usual'
        : role === 'profiMsk' ? 'full'
            : '';
  }
  //Детали списка покупок
  if (pageUrl.includes('/personal/list/5865373/')) return 'usual';
  if (pageUrl.includes('/personal/list/5865817/')) return 'full';
  return '';
  //Корзина
  if (pageUrl.includes('/personal/cart/')) {
    if (role === 'commonKld') return 'usual';
    if (role === 'profiMsk') return 'full';
    if (['guestKld', 'guestMsk'].includes(role)) return 'empty';
    return '';
  }
  //Оформление заказа
  if (pageUrl.includes('/personal/order/')) {
    if (role === 'commonKld') return 'usual';
    if (role === 'profiMsk') return 'full';
    return '';
  }
  return '';
}

function resolveEnvironment(pageUrl) {
  if(pageUrl.includes('localhost:3000')) return 'local';
  if(pageUrl.includes('baucenter.ru')) return 'non-local';
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
  const environment = resolveEnvironment(pageUrl);
  const filename = path.basename(jsonPath).replace(/\.report\.json$/, '');
  const parts = filename.split('_');
  const platform = parts[parts.length - 2];
  const role = parts[parts.length - 1];

  if (id === 'main') {
    entity = null;
  } else if (pageUrl.includes('/personal/list/')) {
    entity =
        role === 'profiMsk' ? 'full' : 
            role === 'commonKld' ? 'usual' : '';
  } else if (pageUrl.includes('/personal/cart/')) {
    entity =
        role === 'profiMsk' ? 'full' : 
            role === 'commonKld' ? 'usual' :
            ['guestKld', 'guestMsk'].includes(role) ? 'empty' : '';
  } else if (pageUrl.includes('/personal/order/')) {
    entity =
        role === 'profiMsk' ? 'full' : 
            role === 'commonKld' ? 'usual' : '';
  }

  return {
    timestamp: content.fetchTime || '',
    project,
    // page: pageUrl,
    environment,
    id,
    platform,
    role,
    entity,
    fcp: extractSeconds(audits['first-contentful-paint']),
    lcp: extractSeconds(audits['largest-contentful-paint']),
    tti: extractSeconds(audits['interactive']),
    si: extractSeconds(audits['speed-index']),
    tbt: extractTbt(audits['total-blocking-time']),
    cls: extractCls(audits['cumulative-layout-shift']),
    ttfb: extractTtfb(audits),
    performance: categories['performance']?.score ? Math.round(categories['performance'].score * 100) : 0,
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

// Создание папки для xlsx если её нет
const xlsxDir = path.join(targetDir, 'xlsx');
if (!fs.existsSync(xlsxDir)) fs.mkdirSync(xlsxDir);

const outputFile = path.join(xlsxDir, `baucenter_lighthouse_report.xlsx`);

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

let existingRows = [];

// Если файл существует, читаем существующие данные
if (fs.existsSync(outputFile)) {
  const existingWorkbook = new ExcelJS.Workbook();
  existingWorkbook.xlsx.readFile(outputFile)
    .then(() => {
      const existingSheet = existingWorkbook.getWorksheet('Lighthouse Results');
      existingSheet.eachRow((row, rowNumber) => {
        if (rowNumber > 1) { // Пропускаем заголовки
          const rowData = {};
          row.eachCell((cell, colNumber) => {
            rowData[headers[colNumber - 1]] = cell.value;
          });
          existingRows.push(rowData);
        }
      });
      
      // Добавляем новые данные
      existingRows = existingRows.concat(result);
      
      // Создаем новый лист
      const newSheet = workbook.addWorksheet('Lighthouse Results');
      
      // Установка колонок с заголовками
      newSheet.columns = headers.map(header => ({
        header,
        key: header,
        width: header.length + 2
      }));

      // Добавляем все строки
      existingRows.forEach(row => {
        newSheet.addRow(row);
      });

      // Жирный шрифт для заголовков
      newSheet.getRow(1).font = { bold: true };

      // Автоширина
      newSheet.columns.forEach(column => {
        let maxLength = column.header.length;
        column.eachCell({ includeEmpty: true }, cell => {
          const len = String(cell.value || '').length;
          if (len > maxLength) maxLength = len;
        });
        column.width = maxLength + 2;
      });

      // Сохранение
      return workbook.xlsx.writeFile(outputFile);
    })
    .then(() => {
      console.log(`📊 XLSX отчет обновлён: ${outputFile}`);
    });
} else {
  // Если файл не существует, создаем новый
  const newSheet = workbook.addWorksheet('Lighthouse Results');
  
  // Установка колонок с заголовками
  newSheet.columns = headers.map(header => ({
    header,
    key: header,
    width: header.length + 2
  }));

  // Добавляем новые строки
  result.forEach(row => {
    newSheet.addRow(row);
  });

  // Жирный шрифт для заголовков
  newSheet.getRow(1).font = { bold: true };

  // Автоширина
  newSheet.columns.forEach(column => {
    let maxLength = column.header.length;
    column.eachCell({ includeEmpty: true }, cell => {
      const len = String(cell.value || '').length;
      if (len > maxLength) maxLength = len;
    });
    column.width = maxLength + 2;
  });

  // Сохранение
  workbook.xlsx.writeFile(outputFile)
    .then(() => {
      console.log(`📊 XLSX отчет создан: ${outputFile}`);
    });
}
