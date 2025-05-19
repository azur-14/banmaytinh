import 'package:flutter/material.dart';
import 'package:danentang/models/ship.dart';
import 'package:danentang/models/Address.dart';
import 'package:danentang/models/User.dart';
import 'package:danentang/Screens/Customer/Payment/shipping_selection_screen.dart';

/// A widget that displays the selected shipping method and allows the user to change it.
class ShippingMethodCard extends StatelessWidget {
  final ShippingMethod? selectedShippingMethod;
  final Address? selectedAddress;
  final User user;
  final Function(dynamic) onShippingMethodUpdated;
  final double cardMaxWidth;
  final double cardMinHeight;

  const ShippingMethodCard({
    super.key,
    required this.selectedShippingMethod,
    required this.selectedAddress,
    required this.user,
    required this.onShippingMethodUpdated,
    required this.cardMaxWidth,
    required this.cardMinHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Text(
          'Phương thức vận chuyển',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        // Card for selecting shipping method
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            onTap: () async {
              // Navigate to ShippingSelectionScreen and await result
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShippingSelectionScreen(
                    user: user,
                    selectedAddress: selectedAddress,
                    selectedShippingMethod: selectedShippingMethod,
                  ),
                ),
              );
              onShippingMethodUpdated(result);
            },
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: cardMinHeight,
                maxWidth: cardMaxWidth,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: selectedShippingMethod != null
                    ? const Icon(
                  Icons.check_circle,
                  color: Color(0xFF38B2AC),
                )
                    : null,
                title: Text(
                  selectedShippingMethod?.name ?? 'Chọn phương thức',
                  style: const TextStyle(color: Color(0xFF2D3748)),
                ),
                subtitle: Text(
                  selectedShippingMethod?.estimatedArrival != null
                      ? 'Ước tính giao hàng: ${selectedShippingMethod!.estimatedArrival}'
                      : '',
                  style: const TextStyle(color: Color(0xFF718096)),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF718096),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}