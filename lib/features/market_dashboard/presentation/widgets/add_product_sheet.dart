import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_market/core/constants/app_colors.dart';
import 'package:eco_market/data/models/product_model.dart';

/// Product categories with scientific CO2 factors (kg CO2 per kg food waste)
enum ProductCategory {
  fastFood('Fast Food / Burger', 3.5, '🍔'),
  packagedSandwich('Paketli Sandviç', 1.2, '🥪'),
  snack('Atıştırmalık / Cips', 1.8, '🍪'),
  bakery('Fırın & Hamur İşi', 0.6, '🍞'),
  produce('Meyve & Sebze', 0.4, '🥬'),
  meal('Ev Yemeği / Tabldot', 2.0, '🍲'),
  dairy('Süt Ürünleri', 2.5, '🥛'),
  beverage('İçecek', 0.3, '🥤'),
  other('Diğer', 1.0, '📦');

  final String displayName;
  final double co2Factor;
  final String emoji;

  const ProductCategory(this.displayName, this.co2Factor, this.emoji);

  /// Get category from string name, defaults to 'other'
  static ProductCategory fromString(String? name) {
    return ProductCategory.values.firstWhere(
      (cat) => cat.name == name,
      orElse: () => ProductCategory.other,
    );
  }
}

/// Comprehensive Product Form Bottom Sheet - Supports both Create and Edit modes
class ProductFormSheet extends StatefulWidget {
  final String marketId;
  final ProductModel? productToEdit;
  final VoidCallback? onProductSaved;

  const ProductFormSheet({
    super.key,
    required this.marketId,
    this.productToEdit,
    this.onProductSaved,
  });

  /// Check if we're in edit mode
  bool get isEditMode => productToEdit != null;

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _normalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _weightController = TextEditingController(text: '100');

