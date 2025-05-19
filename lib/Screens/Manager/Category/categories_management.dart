import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animations/animations.dart';
import '../../../widgets/Footer/mobile_navigation_bar.dart';
import 'package:danentang/models/Category.dart' as model;
import 'package:danentang/Service/product_service.dart';

class CategoriesManagement extends StatelessWidget {
  const CategoriesManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveCategoriesScreen();
  }
}

class ResponsiveCategoriesScreen extends StatefulWidget {
  const ResponsiveCategoriesScreen({super.key});

  @override
  State<ResponsiveCategoriesScreen> createState() => _ResponsiveCategoriesScreenState();
}

class _ResponsiveCategoriesScreenState extends State<ResponsiveCategoriesScreen> {
  late Future<List<model.Category>> _futureCategories;

  @override
  void initState() {
    super.initState();
    _refresh();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    if (token == null || role != 'admin') {
      context.go('/login');
    }
  }

  void _refresh() {
    setState(() {
      _futureCategories = ProductService.fetchAllCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          context.go('/manager'); // Quay lại dashboard
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return PageTransitionSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation, secondaryAnimation) => FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            ),
            child: isMobile
                ? MobileCategoriesScreen(
              key: const ValueKey("Di động"),
              categoriesFuture: _futureCategories,
              onRefresh: _refresh,
            )
                : WebCategoriesScreen(
              key: const ValueKey("Website"),
              categoriesFuture: _futureCategories,
              onRefresh: _refresh,
            ),
          );
        },
      ),
    );
  }
}

class MobileCategoriesScreen extends StatefulWidget {
  final Future<List<model.Category>> categoriesFuture;
  final VoidCallback onRefresh;
  const MobileCategoriesScreen({super.key, required this.categoriesFuture, required this.onRefresh});

  @override
  State<MobileCategoriesScreen> createState() => _MobileCategoriesScreenState();
}

class _MobileCategoriesScreenState extends State<MobileCategoriesScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _errorMessage;

  void _createCategory() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Tên danh mục không được để trống');
      return;
    }

    try {
      final categories = await widget.categoriesFuture;
      if (categories.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
        setState(() => _errorMessage = 'Tên danh mục đã tồn tại');
        return;
      }

      final success = await ProductService.createCategory(model.Category(
        name: name,
        description: desc.isEmpty ? null : desc,
        createdAt: DateTime.now(),
      ));
      if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo danh mục thành công')));
        _nameCtrl.clear();
        _descCtrl.clear();
        setState(() => _errorMessage = null);
        widget.onRefresh();
      } else {
        setState(() => _errorMessage = 'Không thể tạo danh mục');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi: $e');
    }
  }

  void _editCategory(model.Category cat) async {
    if (cat.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Danh mục không hợp lệ')));
      return;
    }

    final nameCtrl = TextEditingController(text: cat.name);
    final descCtrl = TextEditingController(text: cat.description ?? "");
    String? errorMessage;

    final updated = await showDialog<model.Category>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Sửa danh mục'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMessage != null) ...[
                  Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên danh mục'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => ctx.pop(),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    setDialogState(() => errorMessage = 'Tên danh mục không được để trống');
                    return;
                  }
                  final categories = await widget.categoriesFuture;
                  if (categories.any((c) => c.name.toLowerCase() == name.toLowerCase() && c.id != cat.id)) {
                    setDialogState(() => errorMessage = 'Tên danh mục đã tồn tại');
                    return;
                  }
                  final updatedCat = model.Category(
                    id: cat.id,
                    name: name,
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    createdAt: cat.createdAt,
                  );
                  ctx.pop(updatedCat);
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
        );
      },
    );

    if (updated != null) {
      try {
        final success = await ProductService.updateCategory(updated.id!, updated);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật danh mục thành công')));
          widget.onRefresh();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể cập nhật danh mục')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _deleteCategory(String? id) async {
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Danh mục không hợp lệ')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa danh mục này không?'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final ok = await ProductService.deleteCategory(id);
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa danh mục')));
          widget.onRefresh();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa danh mục')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _clearForm() {
    _nameCtrl.clear();
    _descCtrl.clear();
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Quản lý danh mục",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/manager'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: widget.onRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Danh sách danh mục",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<model.Category>>(
                  future: widget.categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Lỗi: ${snapshot.error}"),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: widget.onRefresh,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      );
                    }
                    final categories = snapshot.data!;
                    if (categories.isEmpty) {
                      return const Text("Chưa có danh mục nào.");
                    }
                    return Column(
                      children: categories
                          .map((cat) => ListTile(
                        title: Text(cat.name),
                        subtitle: Text(cat.description ?? "Không có mô tả"),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editCategory(cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(cat.id),
                            ),
                          ],
                        ),
                      ))
                          .toList(),
                    );
                  },
                ),
                const Divider(height: 32),
                const Text(
                  "Thêm danh mục mới",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (_errorMessage != null) ...[
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên danh mục',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _createCategory,
                      child: const Text("Tạo danh mục"),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: _clearForm,
                      child: const Text("Xóa dữ liệu"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: MobileNavigationBar(
        selectedIndex: 0,
        onItemTapped: (_) {},
        isLoggedIn: true,
        role: 'admin',
      ),
    );
  }
}

