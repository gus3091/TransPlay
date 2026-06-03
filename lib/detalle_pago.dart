import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetallePago extends StatelessWidget {
  final Map<String, dynamic> ruta;
  final String categoria; // Ejemplo: 'Normal', 'Estudiante', 'Adulto Mayor'

  const DetallePago({super.key, required this.ruta, required this.categoria});

  double calcularPrecioFinal(double precioBase) {
    if (categoria == 'Estudiante') return precioBase * 0.5; // 50% descuento
    if (categoria == 'Adulto Mayor') return precioBase * 0.5;
    return precioBase; // Normal paga tarifa completa
  }

  Future<void> procesarPago(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser!;
    final precio = calcularPrecioFinal(double.parse(ruta['precio'].toString()));

    try {
      await Supabase.instance.client.from('transacciones').insert({
        'id_usuario': user.id,
        'pasajero_id': user.id,
        'monto': precio,
        'tipo': 'pago',
        'fecha': DateTime.now().toIso8601String(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pago de $precio Bs realizado")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final precio = calcularPrecioFinal(double.parse(ruta['precio'].toString()));
    return Scaffold(
      appBar: AppBar(title: const Text("Detalle de Pago")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Ruta: ${ruta['nombre']}", style: const TextStyle(fontSize: 20)),
            Text("Categoría: $categoria", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text("Total a pagar: $precio Bs", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => procesarPago(context), child: const Text("Confirmar Pago")),
          ],
        ),
      ),
    );
  }
}