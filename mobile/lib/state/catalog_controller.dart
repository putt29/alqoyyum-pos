import 'package:flutter/foundation.dart';

import '../core/errors.dart';
import '../models/catalog.dart';
import '../repositories/catalog_repository.dart';

/// Cache produk AKTIF untuk POS. Sumber data tetap server.
class CatalogController extends ChangeNotifier {
  CatalogController(this._repo);

  final CatalogRepository _repo;

  List<ProductCategory> categories = const [];
  List<Product> products = const [];
  bool loading = false;
  bool loaded = false;
  String? error;

  Future<void> load({bool force = false}) async {
    if (loading || (loaded && !force)) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      categories = await _repo.categories();
      products = await _repo.products();
      loaded = true;
    } catch (e) {
      error = errorMessage(e);
    }
    loading = false;
    notifyListeners();
  }

  List<Product> filter({String query = '', int? categoryId}) {
    final q = query.trim().toLowerCase();
    return products.where((p) {
      if (categoryId != null && p.categoryId != categoryId) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q);
    }).toList();
  }

  void reset() {
    categories = const [];
    products = const [];
    loaded = false;
    error = null;
    notifyListeners();
  }
}
