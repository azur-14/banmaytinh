import 'package:flutter/material.dart';
import 'package:danentang/models/User.dart';
import 'package:danentang/models/Address.dart';

class AddAddressScreen extends StatefulWidget {
  final User user;

  const AddAddressScreen({super.key, required this.user});

  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiverNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _communeController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill receiver name with user's full name
    _receiverNameController.text = widget.user.fullName;
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _phoneNumberController.dispose();
    _addressLineController.dispose();
    _communeController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final newAddress = Address(
        receiverName: _receiverNameController.text,
        phone: _phoneNumberController.text,
        addressLine: _addressLineController.text,
        commune: _communeController.text,
        district: _districtController.text,
        city: _cityController.text,
        isDefault: _isDefault,
      );

      // If the new address is set as default, update other addresses
      if (_isDefault) {
        for (var addr in widget.user.addresses) {
          addr.isDefault = false;
        }
      }

      // Return the new address to the previous screen
      Navigator.pop(context, newAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm địa chỉ mới'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _receiverNameController,
                decoration: const InputDecoration(labelText: 'Tên người nhận'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên người nhận';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (!RegExp(r'^\d{10,11}$').hasMatch(value)) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressLineController,
                decoration: const InputDecoration(labelText: 'Địa chỉ (số nhà, đường)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _communeController,
                decoration: const InputDecoration(labelText: 'Xã/Phường'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập xã/phường';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(labelText: 'Quận/Huyện'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập quận/huyện';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Tỉnh/Thành phố'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tỉnh/thành phố';
                  }
                  return null;
                },
              ),
              CheckboxListTile(
                title: const Text('Đặt làm địa chỉ mặc định'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAddress,
                child: const Text('Lưu địa chỉ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}