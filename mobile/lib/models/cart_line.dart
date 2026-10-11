import 'catalog.dart';

class CartLine {
  CartLine(this.product, {this.quantity = 1, int? unitPrice}) : unitPrice = unitPrice ?? product.salePrice;

  final Product product;
  int quantity;
  int unitPrice;

  int get subtotal => unitPrice * quantity;
}