class WebCategoriesScreen extends StatefulWidget {
  final Future<List<model.Category>> categoriesFuture;
  final VoidCallback onRefresh;

  const WebCategoriesScreen({super.key, required this.categoriesFuture, required this.onRefresh});

  @override
  State<WebCategoriesScreen> createState() => _WebCategoriesScreenState();
}

class _WebCategoriesScreenState extends State<WebCategoriesScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _errorMessage;

  Future<void> _createCategory() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Tên danh mục không được để trống');
      return;
    }

    try {
      final categories = await widget.categoriesFuture;
      if (categories.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
        setState(() => _errorMessage = 'Tên danh mục đã tồn tại');
        return;
      }

      final success = await ProductService.createCategory(model.Category(
        name: name,
        description: desc.isEmpty ? null : desc,
        createdAt: DateTime.now(),
      ));
      if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo danh mục thành công')));
        _nameCtrl.clear();
        _descCtrl.clear();
        setState(() => _errorMessage = null);
        widget.onRefresh();
      } else {
        setState(() => _errorMessage = 'Không thể tạo danh mục');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi: $e');
    }
  }

  Future<void> _editCategory(model.Category cat) async {
    if (cat.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Danh mục không hợp lệ')));
      return;
    }

    final nameCtrl = TextEditingController(text: cat.name);
    final descCtrl = TextEditingController(text: cat.description ?? '');
    String? errorMessage;

    final edited = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sửa danh mục'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorMessage != null) ...[
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên danh mục'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => errorMessage = 'Tên danh mục không được để trống');
                  return;
                }
                final categories = await widget.categoriesFuture;
                if (categories.any((c) => c.name.toLowerCase() == name.toLowerCase() && c.id != cat.id)) {
                  setDialogState(() => errorMessage = 'Tên danh mục đã tồn tại');
                  return;
                }
                final success = await ProductService.updateCategory(
                  cat.id!,
                  model.Category(
                    id: cat.id,
                    name: name,
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    createdAt: cat.createdAt,
                  ),
                );
                if (success) {
                  ctx.pop(true);
                } else {
                  setDialogState(() => errorMessage = 'Không thể cập nhật danh mục');
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (edited == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật danh mục thành công')));
      widget.onRefresh();
    }
  }

  Future<void> _deleteCategory(String? id) async {
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Danh mục không hợp lệ')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa danh mục này không?'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final ok = await ProductService.deleteCategory(id);
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa danh mục')));
          widget.onRefresh();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa danh mục')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _clearForm() {
    _nameCtrl.clear();
    _descCtrl.clear();
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Quản lý danh mục",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: widget.onRefresh,
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[100],
              child: FutureBuilder<List<model.Category>>(
                future: widget.categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Lỗi: ${snapshot.error}"),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: widget.onRefresh,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }
                  final categories = snapshot.data!;
                  if (categories.isEmpty) {
                    return const Center(child: Text("Chưa có danh mục nào."));
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: categories
                        .map((cat) => ListTile(
                      title: Text(cat.name),
                      subtitle: Text(cat.description ?? 'Không có mô tả'),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editCategory(cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCategory(cat.id),
                          ),
                        ],
                      ),
                    ))
                        .toList(),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tạo danh mục mới",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  if (_errorMessage != null) ...[
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên danh mục',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _createCategory,
                        child: const Text("Tạo danh mục"),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: _clearForm,
                        child: const Text("Xóa dữ liệu"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}