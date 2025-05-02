import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://192.168.2.25:5000/'}); 

  Future<List<Product>> fetchProducts(String store) async {
    final response = await http.get(Uri.parse('$baseUrl/estoque/$store'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }
}
