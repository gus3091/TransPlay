import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Importante para detectar Web
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistroPasajeroScreen extends StatefulWidget {
  const RegistroPasajeroScreen({super.key});

  @override
  State<RegistroPasajeroScreen> createState() => _RegistroPasajeroScreenState();
}

class _RegistroPasajeroScreenState extends State<RegistroPasajeroScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nombreController = TextEditingController();
  final _carnetController = TextEditingController();
  
  String _categoria = 'estudiante';
  dynamic _fotoRostro, _fotoCarnet, _fotoEstudiante; // Usamos dynamic para Web/Móvil
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String tipo) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        if (tipo == 'rostro') _fotoRostro = picked;
        if (tipo == 'carnet') _fotoCarnet = picked;
        if (tipo == 'estudiante') _fotoEstudiante = picked;
      });
    }
  }

  Future<String> _subirFoto(dynamic file, String folder) async {
    final supabase = Supabase.instance.client;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$folder/$fileName';
    
    if (kIsWeb) {
      final bytes = await (file as XFile).readAsBytes();
      await supabase.storage.from('fotos_pasajeros').uploadBinary(path, bytes);
    } else {
      await supabase.storage.from('fotos_pasajeros').upload(path, File((file as XFile).path));
    }
    
    return supabase.storage.from('fotos_pasajeros').getPublicUrl(path);
  }

  Future<void> _registrar() async {
    if (_fotoRostro == null || _fotoCarnet == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faltan fotos obligatorias")));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      
      final auth = await supabase.auth.signUp(
        email: "${_emailController.text.trim()}@transpayy.com",
        password: _passController.text.trim(),
      );

      if (auth.user == null) throw Exception("Error al crear usuario");

      // Pasamos los objetos directamente
      String urlRostro = await _subirFoto(_fotoRostro, 'rostros');
      String urlCarnet = await _subirFoto(_fotoCarnet, 'carnets');
      String? urlEstudiante;
      
      if (_categoria == 'estudiante' && _fotoEstudiante != null) {
        urlEstudiante = await _subirFoto(_fotoEstudiante, 'estudiantes');
      }

      // 3. Guardar en BD
      await supabase.from('pasajeros').insert({
        'id': auth.user!.id,
        'nombre_completo': _nombreController.text.trim(),
        'numero_carnet': _carnetController.text.trim(),
        'categoria': _categoria,
        'foto_rostro_url': urlRostro,
        'foto_carnet_url': urlCarnet,
        // ESTA ES LA LÍNEA QUE ESTABA DANDO EL ERROR:
        'foto_universitario_url': urlEstudiante, 
        'estado': 'pendiente',
      });
      
      if (!mounted) return;
      Navigator.pop(context);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro Pasajero")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Usuario (ID)")),
          TextField(controller: _passController, decoration: const InputDecoration(labelText: "Contraseña"), obscureText: true),
          TextField(controller: _nombreController, decoration: const InputDecoration(labelText: "Nombre Completo")),
          TextField(controller: _carnetController, decoration: const InputDecoration(labelText: "Número de Carnet")),
          const SizedBox(height: 20),
          
          DropdownButtonFormField<String>(
            // Usamos initialValue como exige tu compilador
            initialValue: _categoria, 
            decoration: const InputDecoration(labelText: "Categoría"),
            items: ['estudiante', 'normal', 'tercera_edad']
                .map((c) => DropdownMenuItem(
                      value: c, 
                      child: Text(c.toUpperCase()),
                    ))
                .toList(),
            // Al usar initialValue, quitamos el 'value' del widget 
            // y dejamos que el Dropdown lo maneje internamente
            onChanged: (String? newValue) {
              setState(() {
                _categoria = newValue!;
              });
            },
          ),
          
          const SizedBox(height: 10),
          ListTile(title: const Text("Tomar foto rostro"), leading: const Icon(Icons.camera_alt), onTap: () => _pickImage('rostro'), tileColor: _fotoRostro != null ? Colors.green.shade50 : null),
          ListTile(title: const Text("Tomar foto carnet"), leading: const Icon(Icons.camera_alt), onTap: () => _pickImage('carnet'), tileColor: _fotoCarnet != null ? Colors.green.shade50 : null),
          if (_categoria == 'estudiante')
            ListTile(title: const Text("Foto Carnet Estudiante"), leading: const Icon(Icons.camera_alt), onTap: () => _pickImage('estudiante'), tileColor: _fotoEstudiante != null ? Colors.green.shade50 : null),
          const SizedBox(height: 20),
          _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : ElevatedButton(onPressed: _registrar, child: const Text("Registrarse"))
        ],
      ),
    );
  }
}