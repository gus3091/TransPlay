import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChoferDashboardScreen extends StatefulWidget {
  const ChoferDashboardScreen({super.key});

  @override
  State<ChoferDashboardScreen> createState() => _ChoferDashboardScreenState();
}

class _ChoferDashboardScreenState extends State<ChoferDashboardScreen> {
  final user = Supabase.instance.client.auth.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel del Chofer")),
      body: Column(
        children: [
          // 1. Balance del día (Calculado desde transacciones filtradas por id_chofer)
          _buildBalanceWidget(),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Solicitudes de Viaje Activas", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          
          // 2. Lista de solicitudes (viajes activos)
          Expanded(child: _buildViajesActivos()),
        ],
      ),
    );
  }

  Widget _buildBalanceWidget() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('transacciones')
          .stream(primaryKey: ['id'])
          .eq('id_chofer', user.id), // Filtra por el chofer logueado
      builder: (context, snapshot) {
        double balance = 0;
        if (snapshot.hasData) {
          for (var t in snapshot.data!) {
            balance += (t['monto'] as num).toDouble();
          }
        }
        return Card(
          margin: const EdgeInsets.all(20),
          child: ListTile(
            title: const Text("Balance Recaudado (Hoy)"),
            trailing: Text("$balance Bs", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildViajesActivos() {
    // Aquí consultarías una tabla llamada 'viajes_solicitados' 
    // donde el estado sea 'pendiente'
    return const Center(child: Text("No hay solicitudes de viaje en este momento."));
  }
}