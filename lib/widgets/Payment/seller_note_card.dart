import 'package:flutter/material.dart';

class SellerNoteCard extends StatelessWidget {
  final String? sellerNote;
  final Function(String?) onNoteUpdated;
  final double cardMaxWidth;
  final double cardMinHeight;

  const SellerNoteCard({
    super.key,
    required this.sellerNote,
    required this.onNoteUpdated,
    required this.cardMaxWidth,
    required this.cardMinHeight,
  });

  void _showNoteDialog(BuildContext context) async {
    final noteController = TextEditingController(text: sellerNote);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lời nhắn liên hệ với Shop', style: TextStyle(color: Color(0xFF2D3748))),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Nhập lời nhắn cho người bán...',
            hintStyle: TextStyle(color: Color(0xFF718096)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF718096))),
          ),
          TextButton(
            onPressed: () {
              onNoteUpdated(noteController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Xác nhận', style: TextStyle(color: Color(0xFF5A4FCF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lời nhắn liên hệ với Shop',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            onTap: () => _showNoteDialog(context),
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: cardMinHeight, maxWidth: cardMaxWidth),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  sellerNote ?? 'Nhấn để thêm lời nhắn',
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