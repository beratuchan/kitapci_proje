import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../services/image_service.dart';

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
  File? _selectedImage;
  String? _existingImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _authorController = TextEditingController(text: widget.book?.author ?? '');
    _priceController = TextEditingController(text: widget.book?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.book?.stock.toString() ?? '');
    _existingImagePath = widget.book?.imageUrl;
    if (_existingImagePath != null && _existingImagePath!.isNotEmpty) {
      _selectedImage = File(_existingImagePath!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final imageFile = source == ImageSource.gallery
        ? await ImageService.pickImageFromGallery()
        : await ImageService.pickImageFromCamera();
    if (imageFile != null) {
      setState(() {
        _selectedImage = imageFile;
      });
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? savedImagePath = _existingImagePath;
    // Eğer yeni bir resim seçilmişse kaydet
    if (_selectedImage != null && _selectedImage!.path != _existingImagePath) {
      // Eski resmi sil
      if (_existingImagePath != null && _existingImagePath!.isNotEmpty) {
        await ImageService.deleteImageFile(_existingImagePath);
      }
      final newPath = await ImageService.saveImageToLocal(_selectedImage!);
      savedImagePath = newPath;
    }

    final book = Book(
      id: widget.book?.id,
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      price: double.parse(_priceController.text),
      stock: int.parse(_stockController.text),
      imageUrl: savedImagePath ?? '',
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

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamerayla Çek'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
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
              // Resim seçme alanı
              GestureDetector(
                onTap: _showImagePickerDialog,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Resim eklemek için tıklayın'),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
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