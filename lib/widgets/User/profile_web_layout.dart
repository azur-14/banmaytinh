import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';

import '../../Service/user_service.dart';
import '../../models/Address.dart';
import '../../models/User.dart';
import 'text_field_widget.dart';

class ProfileWebLayout extends StatefulWidget {
  const ProfileWebLayout({super.key});

  @override
  _ProfileWebLayoutState createState() => _ProfileWebLayoutState();
}

class _ProfileWebLayoutState extends State<ProfileWebLayout> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      if (email == null) throw Exception('Không tìm thấy email trong SharedPreferences');

      final user = await UserService().fetchUserByEmail(email);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Lỗi khi load user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin người dùng: $e')),
      );
    }
  }

  Future<void> _submitChanges() async {
    if (_user == null) return;
    try {
      final updatedUser = _user!.copyWith();
      await UserService().updateUserFull(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thông tin đã được lưu')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final bytes = await image.readAsBytes(); // đọc ảnh dưới dạng byte
        final base64Image = base64Encode(bytes); // mã hóa base64

        await UserService().updateAvatar(_user!.id!, base64Image); // API cập nhật avatar
        setState(() {
          _user = _user!.copyWith(avatarUrl: base64Image); // cập nhật UI
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ảnh đại diện đã được cập nhật')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
      );
    }
  }


  void _deleteImage() async {
    try {
      await UserService().deleteAvatar(_user!.id!); // gọi API xoá ảnh
      setState(() {
        _user = _user!.copyWith(avatarUrl: null);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xoá ảnh đại diện')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xoá ảnh: $e')),
      );
    }
  }


  void _editAddress(int index) async {
    final addr = _user!.addresses[index];
    final receiver = await _showInputDialog('Người nhận', addr.receiverName);
    final phone = await _showInputDialog('SĐT', addr.phone);
    final line = await _showInputDialog('Số nhà, tên đường', addr.addressLine);
    final commune = await _showInputDialog('Phường/Xã', addr.commune ?? '');
    final district = await _showInputDialog('Quận/Huyện', addr.district ?? '');
    final city = await _showInputDialog('Tỉnh/Thành phố', addr.city ?? '');

    if (receiver != null && phone != null && line != null) {
      final updated = addr.copyWith(
        receiverName: receiver,
        phone: phone,
        addressLine: line,
        commune: commune,
        district: district,
        city: city,
      );
      setState(() {
        final list = List<Address>.from(_user!.addresses);
        list[index] = updated;
        _user = _user!.copyWith(addresses: list);
      });
    }
  }

  void _deleteAddress(int index) {
    setState(() {
      final list = List<Address>.from(_user!.addresses);
      list.removeAt(index);
      _user = _user!.copyWith(addresses: list);
    });
  }

  void _addAddress() async {
    final receiver = await _showInputDialog('Người nhận', '');
    final phone = await _showInputDialog('SĐT', '');
    final line = await _showInputDialog('Số nhà, tên đường', '');
    final commune = await _showInputDialog('Phường/Xã', '');
    final district = await _showInputDialog('Quận/Huyện', '');
    final city = await _showInputDialog('Tỉnh/Thành phố', '');

    if (receiver != null && phone != null && line != null) {
      final newAddr = Address(
        receiverName: receiver,
        phone: phone,
        addressLine: line,
        commune: commune,
        district: district,
        city: city,
        isDefault: _user!.addresses.isEmpty,
      );
      setState(() {
        _user = _user!.copyWith(addresses: [..._user!.addresses, newAddr]);
      });
    }
  }

  void _setDefaultAddress(int index) {
    setState(() {
      final updated = _user!.addresses.asMap().entries.map((e) {
        return e.value.copyWith(isDefault: e.key == index);
      }).toList();
      _user = _user!.copyWith(addresses: updated);
    });
  }

  Future<String?> _showInputDialog(String title, String initial) async {
    final controller = TextEditingController(text: initial);
    return await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3e80f6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final maxWidth = constraints.maxWidth > 1200 ? 1200.0 : constraints.maxWidth * 0.9;
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
            ? 2
            : 1;

        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _isLoading || _user == null
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3e80f6)))
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: FadeIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundImage: _user!.avatarUrl != null
                                        ? MemoryImage(base64Decode(_user!.avatarUrl!))
                                        : null,
                                    backgroundColor: Colors.grey[200],
                                    child: _user!.avatarUrl == null
                                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _user!.fullName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildHoverButton(
                                  onPressed: _pickImage,
                                  text: 'TẢI ẢNH MỚI',
                                  isElevated: true,
                                ),
                                const SizedBox(width: 12),
                                _buildHoverButton(
                                  onPressed: _deleteImage,
                                  text: 'XÓA',
                                  isElevated: false,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFieldWidget(
                        label: 'HỌ VÀ TÊN',
                        value: _user!.fullName,
                        onChanged: (value) => setState(
                                () => _user = _user!.copyWith(fullName: value)),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _user!.gender,
                        decoration: InputDecoration(
                          labelText: 'GIỚI TÍNH',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        items: ['Nam', 'Nữ', 'Khác'].map((g) {
                          return DropdownMenuItem<String>(
                            value: g,
                            child: Text(g),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _user = _user!.copyWith(gender: value)),
                      ),
                      const SizedBox(height: 16),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'NGÀY SINH',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _user!.dateOfBirth != null
                                  ? '${_user!.dateOfBirth!.day}/${_user!.dateOfBirth!.month}/${_user!.dateOfBirth!.year}'
                                  : 'Chưa chọn',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            TextButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _user!.dateOfBirth ?? DateTime(2000),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(0xFF3e80f6),
                                          onPrimary: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  setState(() => _user = _user!.copyWith(dateOfBirth: date));
                                }
                              },
                              child: const Text(
                                'Chọn ngày',
                                style: TextStyle(color: Color(0xFF3e80f6)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Email (readonly)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('EMAIL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            Text(_user!.email, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      // Điểm thân thiết (loyalty points)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ĐIỂM THÂN THIẾT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            Text('${_user!.loyaltyPoints}', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFieldWidget(
                        label: 'SỐ ĐIỆN THOẠI',
                        value: _user!.phoneNumber ?? '',
                        onChanged: (value) => setState(
                                () => _user = _user!.copyWith(phoneNumber: value)),
                        icon: Icons.phone,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'ĐỊA CHỈ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: crossAxisCount == 1
                              ? 3
                              : crossAxisCount == 2
                              ? 2.5
                              : 2,
                        ),
                        itemCount: _user!.addresses.length,
                        itemBuilder: (context, index) {
                          final addr = _user!.addresses[index];
                          return _buildAddressCard(index, addr);
                        },
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: _buildHoverButton(
                          onPressed: _addAddress,
                          text: 'THÊM ĐỊA CHỈ MỚI',
                          icon: Icons.add,
                          isElevated: false,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: _buildHoverButton(
                          onPressed: _submitChanges,
                          text: 'LƯU THAY ĐỔI',
                          icon: Icons.save,
                          isElevated: true,
                          backgroundColor: const Color(0xFF3e80f6),
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressCard(int index, Address addr) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            '${addr.receiverName} - ${addr.phone}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${addr.addressLine}, ${addr.commune ?? ''}, ${addr.district ?? ''}, ${addr.city ?? ''}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          leading: IconButton(
            icon: Icon(
              addr.isDefault ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: () => _setDefaultAddress(index),
          ),
          trailing: Wrap(
            spacing: 8,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF3e80f6)),
                onPressed: () => _editAddress(index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteAddress(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoverButton({
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    bool isElevated = true,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: isElevated
            ? ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: 20) : const SizedBox(),
          label: Text(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? const Color(0xFF3e80f6),
            foregroundColor: textColor ?? Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            shadowColor: Colors.black.withOpacity(0.2),
          ),
        )
            : OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon != null ? Icon(icon, size: 20) : const SizedBox(),
          label: Text(text),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF3e80f6)),
            foregroundColor: const Color(0xFF3e80f6),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}