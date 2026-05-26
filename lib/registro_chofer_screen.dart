import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chofer_dashboard_screen.dart';

class RegistroChoferScreen extends StatefulWidget {
  const RegistroChoferScreen({super.key});

  @override
  State<RegistroChoferScreen> createState() => _RegistroChoferScreenState();
}

class _RegistroChoferScreenState extends State<RegistroChoferScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenciaController = TextEditingController();
  final _placaController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _registrarChofer() async {
    if (_imageFile == null) return;
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final authRes = await supabase.auth.signUp(
        email: "${_emailController.text.trim()}@transpayy.com",
        password: _passwordController.text.trim(),
      );
      final userId = authRes.user!.id;
      final fileName = 'licencias/$userId.jpg';
      await supabase.storage.from('fotos_choferes').upload(fileName, _imageFile!);
      final publicUrl = supabase.storage.from('fotos_choferes').getPublicUrl(fileName);
      await supabase.from('choferes').insert({
        'id': userId,
        'licencia_conducir': _licenciaController.text.trim(),
        'placa_bus': _placaController.text.trim(),
        'foto_licencia_url': publicUrl,
        'estado': 'pendiente'
      });
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChoferDashboardScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Registro Chofer")), body: ListView(padding: const EdgeInsets.all(20), children: [
      TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Carnet")),
      TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Contraseña"), obscureText: true),
      TextField(controller: _licenciaController, decoration: const InputDecoration(labelText: "Licencia")),
      TextField(controller: _placaController, decoration: const InputDecoration(labelText: "Placa")),
      ElevatedButton(onPressed: _pickImage, child: const Text("Foto Licencia")),
      _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _registrarChofer, child: const Text("Registrarse"))
    ]));
  }
}