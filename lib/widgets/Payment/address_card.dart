import 'package:flutter/material.dart';
import 'package:danentang/models/Address.dart';
import 'package:danentang/models/User.dart';
import 'package:danentang/Screens/Customer/Payment/address_selection_screen.dart';

class AddressCard extends StatelessWidget {
  final Address? selectedAddress;
  final bool isHovered;
  final Function(bool) onHover;
  final Function(Address?) onAddressSelected;
  final User user;
  final double cardMaxWidth;
  final double cardMinHeight;

  const AddressCard({
    super.key,
    required this.selectedAddress,
    required this.isHovered,
    required this.onHover,
    required this.onAddressSelected,
    required this.user,
    required this.cardMaxWidth,
    required this.cardMinHeight,
  });

  @override
  Widget build(BuildContext context) {
    final fullAddress = [
      selectedAddress?.addressLine,
      selectedAddress?.commune,
      selectedAddress?.district,
      selectedAddress?.city,
    ].where((part) => part != null && part.isNotEmpty).join(', ');

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: Card(
        elevation: isHovered ? 6 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isHovered ? Colors.white.withAlpha(242) : Colors.white,
        child: InkWell(
          onTap: () async {
            final chosenAddress = await Navigator.push<Address?>(
              context,
              MaterialPageRoute(
                builder: (_) => AddressSelectionScreen(user: user),
              ),
            );
            onAddressSelected(chosenAddress);
          },
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: cardMinHeight, maxWidth: cardMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF718096)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Địa chỉ giao hàng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selectedAddress?.receiverName ?? 'Không có tên người nhận',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF2D3748)),
                        ),
                        Text(
                          fullAddress.isEmpty ? 'Chưa có địa chỉ' : fullAddress,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF718096)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Thay đổi',
                    style: TextStyle(
                      color: isHovered ? const Color(0xFF5A4FCF) : const Color(0xFF718096),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}