import 'package:flutter/material.dart';

class OrderSummaryWidget extends StatelessWidget {
  final double subtotal;
  final double vat;
  final double shipping;
  final double discount;
  final double total;
  final TextEditingController discountController;
  final VoidCallback onApplyCoupon;
  final bool applyingCoupon;
  final String? errorCoupon;
  final int loyaltyPointsAvailable;
  final int loyaltyPointsToUse;
  final TextEditingController loyaltyController;
  final ValueChanged<String> onLoyaltyChanged;
  final VoidCallback onCheckout;

  // Thêm các thuộc tính để xử lý coupon rõ ràng
  final int couponDiscountValue;
  final bool couponApplied;
  final VoidCallback onRemoveCoupon;

  const OrderSummaryWidget({
    Key? key,
    required this.subtotal,
    required this.vat,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.discountController,
    required this.onApplyCoupon,
    required this.applyingCoupon,
    required this.errorCoupon,
    required this.loyaltyPointsAvailable,
    required this.loyaltyPointsToUse,
    required this.loyaltyController,
    required this.onLoyaltyChanged,
    required this.onCheckout,
    // Thêm 3 prop cho coupon
    required this.couponDiscountValue,
    required this.couponApplied,
    required this.onRemoveCoupon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Discount không vượt quá subtotal
    final int displayedDiscount = discount > subtotal ? subtotal.toInt() : discount.toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white, // Keep background white
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tóm tắt đơn hàng",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Mã giảm giá
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: discountController,
                  enabled: !couponApplied, // Disable nếu đã có mã
                  decoration: InputDecoration(
                    hintText: "Nhập mã giảm giá",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Color(0xFFB3E5FC)), // Blue-grey border
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              couponApplied
                  ? IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: "Hủy mã giảm giá",
                onPressed: onRemoveCoupon,
              )
                  : ElevatedButton(
                onPressed: applyingCoupon ? null : onApplyCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7), // Light blue button
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: applyingCoupon
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text("Áp dụng"),
              ),
            ],
          ),
          if (couponApplied)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "Điểm từ mã giảm giá: -₫$couponDiscountValue",
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (couponApplied)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                "Chỉ được sử dụng 1 mã giảm giá cho mỗi đơn hàng.",
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (errorCoupon != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                errorCoupon!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          const SizedBox(height: 12),
          // Điểm tích lũy
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Điểm tích lũy"),
              Text("Bạn có $loyaltyPointsAvailable điểm"),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: loyaltyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Nhập điểm muốn dùng",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Color(0xFFB3E5FC)), // Blue-grey border
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: onLoyaltyChanged,
                ),
              ),
              const SizedBox(width: 8),
              Text("= ₫${loyaltyPointsToUse * 1000}"),
            ],
          ),
          const SizedBox(height: 16),
          // Tóm tắt giá trị
          _buildSummaryRow("Giá", "₫${subtotal.toInt()}"),
          _buildSummaryRow("VAT", "₫${vat.toInt()}"),
          _buildSummaryRow("Vận chuyển", "₫${shipping.toInt()}"),
          _buildSummaryRow("Giảm giá", "-₫$displayedDiscount"),
          const Divider(),
          _buildSummaryRow(
            "Tổng giá",
            "₫${total.toInt()}",
            isTotal: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC3F7), // Light blue button
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              "Mua ngay",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : const Color(0xFF0288D1), // Darker blue for non-total text
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : const Color(0xFF0288D1), // Darker blue for non-total text
            ),
          ),
        ],
      ),
    );
  }
}