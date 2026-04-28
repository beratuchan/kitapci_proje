// lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import '../models/book.dart';

class CartItem {
  final Book book;
  int quantity;

  CartItem({required this.book, required this.quantity});
}

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;
  double get totalPrice => _items.fold(0, (sum, item) => sum + (item.book.price * item.quantity));

  void addItem(Book book, int availableStock) {
    final existingIndex = _items.indexWhere((i) => i.book.id == book.id);
    if (existingIndex != -1) {
      final newQty = _items[existingIndex].quantity + 1;
      if (newQty <= availableStock) {
        _items[existingIndex].quantity = newQty;
      } else {
        // Stok yetersiz uyarısı fırlat ya da false dön; tercihen hata mesajı
        throw Exception('Yeterli stok yok');
      }
    } else {
      if (1 <= availableStock) {
        _items.add(CartItem(book: book, quantity: 1));
      } else {
        throw Exception('Yeterli stok yok');
      }
    }
    notifyListeners();
  }

  void removeItem(int bookId) {
    _items.removeWhere((item) => item.book.id == bookId);
    notifyListeners();
  }

  void updateQuantity(int bookId, int newQuantity, int availableStock) {
    final index = _items.indexWhere((item) => item.book.id == bookId);
    if (index != -1) {
      if (newQuantity <= 0) {
        removeItem(bookId);
      } else if (newQuantity <= availableStock) {
        _items[index].quantity = newQuantity;
        notifyListeners();
      } else {
        throw Exception('Yeterli stok yok');
      }
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}