  // Form state - initialized in initState for edit mode
  String _selectedEmoji = '🥐';
  ProductCategory _selectedCategory = ProductCategory.bakery;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 1));
  bool _isSaving = false;

  // Available emojis
  static const List<String> _foodEmojis = [
    '🥐',
    '🍞',
    '🥯',
    '🥖',
    '🍰',
    '🧁',
    '🥗',
    '🍲',
    '🥛',
    '🧀',
    '🥩',
    '🍎',
    '🥬',
    '🍪',
    '🥤',
  ];

  @override
  void initState() {
    super.initState();

    // CRITICAL: Initialize form with existing product data if editing
    if (widget.productToEdit != null) {
      final product = widget.productToEdit!;

      // Text controllers
      _nameController.text = product.name;
      _descriptionController.text = product.description ?? '';
      _normalPriceController.text = product.originalPrice.toStringAsFixed(2);
      _discountedPriceController.text = product.discountedPrice.toStringAsFixed(
        2,
      );
      _stockController.text = product.stock.toString();
      _weightController.text = product.weight.toStringAsFixed(0);

      // Non-text state variables - CRITICAL to set these!
      _selectedEmoji = product.imageEmoji;
      _selectedCategory = ProductCategory.fromString(product.category);
      _expiryDate = product.expiryDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _normalPriceController.dispose();
    _discountedPriceController.dispose();
    _stockController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// Calculate discount rate from prices
  int get _discountRate {
    final normal = double.tryParse(_normalPriceController.text) ?? 0;
    final discounted = double.tryParse(_discountedPriceController.text) ?? 0;
    if (normal <= 0 || discounted <= 0 || discounted >= normal) return 0;
    return ((1 - (discounted / normal)) * 100).round();
  }

  /// Calculate CO2 saved based on weight and category
  double get _co2Saved {
    final weightGrams = double.tryParse(_weightController.text) ?? 0;
    final weightKg = weightGrams / 1000;
    return _selectedCategory.co2Factor * weightKg;
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final normalPrice = double.tryParse(_normalPriceController.text) ?? 0;
      final discountedPrice =
          double.tryParse(_discountedPriceController.text) ?? 0;
      final stock = int.tryParse(_stockController.text) ?? 1;
      final weightGrams = double.tryParse(_weightController.text) ?? 100;
      int calculatedPoints = (_co2Saved * 100).round();
      if (calculatedPoints < 10) calculatedPoints = 10;

      final productData = {
        'marketId': widget.marketId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'originalPrice': normalPrice,
        'discountedPrice': discountedPrice,
        'discountRate': _discountRate,
        'stock': stock,
        'weight': weightGrams,
        'category': _selectedCategory.name,
        'imageEmoji': _selectedEmoji,
        'expiryDate': Timestamp.fromDate(_expiryDate),
        'co2Saved': _co2Saved,
        'isGreenBadge': true,
        'isActive': true,
        'points': calculatedPoints,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.isEditMode) {
        // UPDATE existing product
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productToEdit!.id)
            .update(productData);
      } else {
        // CREATE new product
        productData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('products')
            .add(productData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? 'Ürün Başarıyla Güncellendi! ✓'
                  : 'Ürün Başarıyla Eklendi! 🚀',
            ),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onProductSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title - changes based on mode
              Row(
                children: [
                  Icon(
                    widget.isEditMode ? Icons.edit : Icons.add_circle,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isEditMode ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Emoji Selector
              _buildSectionLabel('Ürün İkonu'),
              const SizedBox(height: 8),
              _buildEmojiSelector(),
              const SizedBox(height: 16),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                  label: 'Ürün Adı *',
                  hint: 'örn: Bayatlamış Poğaça',
                  icon: Icons.fastfood_outlined,
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Ürün adı gerekli' : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration(
                  label: 'Açıklama',
                  hint: 'Ürün hakkında kısa bilgi',
                  icon: Icons.description_outlined,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Price Row
              _buildSectionLabel('Fiyatlandırma'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _normalPriceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'Normal Fiyat (₺) *',
                        hint: '30.00',
                        icon: Icons.money_off,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Gerekli';
                        if (double.tryParse(v!) == null) return 'Geçersiz';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _discountedPriceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'İndirimli (₺) *',
                        hint: '15.00',
                        icon: Icons.local_offer,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Gerekli';
                        if (double.tryParse(v!) == null) return 'Geçersiz';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              // Discount Preview
              if (_discountRate > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.discountRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.discount,
                          color: AppColors.discountRed,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '%$_discountRate İndirim',
                          style: const TextStyle(
                            color: AppColors.discountRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Stock & Weight Row
              _buildSectionLabel('Stok & Ağırlık'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'Stok Adedi',
                        hint: '5',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'Ağırlık (gram)',
                        hint: '250',
                        icon: Icons.scale,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              _buildSectionLabel('Kategori'),
              const SizedBox(height: 8),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),

              // Expiry Date Picker
              _buildSectionLabel('Son Kullanma Tarihi (SKT)'),
              const SizedBox(height: 8),
              _buildDatePicker(),
              const SizedBox(height: 16),

              // CO2 Preview
              if (_co2Saved > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreenLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tahmini CO₂ Tasarrufu',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${_co2Saved.toStringAsFixed(2)} kg CO₂',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Save Button - text changes based on mode
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProduct,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          widget.isEditMode ? Icons.save : Icons.cloud_upload,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Kaydediliyor...'
                        : (widget.isEditMode ? 'Güncelle' : 'Kaydet'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    disabledBackgroundColor: AppColors.primaryGreen.withValues(
                      alpha: 0.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildEmojiSelector() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _foodEmojis.length,
        itemBuilder: (context, index) {
          final emoji = _foodEmojis[index];
          final isSelected = emoji == _selectedEmoji;

          return GestureDetector(
            onTap: () => setState(() => _selectedEmoji = emoji),
            child: Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreenLight
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProductCategory>(
          value: _selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: ProductCategory.values.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Row(
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(cat.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedCategory = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectExpiryDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              '${_expiryDate.day.toString().padLeft(2, '0')}/${_expiryDate.month.toString().padLeft(2, '0')}/${_expiryDate.year}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _expiryDate.difference(DateTime.now()).inDays <= 1
                    ? AppColors.discountRed.withValues(alpha: 0.1)
                    : AppColors.primaryGreenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _expiryDate.difference(DateTime.now()).inDays <= 0
                    ? 'Bugün!'
                    : '${_expiryDate.difference(DateTime.now()).inDays} gün',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _expiryDate.difference(DateTime.now()).inDays <= 1
                      ? AppColors.discountRed
                      : AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.discountRed, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// Keep backward compatibility alias
@Deprecated('Use ProductFormSheet instead')
typedef AddProductSheet = ProductFormSheet;
