import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:danentang/models/CartItem.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/constants/colors.dart';

class CartItemWidget extends StatefulWidget {
  final CartItem item;
  final Product product;
  final bool isEditing;
  final VoidCallback onDelete;
  final Function(int) onQuantityChanged;
  final bool isMobile;
  final List<ProductVariant> variants;
  final Function(String?)? onVariantChanged;
  final Function(bool) onSelectionChanged;

  const CartItemWidget({
    Key? key,
    required this.item,
    required this.product,
    required this.isEditing,
    required this.onDelete,
    required this.onQuantityChanged,
    required this.isMobile,
    required this.variants,
    this.onVariantChanged,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  _CartItemWidgetState createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    final currentVariant = widget.variants.firstWhere(
          (v) => v.id == widget.item.productVariantId,
      orElse: () => widget.variants.isNotEmpty
          ? widget.variants.first
          : ProductVariant(
        id: '',
        variantName: 'Không có',
        additionalPrice: 0,
        inventory: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(), originalPrice: 0,
      ),
    );

    // Handle image (Base64 or network)
    final imageUrl = widget.product.images.isNotEmpty ? widget.product.images.first.url : '';
    Widget imageWidget;
    if (imageUrl.isEmpty) {
      imageWidget = const Icon(Icons.image, color: Colors.grey, size: 40);
    } else {
      try {
        // Try decoding as Base64
        final bytes = base64Decode(imageUrl);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: widget.isMobile ? 50 : 60,
          height: widget.isMobile ? 50 : 60,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to network image if Base64 decoding fails
            return Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: widget.isMobile ? 50 : 60,
              height: widget.isMobile ? 50 : 60,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image, color: Colors.grey, size: 40),
            );
          },
        );
      } catch (_) {
        // Fallback to network image if Base64 decoding fails
        imageWidget = Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: widget.isMobile ? 50 : 60,
          height: widget.isMobile ? 50 : 60,
          errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.image, color: Colors.grey, size: 40),
        );
      }
    }

    // Fallback colors if AppColors is undefined
    const purpleColor = Color(0xFF2E2E2E);
    const greyColor = Color(0xFF757575);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.white,
        elevation: widget.isMobile ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(widget.isMobile ? 8 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    isSelected = value ?? false;
                  });
                  widget.onSelectionChanged(isSelected);
                },
                activeColor: purpleColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: widget.isMobile ? 50 : 60,
                height: widget.isMobile ? 50 : 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageWidget,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.isMobile && widget.isEditing || !widget.isMobile)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: widget.onDelete,
                            hoverColor: Colors.red.withOpacity(0.2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.variants.length > 1)
                      DropdownButton<String>(
                        value: widget.item.productVariantId,
                        items: widget.variants
                            .map(
                              (v) => DropdownMenuItem(
                            value: v.id,
                            child: Text(
                              '${v.variantName} (+₫${v.additionalPrice.toStringAsFixed(0)})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: widget.onVariantChanged,
                        isExpanded: true,
                        underline: Container(
                          height: 1,
                          color: const Color(0xFFE0E0E0),
                        ),
                      )
                    else
                      Text(
                        currentVariant.variantName,
                        style: TextStyle(
                          fontSize: 14,
                          color: greyColor,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₫${currentVariant.additionalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle,
                                color: purpleColor,
                              ),
                              onPressed: () {
                                if (widget.item.quantity > 1) {
                                  widget.onQuantityChanged(widget.item.quantity - 1);
                                }
                              },
                            ),
                            Text(
                              widget.item.quantity.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF333333),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                color: purpleColor,
                              ),
                              onPressed: () {
                                widget.onQuantityChanged(widget.item.quantity + 1);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}