import 'package:flutter/material.dart';
import 'package:danentang/models/card_info.dart';
import 'package:danentang/Screens/Customer/Payment/payment_method_screen.dart';

class PaymentMethodCard extends StatelessWidget {
  final String? selectedPaymentMethod;
  final CardInfo? selectedCard;
  final List<CardInfo> cards;
  final Function(Map<String, dynamic>?) onPaymentMethodUpdated;
  final double cardMaxWidth;

  const PaymentMethodCard({
    super.key,
    required this.selectedPaymentMethod,
    required this.selectedCard,
    required this.cards,
    required this.onPaymentMethodUpdated,
    required this.cardMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn phương thức thanh toán',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            constraints: BoxConstraints(maxWidth: cardMaxWidth),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'Paypal',
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) => onPaymentMethodUpdated({'paymentMethod': value, 'card': selectedCard, 'cards': cards}),
                  title: const Text('Paypal', style: TextStyle(color: Color(0xFF2D3748))),
                  secondary: const Icon(Icons.paypal, color: Color(0xFF4299E1), size: 20),
                ),
                RadioListTile<String>(
                  value: 'Credit Card',
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) => onPaymentMethodUpdated({'paymentMethod': value, 'card': selectedCard, 'cards': cards}),
                  title: const Text('Credit Card', style: TextStyle(color: Color(0xFF2D3748))),
                  secondary: const Icon(Icons.credit_card, color: Color(0xFF4299E1), size: 20),
                ),
                if (selectedPaymentMethod == 'Credit Card') ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedCard != null ? 'Thẻ tín dụng ${selectedCard!.cardNumber}' : 'Chưa có thẻ được chọn',
                                style: const TextStyle(color: Color(0xFF2D3748), fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              if (selectedCard != null)
                                Text(
                                  'Hết hạn: ${selectedCard!.expiryDate}',
                                  style: const TextStyle(color: Color(0xFF718096), fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentMethodScreen(
                                  initialPaymentMethod: selectedPaymentMethod!,
                                  initialCard: selectedCard,
                                  cards: cards,
                                ),
                              ),
                            );
                            onPaymentMethodUpdated(result);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: const Color(0xFF5A4FCF).withAlpha(26),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Chọn thẻ',
                            style: TextStyle(color: Color(0xFF5A4FCF), fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                RadioListTile<String>(
                  value: 'Cash',
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) => onPaymentMethodUpdated({'paymentMethod': value, 'card': selectedCard, 'cards': cards}),
                  title: const Text('Cash', style: TextStyle(color: Color(0xFF2D3748))),
                  secondary: const Icon(Icons.money, color: Color(0xFF38B2AC), size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}