import 'package:flutter/material.dart';
import 'package:danentang/Screens/Customer/Payment/add_card_screen.dart';
import 'package:danentang/models/card_info.dart'; // Import the shared CardInfo model

class PaymentMethodScreen extends StatefulWidget {
  final String initialPaymentMethod;
  final CardInfo? initialCard;
  final List<CardInfo> cards;

  const PaymentMethodScreen({
    super.key,
    required this.initialPaymentMethod,
    this.initialCard,
    required this.cards,
  });

  @override
  _PaymentMethodScreenState createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  late String selectedPaymentMethod;
  late List<CardInfo> cards;
  CardInfo? selectedCard;

  @override
  void initState() {
    super.initState();
    selectedPaymentMethod = widget.initialPaymentMethod;
    cards = widget.cards;
    selectedCard = widget.initialCard;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    final cardMaxWidth = isWeb ? 600.0 : double.infinity;
    final cardMinHeight = 80.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text('Payment Methods', style: TextStyle(color: Color(0xFF2D3748))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context, {
            'paymentMethod': selectedPaymentMethod,
            'card': selectedCard,
            'cards': cards,
          }),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: cardMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Credit & Debit Card',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final newCard = await Navigator.push<CardInfo>(
                                context,
                                MaterialPageRoute(builder: (_) => const AddCardScreen()),
                              );
                              if (newCard != null) {
                                setState(() {
                                  cards.add(newCard);
                                  selectedCard = newCard;
                                  selectedPaymentMethod = 'Credit Card';
                                });
                              }
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: const Icon(Icons.credit_card, color: Colors.brown, size: 24),
                              title: const Text(
                                'Add Card',
                                style: TextStyle(color: Color(0xFF2D3748)),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Color(0xFF718096)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: cardMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'More Payment Options',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                            ),
                          ),
                          RadioListTile<String>(
                            value: 'Paypal',
                            groupValue: selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                selectedPaymentMethod = value!;
                                selectedCard = null;
                              });
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                            title: const Text(
                              'Paypal',
                              style: TextStyle(color: Color(0xFF2D3748)),
                            ),
                          ),
                          RadioListTile<String>(
                            value: 'Apple Pay',
                            groupValue: selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                selectedPaymentMethod = value!;
                                selectedCard = null;
                              });
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                            title: const Text(
                              'Apple Pay',
                              style: TextStyle(color: Color(0xFF2D3748)),
                            ),
                          ),
                          RadioListTile<String>(
                            value: 'Google Pay',
                            groupValue: selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                selectedPaymentMethod = value!;
                                selectedCard = null;
                              });
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                            title: const Text(
                              'Google Pay',
                              style: TextStyle(color: Color(0xFF2D3748)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'paymentMethod': selectedPaymentMethod,
                    'card': selectedCard,
                    'cards': cards,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0x8B451F), // Brown color similar to the image
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'Confirm Payment',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}