import 'package:danentang/models/User.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class EditDialog {
  static Future<String?> show(
      BuildContext context,
      String initialValue, // ✅ sửa lại kiểu này
      String field,
      String title,
      ) async {
    final TextEditingController controller = TextEditingController(text: initialValue);
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chỉnh sửa $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Nhập $title mới'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}
