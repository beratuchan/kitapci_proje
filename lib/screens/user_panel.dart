import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'my_orders.dart';

class UserPanel extends StatefulWidget {
  const UserPanel({super.key});

  @override
  State<UserPanel> createState() => _UserPanelState();
}

class _UserPanelState extends State<UserPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false).fetchBooks();
    });
  }

  void _addToCart(Book book) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    try {
      cartProvider.addItem(book, book.stock);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sepete eklendi'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _logout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemCount = cartProvider.items.fold(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitaplar'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(cartItemCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrders())),
            icon: const Icon(Icons.history),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: bookProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: bookProvider.books.length,
              itemBuilder: (ctx, index) {
                final book = bookProvider.books[index];
                final cartQty = cartProvider.items.firstWhere(
                  (i) => i.book.id == book.id,
                  orElse: () => CartItem(book: book, quantity: 0),
                ).quantity;
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: book.imageUrl.isNotEmpty
                            ? Image.file(
                                File(book.imageUrl),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.book, size: 50),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(book.author),
                            Text('${book.price} TL', style: const TextStyle(color: Colors.green)),
                            Text('Stok: ${book.stock}'),
                            if (cartQty > 0) Text('Sepette: $cartQty', style: const TextStyle(color: Colors.orange)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: book.stock > 0 ? () => _addToCart(book) : null,
                              child: const Text('Sepete Ekle'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}