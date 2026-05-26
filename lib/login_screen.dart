import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'chofer_dashboard_screen.dart';
import 'register_pasajero_screen.dart';
import 'registro_chofer_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _iniciarSesion() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final authRes = await supabase.auth.signInWithPassword(
        email: "${_emailController.text.trim()}@transpayy.com",
        password: _passwordController.text.trim(),
      );

      final userId = authRes.user!.id;
      final esChofer = await supabase.from('choferes').select('id').eq('id', userId);
      final esPasajero = await supabase.from('pasajeros').select('id').eq('id', userId);

      if (!mounted) return;

      if ((esChofer as List).isNotEmpty) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChoferDashboardScreen()));
      } else if ((esPasajero as List).isNotEmpty) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario sin rol asignado")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Iniciar Sesión")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Carnet")),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Contraseña"), obscureText: true),
            const SizedBox(height: 20),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _iniciarSesion, child: const Text("Ingresar")),
            
            TextButton(
              // ASEGÚRATE QUE 'RegistroPasajeroScreen' SEA EL NOMBRE QUE APARECE EN TU ARCHIVO
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroPasajeroScreen())),
              child: const Text("¿No tienes cuenta? Regístrate como Pasajero"),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroChoferScreen())),
              child: const Text("¿Eres chofer? Regístrate aquí", style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      ),
    );
  }
}