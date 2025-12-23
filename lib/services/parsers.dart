import 'dart:convert';

List<Map<String, dynamic>> parseApiList(String responseBody) {
  final Map<String, dynamic> body = json.decode(responseBody);
  final List<dynamic> data = body['data'] ?? [];
  return List<Map<String, dynamic>>.from(data);
}

List<Map<String, dynamic>> parseLocalList(String content) {
  final Map<String, dynamic> jsonData = json.decode(content);
  final List<dynamic> data = jsonData['data'] ?? [];
  return List<Map<String, dynamic>>.from(data);
}