import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../services/database_helper.dart';
import 'book_form.dart';
import 'sales_chart.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false).fetchBooks();
    });
  }

  // Tüm verileri sıfırla (kullanıcılar, kitaplar, siparişler -> demo veriler)
  Future<void> _resetFullDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm Verileri Sıfırla'),
        content: const Text(
          'Tüm kitaplar, kullanıcılar ve siparişler silinecek. '
          'Yerine demo veriler (admin, normal kullanıcı, 6 kitap, rastgele siparişler) yüklenecek. Devam et?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sıfırla')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper().resetDatabase();
      await Provider.of<BookProvider>(context, listen: false).fetchBooks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm veriler sıfırlandı ve demo veriler yüklendi')),
      );
    }
  }

  // Sadece kitapları sıfırla (kullanıcılar ve siparişler korunur)
  Future<void> _resetBooksOnly() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sadece Kitapları Sıfırla'),
        content: const Text(
          'Mevcut tüm kitaplar silinecek ve demo kitap listesi yeniden eklenecek. '
          'Kullanıcı hesapları ve sipariş geçmişi KORUNACAKTIR. Devam et?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sıfırla')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper().resetBooksOnly();
      await Provider.of<BookProvider>(context, listen: false).fetchBooks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sadece kitaplar sıfırlandı, diğer veriler korundu')),
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Paneli'),
          actions: [
            IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Kitaplar'),
              Tab(text: 'Satış Grafiği'),
              Tab(text: 'Sıfırla'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Kitaplar sekmesi
            bookProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BookForm()),
                            );
                            if (result == true) await bookProvider.fetchBooks();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Yeni Kitap Ekle'),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: bookProvider.books.length,
                          itemBuilder: (ctx, index) {
                            final book = bookProvider.books[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: book.imageUrl.isNotEmpty
                                    ? Image.network(book.imageUrl, width: 50, height: 70, fit: BoxFit.cover)
                                    : Container(width: 50, height: 70, color: Colors.grey[300]),
                                title: Text(book.title),
                                subtitle: Text('${book.author} - ${book.price} TL - Stok: ${book.stock}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => BookForm(book: book)),
                                        );
                                        if (result == true) await bookProvider.fetchBooks();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => bookProvider.deleteBook(book.id!),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
            // Satış Grafiği sekmesi
            const SalesChart(),
            // Sıfırla sekmesi - iki buton
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _resetFullDatabase,
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Tüm Verileri Sıfırla (Demo + Kullanıcılar)'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _resetBooksOnly,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Sadece Kitapları Sıfırla (Kullanıcı/Siparişleri Koru)'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}