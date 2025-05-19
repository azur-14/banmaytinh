import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:danentang/models/User.dart';
import 'package:danentang/models/Address.dart';
import 'package:danentang/Service/user_service.dart';

class UserInformation extends StatefulWidget {
  final String userId;
  const UserInformation({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserInformation> createState() => _UserInformationState();
}

class _UserInformationState extends State<UserInformation> {
  final _formKey = GlobalKey<FormState>();
  final _svc = UserService();
  bool _loading = true;
  bool _isSaving = false;
  User? _user;
  String? _errorMessage;

  // Controllers for editable fields
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  DateTime? _dob;
  String? _gender;
  String? _status;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadUser();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    if (token == null || role != 'admin') {
      if (mounted) context.go('/login');
    }
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final u = await _svc.fetchUserById(widget.userId);
      if (mounted) {
        setState(() {
          _user = u;
          _fullNameCtrl.text = u.fullName;
          _phoneCtrl.text = u.phoneNumber ?? '';
          _avatarCtrl.text = u.avatarUrl ?? '';
          _dob = u.dateOfBirth;
          _gender = u.gender;
          _status = u.status;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi tải thông tin người dùng: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final edited = _user!.copyWith(
      fullName: _fullNameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      avatarUrl: _avatarCtrl.text.trim(),
      dateOfBirth: _dob,
      gender: _gender,
      status: _status,
      addresses: List<Address>.from(_user!.addresses),
    );

    try {
      await _svc.updateUserFull(edited);
      await _loadUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
    );
    if (image == null) return;
    try {
      // Placeholder: Store image path locally or simulate URL
      // TODO: Implement server-side upload in UserService.uploadAvatar
      final url = 'file://${image.path}'; // Temporary local path
      if (mounted) setState(() => _avatarCtrl.text = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tải ảnh thất bại: $e')),
        );
      }
    }
  }

  void _addAddress() {
    final form = GlobalKey<FormState>();
    final recv = TextEditingController();
    final ph = TextEditingController();
    final line = TextEditingController();
    final comm = TextEditingController();
    final dist = TextEditingController();
    final city = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm địa chỉ'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: recv,
                  decoration: const InputDecoration(labelText: 'Người nhận'),
                  validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                ),
                TextFormField(
                  controller: ph,
                  decoration: const InputDecoration(labelText: 'SĐT'),
                  validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: line,
                  decoration: const InputDecoration(labelText: 'Địa chỉ'),
                  validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                ),
                TextFormField(
                  controller: comm,
                  decoration: const InputDecoration(labelText: 'Phường/Xã'),
                  validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                ),
                TextFormField(
                  controller: dist,
                  decoration: const InputDecoration(labelText: 'Quận/Huyện'),
                  validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                ),
                TextFormField(
                  controller: city,
                  decoration: const InputDecoration(labelText: 'Tỉnh/TP'),
                  validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              if (mounted) {
                setState(() {
                  for (var a in _user!.addresses) {
                    a.isDefault = false;
                  }
                  _user!.addresses.add(Address(
                    receiverName: recv.text.trim(),
                    phone: ph.text.trim(),
                    addressLine: line.text.trim(),
                    commune: comm.text.trim(),
                    district: dist.text.trim(),
                    city: city.text.trim(),
                    isDefault: true,
                    createdAt: DateTime.now(),
                  ));
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showEditAddressDialog(int index) {
    final old = _user!.addresses[index];
    final form = GlobalKey<FormState>();
    final recv = TextEditingController(text: old.receiverName);
    final ph = TextEditingController(text: old.phone);
    final line = TextEditingController(text: old.addressLine);
    final comm = TextEditingController(text: old.commune);
    final dist = TextEditingController(text: old.district);
    final city = TextEditingController(text: old.city);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chỉnh sửa địa chỉ'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: recv,
                  decoration: const InputDecoration(labelText: 'Người nhận'),
                  validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                ),
                TextFormField(
                  controller: ph,
                  decoration: const InputDecoration(labelText: 'SĐT'),
                  validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: line,
                  decoration: const InputDecoration(labelText: 'Địa chỉ'),
                  validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                ),
                TextFormField(
                  controller: comm,
                  decoration: const InputDecoration(labelText: 'Phường/Xã'),
                  validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                ),
                TextFormField(
                  controller: dist,
                  decoration: const InputDecoration(labelText: 'Quận/Huyện'),
                  validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                ),
                TextFormField(
                  controller: city,
                  decoration: const InputDecoration(labelText: 'Tỉnh/TP'),
                  validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              if (mounted) {
                setState(() {
                  _user!.addresses[index] = old.copyWith(
                    receiverName: recv.text.trim(),
                    phone: ph.text.trim(),
                    addressLine: line.text.trim(),
                    commune: comm.text.trim(),
                    district: dist.text.trim(),
                    city: city.text.trim(),
                    isDefault: old.isDefault,
                    createdAt: old.createdAt,
                  );
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop && mounted) {
          // Hiển thị dialog xác nhận trước khi quay lại
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Xác nhận'),
              content: const Text('Bạn có muốn quay lại danh sách người dùng?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Đồng ý'),
                ),
              ],
            ),
          );
          if (shouldPop == true && mounted) {
            context.go('/manager/users');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết người dùng'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              // Xác nhận khi nhấn nút back
              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xác nhận'),
                  content: const Text('Bạn có muốn quay lại danh sách người dùng?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Đồng ý'),
                    ),
                  ],
                ),
              );
              if (shouldPop == true && mounted) {
                context.go('/manager/users');
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _loadUser,
              tooltip: 'Làm mới',
            ),
            IconButton(
              icon: Icon(Icons.save, color: _isSaving ? Colors.grey : Colors.black),
              onPressed: _isSaving ? null : _saveAll,
              tooltip: 'Lưu',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUser,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Profile Section
                      Center(
                        child: GestureDetector(
                          onTap: _pickAvatar,
                          child: CircleAvatar(
                            radius: isMobile ? 50 : 60,
                            backgroundImage: _avatarCtrl.text.isNotEmpty
                                ? NetworkImage(_avatarCtrl.text)
                                : null,
                            child: _avatarCtrl.text.isEmpty
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _user!.email,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fullNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Họ tên',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: InputDecoration(
                          labelText: 'SĐT',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: InputDecoration(
                          labelText: 'Giới tính',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['male', 'female', 'other']
                            .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.capitalize()),
                        ))
                            .toList(),
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['Active', 'Banned']
                            .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ))
                            .toList(),
                        onChanged: (v) => setState(() => _status = v),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          _dob == null
                              ? 'Chọn ngày sinh'
                              : 'Ngày sinh: ${DateFormat.yMd('vi_VN').format(_dob!)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _dob ?? DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            locale: const Locale('vi', 'VN'),
                          );
                          if (d != null && mounted) {
                            setState(() => _dob = d);
                          }
                        },
                      ),
                      const Divider(height: 32),
                      // Addresses Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Địa chỉ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addAddress,
                            tooltip: 'Thêm địa chỉ',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_user!.addresses.isEmpty)
                        const Center(
                          child: Text(
                            'Chưa có địa chỉ',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      for (var i = 0; i < _user!.addresses.length; i++)
                        Dismissible(
                          key: ValueKey(
                            '${i}-${_user!.addresses[i].createdAt.toIso8601String()}',
                          ),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            if (mounted) {
                              setState(() {
                                _user!.addresses.removeAt(i);
                              });
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: Text(
                                _user!.addresses[i].addressLine,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${_user!.addresses[i].receiverName}\n'
                                    '${_user!.addresses[i].phone}\n'
                                    '${_user!.addresses[i].commune}, '
                                    '${_user!.addresses[i].district}, '
                                    '${_user!.addresses[i].city}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<int>(
                                    value: i,
                                    groupValue: _user!.addresses
                                        .indexWhere((a) => a.isDefault),
                                    onChanged: (v) {
                                      if (mounted) {
                                        setState(() {
                                          for (var a in _user!.addresses) {
                                            a.isDefault = false;
                                          }
                                          _user!.addresses[i].isDefault = true;
                                        });
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showEditAddressDialog(i),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}