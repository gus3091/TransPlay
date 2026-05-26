import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistroChoferScreen extends StatefulWidget {
  const RegistroChoferScreen({super.key});

  @override
  State<RegistroChoferScreen> createState() => _RegistroChoferScreenState();
}

class _RegistroChoferScreenState extends State<RegistroChoferScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nombreController = TextEditingController();
  final _carnetController = TextEditingController();
  final _placaController = TextEditingController();

  File? _fotoRostro, _fotoLicencia, _fotoCarnet, _fotoBus;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String tipo) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        if (tipo == 'rostro') _fotoRostro = File(picked.path);
        if (tipo == 'licencia') _fotoLicencia = File(picked.path);
        if (tipo == 'carnet') _fotoCarnet = File(picked.path);
        if (tipo == 'bus') _fotoBus = File(picked.path);
      });
    }
  }

  Future<String?> _subirFoto(File file, String folder) async {
    final supabase = Supabase.instance.client;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$folder/$fileName';
    await supabase.storage.from('fotos_choferes').upload(path, file);
    return supabase.storage.from('fotos_choferes').getPublicUrl(path);
  }

  Future<void> _registrarChofer() async {
    // Validar que todas las fotos estén presentes
    if (_fotoRostro == null || _fotoLicencia == null || _fotoCarnet == null || _fotoBus == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor, sube todas las fotos requeridas")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. Registro Auth
      final auth = await supabase.auth.signUp(
        email: "${_emailController.text.trim()}@transpayy.com",
        password: _passController.text.trim(),
      );

      if (auth.user == null) throw Exception("Error al crear cuenta");

      // 2. Subida de imágenes
      String urlRostro = await _subirFoto(_fotoRostro!, 'rostros') ?? '';
      String urlLicencia = await _subirFoto(_fotoLicencia!, 'licencias') ?? '';
      String urlCarnet = await _subirFoto(_fotoCarnet!, 'carnets') ?? '';
      String urlBus = await _subirFoto(_fotoBus!, 'buses') ?? '';

      // 3. Guardar en BD
      await supabase.from('choferes').insert({
        'id': auth.user!.id,
        'nombre_completo': _nombreController.text.trim(),
        'numero_carnet': _carnetController.text.trim(),
        'placa_bus': _placaController.text.trim(),
        'foto_rostro_url': urlRostro,
        'foto_licencia_url': urlLicencia,
        'foto_carnet_url': urlCarnet,
        'foto_bus_url': urlBus,
        'estado': 'pendiente',
      });

      if (!mounted) return;
      Navigator.pop(context); // Regresa al login
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro Chofer")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Usuario (ID)")),
          TextField(controller: _passController, decoration: const InputDecoration(labelText: "Contraseña"), obscureText: true),
          TextField(controller: _nombreController, decoration: const InputDecoration(labelText: "Nombre Completo")),
          TextField(controller: _carnetController, decoration: const InputDecoration(labelText: "Número de Carnet")),
          TextField(controller: _placaController, decoration: const InputDecoration(labelText: "Placa del Bus")),
          const SizedBox(height: 20),
          const Text("Subir Documentos:", style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(title: const Text("Foto de rostro"), leading: const Icon(Icons.camera_alt), onTap: () => _pickImage('rostro'), tileColor: _fotoRostro != null ? Colors.green.shade50 : null),
          ListTile(title: const Text("Foto de licencia"), leading: const Icon(Icons.camera_alt), onTap: () => _pickImage('licencia'), tileColor: _fotoLicencia != null ? Colors.green.shade50 : null),
          ListTile(title: const Text("Foto de carnet"), leading: const Icon(Icons.camera_alt), onTap: () => _pickImage('carnet'), tileColor: _fotoCarnet != null ? Colors.green.shade50 : null),
          ListTile(title: const Text("Foto del bus"), leading: const Icon(Icons.directions_bus), onTap: () => _pickImage('bus'), tileColor: _fotoBus != null ? Colors.green.shade50 : null),
          const SizedBox(height: 20),
          _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : ElevatedButton(onPressed: _registrarChofer, child: const Text("Finalizar Registro"))
        ],
      ),
    );
  }
}