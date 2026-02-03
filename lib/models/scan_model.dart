class ScanModel {
  final int id;
  final int idEmpleado;
  final DateTime fecha;
  final int idDistribucion;
  final String upc;
  final String nombre;
  final int cantidad;
  final int esUltimo;
  final String tipoRegistro;
  final String categoria;
  final String plataforma;

  // --- Tienda Destino
  final int idTiendaDestino;
  final String claveDestino;
  final String nombreDestino;

  // --- Cantidades
  final int? cantidadSolicitada;
  final int? cantidadEscaneadaNueva;

  ScanModel({
    required this.upc,
    required this.nombre,
    required this.cantidad,
    this.id = 0,
    this.idEmpleado = 0,
    DateTime? fecha,
    this.idDistribucion = 0,
    this.esUltimo = 0,
    this.tipoRegistro = '',
    this.idTiendaDestino = 0,
    this.claveDestino = '',
    this.nombreDestino = '',
    this.categoria = 'N/A',
    this.plataforma = 'N/A',
    this.cantidadSolicitada,
    this.cantidadEscaneadaNueva,
  }) : fecha = fecha ?? DateTime.now();

  factory ScanModel.fromJson(Map<String, dynamic> json) {
    return ScanModel(
      // Usamos int.parse porque el JSON trae strings ("23")
      id: int.parse(json['id'].toString()),
      idEmpleado: int.parse(json['id_empleado'].toString()),
      fecha: DateTime.parse(json['fecha'] as String),
      idDistribucion: int.parse(json['id_distribucion'].toString()),
      upc: json['upc'] as String,
      nombre: json['nombre'] as String,
      // Ojo: en tu JSON se llama 'cantidad_escaneada'
      cantidad: int.parse(json['cantidad_escaneada'].toString()),
      esUltimo: int.parse(json['es_ultimo'].toString()),
      tipoRegistro: json['tipo_registro'] as String? ?? '',
      idTiendaDestino: int.parse(json['id_tienda_destino']?.toString() ?? '0'),
      claveDestino: json['clave_tienda_destino'] as String? ?? '',
      nombreDestino: json['nombre_tienda_destino'] as String? ?? '',
      categoria: json['categoria'] as String? ?? 'N/A',
      plataforma: json['plataforma'] as String? ?? 'N/A',
      cantidadEscaneadaNueva: json['cantidad_escaneada'] != null
          ? int.parse(json['cantidad_escaneada'].toString())
          : null,
      cantidadSolicitada: json['cantidad_solicitada'] != null
          ? int.parse(json['cantidad_solicitada'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_empleado': idEmpleado,
      'fecha': fecha.toIso8601String(),
      'id_distribucion': idDistribucion,
      'upc': upc,
      'nombre': nombre,
      'cantidad_escaneada': cantidad,
      'es_ultimo': esUltimo,
      'tipo_registro': tipoRegistro,
      'id_tienda_destino': idTiendaDestino,
      'clave_tienda_destino': claveDestino,
      'nombre_tienda_destino': nombreDestino,
      'categoria': categoria,
      'plataforma': plataforma,
      'cantidad_solicitada': cantidadSolicitada,
      'cantidad_escaneada_nueva': cantidadEscaneadaNueva,
    };
  }
}
