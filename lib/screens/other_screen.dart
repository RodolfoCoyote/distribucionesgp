import 'package:distribucionesgp/api/api_service.dart';
import 'package:distribucionesgp/models/scan_model.dart';
import 'package:distribucionesgp/provider/auth_provider.dart';
import 'package:distribucionesgp/widgets/bottom_nav/user_bottom_nav.dart';
import 'package:distribucionesgp/widgets/custom_snack.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_elevated_button/loading_elevated_button.dart';
import 'package:provider/provider.dart';

class OtherScreen extends StatefulWidget {
  final String idTransferencia;
  const OtherScreen({super.key, required this.idTransferencia});

  @override
  State<OtherScreen> createState() => _OtherScreenState();
}

class _OtherScreenState extends State<OtherScreen> {
  // Controladores para limpiar los inputs
  bool _isLoading = false;
  bool _isDeleting = false;
  String _productStatus = 'nuevo';

  final FocusNode _scannerFocusNode = FocusNode();

  final TextEditingController _upcController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: "1");

  void _loadUltimosEscaneos() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final user = context.read<AuthProvider>().user;

    final response = await api.getUltimosEscaneos(
      user?.idEmpleado.toString() ?? '0',
    );

    if (!mounted) return;

    final dynamic bodyData = response.isSuccessful
        ? response.body
        : response.error;
    Map<String, dynamic>? body = bodyData is Map<String, dynamic>
        ? bodyData
        : null;

    if (response.isSuccessful && body != null && body['success'] == true) {
      final List<dynamic> data = body['data'] as List<dynamic>;
      final List<ScanModel> loadedScans = data
          .map((item) => ScanModel.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _scans.clear();
        _scans.addAll(loadedScans);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Cargamos los últimos escaneos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUltimosEscaneos();
    });
  }

  @override
  void dispose() {
    _scannerFocusNode.dispose();
    super.dispose();
  }

  // Lista de escaneos (Estado)
  final List<ScanModel> _scans = [];

  // Colores consistentes
  final Color gpBlue = const Color.fromARGB(255, 1, 77, 122);
  final Color textMain = const Color(0xFF1A1A1A);

  void _handleProcessScan() async {
    String upc = _upcController.text;
    if (upc.isEmpty) {
      CustomSnack.danger(context, 'El UPC es requerido');
      return;
    }

    upc = _productStatus == 'usado' ? 'U$upc' : upc;

    final int qty = int.tryParse(_qtyController.text) ?? -1;
    if (qty <= 0) {
      CustomSnack.danger(context, 'La cantidad debe ser un número positivo');
      return;
    }

    setState(() => _isLoading = true);

    final api = Provider.of<ApiService>(context, listen: false);
    final user = context.read<AuthProvider>().user;

    final response = await api.scanUpc({
      'id_distribucion': widget.idTransferencia,
      'upc': upc,
      'cantidad': qty,
      'id_empleado': user?.idEmpleado ?? 0,
    });

    if (!mounted) return;

    final dynamic bodyData = response.isSuccessful
        ? response.body
        : response.error;

    final Map<String, dynamic>? body = bodyData is Map<String, dynamic>
        ? bodyData
        : null;

    if (!response.isSuccessful) {
      final String errorMsg = (body != null && body.containsKey('message'))
          ? body['message']
          : 'Error del servidor (${response.statusCode})';
      _showErrorBottomSheet(errorMsg);
      setState(() => _isLoading = false);
      return;
    }

    if (body == null || body['success'] != true) {
      final String message = body?['message'] ?? 'Error desconocido';
      _showErrorBottomSheet(message);
      setState(() => _isLoading = false);
      return;
    }

    // ---------- CABECERA (ES LISTA) ----------
    final List cabeceraList = body['data']['cabecera'] as List;
    final Map<String, dynamic>? cabecera = cabeceraList.isNotEmpty
        ? cabeceraList.first
        : null;

    final int? cantidadEsperada = int.tryParse(
      cabecera?['cantidad_solicitada']?.toString() ?? '',
    );
    final int? cantidadEscaneada = int.tryParse(
      cabecera?['cantidad_escaneada_nueva']?.toString() ?? '',
    );

    String extraMessage = '';
    if (cantidadEsperada != null &&
        cantidadEscaneada != null &&
        cantidadEscaneada >= cantidadEsperada) {
      extraMessage =
          'Has alcanzado la cantidad solicitada de $cantidadEsperada pzas.';
    }

    // ---------- ÚLTIMO MOVIMIENTO (TAMBIÉN LISTA) ----------
    final List movimientos = body['data']['ultimos_movimientos'] as List;
    final Map<String, dynamic>? data = movimientos.isNotEmpty
        ? movimientos.first
        : null;

    if (data != null) {
      data['cantidad_solicitada'] = cantidadEsperada ?? 0;
      data['cantidad_escaneada_nueva'] = cantidadEscaneada ?? 0;

      final scan = ScanModel.fromJson(data);

      setState(() {
        _scans.insert(0, scan);
        _upcController.clear();
        _qtyController.text = '1';
      });

      CustomSnack.success(
        context,
        'Producto agregado. [$cantidadEscaneada de $cantidadEsperada] $extraMessage',
      );

      await Future.delayed(const Duration(milliseconds: 100));
      if (_scannerFocusNode.canRequestFocus) {
        _scannerFocusNode.requestFocus();
      }
    }

    setState(() => _isLoading = false);
  }

  void _showResultBottomSheet(ScanModel scan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ESCANEO",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const Text(
                "DESTINO",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00A3FF),
                ),
              ),
              const SizedBox(height: 12),
              _buildDestinationCard(scan),

              const Divider(height: 32),
              SizedBox(
                width: double.infinity,
                child: Text(
                  scan.nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),

              //Categoria y Plataforma
              Text(
                "UPC: ${scan.upc}",
                style: TextStyle(color: Colors.grey[600], letterSpacing: 1.2),
              ),
              Text(
                "Categoría: ${scan.categoria}",
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                "Plataforma: ${scan.plataforma}",
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 24),
              // BOTÓN DESHACER (REEMPLAZA A CONTINUAR)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(
                    "DESHACER ESCANEO",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Cerrar bottomsheet
                    _confirmUndoDialog(scan); // Abrir confirmación
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmUndoDialog(ScanModel scan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("¿Deshacer escaneo?"),
          content: Text("Se eliminará \n\n${scan.nombre}"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              child: const Text("VOLVER", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _handleUndoAction(scan); // Tu lógica para borrar el registro
              },
              child: const Text("SÍ, ELIMINAR"),
            ),
          ],
        );
      },
    );
  }

  void _handleUndoAction(ScanModel scan) async {
    final api = Provider.of<ApiService>(context, listen: false);

    setState(() => _isDeleting = true);

    final response = await api.rollbackUltimoUpc({
      'id_log': scan.id,
      'id_distribucion': scan.idDistribucion,
      'id_empleado': context.read<AuthProvider>().user?.idEmpleado ?? 0,
    });

    if (!mounted) return;

    final dynamic bodyData = response.isSuccessful
        ? response.body
        : response.error;
    Map<String, dynamic>? body = bodyData is Map<String, dynamic>
        ? bodyData
        : null;

    if (!response.isSuccessful) {
      final String errorMsg = (body != null && body.containsKey('message'))
          ? body['message']
          : 'Error del servidor (${response.statusCode})';
      _showErrorBottomSheet(errorMsg);
    } else if (body == null || body['success'] == false) {
      String message = body?['message'] ?? "Error desconocido";
      _showErrorBottomSheet(message);
    } else {
      setState(() {
        _scans.removeWhere((s) => s.id == scan.id);
        _isDeleting = false;
      });

      CustomSnack.info(context, "Escaneo eliminado correctamente");
    }

    setState(() => _isDeleting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF2F2F2),
          appBar: AppBar(
            title: Text(
              "Escaneo ID ${widget.idTransferencia}",
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0.5,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputSection(),
                const SizedBox(height: 24),
                const Text(
                  "HISTORIAL",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 8),
                _buildLastScansTable(),
              ],
            ),
          ),
          bottomNavigationBar: UserBottomNav(currentIndex: 0),
        ),
        _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Cantidad
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: "Cant.",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Escanear UPC con Prefijo Dinámico
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _upcController,
                      focusNode: _scannerFocusNode,

                      autofocus: true,
                      onSubmitted: (_) => _handleProcessScan(),
                      decoration: InputDecoration(
                        labelText: "Escanear UPC",
                        // Usamos prefix en lugar de prefixIcon
                        prefix: _productStatus == 'usado'
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  right: 4,
                                ), // Solo un pequeño margen derecho
                                child: Text(
                                  "U",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                    fontSize: 15,
                                  ),
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Botón Enviar
                  SizedBox(
                    height: 56,
                    child: LoadingElevatedButton(
                      onPressed: _handleProcessScan,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: gpBlue,
                        foregroundColor: Colors.white,
                      ),
                      disabledWhileLoading: true,
                      isLoading: _isLoading,
                      child: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 3),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Sección de Radio Buttons ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Opción Nuevo
                      Radio<String>(
                        value: 'nuevo',
                        groupValue: _productStatus,
                        activeColor: gpBlue,
                        onChanged: (value) {
                          setState(() => _productStatus = value!);
                        },
                      ),
                      const Text("Nuevo"),

                      const SizedBox(width: 20), // Espacio entre opciones
                      // Opción Usado
                      Radio<String>(
                        value: 'usado',
                        groupValue: _productStatus,
                        activeColor: gpBlue,
                        onChanged: (value) {
                          setState(() => _productStatus = value!);
                        },
                      ),
                      const Text("Usado"),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationCard(ScanModel scan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gpBlue, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: gpBlue, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${scan.claveDestino} - ${scan.nombreDestino}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Text(
            "x${scan.cantidad} pzas",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLastScansTable() {
    if (_scans.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "No hay escaneos recientes",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final ScanModel lastScan = _scans.first;

    //limitamos a los ultimos 5
    final List<ScanModel> previousScans = _scans.skip(1).toList();
    previousScans.length > 5
        ? previousScans.removeRange(5, previousScans.length)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECCIÓN ÚLTIMO ESCANEO
        const Text(
          "ÚLTIMO ESCANEO",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        _buildScanCard(lastScan, isLast: true),

        if (previousScans.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            "ANTERIORES (máx. 5)",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: previousScans.map((scan) {
                return Column(
                  children: [
                    _buildScanCard(scan, isLast: false),
                    if (previousScans.indexOf(scan) != previousScans.length - 1)
                      const Divider(height: 1, indent: 12, endIndent: 12),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // Helper para construir cada fila/tarjeta de escaneo
  Widget _buildScanCard(ScanModel scan, {required bool isLast}) {
    // 1. Parsear la fecha
    final DateTime fechaEscaneo = DateTime.parse(scan.fecha.toString());

    // 2. Formatear con segundos (H:mm:ss para 24h o hh:mm:ss a para 12h)
    final String horaFormateada = DateFormat('HH:mm:ss').format(fechaEscaneo);

    return InkWell(
      onTap: () => _showResultBottomSheet(scan),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isLast
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gpBlue, width: 1.5),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${scan.upc} | ${scan.categoria} | ${scan.plataforma}",
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  //Tienda
                  SizedBox(height: 5),
                  Text(
                    "${scan.claveDestino} - ${scan.nombreDestino}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  //Nombre del producto
                  Text(
                    scan.nombre,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Distribuye mejor el espacio
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      horaFormateada,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "x${scan.cantidad} pzas",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    if (!_isDeleting) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(
          0.4,
        ), // El "shadow" que bloquea la vista
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  void _showErrorBottomSheet(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                "ERROR",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "ENTENDIDO",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
