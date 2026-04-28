import 'package:flutter/material.dart';
import 'package:kitapci/services/database_helper.dart'; // Kendi paket adınıza göre düzenleyin

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Veritabanını başlat (tablolar oluşur)
  await DatabaseHelper().database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitap Uygulaması',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Kitap Uygulaması'),
        ),
        body: const Center(
          child: Text('Uygulama hazır'),
        ),
      ),
    );
  }
}