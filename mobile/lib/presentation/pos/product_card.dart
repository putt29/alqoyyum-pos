import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../models/catalog.dart';
import '../../widgets/common.dart';

/// Kartu produk: icon, nama, kategori, harga, dan kontrol quantity bila sudah dipilih.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Product product;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final inCart = quantity > 0;
    final priceText = product.priceEditable && product.salePrice == 0 ? 'Isi harga' : rp(product.salePrice);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: inCart ? AppColors.navy : AppColors.line, width: inCart ? 1.8 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: AppColors.veryLightBlue, borderRadius: BorderRadius.circular(13)),
                child: Center(child: ItemIcon(iconName: product.iconName, categoryName: product.categoryName, size: 34)),
              ),
              const Spacer(),
              if (product.priceEditable) const StatusPill(text: 'Harga bebas'),
            ]),
            const SizedBox(height: 8),
            Text(product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.15)),
            const SizedBox(height: 2),
            Text(product.categoryName, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
            const Spacer(),
            Text(priceText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.navy)),
            const SizedBox(height: 6),
            SizedBox(
              height: 30,
              child: inCart
                  ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      RoundIconButton(icon: Icons.remove, onTap: onDecrement, filled: false),
                      Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      RoundIconButton(icon: Icons.add, onTap: onIncrement, filled: true),
                    ])
                  : Align(
                      alignment: Alignment.centerRight,
                      child: RoundIconButton(icon: Icons.add, onTap: onTap, filled: true),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap, required this.filled, this.size = 30});

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.navy : AppColors.veryLightBlue,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.6, color: filled ? Colors.white : AppColors.navy),
        ),
      ),
    );
  }
}
