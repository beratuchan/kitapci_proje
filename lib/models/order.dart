class Order {
  final int? id;
  final int userId;
  final int bookId;
  final String orderDate;
  final int quantity;

  // Joined fields (from books table)
  final String? bookTitle;
  final double? bookPrice;

  Order({
    this.id,
    required this.userId,
    required this.bookId,
    required this.orderDate,
    required this.quantity,
    this.bookTitle,
    this.bookPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'order_date': orderDate,
      'quantity': quantity,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      userId: map['user_id'] ?? map['userId'] ?? 0,
      bookId: map['book_id'] ?? map['bookId'] ?? 0,
      orderDate: map['order_date'] ?? map['orderDate'] ?? '',
      quantity: map['quantity'] ?? 1,
      bookTitle: map['book_title'],
      bookPrice: map['book_price']?.toDouble(),
    );
  }
}