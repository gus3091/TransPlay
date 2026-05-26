import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = Supabase.instance.client.auth.currentUser!;
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  double _saldoBilletera = 0.0;
  String _estadoPasajero = 'pendiente';
  
  String _nombreCompleto = "Cargando...";
  String _emailUsuario = "";
  String _fotoRostroUrl = "";
  String _categoriaPasajero = "Regular";

  List<dynamic> _historialViajes = [];
  List<dynamic> _rutasYBusenTurno = [];

  @override
  void initState() {
    super.initState();
    _emailUsuario = user.email ?? "usuario@transpayy.com";
    _cargarDatosCompletosPasajero();
  }

  Future<void> _cargarDatosCompletosPasajero() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final pasajeroData = await supabase
          .from('pasajeros')
          .select('estado, foto_rostro_url, categoria')
          .eq('id', user.id)
          .maybeSingle();

      if (pasajeroData != null) {
        _estadoPasajero = pasajeroData['estado'] ?? 'aprobado';
        _fotoRostroUrl = pasajeroData['foto_rostro_url'] ?? '';
        _categoriaPasajero = pasajeroData['categoria'] ?? 'Regular';
        
        _nombreCompleto = _emailUsuario.split('@').first.toUpperCase();
      }

      if (_estadoPasajero == 'aprobado') {
        final billeteraData = await supabase
            .from('billetera')
            .select('saldo')
            .eq('id_usuario', user.id)
            .maybeSingle();

        if (billeteraData != null) {
          _saldoBilletera = double.tryParse(billeteraData['saldo'].toString()) ?? 0.0;
        }

        final transaccionesRes = await supabase
            .from('transacciones')
            .select()
            .eq('pasajero_id', user.id)
            .order('fecha', ascending: false);
        _historialViajes = transaccionesRes as List;

        final rutasRes = await supabase
            .from('rutas')
            .select('nombre_ruta, bus_placa, origen, destino, chofer_id');
        _rutasYBusenTurno = rutasRes as List;
      }
    } catch (e) {
      debugPrint("Error general en el dashboard: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _procesarPagoPasaje(String idChofer) async {
    const double costoPasaje = 2.00;

    if (_saldoBilletera < costoPasaje) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Saldo insuficiente en tu billetera digital.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final nuevoSaldo = _saldoBilletera - costoPasaje;
      await supabase.from('billetera').update({'saldo': nuevoSaldo}).eq('id_usuario', user.id);

      await supabase.from('transacciones').insert({
        'pasajero_id': user.id,
        'id_chofer': idChofer,
        'monto': costoPasaje,
        'tipo': 'debito',
        'estado': 'completado',
        'fecha': DateTime.now().toIso8601String()
      });

      final billeteraChofer = await supabase.from('billetera').select('saldo').eq('id_usuario', idChofer).maybeSingle();
      if (billeteraChofer != null) {
        final saldoActualChofer = double.tryParse(billeteraChofer['saldo'].toString()) ?? 0.0;
        await supabase.from('billetera').update({'saldo': saldoActualChofer + costoPasaje}).eq('id_usuario', idChofer);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Pasaje Pagado. ¡Notificación enviada al Chofer por 2.00 Bs!")),
      );
      _cargarDatosCompletosPasajero();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al cobrar pasaje: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogoRecargaQR() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Recargar Billetera via QR", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Escanea o guarda este código para transferir saldo instantáneo a tu cuenta de TransPayy."),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=TransPayyRecarga-${user.id}',
                height: 160,
                width: 160,
              ),
            ),
            const SizedBox(height: 10),
            const Text("Monto de simulación fija: +10.00 Bs", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await supabase.from('billetera').update({'saldo': _saldoBilletera + 10.00}).eq('id_usuario', user.id);
                await supabase.from('transacciones').insert({
                  'pasajero_id': user.id,
                  'monto': 10.00,
                  'tipo': 'credito',
                  'estado': 'completado',
                  'fecha': DateTime.now().toIso8601String()
                });
                _cargarDatosCompletosPasajero();
              } catch (e) {
                debugPrint("Error al recargar: $e");
              }
            },
            child: const Text("Simular Depósito"),
          ),
        ],
      ),
    );
  }

  void _abrirEscannerQR() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Escanea el QR del Bus"),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                final String codigoEscaneado = barcodes.first.rawValue!;
                Navigator.pop(context);
                _procesarPagoPasaje(codigoEscaneado);
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_estadoPasajero == 'pendiente') {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_maybe, size: 90, color: Colors.orange),
                const SizedBox(height: 15),
                const Text("Cuenta en Revisión", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Espera a que el administrador apruebe tu registro.", textAlign: TextAlign.center),
                const SizedBox(height: 25),
                ElevatedButton(onPressed: _cargarDatosCompletosPasajero, child: const Text("Verificar ahora")),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("TransPayy Pasajero", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargarDatosCompletosPasajero),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await supabase.auth.signOut();
              navigator.pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25, top: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.blue.shade200,
                          backgroundImage: _fotoRostroUrl.isNotEmpty ? NetworkImage(_fotoRostroUrl) : null,
                          child: _fotoRostroUrl.isEmpty ? const Icon(Icons.person, size: 35, color: Colors.white) : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_nombreCompleto, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(_emailUsuario, style: TextStyle(color: Colors.blue.shade100, fontSize: 13)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(color: Colors.teal.shade400, borderRadius: BorderRadius.circular(10)),
                              child: Text(_categoriaPasajero, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15), 
                      borderRadius: BorderRadius.circular(15)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("SALDO DISPONIBLE", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 3),
                            Text("${_saldoBilletera.toStringAsFixed(2)} Bs", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                          onPressed: _mostrarDialogoRecargaQR,
                          icon: const Icon(Icons.qr_code, size: 18),
                          label: const Text("Recargar", style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: InkWell(
                  onTap: _abrirEscannerQR,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade900]),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    // CORREGIDO AQUÍ: Añadido 'const' al Row de forma global
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, color: Colors.white, size: 36),
                        SizedBox(width: 15),
                        Text("ESCANEAR QR DE BUS / PAGAR", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
              child: Align(alignment: Alignment.centerLeft, child: Text("🗺️ Rutas y Buses Disponibles", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))),
            ),
            Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 10),
              child: _rutasYBusenTurno.isEmpty
                  ? const Center(child: Text("No hay rutas registradas en el sistema.", style: TextStyle(fontStyle: FontStyle.italic)))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: _rutasYBusenTurno.length,
                      itemBuilder: (context, index) {
                        final ruta = _rutasYBusenTurno[index];
                        return Container(
                          width: 240,
                          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(ruta['nombre_ruta'] ?? 'Línea Desconocida', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue)),
                              const SizedBox(height: 2),
                              Text("De: ${ruta['origen']} a ${ruta['destino']}", style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                              const Divider(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.directions_bus, size: 16, color: Colors.orange),
                                  const SizedBox(width: 5),
                                  Text("Bus Placa: ${ruta['bus_placa'] ?? 'Sin asignar'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
              child: Align(alignment: Alignment.centerLeft, child: Text("📊 Historial de Transacciones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
              child: _historialViajes.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(25.0),
                      child: Center(child: Text("Aún no tienes movimientos en tu cuenta.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _historialViajes.length,
                      itemBuilder: (context, index) {
                        final tx = _historialViajes[index];
                        final bool esDebito = tx['tipo'] == 'debito';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: esDebito ? Colors.red.shade50 : Colors.green.shade50,
                            child: Icon(esDebito ? Icons.local_atm : Icons.account_balance_wallet, color: esDebito ? Colors.red : Colors.green),
                          ),
                          title: Text(esDebito ? "Pago de Pasaje Bus" : "Recarga de Saldo QR"),
                          subtitle: Text(tx['estado']?.toString().toUpperCase() ?? 'COMPLETADO', style: const TextStyle(fontSize: 11)),
                          trailing: Text(
                            "${esDebito ? '-' : '+'} ${tx['monto']} Bs",
                            style: TextStyle(color: esDebito ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}