import 'package:flutter/material.dart';
import 'package:danentang/models/Category.dart';
import 'package:intl/intl.dart'; // For formatting price

class FilterPanel extends StatelessWidget {
  final List<Category> categories;
  final List<String> brands;
  final String? selectedCategoryId;
  final String? selectedBrand;
  final double priceRange;
  final int? selectedRating;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onBrandChanged;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<double> onPriceChangeEnd;
  final ValueChanged<int?> onRatingChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const FilterPanel({
    super.key,
    required this.categories,
    required this.brands,
    this.selectedCategoryId,
    this.selectedBrand,
    required this.priceRange,
    this.selectedRating,
    required this.onCategoryChanged,
    required this.onBrandChanged,
    required this.onPriceChanged,
    required this.onPriceChangeEnd,
    required this.onRatingChanged,
    required this.onReset,
    required this.onApply,
  });

  // Format price with commas and VND symbol
  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: isMobile ? const EdgeInsets.all(8) : const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Filter Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 16),
            // Category Section
            Text(
              'Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: selectedCategoryId == null,
                    selectedColor: Colors.blue[100],
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: selectedCategoryId == null ? Colors.blue[700] : Colors.grey[800],
                      fontWeight: FontWeight.w600, // Bolder for "All"
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onSelected: (selected) {
                      if (selected) onCategoryChanged(null);
                    },
                  ),
                ),
                ...categories.map((category) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: selectedCategoryId == category.id,
                    selectedColor: Colors.blue[100],
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: selectedCategoryId == category.id ? Colors.blue[700] : Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onSelected: (selected) {
                      if (selected) onCategoryChanged(category.id);
                    },
                  ),
                )),
              ],
            ),
            const Divider(height: 24),
            // Brand Section
            Text(
              'Brand',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedBrand,
                hint: const Text('Select Brand'),
                isExpanded: true,
                underline: const SizedBox(),
                items: brands
                    .map((brand) => DropdownMenuItem<String>(
                  value: brand,
                  child: Text(brand),
                ))
                    .toList(),
                onChanged: onBrandChanged,
              ),
            ),
            const Divider(height: 24),
            // Price Range Section
            Text(
              'Price Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₫0', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(_formatPrice(100000000), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            Slider(
              value: priceRange,
              min: 0,
              max: 100000000,
              divisions: 100,
              activeColor: Colors.blue[700],
              inactiveColor: Colors.grey[300],
              label: _formatPrice(priceRange),
              onChanged: onPriceChanged,
              onChangeEnd: onPriceChangeEnd,
            ),
            Text(
              'Max: ${_formatPrice(priceRange)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const Divider(height: 24),
            // Rating Section
            Text(
              'Minimum Rating',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final rating = 5 - index;
                return GestureDetector(
                  onTap: () => onRatingChanged(rating),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: selectedRating != null && rating <= selectedRating!
                          ? Colors.blue[50]
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.star,
                      color: selectedRating != null && rating <= selectedRating!
                          ? Colors.amber
                          : Colors.grey,
                      size: 24,
                    ),
                  ),
                );
              }),
            ),
            const Divider(height: 24),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: onReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 2,
                  ),
                  child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 2,
                  ),
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}