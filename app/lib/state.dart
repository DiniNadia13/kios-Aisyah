import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';

typedef Json = Map<String, dynamic>;

class AuthState extends ChangeNotifier {
  Json? user;
  bool loading = true;

  bool get loggedIn => user != null;
  bool get isAdmin => user?['role'] == 'admin';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    Api.token = p.getString('token');
    if (Api.token != null) {
      try {
        user = Json.from(await Api.get('/me'));
      } on ApiException {
        Api.token = null;
        await p.remove('token');
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _auth(String path, Json data) async {
    final r = await Api.post(path, data);
    Api.token = r['token'] as String;
    user = Json.from(r['user'] as Map);
    final p = await SharedPreferences.getInstance();
    await p.setString('token', Api.token!);
    notifyListeners();
  }

  Future<void> login(String phone, String password) =>
      _auth('/login', {'phone': phone, 'password': password});

  Future<void> register(String name, String phone, String password) =>
      _auth('/register', {'name': name, 'phone': phone, 'password': password});

  Future<void> logout() async {
    try {
      await Api.post('/logout');
    } catch (_) {}
    Api.token = null;
    user = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
    notifyListeners();
  }
}

class CartItem {
  final Json product;
  int qty;
  CartItem(this.product, this.qty);

  int get id => (product['id'] ?? product['product_id']) as int;
  int get price => ((product['final_price'] ?? product['price']) as num).toInt();
  int get stock => ((product['stock'] ?? 999) as num).toInt();
  int get subtotal => price * qty;
}

class CartState extends ChangeNotifier {
  final Map<int, CartItem> items = {};

  /// Batas gratis ongkir (dari server, bisa diubah admin).
  int freeShippingMin = 150000;

  Future<void> loadSettings() async {
    try {
      final r = await Api.get('/home');
      freeShippingMin = (r['free_shipping_min'] as num).toInt();
      notifyListeners();
    } catch (_) {}
  }

  int get count => items.values.fold(0, (a, b) => a + b.qty);
  int get subtotal => items.values.fold(0, (a, b) => a + b.subtotal);
  int get remainingForFree => (freeShippingMin - subtotal).clamp(0, freeShippingMin);

  /// Mengembalikan false jika stok tidak cukup.
  bool add(Json product, [int qty = 1]) {
    final id = (product['id'] ?? product['product_id']) as int;
    final maxStock = ((product['stock'] ?? 999) as num).toInt();
    final existing = items[id];
    final next = (existing?.qty ?? 0) + qty;
    if (next > maxStock) return false;
    if (existing != null) {
      existing.qty = next;
    } else {
      items[id] = CartItem(product, qty);
    }
    notifyListeners();
    return true;
  }

  void setQty(int id, int qty) {
    final item = items[id];
    if (item == null) return;
    if (qty <= 0) {
      items.remove(id);
    } else if (qty <= item.stock) {
      item.qty = qty;
    }
    notifyListeners();
  }

  void clear() {
    items.clear();
    notifyListeners();
  }

  List<Json> payload() => items.values
      .map((i) => {'product_id': i.id, 'quantity': i.qty})
      .toList();
}

class OrdersState extends ChangeNotifier {
  List<Json>? orders;
  bool loading = false;
  String? error;

  Future<void> load() async {
    if (Api.token == null) {
      orders = [];
      loading = false;
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final r = await Api.get('/orders');
      orders = (r['data'] as List).map((e) => Json.from(e as Map)).toList();
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    orders = null;
    error = null;
    notifyListeners();
  }
}

