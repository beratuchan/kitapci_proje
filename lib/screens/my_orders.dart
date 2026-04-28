import 'package:flutter/material.dart';
import 'package:kitapci/providers/order_provider.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class MyOrders extends StatefulWidget {
  const MyOrders({super.key});

  @override
  State<MyOrders> createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  @override
  void initState() {
    super.initState();
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (userId != null) {
      orderProvider.fetchOrdersByUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Siparişlerim')),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderProvider.orders.isEmpty
              ? const Center(child: Text('Henüz siparişiniz yok'))
              : ListView.builder(
                  itemCount: orderProvider.orders.length,
                  itemBuilder: (ctx, index) {
                    final order = orderProvider.orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(order['bookTitle']),
                        subtitle: Text('Tarih: ${order['orderDate']} - Adet: ${order['quantity']}'),
                        trailing: Text('${(order['bookPrice'] as num) * (order['quantity'] as num)} TL'),
                      ),
                    );
                  },
                ),
    );
  }
}