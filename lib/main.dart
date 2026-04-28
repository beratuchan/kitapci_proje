import 'package:flutter/material.dart';
import 'package:kitapci/providers/cart_provider.dart';
import 'package:kitapci/providers/order_provider.dart';
import 'package:kitapci/services/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:kitapci/providers/auth_provider.dart';
import 'package:kitapci/providers/book_provider.dart';
import 'package:kitapci/screens/login_screen.dart';
import 'package:kitapci/screens/admin_panel.dart';
import 'package:kitapci/screens/user_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()), 
      ],
      child: MaterialApp(
        title: 'Kitapçı App',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/admin': (context) => const AdminPanel(),
          '/user': (context) => const UserPanel(),
          '/login': (context) => const LoginScreen(),
        },
      ),
    );
  }
}