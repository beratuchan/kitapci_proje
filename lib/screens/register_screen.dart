import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final newUser = User(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: 'user', // Varsayılan rol user
      name: _nameController.text.trim(),
    );

    final success = await authProvider.register(newUser);

    if (!mounted) return;

    if (success) {
      // Otomatik giriş yapıldı (register metodunda currentUser set ediliyor)
      if (authProvider.userRole == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/user');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu e-posta adresi zaten kullanılıyor veya kayıt başarısız')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ad Soyad giriniz';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'E-posta giriniz';
                  if (!value.contains('@')) return 'Geçerli e-posta giriniz';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Şifre giriniz';
                  if (value.length < 4) return 'Şifre en az 4 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Şifre Tekrarı',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Şifreyi tekrar giriniz';
                  if (value != _passwordController.text) return 'Şifreler eşleşmiyor';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Kayıt Ol'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}