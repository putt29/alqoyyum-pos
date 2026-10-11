import '../core/json.dart';
import '../models/catalog.dart';
import '../services/api_client.dart';

class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Future<List<ProductCategory>> categories() async {
    final data = await _api.get('/api/categories');
    return asList(data).map((e) => ProductCategory.fromJson(asMap(e))).toList();
  }

  Future<List<Product>> products({String q = '', int? categoryId, bool includeInactive = false}) async {
    final data = await _api.get('/api/products', query: {
      'q': q,
      'category_id': categoryId,
      'include_inactive': includeInactive ? 'true' : null,
    });
    return asList(data).map((e) => Product.fromJson(asMap(e))).toList();
  }

  Future<Product> createProduct(Map<String, dynamic> body) async =>
      Product.fromJson(asMap(await _api.post('/api/products', body: body)));

  Future<Product> updateProduct(int id, Map<String, dynamic> body) async =>
      Product.fromJson(asMap(await _api.patch('/api/products/$id', body: body)));
}
