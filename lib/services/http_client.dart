import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_headers.dart';
import '../secrets.dart';

class HttpClient {
  final String baseUrl;

  HttpClient({this.baseUrl = backendUrl});

  Future<http.Response> get(String endpoint) async {
    final headers = await AuthHeaders.getHeaders();
    final url = '$baseUrl$endpoint';
    return http.get(Uri.parse(url), headers: headers);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await AuthHeaders.getHeaders();
    final url = '$baseUrl$endpoint';
    return http.post(Uri.parse(url), headers: headers, body: json.encode(body));
  }

  // Se precisar, add PUT, DELETE, PATCH do mesmo jeito
}
