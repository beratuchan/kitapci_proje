import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../providers/order_provider.dart';
import 'my_orders.dart';

class UserPanel extends StatefulWidget {
  const UserPanel({super.key});

  @override
  State<UserPanel> createState() => _UserPanelState();
}

class _UserPanelState extends State<UserPanel> {
  final Map<int, int> _cart = {}; // bookId -> quantity

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false).fetchBooks();
    });
  }

  void _addToCart(int bookId) {
    setState(() {
      _cart[bookId] = (_cart[bookId] ?? 0) + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sepete eklendi'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sepet boş')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    for (var entry in _cart.entries) {
      await orderProvider.placeOrder(entry.key, entry.value, userId);
    }
    setState(() {
      _cart.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Siparişiniz alındı')),
    );
  }

  void _logout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final cartItemCount = _cart.values.fold(0, (sum, q) => sum + q);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitaplar'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {},
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      cartItemCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrders()));
            },
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
                final cartQuantity = _cart[book.id] ?? 0;
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: book.imageUrl.isNotEmpty
                            ? Image.network(book.imageUrl, fit: BoxFit.cover, width: double.infinity)
                            : Container(color: Colors.grey[300], child: const Icon(Icons.book, size: 50)),
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
                            if (cartQuantity > 0)
                              Text('Sepette: $cartQuantity', style: const TextStyle(color: Colors.orange)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: book.stock > 0 ? () => _addToCart(book.id!) : null,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _checkout,
        icon: const Icon(Icons.shopping_cart_checkout),
        label: Text('Sepeti Onayla (${_cart.length})'),
      ),
    );
  }
}