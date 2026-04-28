import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';

class BookForm extends StatefulWidget {
  final Book? book;
  const BookForm({super.key, this.book});

  @override
  State<BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<BookForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _imageUrlController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _authorController = TextEditingController(text: widget.book?.author ?? '');
    _priceController = TextEditingController(text: widget.book?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.book?.stock.toString() ?? '');
    _imageUrlController = TextEditingController(text: widget.book?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final book = Book(
      id: widget.book?.id,
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      price: double.parse(_priceController.text),
      stock: int.parse(_stockController.text),
      imageUrl: _imageUrlController.text.trim(),
    );

    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bool success;
    if (widget.book == null) {
      success = await bookProvider.addBook(book);
    } else {
      success = await bookProvider.updateBook(book);
    }

    setState(() => _isLoading = false);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydetme hatası')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book == null ? 'Yeni Kitap' : 'Kitap Düzenle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Kitap Adı'),
                validator: (v) => v == null || v.isEmpty ? 'Kitap adı giriniz' : null,
              ),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Yazar'),
                validator: (v) => v == null || v.isEmpty ? 'Yazar adı giriniz' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Fiyat (TL)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Fiyat giriniz';
                  if (double.tryParse(v) == null) return 'Geçerli sayı giriniz';
                  return null;
                },
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Stok giriniz';
                  if (int.tryParse(v) == null) return 'Geçerli sayı giriniz';
                  return null;
                },
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Resim URL (opsiyonel)'),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveBook,
                      child: Text(widget.book == null ? 'Ekle' : 'Güncelle'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}