import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'historial_screen.dart';
import 'recarga_screen.dart'; // Asegúrate de tener este archivo creado

class BilleteraScreen extends StatelessWidget {
  const BilleteraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Inicia sesión")));

    return Scaffold(
      appBar: AppBar(title: const Text("Mi Billetera")),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 30),
            
            // 1. SALDO EN TIEMPO REAL
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('billetera')
                  .stream(primaryKey: ['id_usuario'])
                  .eq('id_usuario', user.id),
              builder: (context, snapshot) {
                final saldo = (snapshot.hasData && snapshot.data!.isNotEmpty) 
                    ? snapshot.data!.first['saldo'] 
                    : 0.0;
                return Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      const Text("Saldo Disponible", style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
                      Text("${saldo.toString()} Bs", 
                        style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 40),

            // 2. BOTONES DE ACCIÓN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Botón Recargar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Recargar Saldo"),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
                      onPressed: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => RecargaScreen())
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Botón Historial
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text("Ver Historial"),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15)),
                      onPressed: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const HistorialScreen())
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}