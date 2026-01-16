import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:alembro/secrets.dart';


Future<bool> hasInternetConnection() async {
  final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());

  if (connectivityResult.contains(ConnectivityResult.none)){
    return false;
  }

  try {
    final response = await http
        .head(Uri.parse('$backendUrl/ping'))
        .timeout(const Duration(seconds: 6));
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}