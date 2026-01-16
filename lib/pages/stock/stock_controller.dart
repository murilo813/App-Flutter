import 'package:alembro/models/product.dart';
import 'package:alembro/services/local/storage_service.dart';

class StockData {
  final List<Product> products;
  final String? lastSynced;
  StockData(this.products, this.lastSynced);
}

class StockController {
  Future<StockData> loadStock() async {
    final json = await BaseStorage.getRawData('stock.json');
    
    if (json == null || json['data'] == null) {
      return StockData([], null);
    }

    final List<Product> products = (json['data'] as List)
        .map((e) => Product.fromJson(e))
        .toList();

    return StockData(products, json['lastSynced']);
  }
}
