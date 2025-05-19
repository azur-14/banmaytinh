import 'package:flutter/material.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/Screens/Customer/Payment/payment_screen.dart';

class BuyNowDialog extends StatefulWidget {
  final Product product;
  final double discountedPrice;
  const BuyNowDialog({super.key, required this.product, required this.discountedPrice});

  @override
  _BuyNowDialogState createState() => _BuyNowDialogState();
}

class _BuyNowDialogState extends State<BuyNowDialog> {
  String selectedColor = '';
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.product.variants.isNotEmpty ? widget.product.variants[0].variantName : 'Default';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth <= 800) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildDialogContent(isMobile: true),
        ).then((_) => Navigator.pop(context));
      }
    });
  }

  Widget _buildDialogContent({required bool isMobile}) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        String localSelectedColor = selectedColor;
        int localQuantity = quantity;
        int maxQuantity = _getMaxQuantity(localSelectedColor);

        // Define color scheme
        const primaryColor = Color(0xFF333333); // Dark gray for text and accents
        const accentColor = Color(0xFF1E90FF); // Warm orange for buttons
        const backgroundColor = Color(0xFFF9F9F9); // Soft white background
        const secondaryColor = Color(0xFFE0E0E0); // Light gray for borders

        return Container(
          width: double.infinity,
          height: isMobile ? MediaQuery.of(context).size.height * 0.85 : null,
          decoration: isMobile
              ? const BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          )
              : null,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMobile)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: primaryColor.withOpacity(0.6), size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₫${widget.discountedPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mã sản phẩm: ${widget.product.id}',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tên sản phẩm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Biến thể',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.product.variants.map((variant) {
                      bool isSelected = localSelectedColor == variant.variantName;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            localSelectedColor = variant.variantName;
                            maxQuantity = _getMaxQuantity(localSelectedColor);
                            if (localQuantity > maxQuantity) {
                              localQuantity = maxQuantity;
                            }
                            selectedColor = localSelectedColor;
                            quantity = localQuantity;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : Colors.white,
                            border: Border.all(color: secondaryColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            variant.variantName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Số lượng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: secondaryColor),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: primaryColor, size: 24),
                              onPressed: localQuantity > 1
                                  ? () {
                                setState(() {
                                  localQuantity--;
                                  quantity = localQuantity;
                                });
                              }
                                  : null,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              constraints: const BoxConstraints(),
                            ),
                            Container(
                              width: 50,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '$localQuantity',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: primaryColor, size: 24),
                              onPressed: localQuantity < maxQuantity
                                  ? () {
                                setState(() {
                                  localQuantity++;
                                  quantity = localQuantity;
                                });
                              }
                                  : null,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        'Tồn kho: $maxQuantity',
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              products: [
                                {
                                  'product': widget.product,
                                  'color': localSelectedColor,
                                  'quantity': localQuantity,
                                },
                              ],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Mua ngay',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _getMaxQuantity(String color) {
    if (widget.product.variants.isEmpty) {
      return 100;
    }
    return widget.product.variants
        .firstWhere((variant) => variant.variantName == color, orElse: () => widget.product.variants[0])
        .inventory ??
        100;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return isDesktop
        ? AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFFF9F9F9),
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          child: _buildDialogContent(isMobile: false),
        ),
      ),
    )
        : const SizedBox();
  }
}