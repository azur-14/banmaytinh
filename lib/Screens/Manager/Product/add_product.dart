import 'dart:convert';
import 'dart:io';
import 'package:bson/bson.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:danentang/models/product.dart';
import 'package:danentang/models/Category.dart';
import 'package:danentang/models/tag.dart';
import 'package:danentang/Service/product_service.dart';
import '../../../widgets/Footer/mobile_navigation_bar.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late bool isEdit;

  late TextEditingController _nameCtl;
  late TextEditingController _brandCtl;
  late TextEditingController _descCtl;
  late TextEditingController _discountCtl;

  List<Category> _categories = [];
  String? _selectedCategoryId;

  List<Tag> _allTags = [];
  List<String> _selectedTagIds = [];

  final List<String?> _imageBase64 = [];
  final List<TextEditingController> _variantNameCtrls = [];
  final List<TextEditingController> _variantOriginalPriceCtrls = [];
  final List<TextEditingController> _variantPriceCtrls = [];
  final List<TextEditingController> _variantInvCtrls = [];

  bool _loading = false;
  final _baseDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  @override
  void initState() {
    super.initState();
    isEdit = widget.product != null;
    _nameCtl = TextEditingController(text: widget.product?.name ?? '');
    _brandCtl = TextEditingController(text: widget.product?.brand ?? '');
    _descCtl = TextEditingController(text: widget.product?.description ?? '');
    _discountCtl = TextEditingController(text: widget.product?.discountPercentage.toString() ?? '0');

    _selectedCategoryId = widget.product?.categoryId;

    if (widget.product != null && widget.product!.images.isNotEmpty) {
      for (var img in widget.product!.images) _imageBase64.add(img.url);
    }
    if (_imageBase64.isEmpty) _addImageField();

    if (widget.product != null && widget.product!.variants.isNotEmpty) {
      for (var v in widget.product!.variants) {
        _variantNameCtrls.add(TextEditingController(text: v.variantName));
        _variantOriginalPriceCtrls.add(TextEditingController(text: v.originalPrice.toString()));
        _variantPriceCtrls.add(TextEditingController(text: v.additionalPrice.toString()));
        _variantInvCtrls.add(TextEditingController(text: v.inventory.toString()));
      }
    }
    if (_variantNameCtrls.isEmpty) _addVariantField();

    ProductService.fetchAllCategories().then((cats) {
      setState(() {
        _categories = cats;
        _selectedCategoryId ??= cats.isNotEmpty ? cats.first.id : null;
      });
    }).catchError((e) {
      setState(() {
        _categories = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải danh mục: $e')));
    });

    ProductService.fetchAllTags().then((tags) async {
      List<String> current = [];
      if (widget.product != null) {
        try {
          current = (await ProductService.fetchTagsOfProduct(widget.product!.id)).map((t) => t.id).toList();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải thẻ sản phẩm: $e')));
        }
      }
      setState(() {
        _allTags = tags;
        _selectedTagIds = current;
      });
    }).catchError((e) {
      setState(() {
        _allTags = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải thẻ: $e')));
    });
  }

  void _addImageField() => _imageBase64.add(null);

  void _addVariantField() {
    _variantNameCtrls.add(TextEditingController());
    _variantOriginalPriceCtrls.add(TextEditingController(text: '0'));
    _variantPriceCtrls.add(TextEditingController(text: '0'));
    _variantInvCtrls.add(TextEditingController(text: '0'));
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _brandCtl.dispose();
    _descCtl.dispose();
    _discountCtl.dispose();
    for (var c in _variantNameCtrls) c.dispose();
    for (var c in _variantOriginalPriceCtrls) c.dispose();
    for (var c in _variantPriceCtrls) c.dispose();
    for (var c in _variantInvCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _imageBase64[index] = base64Encode(bytes));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final images = List<ProductImage>.generate(
      _imageBase64.length,
          (i) => ProductImage(
        id: (widget.product?.images.length ?? 0) > i && widget.product!.images[i].id.isNotEmpty
            ? widget.product!.images[i].id
            : ObjectId().toHexString(),
        url: _imageBase64[i] ?? '',
        sortOrder: i,
      ),
    );

    final variants = List<ProductVariant>.generate(
      _variantNameCtrls.length,
          (i) => ProductVariant(
        id: (widget.product?.variants.length ?? 0) > i && widget.product!.variants[i].id.isNotEmpty
            ? widget.product!.variants[i].id
            : ObjectId().toHexString(),
        createdAt: (widget.product?.variants.length ?? 0) > i
            ? widget.product!.variants[i].createdAt
            : DateTime.now(),
        variantName: _variantNameCtrls[i].text.trim(),
        originalPrice: double.tryParse(_variantOriginalPriceCtrls[i].text) ?? 0,
        additionalPrice: double.tryParse(_variantPriceCtrls[i].text) ?? 0,
        inventory: int.tryParse(_variantInvCtrls[i].text) ?? 0,
        updatedAt: DateTime.now(),
      ),
    );

    final p = Product(
      id: widget.product?.id ?? ObjectId().toHexString(),
      name: _nameCtl.text.trim(),
      brand: _brandCtl.text.trim(),
      description: _descCtl.text.trim(),
      discountPercentage: int.tryParse(_discountCtl.text.trim()) ?? 0,
      categoryId: _selectedCategoryId ?? '',
      createdAt: widget.product?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      images: images,
      variants: variants,
    );

    try {
      if (widget.product == null) {
        await ProductService.createProduct(p);
      } else {
        await ProductService.updateProduct(p);
      }
      await ProductService.upsertTagsForProduct(p.id, _selectedTagIds);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'Add Product'),
        leading: isMobile
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        )
            : null,
      ),
      body: (_categories.isEmpty || _allTags.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Name, Brand, Description
              TextFormField(
                controller: _nameCtl,
                decoration: _baseDecoration.copyWith(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandCtl,
                decoration: _baseDecoration.copyWith(labelText: 'Brand'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtl,
                decoration: _baseDecoration.copyWith(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              // Discount percentage
              isEdit
                  ? TextFormField(
                controller: _discountCtl,
                decoration: _baseDecoration.copyWith(labelText: 'Discount %'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid' : null,
              )
                  : TextFormField(
                controller: _discountCtl,
                enabled: false,
                decoration: _baseDecoration.copyWith(
                  labelText: 'Discount %',
                  suffixIcon: const Icon(Icons.lock_outline),
                ),
              ),

              const SizedBox(height: 12),
              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: _baseDecoration.copyWith(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
              const SizedBox(height: 12),
              // Tags
              ExpansionTile(
                title: const Text('Tags'),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _allTags.map((tag) {
                      final selected = _selectedTagIds.contains(tag.id);
                      return FilterChip(
                        label: Text(tag.name),
                        selected: selected,
                        onSelected: (sel) {
                          setState(() {
                            if (sel)
                              _selectedTagIds.add(tag.id);
                            else
                              _selectedTagIds.remove(tag.id);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Images
              ExpansionTile(
                title: const Text('Images'),
                children: [
                  for (var i = 0; i < _imageBase64.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _imageBase64[i] != null &&
                                _imageBase64[i]!.isNotEmpty
                                ? _safeBase64Image(_imageBase64[i]!,
                                width: 64, height: 64)
                                : const Icon(Icons.image,
                                size: 32, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.upload),
                            label: const Text('Pick Image'),
                            onPressed: () => _pickImage(i),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () => setState(() {
                              _imageBase64.removeAt(i);
                            }),
                          ),
                        ],
                      ),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Add Image Field'),
                    onPressed: _addImageField,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Variants
              ExpansionTile(
                title: const Text('Variants'),
                children: [
                  for (var i = 0; i < _variantNameCtrls.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _variantNameCtrls[i],
                            decoration:
                            const InputDecoration(labelText: 'Name'),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _variantOriginalPriceCtrls[i],
                                  decoration: const InputDecoration(labelText: 'Original Price'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _variantPriceCtrls[i],
                                  decoration: const InputDecoration(labelText: 'Add. Price'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _variantInvCtrls[i],
                                  decoration: const InputDecoration(labelText: 'Stock'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() {
                                  _variantNameCtrls.removeAt(i);
                                  _variantOriginalPriceCtrls.removeAt(i);
                                  _variantPriceCtrls.removeAt(i);
                                  _variantInvCtrls.removeAt(i);
                                }),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Variant Field'),
                    onPressed: _addVariantField,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : Text(isEdit ? 'Save Changes' : 'Create Product'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isMobile
          ? MobileNavigationBar(
        selectedIndex: 0,
        onItemTapped: (_) {},
        isLoggedIn: true,
        role: 'manager',
      )
          : null,
    );
  }

  Widget _safeBase64Image(String base64String,
      {double? width, double? height}) {
    try {
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade300,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } catch (_) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
  }
}