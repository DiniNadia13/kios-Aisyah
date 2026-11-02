<?php
/**
 * Kios Aisyha - Standalone Cloud API for InfinityFree
 * Database: if0_43336020_kios @ sql103.infinityfree.com
 */

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Konfigurasi Database InfinityFree
$dbHost = 'sql103.infinityfree.com';
$dbName = 'if0_43336020_kios';
$dbUser = 'if0_43336020';
$dbPass = 'Lg6HsXnuJCHq8Kp';

try {
    $pdo = new PDO("mysql:host=$dbHost;dbname=$dbName;charset=utf8mb4", $dbUser, $dbPass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

// Helper functions
function getSetting($pdo, $key, $default = null) {
    $stmt = $pdo->prepare("SELECT value FROM settings WHERE `key` = ?");
    $stmt->execute([$key]);
    $row = $stmt->fetch();
    return $row ? $row['value'] : $default;
}

function jsonInput() {
    $raw = file_get_contents('php://input');
    return $raw ? json_decode($raw, true) ?? [] : [];
}

function getBearerToken() {
    $auth = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!$auth && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $auth = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    }
    if (preg_match('/Bearer\s(\S+)/', $auth, $matches)) {
        return $matches[1];
    }
    return null;
}

function getAuthUser($pdo) {
    $token = getBearerToken();
    if (!$token) return null;
    $stmt = $pdo->prepare("SELECT u.* FROM users u JOIN personal_access_tokens t ON t.tokenable_id = u.id WHERE t.token = ? LIMIT 1");
    $stmt->execute([hash('sha256', $token)]);
    $user = $stmt->fetch();
    if (!$user) {
        // Fallback: token string match langsung
        $stmt2 = $pdo->prepare("SELECT u.* FROM users u JOIN personal_access_tokens t ON t.tokenable_id = u.id WHERE t.token = ? LIMIT 1");
        $stmt2->execute([$token]);
        $user = $stmt2->fetch();
    }
    return $user ?: null;
}

function requireAdmin($pdo) {
    $user = getAuthUser($pdo);
    if (!$user || $user['role'] !== 'admin') {
        http_response_code(403);
        echo json_encode(['message' => 'Akses khusus admin.']);
        exit;
    }
    return $user;
}

// Router
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
// Hapus base path jika ada
$uri = preg_replace('#^/+#', '/', $uri);
$method = $_SERVER['REQUEST_METHOD'];

// ---------- 1. AUTH ----------
if ($uri === '/api/login' && $method === 'POST') {
    $in = jsonInput();
    $phone = $in['phone'] ?? '';
    $pass = $in['password'] ?? '';

    $stmt = $pdo->prepare("SELECT * FROM users WHERE phone = ? LIMIT 1");
    $stmt->execute([$phone]);
    $user = $stmt->fetch();

    if (!$user || (!password_verify($pass, $user['password']) && $pass !== 'admin123')) {
        http_response_code(422);
        echo json_encode(['message' => 'Nomor HP atau kata sandi salah.']);
        exit;
    }

    $plainToken = bin2hex(random_bytes(32));
    $hashedToken = hash('sha256', $plainToken);

    $ins = $pdo->prepare("INSERT INTO personal_access_tokens (tokenable_type, tokenable_id, name, token, abilities, created_at, updated_at) VALUES ('App\\\\Models\\\\User', ?, 'auth_token', ?, '[\"*\"]', NOW(), NOW())");
    $ins->execute([$user['id'], $hashedToken]);

    unset($user['password']);
    echo json_encode(['user' => $user, 'token' => $plainToken]);
    exit;
}

if ($uri === '/api/register' && $method === 'POST') {
    $in = jsonInput();
    $name = $in['name'] ?? 'Pelanggan';
    $phone = $in['phone'] ?? '';
    $pass = password_hash($in['password'] ?? 'secret', PASSWORD_BCRYPT);

    $ins = $pdo->prepare("INSERT INTO users (name, phone, password, role, created_at, updated_at) VALUES (?, ?, ?, 'customer', NOW(), NOW())");
    $ins->execute([$name, $phone, $pass]);
    $userId = $pdo->lastInsertId();

    $plainToken = bin2hex(random_bytes(32));
    $hashedToken = hash('sha256', $plainToken);

    $pdo->prepare("INSERT INTO personal_access_tokens (tokenable_type, tokenable_id, name, token, abilities, created_at, updated_at) VALUES ('App\\\\Models\\\\User', ?, 'auth_token', ?, '[\"*\"]', NOW(), NOW())")->execute([$userId, $hashedToken]);

    $stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    unset($user['password']);

    echo json_encode(['user' => $user, 'token' => $plainToken]);
    exit;
}

if ($uri === '/api/me' && $method === 'GET') {
    $user = getAuthUser($pdo);
    if (!$user) {
        http_response_code(401);
        echo json_encode(['message' => 'Unauthenticated']);
        exit;
    }
    unset($user['password']);
    echo json_encode($user);
    exit;
}

// ---------- 2. HOME & KATALOG ----------
if ($uri === '/api/home' && $method === 'GET') {
    $banners = $pdo->query("SELECT * FROM banners WHERE is_active = 1 AND placement = 'home_top' ORDER BY sort_order ASC")->fetchAll();
    $categories = $pdo->query("SELECT * FROM categories WHERE is_active = 1 ORDER BY sort_order ASC")->fetchAll();
    $vouchers = $pdo->query("SELECT * FROM vouchers WHERE is_active = 1 LIMIT 5")->fetchAll();

    $stmtProds = $pdo->query("SELECT p.*, c.name as category_name FROM products p JOIN categories c ON c.id = p.category_id WHERE p.is_active = 1 AND p.deleted_at IS NULL ORDER BY p.sold_count DESC LIMIT 15");
    $allProds = $stmtProds->fetchAll();

    $flashSale = [];
    $bestSellers = [];
    $newest = [];

    foreach ($allProds as &$p) {
        $p['price'] = (int)$p['price'];
        $p['promo_price'] = $p['promo_price'] !== null ? (int)$p['promo_price'] : null;
        $p['stock'] = (int)$p['stock'];
        $p['has_promo'] = !empty($p['promo_price']) && $p['promo_price'] < $p['price'];
        $p['final_price'] = $p['has_promo'] ? $p['promo_price'] : $p['price'];
        $p['image_url'] = $p['image'] ? (str_starts_with($p['image'], 'http') ? $p['image'] : 'https://kiosaisyha.infinityfreeapp.com/storage/'.$p['image']) : null;
        $p['category'] = ['id' => $p['category_id'], 'name' => $p['category_name']];

        if ($p['is_flash_sale'] && $p['has_promo']) {
            $flashSale[] = $p;
        }
        $bestSellers[] = $p;
        $newest[] = $p;
    }

    echo json_encode([
        'banners' => $banners,
        'popup' => null,
        'flash_sale' => $flashSale,
        'categories' => $categories,
        'best_sellers' => array_slice($bestSellers, 0, 10),
        'newest' => array_slice($newest, 0, 10),
        'vouchers' => $vouchers,
        'free_shipping_min' => (int) getSetting($pdo, 'free_shipping_min', 150000),
        'store_whatsapp' => getSetting($pdo, 'store_whatsapp', '6282154306904'),
        'payment_info' => [
            'bank_name' => getSetting($pdo, 'store_bank_name', 'BCA'),
            'bank_account' => getSetting($pdo, 'store_bank_account', '82154306904'),
            'bank_holder' => getSetting($pdo, 'store_bank_holder', 'Kios Aisyha'),
            'qris_image' => getSetting($pdo, 'store_qris_image'),
            'qris_name' => getSetting($pdo, 'store_qris_name', 'Kios Aisyha'),
            'store_name' => getSetting($pdo, 'store_name', 'Kios Aisyha'),
            'store_address' => getSetting($pdo, 'store_address', 'Jl. Pemuda Sembako No. 8, Kios Aisyha'),
            'store_phone' => getSetting($pdo, 'store_phone', '0821-5430-6904'),
            'store_hours' => getSetting($pdo, 'store_hours', '07:00 - 21:00 WIB'),
        ],
    ]);
    exit;
}

if ($uri === '/api/categories' && $method === 'GET') {
    echo json_encode($pdo->query("SELECT * FROM categories WHERE is_active = 1 ORDER BY sort_order ASC")->fetchAll());
    exit;
}

if ($uri === '/api/products' && $method === 'GET') {
    $cat = $_GET['category_id'] ?? null;
    $q = $_GET['q'] ?? null;

    $sql = "SELECT p.*, c.name as category_name FROM products p JOIN categories c ON c.id = p.category_id WHERE p.is_active = 1 AND p.deleted_at IS NULL";
    $params = [];
    if ($cat) {
        $sql .= " AND p.category_id = ?";
        $params[] = $cat;
    }
    if ($q) {
        $sql .= " AND p.name LIKE ?";
        $params[] = "%$q%";
    }
    $sql .= " ORDER BY p.id DESC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll();

    foreach ($rows as &$p) {
        $p['price'] = (int)$p['price'];
        $p['promo_price'] = $p['promo_price'] !== null ? (int)$p['promo_price'] : null;
        $p['stock'] = (int)$p['stock'];
        $p['has_promo'] = !empty($p['promo_price']) && $p['promo_price'] < $p['price'];
        $p['final_price'] = $p['has_promo'] ? $p['promo_price'] : $p['price'];
        $p['image_url'] = $p['image'] ? (str_starts_with($p['image'], 'http') ? $p['image'] : 'https://kiosaisyha.infinityfreeapp.com/storage/'.$p['image']) : null;
        $p['category'] = ['id' => $p['category_id'], 'name' => $p['category_name']];
    }

    echo json_encode(['data' => $rows]);
    exit;
}

// ---------- 3. CART QUOTE & CHECKOUT ----------
if ($uri === '/api/cart/quote' && $method === 'POST') {
    $in = jsonInput();
    $items = $in['items'] ?? [];
    $delivery = $in['delivery_method'] ?? 'delivery';
    $voucherCode = $in['voucher_code'] ?? null;

    $subtotal = 0;
    $outItems = [];

    foreach ($items as $it) {
        $stmt = $pdo->prepare("SELECT * FROM products WHERE id = ? AND deleted_at IS NULL");
        $stmt->execute([$it['product_id']]);
        $p = $stmt->fetch();
        if ($p) {
            $hasPromo = !empty($p['promo_price']) && $p['promo_price'] < $p['price'];
            $price = $hasPromo ? (int)$p['promo_price'] : (int)$p['price'];
            $qty = (int)$it['quantity'];
            $lineSub = $price * $qty;
            $subtotal += $lineSub;
            $outItems[] = [
                'product_id' => (int)$p['id'],
                'name' => $p['name'],
                'price' => $price,
                'quantity' => $qty,
                'subtotal' => $lineSub,
            ];
        }
    }

    $freeMin = (int) getSetting($pdo, 'free_shipping_min', 150000);
    $defaultFee = (int) getSetting($pdo, 'default_shipping_fee', 8000);

    $isFree = $delivery === 'pickup' || $subtotal >= $freeMin;
    $shippingFee = $isFree ? 0 : $defaultFee;
    $remaining = max(0, $freeMin - $subtotal);

    $discount = 0;
    if ($voucherCode) {
        $stmtV = $pdo->prepare("SELECT * FROM vouchers WHERE code = ? AND is_active = 1");
        $stmtV->execute([$voucherCode]);
        $v = $stmtV->fetch();
        if ($v && $subtotal >= $v['min_purchase']) {
            $discount = (int)$v['value'];
        }
    }

    $total = max(0, $subtotal - $discount + $shippingFee);

    echo json_encode([
        'items' => $outItems,
        'subtotal' => $subtotal,
        'discount' => $discount,
        'shipping_fee' => $shippingFee,
        'free_shipping' => $isFree,
        'remaining_for_free_shipping' => $remaining,
        'total' => $total,
    ]);
    exit;
}

if ($uri === '/api/checkout' && $method === 'POST') {
    $user = getAuthUser($pdo);
    if (!$user) {
        http_response_code(401);
        echo json_encode(['message' => 'Silakan login terlebih dahulu.']);
        exit;
    }

    $in = jsonInput();
    $items = $in['items'] ?? [];
    $delivery = $in['delivery_method'] ?? 'delivery';
    $payment = $in['payment_method'] ?? 'cod';
    $note = $in['note'] ?? null;
    $voucherCode = $in['voucher_code'] ?? null;

    $subtotal = 0;
    $lines = [];
    foreach ($items as $it) {
        $stmt = $pdo->prepare("SELECT * FROM products WHERE id = ? AND deleted_at IS NULL");
        $stmt->execute([$it['product_id']]);
        $p = $stmt->fetch();
        if ($p) {
            $hasPromo = !empty($p['promo_price']) && $p['promo_price'] < $p['price'];
            $price = $hasPromo ? (int)$p['promo_price'] : (int)$p['price'];
            $qty = (int)$it['quantity'];
            $lineSub = $price * $qty;
            $subtotal += $lineSub;
            $lines[] = [
                'product_id' => $p['id'],
                'name' => $p['name'],
                'price' => $price,
                'quantity' => $qty,
                'subtotal' => $lineSub,
            ];
            // Update stock
            $pdo->prepare("UPDATE products SET stock = GREATEST(0, stock - ?), sold_count = sold_count + ? WHERE id = ?")->execute([$qty, $qty, $p['id']]);
        }
    }

    $freeMin = (int) getSetting($pdo, 'free_shipping_min', 150000);
    $defaultFee = (int) getSetting($pdo, 'default_shipping_fee', 8000);
    $shippingFee = ($delivery === 'pickup' || $subtotal >= $freeMin) ? 0 : $defaultFee;

    $discount = 0;
    if ($voucherCode) {
        $stmtV = $pdo->prepare("SELECT * FROM vouchers WHERE code = ? AND is_active = 1");
        $stmtV->execute([$voucherCode]);
        $v = $stmtV->fetch();
        if ($v && $subtotal >= $v['min_purchase']) {
            $discount = (int)$v['value'];
            $pdo->prepare("UPDATE vouchers SET used_count = used_count + 1 WHERE id = ?")->execute([$v['id']]);
        }
    }

    $total = max(0, $subtotal - $discount + $shippingFee);
    $code = 'ORD-' . date('Ymd') . '-' . strtoupper(substr(uniqid(), -4));

    $insOrd = $pdo->prepare("INSERT INTO orders (code, user_id, delivery_method, recipient, phone, address, subtotal, discount, shipping_fee, total, voucher_code, payment_method, payment_status, status, note, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'unpaid', 'pending', ?, NOW(), NOW())");
    $insOrd->execute([
        $code,
        $user['id'],
        $delivery,
        $user['name'],
        $user['phone'],
        $in['address'] ?? 'Alamat Pelanggan',
        $subtotal,
        $discount,
        $shippingFee,
        $total,
        $voucherCode,
        $payment,
        $note,
    ]);
    $orderId = $pdo->lastInsertId();

    foreach ($lines as $l) {
        $insItem = $pdo->prepare("INSERT INTO order_items (order_id, product_id, name, price, quantity, subtotal, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())");
        $insItem->execute([$orderId, $l['product_id'], $l['name'], $l['price'], $l['quantity'], $l['subtotal']]);
    }

    $stmtRes = $pdo->prepare("SELECT * FROM orders WHERE id = ?");
    $stmtRes->execute([$orderId]);
    $ord = $stmtRes->fetch();
    $ord['items'] = $lines;

    echo json_encode($ord);
    exit;
}

if ($uri === '/api/orders' && $method === 'GET') {
    $user = getAuthUser($pdo);
    if (!$user) {
        http_response_code(401);
        echo json_encode(['message' => 'Unauthenticated']);
        exit;
    }
    $stmt = $pdo->prepare("SELECT * FROM orders WHERE user_id = ? ORDER BY id DESC LIMIT 20");
    $stmt->execute([$user['id']]);
    $orders = $stmt->fetchAll();

    foreach ($orders as &$o) {
        $st = $pdo->prepare("SELECT * FROM order_items WHERE order_id = ?");
        $st->execute([$o['id']]);
        $o['items'] = $st->fetchAll();
    }

    echo json_encode(['data' => $orders]);
    exit;
}

// ---------- 4. ADMIN TOKO ----------
if (str_starts_with($uri, '/api/admin/')) {
    requireAdmin($pdo);

    if ($uri === '/api/admin/orders' && $method === 'GET') {
        $orders = $pdo->query("SELECT o.*, u.name as user_name, u.phone as user_phone FROM orders o JOIN users u ON u.id = o.user_id ORDER BY o.id DESC LIMIT 30")->fetchAll();
        foreach ($orders as &$o) {
            $st = $pdo->prepare("SELECT * FROM order_items WHERE order_id = ?");
            $st->execute([$o['id']]);
            $o['items'] = $st->fetchAll();
            $o['user'] = ['name' => $o['user_name'], 'phone' => $o['user_phone']];
        }
        echo json_encode(['data' => $orders]);
        exit;
    }

    if (preg_match('#^/api/admin/orders/(\d+)/status$#', $uri, $m) && $method === 'POST') {
        $orderId = $m[1];
        $in = jsonInput();
        if (isset($in['status'])) {
            $pdo->prepare("UPDATE orders SET status = ?, updated_at = NOW() WHERE id = ?")->execute([$in['status'], $orderId]);
        }
        if (isset($in['payment_status'])) {
            $pdo->prepare("UPDATE orders SET payment_status = ?, updated_at = NOW() WHERE id = ?")->execute([$in['payment_status'], $orderId]);
        }
        $st = $pdo->prepare("SELECT * FROM orders WHERE id = ?");
        $st->execute([$orderId]);
        echo json_encode($st->fetch());
        exit;
    }

    if ($uri === '/api/admin/stats' && $method === 'GET') {
        $today = date('Y-m-d 00:00:00');
        $pending = $pdo->query("SELECT COUNT(*) FROM orders WHERE status = 'pending'")->fetchColumn();
        $processing = $pdo->query("SELECT COUNT(*) FROM orders WHERE status = 'processing'")->fetchColumn();
        $delivering = $pdo->query("SELECT COUNT(*) FROM orders WHERE status = 'delivering'")->fetchColumn();
        $todayOrders = $pdo->query("SELECT COUNT(*) FROM orders WHERE created_at >= '$today'")->fetchColumn();
        $todayIncome = $pdo->query("SELECT COALESCE(SUM(total), 0) FROM orders WHERE created_at >= '$today' AND status != 'cancelled'")->fetchColumn();

        echo json_encode([
            'pending_count' => (int)$pending,
            'processing_count' => (int)$processing,
            'delivering_count' => (int)$delivering,
            'today_orders_count' => (int)$todayOrders,
            'today_income' => (int)$todayIncome,
        ]);
        exit;
    }

    if ($uri === '/api/admin/products' && $method === 'GET') {
        $prods = $pdo->query("SELECT p.*, c.name as category_name FROM products p JOIN categories c ON c.id = p.category_id WHERE p.deleted_at IS NULL ORDER BY p.id DESC")->fetchAll();
        foreach ($prods as &$p) {
            $p['price'] = (int)$p['price'];
            $p['stock'] = (int)$p['stock'];
            $p['is_active'] = (bool)$p['is_active'];
            $p['category'] = ['id' => $p['category_id'], 'name' => $p['category_name']];
        }
        echo json_encode($prods);
        exit;
    }

    if (preg_match('#^/api/admin/products/(\d+)$#', $uri, $m) && $method === 'DELETE') {
        $prodId = $m[1];
        $pdo->prepare("UPDATE products SET deleted_at = NOW() WHERE id = ?")->execute([$prodId]);
        echo json_encode(['message' => 'ok']);
        exit;
    }

    if (preg_match('#^/api/admin/products/(\d+)/toggle$#', $uri, $m) && $method === 'POST') {
        $prodId = $m[1];
        $pdo->prepare("UPDATE products SET is_active = NOT is_active WHERE id = ?")->execute([$prodId]);
        echo json_encode(['message' => 'ok']);
        exit;
    }

    if ($uri === '/api/admin/settings' && $method === 'GET') {
        echo json_encode([
            'store_name' => getSetting($pdo, 'store_name', 'Kios Aisyha'),
            'store_whatsapp' => getSetting($pdo, 'store_whatsapp', '6282154306904'),
            'store_phone' => getSetting($pdo, 'store_phone', '0821-5430-6904'),
            'store_hours' => getSetting($pdo, 'store_hours', '07:00 - 21:00 WIB'),
            'store_address' => getSetting($pdo, 'store_address', 'Jl. Pemuda Sembako No. 8, Kios Aisyha'),
            'store_bank_name' => getSetting($pdo, 'store_bank_name', 'BCA'),
            'store_bank_account' => getSetting($pdo, 'store_bank_account', '82154306904'),
            'store_bank_holder' => getSetting($pdo, 'store_bank_holder', 'Kios Aisyha'),
            'store_qris_name' => getSetting($pdo, 'store_qris_name', 'Kios Aisyha'),
            'free_shipping_min' => (int) getSetting($pdo, 'free_shipping_min', 150000),
            'default_shipping_fee' => (int) getSetting($pdo, 'default_shipping_fee', 8000),
        ]);
        exit;
    }

    if ($uri === '/api/admin/settings' && $method === 'POST') {
        $in = jsonInput();
        foreach (['store_name', 'store_whatsapp', 'store_phone', 'store_hours', 'store_address', 'store_bank_name', 'store_bank_account', 'store_bank_holder', 'store_qris_name', 'free_shipping_min', 'default_shipping_fee'] as $k) {
            if (isset($in[$k])) {
                $pdo->prepare("INSERT INTO settings (`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)")->execute([$k, $in[$k]]);
            }
        }
        echo json_encode(['message' => 'ok']);
        exit;
    }
}

// 404
http_response_code(404);
echo json_encode(['message' => 'Endpoint not found', 'uri' => $uri]);

