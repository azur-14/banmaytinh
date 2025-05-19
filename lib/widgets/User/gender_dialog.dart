import 'package:danentang/models/User.dart';
import 'package:flutter/material.dart';

class GenderDialog {
  static Future<String?> show(BuildContext context, {String? currentGender}) async {
    return await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn giới tính'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Nam', 'Nữ', 'Khác'].map((gender) {
              return RadioListTile<String>(
                title: Text(gender),
                value: gender,
                groupValue: currentGender,
                onChanged: (value) => Navigator.pop(context, value),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }
}