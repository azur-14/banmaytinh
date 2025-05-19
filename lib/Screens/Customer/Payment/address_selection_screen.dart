import 'package:flutter/material.dart';
import 'package:danentang/models/User.dart';
import 'package:danentang/models/Address.dart';
import 'package:danentang/Service/user_service.dart';

class AddressSelectionScreen extends StatefulWidget {
  final User user;

  const AddressSelectionScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  Address? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.user.addresses.firstWhere(
          (addr) => addr.isDefault,
      orElse: () => widget.user.addresses.first,
    );

  }
  Future<void> _showAddressDialog({Address? existing, required int? index}) async {
    final formKey = GlobalKey<FormState>();
    final receiverCtrl = TextEditingController(text: existing?.receiverName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final addressLineCtrl = TextEditingController(text: existing?.addressLine ?? '');
    final communeCtrl = TextEditingController(text: existing?.commune ?? '');
    final districtCtrl = TextEditingController(text: existing?.district ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');

    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing != null ? 'Chỉnh sửa địa chỉ' : 'Thêm địa chỉ mới'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: receiverCtrl,
                  decoration: const InputDecoration(labelText: 'Người nhận'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || !RegExp(r'^\d{10,11}$').hasMatch(v)
                      ? 'Số không hợp lệ'
                      : null,
                ),
                TextFormField(
                  controller: addressLineCtrl,
                  decoration: const InputDecoration(labelText: 'Số nhà, tên đường'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                ),
                TextFormField(
                  controller: communeCtrl,
                  decoration: const InputDecoration(labelText: 'Phường/Xã'),
                ),
                TextFormField(
                  controller: districtCtrl,
                  decoration: const InputDecoration(labelText: 'Quận/Huyện'),
                ),
                TextFormField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(labelText: 'Tỉnh/Thành phố'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newAddress = Address(
                  receiverName: receiverCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  addressLine: addressLineCtrl.text.trim(),
                  commune: communeCtrl.text.trim(),
                  district: districtCtrl.text.trim(),
                  city: cityCtrl.text.trim(),
                  isDefault: existing?.isDefault ?? widget.user.addresses.isEmpty,
                );

                setState(() {
                  if (index != null) {
                    widget.user.addresses[index] = newAddress;
                  } else {
                    widget.user.addresses.add(newAddress);
                    _selectedAddress = newAddress;
                  }
                });

                UserService().updateUserFull(widget.user);
                Navigator.pop(context, true);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    receiverCtrl.dispose();
    phoneCtrl.dispose();
    addressLineCtrl.dispose();
    communeCtrl.dispose();
    districtCtrl.dispose();
    cityCtrl.dispose();
  }

  Future<void> _addNewAddress() async {
    await _showAddressDialog(index: null);
  }

  Future<void> _deleteAddress(int index) async {
    final removed = widget.user.addresses.removeAt(index);
    if (_selectedAddress == removed) {
      _selectedAddress = widget.user.addresses.firstWhere(
            (addr) => addr.isDefault,
        orElse: () => widget.user.addresses.first,
      );
    }
    setState(() {});
    await UserService().updateUserFull(widget.user);
  }

  Future<void> _setDefault(int index) async {
    for (int i = 0; i < widget.user.addresses.length; i++) {
      widget.user.addresses[i] = widget.user.addresses[i].copyWith(isDefault: i == index);
    }
    _selectedAddress = widget.user.addresses[index];
    setState(() {});
    await UserService().updateUserFull(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn địa chỉ giao hàng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _selectedAddress),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: widget.user.addresses.isEmpty
                  ? const Center(child: Text('Chưa có địa chỉ nào.'))
                  : ListView.builder(
                itemCount: widget.user.addresses.length,
                itemBuilder: (context, index) {
                  final a = widget.user.addresses[index];
                  final full = [
                    a.addressLine,
                    a.commune,
                    a.district,
                    a.city
                  ].where((part) => part != null && part.isNotEmpty).join(', ');

                  return Card(
                    child: RadioListTile<Address>(
                      value: a,
                      groupValue: _selectedAddress,
                      onChanged: (val) => setState(() => _selectedAddress = val),
                      title: Text(a.receiverName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(full),
                          Text('SĐT: ${a.phone}'),
                          if (a.isDefault)
                            const Text('Mặc định', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                      secondary: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') _showAddressDialog(existing: a, index: index);
                          if (value == 'delete') _deleteAddress(index);
                          if (value == 'setDefault') _setDefault(index);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                          const PopupMenuItem(value: 'delete', child: Text('Xoá')),
                          if (!a.isDefault)
                            const PopupMenuItem(value: 'setDefault', child: Text('Chọn làm mặc định')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addNewAddress,
              icon: const Icon(Icons.add_location),
              label: const Text('Thêm địa chỉ mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
