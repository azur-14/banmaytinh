// lib/Screens/Manager/User/user_list_screen.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:danentang/models/User.dart';
import 'package:danentang/Service/user_service.dart';
import 'package:danentang/Screens/Manager/User/user_information.dart';
import 'package:danentang/widgets/Footer/mobile_navigation_bar.dart';

import '../../../models/Address.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen>
    with SingleTickerProviderStateMixin {
  final _service = UserService();
  final _searchCtrl = TextEditingController();

  List<User> _users = [];
  List<User> _filtered = [];
  Set<String> _selectedIds = {};
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      // Lấy danh sách user (loại trừ admin)
      final all = await _service.fetchUsers();
      setState(() {
        _users = all;
        _filtered = all;
        _selectedIds.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Load thất bại: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _users.where((u) {
        return u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q);
      }).toList();
    });
  }

  void _clearSelection() => setState(() => _selectedIds.clear());

  void _toggleSelection(User u) {
    setState(() {
      if (_selectedIds.contains(u.id)) {
        _selectedIds.remove(u.id);
      } else {
        _selectedIds.add(u.id);
      }
    });
  }

  AppBar _buildAppBar() {
    if (_selectedIds.isNotEmpty) {
      return AppBar(
        backgroundColor: Colors.blueGrey,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _clearSelection,
        ),
        title: Text(
          '${_selectedIds.length} đã chọn',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return AppBar(
      backgroundColor: Colors.white,
      title: const Text('Danh sách Người dùng',
          style: TextStyle(color: Colors.black)),
      elevation: 0,
      centerTitle: true,
      leading: (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)
          ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      )
          : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
          ? Center(
        child: Text(_searchCtrl.text.isEmpty
            ? 'Chưa có người dùng'
            : 'Không tìm thấy "${_searchCtrl.text}"'),
      )
          : RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filtered.length,
          itemBuilder: (ctx, i) {
            final u = _filtered[i];
            return AnimatedUserCard(
              user: u,
              delay: i * 100,
              isSelected: _selectedIds.contains(u.id),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      UserInformation(userId: u.id),
                ),
              ),
              onLongPress: () => _toggleSelection(u),
            );
          },
        ),
      ),
      bottomNavigationBar: isMobile
          ? MobileNavigationBar(
        selectedIndex: _currentIndex,
        onItemTapped: (i) => setState(() => _currentIndex = i),
        isLoggedIn: true,
        role: 'manager',
      )
          : null,
    );
  }
}

class AnimatedUserCard extends StatefulWidget {
  final User user;
  final int delay;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AnimatedUserCard({
    super.key,
    required this.user,
    required this.delay,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  _AnimatedUserCardState createState() => _AnimatedUserCardState();
}

class _AnimatedUserCardState extends State<AnimatedUserCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _offsetAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(_ctrl);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Decode avatar (base64 or URL)
    Uint8List? avatarBytes;
    final raw = widget.user.avatarUrl;
    if (raw != null && raw.isNotEmpty) {
      if (raw.startsWith('data:')) {
        final b64 = raw.split(',').last;
        try {
          avatarBytes = base64Decode(b64);
        } catch (_) {}
      }
    }

    // 1) find the default address (or use an empty placeholder)
    final defaultAddr = widget.user.addresses.firstWhere(
          (a) => a.isDefault,
      orElse: () => Address(
        receiverName: '',
        phone: '',
        addressLine: '-',
        commune: null,
        district: null,
        city: null,
        isDefault: false,
      ),
    );

// 2) build a full-line string, skipping any null/empty parts
    final parts = [
      defaultAddr.addressLine,
      defaultAddr.commune,
      defaultAddr.district,
      defaultAddr.city,
    ]
        .where((s) => s != null && s.trim().isNotEmpty)
        .cast<String>()
        .toList();

    final addressText = parts.join(', ');

    // Build date string
    final dateText = DateFormat.yMMMd()
        .add_jm()
        .format(widget.user.createdAt.toLocal());

    return SlideTransition(
      position: _offsetAnim,
      child: FadeTransition(
        opacity: _opacityAnim,
        child: Card(
          shape: RoundedRectangleBorder(
            side: widget.isSelected
                ? BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2)
                : BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (widget.isSelected)
                    Checkbox(
                      value: widget.isSelected,
                      onChanged: (_) => widget.onLongPress(),
                    ),
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: avatarBytes != null
                        ? MemoryImage(avatarBytes)
                        : (widget.user.avatarUrl != null &&
                        !widget.user.avatarUrl!.startsWith('data:')
                        ? NetworkImage(widget.user.avatarUrl!)
                        : const AssetImage(
                        'assets/Manager/Avatar/avatar.jpg')) as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.user.fullName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(widget.user.email,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(addressText,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(dateText,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
