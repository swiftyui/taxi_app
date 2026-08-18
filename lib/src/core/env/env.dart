import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
final class Env {
  @EnviedField(
    varName: 'googleMapsApiKey',
    obfuscate: true,
    useConstantCase: true,
  )
  static final String googleMapsApiKey = _Env.googleMapsApiKey;
}
