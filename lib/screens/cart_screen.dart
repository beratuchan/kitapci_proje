// lib/screens/cart_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final bookProvider = Provider.of<BookProvider>(context);

    Future<void> _placeOrder() async {
      final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      if (userId == null) return;
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      // Tüm sepet ürünleri için sipariş oluştur
      for (var item in cartProvider.items) {
        // Stok güncel mi kontrol et (tekrar)
        final book = bookProvider.books.firstWhere((b) => b.id == item.book.id);
        if (book.stock < item.quantity) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${book.title} için yeterli stok yok!')),
            );
          }
          return;
        }
        final success = await orderProvider.placeOrder(item.book.id!, item.quantity, userId);
        if (!success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${book.title} siparişi başarısız!')),
            );
          }
          return;
        }
      }
      // Sepeti temizle
      cartProvider.clearCart();
      // Kitapları yeniden yükle (stok güncellemesi için)
      await bookProvider.fetchBooks();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Siparişleriniz alındı'))
        );
        Navigator.pop(context); // Sepetten çık
      }
    }

    // Yardımcı fonksiyon: görsel gösterimi (yerel dosya kontrolü)
    Widget _buildBookImage(String? imageUrl) {
      if (imageUrl == null || imageUrl.isEmpty) {
        return Container(width: 50, height: 70, color: Colors.grey[300]);
      }
      final file = File(imageUrl);
      if (!file.existsSync()) {
        return Container(width: 50, height: 70, color: Colors.grey[300]);
      }
      return Image.file(
        file,
        width: 50,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(width: 50, height: 70, color: Colors.grey[300]),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sepetim')),
      body: cartProvider.items.isEmpty
          ? const Center(child: Text('Sepetiniz boş'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartProvider.items.length,
                    itemBuilder: (ctx, idx) {
                      final item = cartProvider.items[idx];
                      final book = item.book;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: _buildBookImage(book.imageUrl),
                          title: Text(book.title),
                          subtitle: Text('${book.price} TL x ${item.quantity} = ${book.price * item.quantity} TL'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  final newQty = item.quantity - 1;
                                  if (newQty >= 1) {
                                    try {
                                      cartProvider.updateQuantity(book.id!, newQty, book.stock);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString()))
                                        );
                                      }
                                    }
                                  } else {
                                    cartProvider.removeItem(book.id!);
                                  }
                                },
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  try {
                                    cartProvider.updateQuantity(book.id!, item.quantity + 1, book.stock);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString()))
                                      );
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () => cartProvider.removeItem(book.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    boxShadow: const [BoxShadow(blurRadius: 4)]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Toplam: ${cartProvider.totalPrice.toStringAsFixed(2)} TL',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      ElevatedButton.icon(
                        onPressed: _placeOrder,
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: const Text('Siparişi Onayla'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}