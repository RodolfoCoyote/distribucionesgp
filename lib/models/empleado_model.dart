class EmpleadoModel {
  final int idEmpleado;
  final String nombre;
  final int idZona;
  final String zona;

  EmpleadoModel({
    required this.idEmpleado,
    required this.nombre,
    required this.idZona,
    required this.zona,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_empleado': idEmpleado,
      'nombre_completo': nombre,
      'id_zona': idZona,
      'zona': zona,
    };
  }

  factory EmpleadoModel.fromJson(Map<String, dynamic> json) {
    return EmpleadoModel(
      idEmpleado: int.tryParse(json['id_empleado'].toString()) ?? 0,
      nombre: json['nombre_completo'],
      idZona: int.tryParse(json['id_zona'].toString()) ?? 0,
      zona: json['zona'],
    );
  }

  factory EmpleadoModel.empty() {
    return EmpleadoModel(idEmpleado: 0, nombre: '', idZona: 0, zona: '');
  }
}
