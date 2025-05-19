import 'package:flutter/material.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/models/CartItem.dart';

class AddToCartDialog extends StatefulWidget {
  final Product product;
  final double discountedPrice;

  const AddToCartDialog({
    super.key,
    required this.product,
    required this.discountedPrice,
  });

  @override
  State<AddToCartDialog> createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends State<AddToCartDialog> {
  late String _selectedVariantName;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedVariantName = widget.product.variants.isNotEmpty
        ? widget.product.variants.first.variantName
        : '';
  }

  int get _maxQuantity {
    if (widget.product.variants.isEmpty) return 100;
    final v = widget.product.variants.firstWhere(
          (v) => v.variantName == _selectedVariantName,
      orElse: () => widget.product.variants.first,
    );
    return v.inventory;
  }

  void _decrement() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  void _increment() {
    if (_quantity < _maxQuantity) setState(() => _quantity++);
  }

  void _onAddPressed() {
    final variant = widget.product.variants.firstWhere(
          (v) => v.variantName == _selectedVariantName,
      orElse: () => widget.product.variants.first,
    );

    final item = CartItem(
      productId: widget.product.id,
      productVariantId: variant.id,
      quantity: _quantity,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    // Define color scheme
    const primaryColor = Color(0xFF333333); // Dark gray for text and accents
    const accentColor = Color(0xFF1E90FF); // Warm orange for buttons
    const backgroundColor = Color(0xFFF9F9F9); // Soft white background
    const secondaryColor = Color(0xFFE0E0E0); // Light gray for borders

    return AlertDialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        'Thêm vào giỏ hàng',
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Variant Selection
            Text(
              'Chọn biến thể',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.product.variants.map((v) {
                final selected = v.variantName == _selectedVariantName;
                return ChoiceChip(
                  label: Text(
                    v.variantName,
                    style: TextStyle(
                      color: selected ? Colors.white : primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: selected,
                  selectedColor: accentColor,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: secondaryColor),
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedVariantName = v.variantName;
                      if (_quantity > _maxQuantity) _quantity = _maxQuantity;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Quantity Selection
            Text(
              'Số lượng',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.remove, color: primaryColor, size: 24),
                  onPressed: _decrement,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: secondaryColor),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.add, color: primaryColor, size: 24),
                  onPressed: _increment,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 24),
                Text(
                  'Tồn: $_maxQuantity',
                  style: TextStyle(
                    color: primaryColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Hủy',
            style: TextStyle(
              color: primaryColor.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _onAddPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 0,
          ),
          child: const Text(
            'Thêm vào giỏ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}