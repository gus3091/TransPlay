import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detalle_bus_screen.dart';

class RutasScreen extends StatelessWidget {
  const RutasScreen({super.key});

  Future<void> _verDetalleRuta(BuildContext context, Map<String, dynamic> ruta) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = Supabase.instance.client.auth.currentUser!;
      
      // Consultamos la categoría. Usamos .maybeSingle() para evitar errores si no hay fila
      final response = await Supabase.instance.client
          .from('perfiles')
          .select('categoria')
          .eq('id', user.id)
          .maybeSingle();

      // Si es null, ponemos "Normal" por defecto
      final String categoria = (response != null && response['categoria'] != null) 
          ? response['categoria'].toString() 
          : 'Normal';

      if (!context.mounted) return;
      Navigator.pop(context); // Quitar cargando

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetalleBusScreen(
            ruta: ruta, 
            categoria: categoria,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar perfil: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rutas Disponibles")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client.from('rutas').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No hay rutas"));

          final rutas = snapshot.data!;
          return ListView.builder(
            itemCount: rutas.length,
            itemBuilder: (context, index) {
              final ruta = rutas[index];
              return Card(
                child: ListTile(
                  title: Text(ruta['nombre_ruta'] ?? "Sin nombre"),
                  subtitle: Text("${ruta['origen'] ?? ''} ➔ ${ruta['destino'] ?? ''}"),
                  onTap: () => _verDetalleRuta(context, ruta),
                ),
              );
            },
          );
        },
      ),
    );
  }
}