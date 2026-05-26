import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'billetera_screen.dart';
import 'rutas_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, 
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("TransPayy - Inicio"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 40)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      user?.email ?? "Usuario",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildMenuCard(
                    context, 
                    "Ver Rutas y Buses", 
                    Icons.map, 
                    Colors.blue,
                    () {
                      // Depuración: Verifica si esto aparece en la consola de VS Code
                      debugPrint("Presionado: Rutas");
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const RutasScreen())
                      );
                    }
                  ),
                  const SizedBox(height: 10),
                  _buildMenuCard(
                    context, 
                    "Mi Billetera", 
                    Icons.account_balance_wallet, 
                    Colors.green,
                    () {
                      debugPrint("Presionado: Billetera");
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const BilleteraScreen())
                      );
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    // Usamos Card + InkWell para asegurar el área táctil
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: onTap, // Aquí se asigna la función
        borderRadius: BorderRadius.circular(4),
        child: ListTile(
          leading: Icon(icon, color: color, size: 30),
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}