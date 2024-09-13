import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:shoplifter/main.dart' as entrypoint;  // Replace 'your_app' with the actual package name
void main() {
  setUrlStrategy(PathUrlStrategy());
  entrypoint.main();
}
