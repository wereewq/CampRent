const http = require('http');
const url = require('url');

const args = process.argv.slice(2);
let port = 8090;
let allowedOrigin = 'http://localhost:5555';

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--port' && args[i + 1]) port = parseInt(args[i + 1], 10);
  if (args[i] === '--origin' && args[i + 1]) allowedOrigin = args[i + 1];
}

let db = {
  categories: [
    { id: 1, name: 'Водный спорт', description: 'SUP-борды, весла, каяки', icon: 'water', deletedAt: null },
    { id: 2, name: 'Кемпинг и бивак', description: 'Палатки, спальники, горелки', icon: 'camping', deletedAt: null },
    { id: 3, name: 'Велопрокат', description: 'Горные и гравийные велосипеды', icon: 'bike', deletedAt: null },
  ],
  equipments: [
    { id: 1, categoryId: 1, name: 'SUP-борд Gladiator Pro 10.6', brand: 'Gladiator', dailyPrice: 1500, deposit: 5000, status: 'available', deletedAt: null },
    { id: 2, categoryId: 1, name: 'SUP-борд Red Paddle Ride 10.8', brand: 'Red Paddle', dailyPrice: 2200, deposit: 8000, status: 'available', deletedAt: null },
    { id: 3, categoryId: 2, name: 'Палатка кемпинговая 3-местная', brand: 'Tramp', dailyPrice: 900, deposit: 3000, status: 'available', deletedAt: null },
    { id: 4, categoryId: 3, name: 'Велосипед горный Trail 29', brand: 'Cannondale', dailyPrice: 1800, deposit: 6000, status: 'available', deletedAt: null },
  ],
  techPassports: [
    { id: 1, equipmentId: 1, serialNumber: 'SN-GLAD-2025-01', purchaseDate: '2025-04-10', maxLoadKg: 130, wearPercent: 15, deletedAt: null },
    { id: 2, equipmentId: 2, serialNumber: 'SN-RED-2024-99', purchaseDate: '2024-06-15', maxLoadKg: 150, wearPercent: 45, deletedAt: null },
    { id: 3, equipmentId: 3, serialNumber: 'SN-TRMP-3P-04', purchaseDate: '2025-02-01', maxLoadKg: 0, wearPercent: 5, deletedAt: null },
    { id: 4, equipmentId: 4, serialNumber: 'SN-CANN-TR-88', purchaseDate: '2025-05-20', maxLoadKg: 120, wearPercent: 30, deletedAt: null },
  ],
  customers: [
    { id: 1, fullName: 'Иван Сергеев', phone: '+79991112233', email: 'ivan@example.com', passportNumber: '4512 889900', deletedAt: null },
    { id: 2, fullName: 'Мария Ветрова', phone: '+79992223344', email: 'maria@example.com', passportNumber: '4515 112233', deletedAt: null },
  ],
  accessories: [
    { id: 1, categoryId: 1, name: 'Спасжилет страховочный L', dailyPrice: 200, inStock: 15, deletedAt: null },
    { id: 2, categoryId: 1, name: 'Гермомешок 20L', dailyPrice: 150, inStock: 20, deletedAt: null },
    { id: 3, categoryId: 2, name: 'Горелка газовая туристическая', dailyPrice: 250, inStock: 8, deletedAt: null },
    { id: 4, categoryId: 3, name: 'Шлем защитный M', dailyPrice: 150, inStock: 10, deletedAt: null },
  ],
  rentalOrders: [
    {
      id: 1,
      customerId: 1,
      equipmentId: 1,
      startDate: '2026-06-01',
      endDate: '2026-06-04',
      totalDays: 3,
      dailyRate: 1500,
      baseCost: 4500,
      discountPercent: 10,
      depositAmount: 5000,
      totalAmount: 9050,
      status: 'active',
      deletedAt: null
    }
  ],
  orderAccessories: [
    { id: 1, orderId: 1, accessoryId: 1, quantity: 1, dailyPrice: 200 },
    { id: 2, orderId: 1, accessoryId: 2, quantity: 2, dailyPrice: 150 }
  ],
  inspectionActs: [
    {
      id: 1,
      orderId: 1,
      inspectorName: 'Дежурный инструктор',
      inspectionDate: '2026-06-04',
      conditionStatus: 'Идеальное',
      penaltyAmount: 0,
      notes: 'Снаряжение осмотрено, дефектов нет',
      deletedAt: null
    }
  ],
  users: [
    { id: 1, username: 'admin', password: 'Password123!', fullName: 'Управляющий CampRent', role: 'admin' },
    { id: 2, username: 'instructor', password: 'Password123!', fullName: 'Дежурный Инструктор', role: 'librarian' },
    { id: 3, username: 'customer', password: 'Password123!', fullName: 'Полина (Клиент)', role: 'reader' },
  ]
};

