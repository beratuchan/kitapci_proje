class Book {
  int? id;  // final değil!
  String title;
  String author;
  double price;
  int stock;
  String imageUrl;

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.price,
    required this.stock,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      price: map['price'],
      stock: map['stock'],
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}