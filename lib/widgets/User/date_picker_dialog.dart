import 'package:flutter/material.dart';

class ProfileDatePickerDialog {
  static Future<DateTime?> show(BuildContext context, DateTime? initialDate) async {
    final now = DateTime.now();

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    return selectedDate;
  }
}
