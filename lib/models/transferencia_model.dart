class TransferenciaModel {
  final int id;
  final String nombre;
  final List<int> transferenciasCreadas;
  final int tiendaOrigen;
  final String observaciones;
  final DateTime createdAt;

  TransferenciaModel({
    required this.id,
    required this.nombre,
    required this.transferenciasCreadas,
    required this.tiendaOrigen,
    required this.observaciones,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_lista_distribucion': id,
      'nombre_distribucion': nombre,
      'transferencias_creadas': transferenciasCreadas,
      'tienda_origen': tiendaOrigen,
      'observaciones': observaciones,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransferenciaModel.fromJson(Map<String, dynamic> json) {
    return TransferenciaModel(
      id: int.tryParse(json['id_lista_distribucion'].toString()) ?? 0,
      nombre: json['nombre_distribucion'],
      transferenciasCreadas: (json['transferencias_creadas'] as List<dynamic>)
          .map((e) => int.tryParse(e['id_transferencia'].toString()) ?? 0)
          .toList(),
      tiendaOrigen: int.tryParse(json['tienda_origen'].toString()) ?? 0,
      observaciones: json['observaciones'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  factory TransferenciaModel.empty() {
    return TransferenciaModel(
      id: 0,
      nombre: '',
      transferenciasCreadas: [],
      tiendaOrigen: 0,
      observaciones: '',
      createdAt: DateTime.now(),
    );
  }
}