let nextId = {
  categories: 4,
  equipments: 5,
  techPassports: 5,
  customers: 3,
  accessories: 5,
  rentalOrders: 2,
  orderAccessories: 3,
  inspectionActs: 2,
  users: 4
};

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
  res.end(JSON.stringify(data, null, 2));
}

function hasDateOverlap(equipmentId, newStart, newEnd) {
  const start = new Date(newStart);
  const end = new Date(newEnd);
  return db.rentalOrders.some(order => {
    if (order.deletedAt || order.equipmentId !== equipmentId || order.status === 'completed' || order.status === 'cancelled') return false;
    const oStart = new Date(order.startDate);
    const oEnd = new Date(order.endDate);
    return (start <= oEnd && end >= oStart);
  });
}

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;
  const q = parsedUrl.query;

  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': allowedOrigin,
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    });
    return res.end();
  }

  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', () => {
    let data = {};
    if (body) {
      try { data = JSON.parse(body); } catch (_) {}
    }

    if (path === '/' || path === '/api' || path === '/api/') {
      return sendJson(res, 200, { status: 'ok', service: 'CampRent PocketBase API' });
    }

    // AUTH REGISTER
    if ((path === '/api/auth/register' || path === '/auth/register') && req.method === 'POST') {
      const { username, password, fullName, role } = data;
      if (!username || !password) {
        return sendJson(res, 422, { message: 'Укажите логин и пароль' });
      }
      const existing = db.users.find(u => u.username.toLowerCase() === username.trim().toLowerCase());
      if (existing) {
        return sendJson(res, 409, { message: 'Пользователь с таким логином уже зарегистрирован' });
      }

      const assignedRole = role || 'reader';
      const newUser = {
        id: nextId.users++,
        username: username.trim(),
        password,
        fullName: (fullName && fullName.trim().length > 0) ? fullName.trim() : username.trim(),
        role: assignedRole,
      };
      db.users.push(newUser);

      return sendJson(res, 201, {
        accessToken: `camp-jwt-${encodeURIComponent(newUser.username)}-${newUser.role}`,
        refreshToken: `camp-refresh-${encodeURIComponent(newUser.username)}`,
        user: { id: newUser.id, username: newUser.username, fullName: newUser.fullName, role: newUser.role }
      });
    }

    // AUTH LOGIN
    if ((path === '/api/auth/login' || path === '/auth/login') && req.method === 'POST') {
      const user = db.users.find(u => u.username === data.username && u.password === data.password);
      if (!user) return sendJson(res, 401, { message: 'Неверный логин или пароль' });
      return sendJson(res, 200, {
        accessToken: `camp-jwt-${encodeURIComponent(user.username)}-${user.role}`,
        refreshToken: `camp-refresh-${encodeURIComponent(user.username)}`,
        user: { id: user.id, username: user.username, fullName: user.fullName, role: user.role }
      });
    }

    const authHeader = req.headers['authorization'] || '';
    let userRole = 'reader';
    let authUsername = null;
    if (authHeader.includes('camp-jwt-')) {
      const token = authHeader.replace(/^Bearer\s+/, '').replace('camp-jwt-', '');
      const lastDash = token.lastIndexOf('-');
      if (lastDash !== -1) {
        authUsername = decodeURIComponent(token.substring(0, lastDash));
        userRole = token.substring(lastDash + 1);
      }
    }

    // AUTH ME
    if (path === '/api/auth/me' || path === '/auth/me') {
      if (!authUsername) return sendJson(res, 401, { message: 'Сессия истекла' });
      const user = db.users.find(u => u.username === authUsername);
      if (!user) return sendJson(res, 401, { message: 'Пользователь не найден' });
      return sendJson(res, 200, user);
    }

    // AUTH REFRESH
    if (path === '/api/auth/refresh' || path === '/auth/refresh') {
      return sendJson(res, 200, {
        accessToken: `camp-jwt-refreshed`,
        refreshToken: `camp-refresh-new`,
        user: db.users[0]
      });
    }

    // Collections routing
    const cleanPath = path
      .replace(/^\/api\/collections\//, '')
      .replace(/^\/collections\//, '')
      .replace(/^\/api\//, '')
      .replace(/^\//, '');

    const parts = cleanPath.split('/').filter(Boolean);
    const collection = parts[0] === 'records' ? parts[1] : parts[0];
    const isRecords = parts.includes('records');
    const id = (isRecords ? parts[parts.indexOf('records') + 1] : parts[1]) ? parseInt(isRecords ? parts[parts.indexOf('records') + 1] : parts[1], 10) : null;
    const isRestore = cleanPath.includes('/restore');

    // RESTORE
    if (isRestore && req.method === 'POST') {
      const restoreId = parseInt(parts[isRecords ? parts.indexOf('records') + 1 : 1], 10);
      const item = db.equipments.find(e => e.id === restoreId);
      if (item) {
        item.deletedAt = null;
        return sendJson(res, 200, item);
      }
      return sendJson(res, 404, { message: 'Запись не найдена' });
    }

    if (!db[collection]) {
      return sendJson(res, 404, { message: `Коллекция ${collection} не найдена` });
    }

    // Role restrictions: client cannot edit or delete
    if ((req.method === 'DELETE' || req.method === 'PUT' || (req.method === 'POST' && collection === 'equipments')) && userRole === 'reader') {
      return sendJson(res, 403, { message: 'Серверный отказ (403): клиент не имеет прав на редактирование каталога' });
    }

    // CREATE INSPECTION ACT
    if (collection === 'inspectionActs' && req.method === 'POST') {
      const act = {
        id: nextId.inspectionActs++,
        orderId: data.orderId,
        inspectorName: data.inspectorName || 'Дежурный Инструктор',
        inspectionDate: data.inspectionDate || new Date().toISOString().substring(0, 10),
        conditionStatus: data.conditionStatus || 'Идеальное',
        penaltyAmount: Number(data.penaltyAmount) || 0,
        notes: data.notes || '',
        deletedAt: null
      };
      db.inspectionActs.push(act);

      const order = db.rentalOrders.find(o => o.id === data.orderId);
      if (order) order.status = 'completed';

      return sendJson(res, 201, act);
    }

    // CREATE RENTAL ORDER
    if (collection === 'rentalOrders' && req.method === 'POST') {
      const { equipmentId, startDate, endDate, dailyRate, depositAmount, accessories = [] } = data;
      if (!equipmentId || !startDate || !endDate) {
        return sendJson(res, 422, { message: 'Ошибка валидации', errors: { dates: 'Укажите период' } });
      }

      if (hasDateOverlap(equipmentId, startDate, endDate)) {
        return sendJson(res, 409, { message: 'Данный инвентарь уже забронирован на выбранные даты!' });
      }

      const s = new Date(startDate);
      const e = new Date(endDate);
      const days = Math.max(1, Math.ceil(Math.abs(e - s) / (1000 * 60 * 60 * 24)));
      const baseCost = days * (dailyRate || 1500);
      const discount = days >= 3 ? 10 : 0;
      const discountedCost = baseCost * (1 - discount / 100);

      let accessoriesCost = 0;
      for (const a of accessories) {
        accessoriesCost += ((a.dailyPrice || 0) * (a.quantity || 1) * days);
      }

      const totalAmount = discountedCost + accessoriesCost + (depositAmount || 0);

      const newOrder = {
        id: nextId.rentalOrders++,
        customerId: data.customerId || 1,
        equipmentId,
        startDate,
        endDate,
        totalDays: days,
        dailyRate: dailyRate || 1500,
        baseCost,
        discountPercent: discount,
        depositAmount: depositAmount || 0,
        totalAmount,
        status: 'active',
        deletedAt: null
      };
      db.rentalOrders.push(newOrder);

      for (const a of accessories) {
        db.orderAccessories.push({
          id: nextId.orderAccessories++,
          orderId: newOrder.id,
          accessoryId: a.accessoryId,
          quantity: a.quantity || 1,
          dailyPrice: a.dailyPrice || 0
        });
      }

      return sendJson(res, 201, newOrder);
    }

    // CREATE RECORD (EQUIPMENT, ETC)
    if (req.method === 'POST' && !id) {
      const newItem = {
        id: nextId[collection]++,
        ...data,
        dailyPrice: Number(data.dailyPrice) || 0,
        deposit: Number(data.deposit) || 0,
        categoryId: Number(data.categoryId) || 1,
        deletedAt: null
      };
      db[collection].push(newItem);

      // Auto-create 1:1 TechPassport for equipments
      if (collection === 'equipments') {
        const pass = {
          id: nextId.techPassports++,
          equipmentId: newItem.id,
          serialNumber: data.serialNumber || `SN-CAMP-2026-${String(newItem.id).padStart(2, '0')}`,
          purchaseDate: data.purchaseDate || new Date().toISOString().substring(0, 10),
          maxLoadKg: Number(data.maxLoadKg) || 120,
          wearPercent: Number(data.wearPercent) || 0,
          deletedAt: null
        };
        db.techPassports.push(pass);
      }

      return sendJson(res, 201, newItem);
    }

    // UPDATE RECORD (PUT)
    if (req.method === 'PUT' && id) {
      const index = db[collection].findIndex(x => x.id === id);
      if (index === -1) return sendJson(res, 404, { message: 'Запись не найдена' });

      db[collection][index] = {
        ...db[collection][index],
        ...data,
        id,
        dailyPrice: data.dailyPrice !== undefined ? Number(data.dailyPrice) : db[collection][index].dailyPrice,
        deposit: data.deposit !== undefined ? Number(data.deposit) : db[collection][index].deposit,
        categoryId: data.categoryId !== undefined ? Number(data.categoryId) : db[collection][index].categoryId,
      };

      if (collection === 'equipments') {
        let pass = db.techPassports.find(p => p.equipmentId === id);
        if (pass) {
          if (data.serialNumber) pass.serialNumber = data.serialNumber;
          if (data.wearPercent !== undefined) pass.wearPercent = Number(data.wearPercent);
          if (data.maxLoadKg !== undefined) pass.maxLoadKg = Number(data.maxLoadKg);
        }
      }

      return sendJson(res, 200, db[collection][index]);
    }

    // GET Records
    if (req.method === 'GET' && !id) {
      let list = db[collection];

      if (q.deleted === 'true') {
        list = list.filter(x => x.deletedAt !== null);
      } else {
        list = list.filter(x => x.deletedAt === null);
      }

      if (q.search) {
        const needle = q.search.trim().toLowerCase();
        list = list.filter(x => (x.name && x.name.toLowerCase().includes(needle)) || (x.serialNumber && x.serialNumber.toLowerCase().includes(needle)));
      }

      return sendJson(res, 200, {
        page: 1,
        perPage: list.length,
        totalItems: list.length,
        totalPages: 1,
        items: list
      });
    }

    // GET by ID
    if (req.method === 'GET' && id) {
      const item = db[collection].find(x => x.id === id);
      if (!item) return sendJson(res, 404, { message: 'Запись не найдена' });
      return sendJson(res, 200, item);
    }

    // DELETE (Soft & Hard)
    if (req.method === 'DELETE' && id) {
      const idx = db[collection].findIndex(x => x.id === id);
      if (idx === -1) return sendJson(res, 404, { message: 'Не найдено' });

      if (q.hard === 'true') {
        db[collection].splice(idx, 1);
      } else {
        db[collection][idx].deletedAt = new Date().toISOString();
      }
      return sendJson(res, 200, { message: 'Успешно удалено' });
    }

    sendJson(res, 405, { message: 'Метод не поддерживается' });
  });
});

server.listen(port, () => {
  console.log(`[CampRent API] Сервер запущен: http://localhost:${port}/api`);
});
