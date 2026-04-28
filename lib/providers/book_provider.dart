import 'package:flutter/foundation.dart';
import 'package:kitapci/services/database_helper.dart';
import '../models/book.dart';

class BookProvider extends ChangeNotifier {
  List<Book> _books = [];
  bool _isLoading = false;

  List<Book> get books => _books;
  bool get isLoading => _isLoading;

  Future<void> fetchBooks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> maps = await DatabaseHelper().getAllBooks();
      _books = maps.map((map) => Book.fromMap(map)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch books error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBook(Book book) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await DatabaseHelper().insertBook(book.toMap());
      book.id = id;
      _books.add(book);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Add book error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBook(Book book) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseHelper().updateBook(book.toMap());
      final index = _books.indexWhere((b) => b.id == book.id);
      if (index != -1) _books[index] = book;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update book error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBook(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseHelper().deleteBook(id);
      _books.removeWhere((book) => book.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete book error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}