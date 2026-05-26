import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Asegúrate de importar el archivo donde creaste DetalleTransaccionScreen
import 'detalle_transaccion_screen.dart'; 

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Historial de Pagos")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('transacciones')
            .stream(primaryKey: ['id'])
            .eq('pasajero_id', user!.id)
            .order('fecha', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No se encontraron movimientos.", 
              textAlign: TextAlign.center),
            );
          }

          final transacciones = snapshot.data!;
          return ListView.builder(
            itemCount: transacciones.length,
            itemBuilder: (context, index) {
              final t = transacciones[index];
              final esPago = t['tipo'] == 'pago';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  // AQUÍ ESTÁ LA ACTUALIZACIÓN:
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalleTransaccionScreen(transaccion: t),
                      ),
                    );
                  },
                  leading: Icon(
                    esPago ? Icons.directions_bus : Icons.add_circle,
                    color: esPago ? Colors.red : Colors.green,
                    size: 30,
                  ),
                  title: Text(esPago ? "Pago de Pasaje" : "Recarga de Saldo"),
                  subtitle: Text("Fecha: ${t['fecha'].toString().substring(0, 16)}"),
                  trailing: Text(
                    "${esPago ? '-' : '+'}${t['monto']} Bs",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: esPago ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}