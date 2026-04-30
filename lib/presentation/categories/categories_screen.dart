// lib/presentation/categories/categories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/l10n/app_l10n.dart';
import '../../data/models/category_model.dart';
import '../providers/app_providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t('categories')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.t('expense')),
            Tab(text: context.t('income')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(CategoryType.expense),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(CategoryType.expense),
          _buildCategoryList(CategoryType.income),
        ],
      ),
    );
  }

  Widget _buildCategoryList(CategoryType type) {
    // ✅ ফিক্স: Notifier এর বদলে সরাসরি স্টেট (List) watch করা হচ্ছে
    final allCategories = ref.watch(categoriesProvider);

    // এখানে লিস্ট ফিল্টার করা হচ্ছে
    final categoryList = allCategories.where((cat) {
      if (cat.isDeleted) return false;
      if (cat.type == CategoryType.both) return true;
      return cat.type == type;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categoryList.length + 1,
      itemBuilder: (context, index) {
        if (index == categoryList.length) {
          return _buildAddCategoryCard(type);
        }
        return _buildCategoryCard(categoryList[index]);
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    final color = _getColorFromHex(category.colorHex);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              category.icon,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          category.nameBn,
          style: AppTextStyles.caption,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            if (!category.isDefault) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditCategoryDialog(category);
                  } else if (value == 'delete') {
                    _deleteCategory(category);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                      value: 'edit', child: Text(context.t('edit'))),
                  PopupMenuItem(
                      value: 'delete', child: Text(context.t('delete'))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryCard(CategoryType type) {
    return InkWell(
      onTap: () => _showAddCategoryDialog(type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline,
                color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              context.t('add_new_category'),
              style: AppTextStyles.body1.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(CategoryType type) {
    final nameController = TextEditingController();
    final nameBnController = TextEditingController();
    String selectedIcon = '📦';
    Color selectedColor = AppColors.primary;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.t('add_category_type', params: {
            'type': type == CategoryType.expense
                ? context.t('expense')
                : context.t('income')
          })),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Selector
                Text(context.t('select_icon'), style: AppTextStyles.body2),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '🍔',
                    '📚',
                    '🚗',
                    '🏥',
                    '🎮',
                    '🛒',
                    '💡',
                    '🎵',
                    '✈️',
                    '💰',
                    '🏠',
                    '📱',
                    '⚽',
                    '🎨',
                    '🔧',
                    '📦'
                  ]
                      .map((icon) => InkWell(
                            onTap: () => setState(() => selectedIcon = icon),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: selectedIcon == icon
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedIcon == icon
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(icon,
                                    style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Color Selector
                Text(context.t('select_color'), style: AppTextStyles.body2),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppColors.chartColors
                      .map((color) => InkWell(
                            onTap: () => setState(() => selectedColor = color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Name Fields
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: context.t('category_name_english'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameBnController,
                  decoration: InputDecoration(
                    labelText: context.t('category_name_bangla'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    nameBnController.text.isNotEmpty) {
                  final category = CategoryModel(
                    id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text,
                    nameBn: nameBnController.text,
                    icon: selectedIcon,
                    colorHex: _colorToHex(selectedColor),
                    type: type,
                    createdAt: DateTime.now(),
                  );
                  await ref.read(categoriesProvider.notifier).addCategory(category);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(context.t('category_added_success'))),
                  );
                }
              },
              child: Text(context.t('add')),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    final nameBnController = TextEditingController(text: category.nameBn);
    String selectedIcon = category.icon;
    Color selectedColor = _getColorFromHex(category.colorHex);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.t('edit_category')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Similar to add dialog but with pre-filled values
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: context.t('category_name_english'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameBnController,
                  decoration: InputDecoration(
                    labelText: context.t('category_name_bangla'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    nameBnController.text.isNotEmpty) {
                  final updatedCategory = category.copyWith(
                    name: nameController.text,
                    nameBn: nameBnController.text,
                    icon: selectedIcon,
                    colorHex: _colorToHex(selectedColor),
                  );
                  await ref
                      .read(categoriesProvider.notifier)
                      .updateCategory(updatedCategory);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(context.t('category_updated_success'))),
                  );
                }
              },
              child: Text(context.t('update')),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('delete_category')),
        content: Text(context.t('delete_category_confirm',
            params: {'name': category.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(categoriesProvider.notifier).deleteCategory(category.id);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.t('category_deleted'))),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.t('delete')),
          ),
        ],
      ),
    );
  }

  Color _getColorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }
}
