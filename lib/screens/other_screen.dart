import 'package:distribucionesgp/api/api_service.dart';
import 'package:distribucionesgp/models/scan_model.dart';
import 'package:distribucionesgp/provider/auth_provider.dart';
import 'package:distribucionesgp/widgets/bottom_nav/user_bottom_nav.dart';
import 'package:distribucionesgp/widgets/custom_snack.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_elevated_button/loading_elevated_button.dart';
import 'package:provider/provider.dart';

//--
import 'dart:convert';
import 'package:flutter/services.dart';

Future<Map<String, dynamic>> loadMockResponse() async {
  final jsonString = await rootBundle.loadString(
    'assets/mocks/scan_upc_response.json',
  );

  return jsonDecode(jsonString);
}

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

  // teclado
  bool _keyboardEnabled = true;

  final FocusNode _scannerFocusNode = FocusNode();

  final TextEditingController _upcController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: "1");

  // estados del teclado
  void _hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _showKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  //Loading
  bool _isLoadingUltimos = false;

  void _loadUltimosEscaneos() async {
    try {
      setState(() => _isLoadingUltimos = true);
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
    } catch (e) {
      _showErrorBottomSheet(
        'Error al cargar los últimos escaneos. Contacta a Desarrollo.',
      );
      if (kDebugMode) {
        print('Error al cargar últimos escaneos: $e');
      }
    } finally {
      setState(() => _isLoadingUltimos = false);
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
    _hideKeyboard();
    try {
      String upc = _upcController.text;
      if (upc.isEmpty) {
        CustomSnack.danger(context, 'El UPC es requerido');
        return;
      }
      //Si marcaron el producto usado, agregamos prefijo U
      upc = _productStatus == 'usado' ? 'U$upc' : upc;

      //Controlamos la cantidad ingresada.
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

      //Leemos debug desde respuesta.json
      // final response = await loadMockResponse();

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
        setState(() => _isLoading = false);
        return;
      }

      // debug
      // final Map<String, dynamic>? body = response;

      if (body == null || body['success'] == false) {
        String message = body?['message'] ?? "Error desconocido";
        _showErrorBottomSheet(message);
        setState(() => _isLoading = false);
        return;
      }

      // --- LOGICA DE ÉXITO ---

      // !--- cabecera
      final List<dynamic> cabeceraList = body['data']['cabecera'];

      final Map<String, dynamic>? cabecera = cabeceraList.isNotEmpty
          ? cabeceraList.first as Map<String, dynamic>
          : null;

      final data = body['data']['ultimo'] as Map<String, dynamic>?;

      final int cantidadEscaneadaNueva = cabecera != null
          ? int.tryParse(
                  cabecera['cantidad_escaneada_nueva']?.toString() ?? '',
                ) ??
                0
          : 0;

      final int cantidadTotal = cabecera != null
          ? int.tryParse(cabecera['cantidad_solicitada']?.toString() ?? '') ?? 0
          : 0;

      data?['cantidad_escaneada_nueva'] = cantidadEscaneadaNueva;
      data?['cantidad_solicitada'] = cantidadTotal;

      if (data != null) {
        final scan = ScanModel.fromJson(data);
        setState(() {
          _scans.insert(0, scan); // Insertar al inicio
          _upcController.clear();
          _qtyController.text = "1";
        });

        // Volvemos a pedir foco al input
        await Future.delayed(Duration(milliseconds: 100));
        if (_scannerFocusNode.canRequestFocus) {
          _scannerFocusNode.requestFocus();
        }
      }
    } catch (e, stackTrace) {
      // Manejo de errores inesperados
      if (kDebugMode) {
        print('Error inesperado: $e');
        print('Stack trace: $stackTrace');
      }
      _showErrorBottomSheet(
        'Ocurrió un error inesperado. Por favor, reinicia la aplicación y verifica el último escaneo.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showResultBottomSheet(ScanModel scan) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
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
          content: Text(
            "Se eliminarán ${scan.cantidad} piezas de ${scan.nombre} a la tienda ${scan.idTiendaDestino} - ${scan.claveDestino}.",
          ),
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
              "Distribución ID ${widget.idTransferencia}",
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0.5,
            actions: [
              IconButton(
                icon: Icon(Icons.keyboard, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _keyboardEnabled = !_keyboardEnabled;

                    if (_keyboardEnabled) {
                      _showKeyboard();
                    } else {
                      _hideKeyboard();
                    }
                  });
                },
                tooltip: _keyboardEnabled
                    ? 'Ocultar teclado'
                    : 'Mostrar teclado',
              ),
            ],
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
                      style: TextStyle(
                        fontSize: _scale(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: "Cant.",
                        labelStyle: TextStyle(fontSize: _scale(context, 13)),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: _scale(context, 12),
                          horizontal: _scale(context, 10),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _scale(context, 8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: _scale(context, 6)),

                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _upcController,
                      focusNode: _scannerFocusNode,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: TextStyle(
                        fontSize: _scale(context, 18),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                      onTap: () {
                        print('Input UPC tapped');
                        _hideKeyboard();
                      },
                      onSubmitted: (_) => _handleProcessScan(),
                      decoration: InputDecoration(
                        labelText: "Escanear UPC",
                        labelStyle: TextStyle(fontSize: _scale(context, 14)),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: _scale(context, 14),
                          horizontal: _scale(context, 12),
                        ),
                        prefix: _productStatus == 'usado'
                            ? Padding(
                                padding: EdgeInsets.only(
                                  right: _scale(context, 6),
                                ),
                                child: Text(
                                  "U",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                    fontSize: _scale(context, 18),
                                  ),
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _scale(context, 8),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: _scale(context, 6)),

                  // Botón Enviar
                  SizedBox(
                    height: _scale(context, 56),
                    width: _scale(context, 56),
                    child: LoadingElevatedButton(
                      onPressed: _handleProcessScan,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: gpBlue,
                        foregroundColor: Colors.white,
                      ),
                      disabledWhileLoading: true,
                      isLoading: _isLoading,
                      child: Icon(Icons.send, size: _scale(context, 22)),
                    ),
                  ),
                ],
              ),

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
                  "#${scan.idTiendaDestino} ${scan.claveDestino} - ${scan.nombreDestino}",
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
            "No tienes escaneos en las últimas 24 horas para esta distribución.",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
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

    //Cantidad actual escaneada
    final String currentQty =
        lastScan.cantidadEscaneadaNueva != null &&
            lastScan.cantidadSolicitada != null
        ? "[${lastScan.cantidadEscaneadaNueva} de ${lastScan.cantidadSolicitada} pzas para la tienda]"
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECCIÓN ÚLTIMO ESCANEO
        const Text(
          "ÚLTIMO ESCANEO",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        _buildScanCard(lastScan, isLast: true, currentQty: currentQty),

        if (previousScans.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            "ANTERIORES (últimos 5)",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              //Transparente
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
                    SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScanCard(
    ScanModel scan, {
    required bool isLast,
    String currentQty = '',
  }) {
    final DateTime fechaEscaneo = DateTime.parse(scan.fecha.toString());
    final String horaFormateada = DateFormat('HH:mm:ss').format(fechaEscaneo);

    return InkWell(
      onTap: () => _showResultBottomSheet(scan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(isLast ? 16 : 12),
        decoration: BoxDecoration(
          color: isLast
              ? const Color.fromARGB(186, 249, 254, 248)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLast
                ? const Color.fromARGB(255, 23, 147, 33)
                : Colors.grey.shade300,
            width: isLast ? 1.5 : 1,
          ),
        ),
        child: isLast
            ? _buildHighlightedScan(context, scan, horaFormateada, currentQty)
            : _buildNormalScan(context, scan, horaFormateada),
      ),
    );
  }

  Widget _buildHighlightedScan(
    BuildContext context,
    ScanModel scan,
    String hora,
    String currentQty,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // MENSAJE DE ÉXITO
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: _scale(context, 16),
            ),
            const SizedBox(width: 6),
            Text(
              "UPC agregado $currentQty",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: _scale(context, 14),
              ),
            ),
          ],
        ),

        SizedBox(height: _scale(context, 5)),

        // TIENDA
        Center(
          child: Column(
            children: [
              Text(
                "#${scan.idTiendaDestino} ${scan.claveDestino}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _scale(context, 46),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                scan.nombreDestino,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _scale(context, 13),
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        SizedBox(height: _scale(context, 14)),

        // PRODUCTO
        Text(
          scan.nombre,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _scale(context, 16),
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: _scale(context, 4)),

        // UPC CENTRADO
        Text(
          scan.upc,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _scale(context, 13),
            color: Colors.grey[600],
            letterSpacing: 1.2,
          ),
        ),

        SizedBox(height: _scale(context, 4)),

        // FOOTER
        Row(
          children: [
            // Hora: izquierda real
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  hora,
                  style: TextStyle(
                    fontSize: _scale(context, 13),
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),

            // Cantidad: centro real
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  "x${scan.cantidad} pzas",
                  style: TextStyle(
                    fontSize: _scale(context, 20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Spacer derecho para balancear
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildNormalScan(BuildContext context, ScanModel scan, String hora) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${scan.upc} | ${scan.categoria} | ${scan.plataforma}",
                style: TextStyle(
                  fontSize: _scale(context, 11),
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: _scale(context, 4)),
              Text(
                "#${scan.idTiendaDestino} ${scan.claveDestino} - ${scan.nombreDestino}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _scale(context, 14),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: _scale(context, 4)),
              Text(
                scan.nombre,
                style: TextStyle(fontSize: _scale(context, 13)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              hora,
              style: TextStyle(
                fontSize: _scale(context, 12),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: _scale(context, 6)),
            Text(
              "x${scan.cantidad}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: _scale(context, 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    if (!_isDeleting || !_isLoadingUltimos) {
      return const SizedBox.shrink();
    }

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
                  onPressed: () => {
                    //Borramos contenido de el input
                    _upcController.clear(),
                    Navigator.pop(context),
                  },
                  child: const Text(
                    "Entendido",
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

double _scale(BuildContext context, double base) {
  final width = MediaQuery.of(context).size.width;

  // 400 = móvil chico
  // 1200 = ventana desktop promedio
  final factor = (width / 1200).clamp(0.8, 1.4);

  return base * factor;
}
