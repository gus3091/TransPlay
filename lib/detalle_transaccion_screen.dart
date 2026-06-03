import 'package:flutter/material.dart';

class DetalleTransaccionScreen extends StatelessWidget {
  final Map<String, dynamic> transaccion;
  const DetalleTransaccionScreen({super.key, required this.transaccion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalle del Movimiento")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ListTile(title: const Text("Tipo"), subtitle: Text(transaccion['tipo'] ?? "-")),
              ListTile(title: const Text("Monto"), subtitle: Text("${transaccion['monto']} Bs")),
              ListTile(title: const Text("Fecha"), subtitle: Text(transaccion['fecha'].toString())),
              ListTile(title: const Text("ID Chofer"), subtitle: Text(transaccion['id_chofer'] ?? "No aplica")),
              ListTile(title: const Text("Estado"), subtitle: Text(transaccion['estado'] ?? "Completado")),
            ],
          ),
        ),
      ),
    );
  }
}