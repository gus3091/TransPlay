import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class RegistroPasajeroScreen extends StatefulWidget {
  const RegistroPasajeroScreen({super.key});

  @override
  State<RegistroPasajeroScreen> createState() => _RegistroPasajeroScreenState();
}

class _RegistroPasajeroScreenState extends State<RegistroPasajeroScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; // Añadido para controlar la carga

  Future<void> _registrarPasajero() async {
    setState(() => _isLoading = true); // Activar indicador de carga
    try {
      final supabase = Supabase.instance.client;
      final authRes = await supabase.auth.signUp(
        email: "${_emailController.text.trim()}@transpayy.com",
        password: _passwordController.text.trim(),
      );

      if (authRes.user != null) {
        await supabase.from('pasajeros').insert({'id': authRes.user!.id});
        
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } catch (e) {
      if (!mounted) return; // Verificación necesaria
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false); // Desactivar carga
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro Pasajero")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Carnet")),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Contraseña"), obscureText: true),
            const SizedBox(height: 20),
            _isLoading 
              ? const CircularProgressIndicator() 
              : ElevatedButton(onPressed: _registrarPasajero, child: const Text("Registrarse")),
          ],
        ),
      ),
    );
  }
}