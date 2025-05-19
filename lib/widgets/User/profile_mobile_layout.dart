import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:danentang/Service/user_service.dart';
import 'package:danentang/models/Address.dart';
import 'package:danentang/models/User.dart';
import 'edit_dialog.dart';
import 'gender_dialog.dart';
import 'date_picker_dialog.dart';

class ProfileMobileLayout extends StatefulWidget {
  const ProfileMobileLayout({super.key});

  @override
  _ProfileMobileLayoutState createState() => _ProfileMobileLayoutState();
}

class _ProfileMobileLayoutState extends State<ProfileMobileLayout> {
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
        const SnackBar(content: Text('Cập nhật thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();         // đọc byte từ ảnh
        final base64Image = base64Encode(bytes);         // mã hoá base64

        await UserService().updateAvatar(_user!.id!, base64Image);
        setState(() {
          _user = _user!.copyWith(avatarUrl: base64Image);
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


  Future<void> _deleteAvatar() async {
    try {
      await UserService().deleteAvatar(_user!.id!);
      setState(() => _user = _user!.copyWith(avatarUrl: null));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ảnh đại diện đã được xoá')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xoá ảnh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final dateFormatter = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: _user!.avatarUrl != null
                    ? MemoryImage(base64Decode(_user!.avatarUrl!))
                    : null,
                child: _user!.avatarUrl == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_user!.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2E5B),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cập nhật ảnh'),
                  ),
                  TextButton(
                    onPressed: _deleteAvatar,
                    child: const Text('Xoá ảnh đại diện', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Thông tin cá nhân', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildInfoRow(context, 'Giới tính', _user!.gender ?? '', _showGenderDialog),
          _buildInfoRow(context, 'Ngày sinh', _user!.dateOfBirth != null ? dateFormatter.format(_user!.dateOfBirth!) : '', _showDatePickerDialog),
          _buildInfoRow(context, 'SĐT', _user!.phoneNumber ?? '', () => _showEditDialog('phoneNumber', 'Số điện thoại')),
          // Email (không cho edit)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Email', style: TextStyle(fontSize: 16)),
                Text(_user!.email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
          // Điểm khách hàng thân thiết (readonly)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Điểm thân thiết', style: TextStyle(fontSize: 16)),
                // giả sử User có field loyaltyPoints kiểu int
                Text('${_user!.loyaltyPoints}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildAddressList(),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _submitChanges,
              icon: const Icon(Icons.save),
              label: const Text('Xác nhận sửa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editAddressDialog(Address addr, int index) async {
    final receiver = await EditDialog.show(context, addr.receiverName, 'receiverName', 'Người nhận') ?? addr.receiverName;
    final phone    = await EditDialog.show(context, addr.phone, 'phone', 'SĐT') ?? addr.phone;
    final line     = await EditDialog.show(context, addr.addressLine, 'addressLine', 'Số nhà, tên đường') ?? addr.addressLine;
    final commune  = await EditDialog.show(context, addr.commune ?? '', 'commune', 'Phường/Xã') ?? addr.commune;
    final district = await EditDialog.show(context, addr.district ?? '', 'district', 'Quận/Huyện') ?? addr.district;
    final city     = await EditDialog.show(context, addr.city ?? '', 'city', 'Tỉnh/Thành phố') ?? addr.city;

    final updated = addr.copyWith(
      receiverName: receiver,
      phone: phone,
      addressLine: line,
      commune: commune,
      district: district,
      city: city,
    );

    final updatedAddresses = [..._user!.addresses];
    updatedAddresses[index] = updated;

    setState(() {
      _user = _user!.copyWith(addresses: updatedAddresses);
    });
  }

  void _deleteAddress(int index) {
    final addresses = [..._user!.addresses]..removeAt(index);
    setState(() => _user = _user!.copyWith(addresses: addresses));
  }

  void _setDefaultAddress(int index) {
    final updated = _user!.addresses.map((a) => a.copyWith(isDefault: false)).toList();
    updated[index] = updated[index].copyWith(isDefault: true);
    setState(() => _user = _user!.copyWith(addresses: updated));
  }

  Future<void> _addNewAddress() async {
    final receiver = await EditDialog.show(context, '', 'receiverName', 'Người nhận');
    if (receiver == null) return;
    final phone    = await EditDialog.show(context, '', 'phone', 'SĐT');
    final line     = await EditDialog.show(context, '', 'addressLine', 'Số nhà, tên đường');
    final commune  = await EditDialog.show(context, '', 'commune', 'Phường/Xã');
    final district = await EditDialog.show(context, '', 'district', 'Quận/Huyện');
    final city     = await EditDialog.show(context, '', 'city', 'Tỉnh/Thành phố');

    final newAddr = Address(
      receiverName: receiver ?? '',
      phone: phone ?? '',
      addressLine: line ?? '',
      commune: commune,
      district: district,
      city: city,
      isDefault: _user!.addresses.isEmpty,
    );

    setState(() {
      _user = _user!.copyWith(addresses: [..._user!.addresses, newAddr]);
    });
  }

  Future<void> _showGenderDialog() async {
    final selectedGender = await GenderDialog.show(
      context,
      currentGender: _user?.gender,
    );
    if (selectedGender != null) {
      setState(() => _user = _user!.copyWith(gender: selectedGender));
    }
  }

  Future<void> _showDatePickerDialog() async {
    final selectedDate = await ProfileDatePickerDialog.show(context, _user?.dateOfBirth);
    if (selectedDate != null) {
      setState(() => _user = _user!.copyWith(dateOfBirth: selectedDate));
    }
  }

  Future<void> _showEditDialog(String field, String title) async {
    final currentValue = field == 'phoneNumber' ? _user?.phoneNumber ?? '' : '';
    final newValue = await EditDialog.show(context, currentValue, field, title);

    if (newValue != null) {
      setState(() {
        if (field == 'phoneNumber') {
          _user = _user!.copyWith(phoneNumber: newValue);
        }
      });
    }
  }

  Widget _buildAddressList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Địa chỉ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add), onPressed: _addNewAddress),
          ],
        ),
        ..._user!.addresses.asMap().entries.map((entry) {
          final index = entry.key;
          final a = entry.value;
          return Card(
            child: ListTile(
              title: Text(a.receiverName),
              subtitle: Text('${a.addressLine}, ${a.commune}, ${a.district}, ${a.city}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _editAddressDialog(a, index);
                  if (value == 'delete') _deleteAddress(index);
                  if (value == 'setDefault') _setDefaultAddress(index);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                  const PopupMenuItem(value: 'delete', child: Text('Xoá')),
                  if (!a.isDefault) const PopupMenuItem(value: 'setDefault', child: Text('Chọn làm mặc định')),
                ],
              ),
              leading: a.isDefault ? const Icon(Icons.star, color: Colors.amber) : const Icon(Icons.location_on),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

}