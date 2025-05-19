import 'package:flutter/material.dart';
import 'package:danentang/models/voucher.dart';

class VoucherSelectionScreen extends StatelessWidget {
  final List<Voucher> vouchers = [
    Voucher(
      code: 'CHAO200',
      description: 'Giảm 50%',
      condition: 'Thêm sản phẩm trị giá 50.000đ để sử dụng',
      discount: 0.5,
    ),
    Voucher(
      code: 'HOAN12K',
      description: 'Hoàn tiền lên tới 12.000đ',
      condition: 'Thêm sản phẩm trị giá 50.000đ để sử dụng',
      discount: 12.0,
    ),
    Voucher(
      code: 'COMBO50',
      description: 'Giảm 50% cho đơn Combo',
      condition: 'Thêm sản phẩm trị giá 700.000đ để sử dụng',
      discount: 0.5,
    ),
    Voucher(
      code: 'CHAO200NEW',
      description: 'Giảm 50% cho đơn đầu tiên',
      condition: 'Thêm sản phẩm trị giá 50.000đ để sử dụng',
      discount: 0.5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã khuyến mãi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Ưu đãi dành cho bạn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...vouchers.map((voucher) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(voucher.code),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(voucher.condition),
                    Text(voucher.description),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, voucher);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('SỬ DỤNG'),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
