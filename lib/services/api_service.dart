import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://192.168.2.27:5000/'}); 

  Future<List<Product>> fetchProducts() async {
    final url = '$baseUrl/estoque/geral';
    print('Fazendo requisição para: $url');
    try {
      final response = await http.get(Uri.parse(url));
      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao carregar produtos (status ${response.statusCode})');
      }
    } catch (e) {
      print('Erro na requisição: $e');
      throw Exception('Erro ao conectar: $e');
    }
  }
}
