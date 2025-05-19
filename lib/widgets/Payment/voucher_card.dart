import 'package:flutter/material.dart';
import 'package:danentang/models/voucher.dart';
import 'package:danentang/Screens/Customer/Payment/voucher_selection_screen.dart';

class VoucherCard extends StatelessWidget {
  final Voucher? selectedVoucher;
  final Function(Voucher?) onVoucherSelected;
  final double cardMaxWidth;
  final double cardMinHeight;

  const VoucherCard({
    super.key,
    required this.selectedVoucher,
    required this.onVoucherSelected,
    required this.cardMaxWidth,
    required this.cardMinHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoàn tất Voucher',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            onTap: () async {
              final chosen = await Navigator.push<Voucher>(
                context,
                MaterialPageRoute(builder: (_) => VoucherSelectionScreen()),
              );
              onVoucherSelected(chosen);
            },
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: cardMinHeight, maxWidth: cardMaxWidth),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  selectedVoucher?.code ?? 'Chọn mã giảm giá',
                  style: const TextStyle(color: Color(0xFF2D3748)),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF718096)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}