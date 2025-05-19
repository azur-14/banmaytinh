import 'package:flutter/material.dart';
import 'package:danentang/models/ship.dart';
import 'package:danentang/models/User.dart';
import 'package:danentang/models/Address.dart';

import 'address_selection_screen.dart';

class ShippingSelectionScreen extends StatefulWidget {
  final User user;
  final Address? selectedAddress; // Parameter for selected address
  final ShippingMethod? selectedShippingMethod; // Parameter for selected shipping method

  const ShippingSelectionScreen({
    super.key,
    required this.user,
    this.selectedAddress, // Optional selected address
    this.selectedShippingMethod, // Optional selected shipping method
  });

  @override
  _ShippingSelectionScreenState createState() => _ShippingSelectionScreenState();
}

class _ShippingSelectionScreenState extends State<ShippingSelectionScreen> {
  late ShippingMethod selectedMethod;

  @override
  void initState() {
    super.initState();
    // Initialize with the selected shipping method from the parent screen, or default to 'Tiết kiệm' if null
    selectedMethod = widget.selectedShippingMethod ??
        ShippingMethod(
          name: 'Tiết kiệm',
          estimatedArrival: DateTime.now().add(const Duration(days: 7)).toString().split(' ')[0], // 2025-05-21
          price: 20000,
        );
  }

  void _selectShippingMethod(ShippingMethod? method) {
    if (method == null) return;
    setState(() => selectedMethod = method);
    Navigator.pop(context, selectedMethod);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    // Use the selectedAddress if provided, otherwise fall back to the first address in user.addresses
    final Address? displayAddress = widget.selectedAddress ??
        (user.addresses.isNotEmpty ? user.addresses.first : null);

    // Format the address for display
    final addrLine = displayAddress != null
        ? [
      displayAddress.addressLine,
      displayAddress.commune,
      displayAddress.district,
      displayAddress.city,
    ].where((part) => part != null && part.isNotEmpty).join(', ')
        : 'Chưa có địa chỉ';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn phương thức giao hàng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Phương thức giao hàng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          RadioListTile<ShippingMethod>(
            title: const Text('Tiết kiệm'),
            subtitle: Text('Dự kiến giao: ${DateTime.now().add(const Duration(days: 7)).toString().split(' ')[0]}'), // 2025-05-21
            value: ShippingMethod(
              name: 'Tiết kiệm',
              estimatedArrival: DateTime.now().add(const Duration(days: 7)).toString().split(' ')[0],
              price: 20000,
            ),
            groupValue: selectedMethod,
            onChanged: _selectShippingMethod,
            secondary: selectedMethod.name == 'Tiết kiệm'
                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                : const Icon(Icons.local_shipping),
            activeColor: Colors.brown,
          ),
          RadioListTile<ShippingMethod>(
            title: const Text('Thông thường'),
            subtitle: Text('Dự kiến giao: ${DateTime.now().add(const Duration(days: 5)).toString().split(' ')[0]}'), // 2025-05-19
            value: ShippingMethod(
              name: 'Thông thường',
              estimatedArrival: DateTime.now().add(const Duration(days: 5)).toString().split(' ')[0],
              price: 30000,
            ),
            groupValue: selectedMethod,
            onChanged: _selectShippingMethod,
            secondary: selectedMethod.name == 'Thông thường'
                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                : const Icon(Icons.local_shipping),
            activeColor: Colors.brown,
          ),
          RadioListTile<ShippingMethod>(
            title: const Text('Hỏa tốc'),
            subtitle: Text('Dự kiến giao: ${DateTime.now().add(const Duration(days: 3)).toString().split(' ')[0]}'), // 2025-05-17
            value: ShippingMethod(
              name: 'Hỏa tốc',
              estimatedArrival: DateTime.now().add(const Duration(days: 3)).toString().split(' ')[0],
              price: 50000,
            ),
            groupValue: selectedMethod,
            onChanged: _selectShippingMethod,
            secondary: selectedMethod.name == 'Hỏa tốc'
                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                : const Icon(Icons.local_shipping),
            activeColor: Colors.brown,
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(displayAddress?.receiverName ?? user.fullName),
            subtitle: Text(addrLine),
            trailing: const Icon(Icons.check_circle_outline),
            onTap: () {
              // Navigate to address selection screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddressSelectionScreen(user: user),
                ),
              ).then((chosenAddress) {
                if (chosenAddress != null) {
                  // Update the selected address in the parent screen (PaymentScreen)
                  Navigator.pop(context, chosenAddress);
                }
              });
            },
          ),
        ],
      ),
    );
  }
}