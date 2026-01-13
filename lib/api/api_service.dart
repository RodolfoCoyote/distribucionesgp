import 'package:chopper/chopper.dart';
import 'package:distribucionesgp/api/auth_interceptor.dart';
import 'package:distribucionesgp/utils/constants.dart';

part 'api_service.chopper.dart';

@ChopperApi(baseUrl: "/")
abstract class ApiService extends ChopperService {
  // Login
  @Post(path: 'auth/inicio_empleado')
  Future<Response> login(@Body() Map<String, dynamic> body);

  // Obtener distribuciones
  @Get(path: 'logistica/distribuciones/transferencias')
  Future<Response> getDistributions();

  @Post(path: 'logistica/distribuciones/escaneo_upc')
  Future<Response> scanUpc(@Body() Map<String, dynamic> body);

  @Post(path: 'logistica/distribuciones/rollback_ultimo_upc')
  Future<Response> rollbackUltimoUpc(@Body() Map<String, dynamic> body);

  @Get(path: 'logistica/distribuciones/ultimos_escaneos/{empleadoId}')
  Future<Response> getUltimosEscaneos(@Path('empleadoId') String empleadoId);

  static ApiService create() {
    final client = ChopperClient(
      baseUrl: Uri.parse(AppConstants.apiBaseUrl),
      services: [_$ApiService()],
      // Usar el convertidor estándar para éxito y error
      converter: const JsonConverter(),
      errorConverter: const JsonConverter(), // <--- AGREGA ESTA LÍNEA
      interceptors: [HttpLoggingInterceptor(), AuthInterceptor()],
    );
    return _$ApiService(client);
  }
}
