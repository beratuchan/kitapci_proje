import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';

class OrderProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;

Future<bool> placeOrder(int bookId, int quantity, int userId) async {
  _isLoading = true;
  notifyListeners();

  try {
    // Önce stok kontrolü ve azaltma
    final stockUpdated = await DatabaseHelper().decreaseBookStock(bookId, quantity);
    if (!stockUpdated) {
      _isLoading = false;
      notifyListeners();
      return false; // Stok yetersiz
    }

    final order = {
      'userId': userId,
      'bookId': bookId,
      'orderDate': DateTime.now().toIso8601String(),
      'quantity': quantity,
    };
    await DatabaseHelper().insertOrder(order);
    await fetchOrdersByUser(userId);
    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    debugPrint('Place order error: $e');
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  Future<void> fetchOrdersByUser(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final orders = await DatabaseHelper().getOrdersByUser(userId);
      _orders = orders;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch orders error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, double>> getMonthlySales() async {
    try {
      final salesData = await DatabaseHelper().getMonthlySales();
      Map<String, double> salesMap = {};
      for (var item in salesData) {
        salesMap[item['month']] = (item['totalAmount'] as num).toDouble();
      }
      return salesMap;
    } catch (e) {
      return {};
    }
  }
}