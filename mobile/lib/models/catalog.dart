import '../core/json.dart';

class ProductCategory {
  const ProductCategory({required this.id, required this.name, required this.receiptLabel, required this.iconName});

  final int id;
  final String name;
  final String receiptLabel;
  final String iconName;

  factory ProductCategory.fromJson(Map<String, dynamic> j) => ProductCategory(
        id: asInt(j['id']),
        name: asStr(j['name']),
        receiptLabel: asStr(j['receipt_label']),
        iconName: asStr(j['icon_name']),
      );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.unit,
    required this.costPrice,
    required this.salePrice,
    required this.priceEditable,
    required this.iconName,
    required this.isActive,
  });

  final int id;
  final String name;
  final int categoryId;
  final String categoryName;
  final String? unit;
  final double? costPrice;
  final int salePrice;
  final bool priceEditable;
  final String iconName;
  final bool isActive;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: asInt(j['id']),
        name: asStr(j['name']),
        categoryId: asInt(j['category_id']),
        categoryName: asStr(j['category_name']),
        unit: asStrOrNull(j['unit']),
        costPrice: asDoubleOrNull(j['cost_price']),
        salePrice: asInt(j['sale_price']),
        priceEditable: asBool(j['price_editable']),
        iconName: asStr(j['icon_name']),
        isActive: j['is_active'] == null ? true : asBool(j['is_active']),
      );
}
