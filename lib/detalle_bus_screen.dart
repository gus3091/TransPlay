import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetalleBusScreen extends StatelessWidget {
  final Map<String, dynamic> ruta;
  final String categoria;

  const DetalleBusScreen({super.key, required this.ruta, required this.categoria});

  double get precioFinal {
    double precioBase = double.tryParse(ruta['precio']?.toString() ?? '3.00') ?? 3.00;
    return (categoria == 'Normal') ? precioBase : (precioBase * 0.5);
  }

  Future<void> _realizarPago(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    
    try {
      // 1. Obtener saldo
      final data = await supabase
          .from('billetera')
          .select('saldo')
          .eq('id_usuario', user.id)
          .maybeSingle();
      
      if (data == null) throw Exception("Billetera no configurada");
      
      double saldoActual = (data['saldo'] as num).toDouble();
      if (saldoActual < precioFinal) throw Exception("Saldo insuficiente");

      // 2. Descontar saldo
      await supabase
          .from('billetera')
          .update({'saldo': saldoActual - precioFinal})
          .eq('id_usuario', user.id);
      
      // 3. Insertar transacción
      // ELIMINAMOS 'id_usuario' porque no existe en la tabla transacciones
      await supabase.from('transacciones').insert({
        'pasajero_id': user.id, // Esta es la única columna de usuario que tienes
        'monto': precioFinal,
        'fecha': DateTime.now().toIso8601String(),
        'tipo': 'pago'
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Pago realizado con éxito!")));
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      // Esto te dirá exactamente qué columna está fallando si aún hay error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ruta['nombre_ruta'] ?? "Detalle")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Categoría: $categoria", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _realizarPago(context),
              child: Text("Pagar Pasaje (${precioFinal.toStringAsFixed(2)} Bs)"),
            ),
          ],
        ),
      ),
    );
  }
}