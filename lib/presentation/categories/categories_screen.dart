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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getColorFromHex(category.colorHex);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
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
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(context.t('add_category_type', params: {
            'type': type == CategoryType.expense
                ? context.t('expense')
                : context.t('income')
          })),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Real-time Preview Section
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: selectedColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedColor.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: selectedColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selectedColor.withValues(alpha: 0.3)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selectedIcon,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nameController.text.trim().isNotEmpty
                                    ? nameController.text
                                    : (isBn ? 'ক্যাটেগরির নাম' : 'Category Name'),
                                style: AppTextStyles.body1.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: selectedColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (nameBnController.text.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  nameBnController.text,
                                  style: AppTextStyles.caption.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final icon = await showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => const _IconPickerBottomSheet(),
                            );
                            if (icon != null) {
                              setState(() => selectedIcon = icon);
                            }
                          },
                          icon: const Icon(Icons.palette_outlined, size: 16),
                          label: Text(isBn ? 'আইকন' : 'Icon', style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            backgroundColor: selectedColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Colors palette selector
                  Text(context.t('select_color'), style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppColors.categoryColors
                            .map((color) => InkWell(
                                  onTap: () => setState(() => selectedColor = color),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedColor == color
                                            ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: selectedColor == color
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          )
                                        : null,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name Input Fields
                  TextField(
                    controller: nameController,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: context.t('category_name_english'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameBnController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: context.t('category_name_bangla'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.translate),
                    ),
                  ),
                ],
              ),
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
                    name: nameController.text.trim(),
                    nameBn: nameBnController.text.trim(),
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
                      content: Text(context.t('category_added_success')),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(context.t('edit_category')),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Real-time Preview Section
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: selectedColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedColor.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: selectedColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selectedColor.withValues(alpha: 0.3)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selectedIcon,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nameController.text.trim().isNotEmpty
                                    ? nameController.text
                                    : (isBn ? 'ক্যাটেগরির নাম' : 'Category Name'),
                                style: AppTextStyles.body1.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: selectedColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (nameBnController.text.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  nameBnController.text,
                                  style: AppTextStyles.caption.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final icon = await showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => const _IconPickerBottomSheet(),
                            );
                            if (icon != null) {
                              setState(() => selectedIcon = icon);
                            }
                          },
                          icon: const Icon(Icons.palette_outlined, size: 16),
                          label: Text(isBn ? 'আইকন' : 'Icon', style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            backgroundColor: selectedColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Colors palette selector
                  Text(context.t('select_color'), style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppColors.categoryColors
                            .map((color) => InkWell(
                                  onTap: () => setState(() => selectedColor = color),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selectedColor == color
                                            ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: selectedColor == color
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          )
                                        : null,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name Input Fields
                  TextField(
                    controller: nameController,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: context.t('category_name_english'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameBnController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: context.t('category_name_bangla'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.translate),
                    ),
                  ),
                ],
              ),
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
                    name: nameController.text.trim(),
                    nameBn: nameBnController.text.trim(),
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
                      content: Text(context.t('category_updated_success')),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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

// ─────────────────────────────────────────────────────────────────────────
// Emoji Library Map for Search and Categorized Display
// ─────────────────────────────────────────────────────────────────────────
const Map<String, Map<String, List<String>>> _emojiLibrary = {
  'BILLS & UTILITIES': {
    '🏠': ['home', 'house', 'rent', 'renting', 'property', 'বাড়ি', 'বাসা', 'ভাড়া'],
    '💡': ['light', 'bulb', 'electricity', 'power', 'util', 'utility', 'বিদ্যুৎ', 'আলো', 'বাল্ব'],
    '💧': ['water', 'tap', 'utilities', 'utility', 'পানি', 'জল', 'ইউটিলিটি'],
    '📶': ['wifi', 'internet', 'router', 'network', 'broadband', 'ইন্টারনেট', 'ওয়াইফাই'],
    '⛽': ['gas', 'cylinder', 'fuel', 'petrol', 'octane', 'diesel', 'গ্যাস', 'জ্বালানি', 'তেল'],
    '🧹': ['broom', 'clean', 'cleaning', 'maid', 'sweeper', 'ঝাড়ু', 'পরিষ্কার'],
    '🔧': ['wrench', 'tool', 'repair', 'maintenance', 'fixing', 'রেন্চ', 'মেরামত'],
    '🌀': ['fan', 'cooler', 'vent', 'ac', 'ফ্যান', 'বাতাস'],
    '🛵': ['scooter', 'bike', 'delivery', 'ride', 'স্কুটার', 'বাইক'],
    '🛋️': ['sofa', 'furniture', 'decor', 'living', 'couch', 'সোফা', 'আসবাবপত্র'],
    '⚡': ['lightning', 'electricity', 'power', 'charge', 'বিদ্যুৎ', 'চার্জ'],
    '🏡': ['villa', 'home', 'garden', 'star', 'বাড়ি'],
    '🛠️': ['tools', 'hammer', 'screwdriver', 'repair', 'যন্ত্রপাতি', 'মেরামত'],
    '🔨': ['hammer', 'tool', 'work', 'হাতুড়ি'],
    '🧾': ['invoice', 'bill', 'receipt', 'slip', 'বিল', 'রসিদ'],
    '🔑': ['key', 'lock', 'access', 'চাবি', 'তালা'],
    '🗑️': ['trash', 'garbage', 'dustbin', 'waste', 'ময়লা', 'ডাস্টবিন'],
  },
  'TRANSPORTATION': {
    '🚗': ['car', 'auto', 'taxi', 'drive', 'ride', 'গাড়ি', 'ট্যাক্সি'],
    '🏍️': ['motorcycle', 'bike', 'ride', 'মোটরসাইকেল', 'বাইক'],
    '🚲': ['bicycle', 'cycle', 'বাইসাইকেল', 'সাইকেল'],
    '🚌': ['bus', 'transit', 'public', 'বাস', 'পরিবহন'],
    '🚄': ['train', 'metro', 'railway', 'ট্রেন', 'মেট্রো'],
    '🚢': ['ship', 'boat', 'launch', 'ferry', 'জাহাজ', 'লঞ্চ'],
    '⛽': ['fuel', 'gas', 'petrol', 'octane', 'পাম্প', 'জ্বালানি'],
    '🚕': ['taxi', 'cab', 'ride', 'ট্যাক্সি'],
    '🚚': ['truck', 'delivery', 'courier', 'van', 'ট্রাক', 'কুরিয়ার'],
    '🛴': ['scooter', 'kick', 'স্কুটার'],
    '✈️': ['airplane', 'flight', 'travel', 'প্লেন', 'বিমান'],
    '🚁': ['helicopter', 'chopper', 'হেলিকপ্টার'],
    '⚓': ['anchor', 'port', 'নঙ্গর', 'বন্দর'],
  },
  'TRAVEL & VACATION': {
    '✈️': ['airplane', 'flight', 'travel', 'holiday', 'ভ্রমণ', 'বিমান'],
    '🧳': ['suitcase', 'luggage', 'baggage', 'travel', 'ভ্রমণ', 'লাগেজ'],
    '🗺️': ['map', 'travel', 'location', 'navigation', 'মানচিত্র', 'ম্যাপ'],
    '🧭': ['compass', 'direction', 'travel', 'কম্পাস'],
    '🏖️': ['beach', 'umbrella', 'holiday', 'vacation', 'সমুদ্র', 'সৈকত'],
    '⛺': ['tent', 'camping', 'outdoor', 'তাঁবু', 'ক্যাম্পিং'],
    '🏨': ['hotel', 'stay', 'vacation', 'রিসোর্ট', 'হোটেল'],
    '🛂': ['passport', 'visa', 'immigration', 'পাসপোর্ট', 'ভিসা'],
    '🌐': ['globe', 'world', 'travel', 'globe', 'পৃথিবী', 'বিশ্ব'],
    '🎟️': ['ticket', 'pass', 'entry', 'টিকিট'],
    '🎢': ['rollercoaster', 'park', 'amusement', 'পার্ক', 'রাইড'],
  },
  'HEALTH & FITNESS': {
    '🏥': ['hospital', 'clinic', 'medical', 'ডাক্তার', 'হাসপাতাল'],
    '🧪': ['lab', 'test', 'medicine', 'পরীক্ষা', 'ল্যাব'],
    '💈': ['barber', 'salon', 'haircut', 'সেলুন', 'চুল'],
    '💇': ['haircut', 'salon', 'barber', 'চুল', 'বিউটি পার্লার'],
    '🏋️': ['gym', 'fitness', 'workout', 'weight', 'জিম', 'ব্যায়াম'],
    '🌿': ['herb', 'ayurvedic', 'natural', 'হর্বাল', 'ভেষজ'],
    '🚬': ['cigarette', 'smoking', 'tobacco', 'ধূমপান', 'সিগারেট'],
    '🩹': ['bandage', 'wound', 'plaster', 'ব্যান্ডেজ'],
    '🩺': ['stethoscope', 'doctor', 'checkup', 'ডাক্তার', 'স্টেথোস্কোপ'],
    '🍎': ['apple', 'diet', 'healthy', 'ফল', 'আপেল'],
    '❤️': ['heart', 'love', 'health', 'হৃদয়', 'স্বাস্থ্য'],
    '🏃': ['running', 'run', 'cardio', 'হাঁটা', 'দৌড়'],
    '🚴': ['cycling', 'ride', 'cardio', 'সাইকেল'],
    '💊': ['pill', 'medicine', 'tablet', 'drug', 'ওষুধ', 'ট্যাবলেট'],
    '🧴': ['lotion', 'shampoo', 'care', 'নিজের যত্ন', 'লোশন'],
  },
  'ENTERTAINMENT': {
    '💻': ['laptop', 'computer', 'pc', 'work', 'ল্যাপটপ', 'কম্পিউটার'],
    '📱': ['phone', 'mobile', 'recharge', 'মোবাইল', 'ফোন'],
    '🎬': ['movie', 'cinema', 'video', 'netflix', 'সিনেমা', 'মুভি'],
    '🎮': ['game', 'gaming', 'playstation', 'xbox', 'গেম', 'খেলা'],
    '📷': ['camera', 'photo', 'photography', 'ক্যামেরা', 'ছবি'],
    '🎵': ['music', 'song', 'spotify', 'গান', 'মিউজিক'],
    '📝': ['note', 'memo', 'writing', 'নোট', 'খাতা'],
    '🏷️': ['tag', 'price', 'discount', 'অফার', 'ডিসকাউন্ট'],
    '🌐': ['globe', 'internet', 'browsing', 'ওয়েবসাইট'],
    '📶': ['wifi', 'network', 'signal', 'নেটওয়ার্ক'],
    '💵': ['cash', 'money', 'dollar', 'টাকা', 'ক্যাশ'],
    '🎧': ['headphone', 'music', 'audio', 'হেডফোন', 'গান'],
    '📺': ['tv', 'television', 'serial', 'টিভি'],
    '🎟️': ['ticket', 'cinema', 'movie', 'টিকিট'],
    '🍺': ['beer', 'alcohol', 'drink', 'মদ', 'বিয়ার'],
    '🎤': ['mic', 'karaoke', 'singing', 'মাইক', 'গান'],
    '🍿': ['popcorn', 'cinema', 'snack', 'পপকর্ন', 'খাবার'],
    '🎨': ['art', 'paint', 'hobby', 'draw', 'আর্ট', 'রঙ'],
  },
  'FAMILY & PERSONAL': {
    '🙋': ['person', 'me', 'self', 'আমি', 'নিজের'],
    '🚼': ['baby', 'stroller', 'child', 'বাচ্চা', 'শিশু'],
    '🐾': ['pet', 'paw', 'dog', 'cat', 'পোষা প্রাণী', 'বিড়াল', 'কুকুর'],
    '🌙': ['moon', 'night', 'sleep', 'চাঁদ', 'রাত'],
    '🎁': ['gift', 'present', 'birthday', 'উপহার', 'জন্মদিন'],
    '🤝': ['handshake', 'deal', 'agreement', 'চুক্তি', 'পাবলিক'],
    '💍': ['ring', 'marriage', 'proposal', 'আংটি', 'বিয়ে'],
    '💒': ['wedding', 'marriage', 'ceremony', 'বিয়ে', 'অনুষ্ঠান'],
    '👶': ['baby', 'kid', 'child', 'বাচ্চা', 'শিশু'],
    '💖': ['heart', 'love', 'family', 'ভালোবাসা', 'পরিবার'],
    '👨‍👩‍👧‍👦': ['family', 'kids', 'parents', 'পরিবার', 'বাবা-মা'],
    '👫': ['friends', 'couple', 'partner', 'বন্ধু', 'দম্পতি'],
  },
  'SHOPPING & LIFESTYLE': {
    '🛒': ['shopping', 'grocery', 'cart', 'বাজার', 'কেনাকাটা'],
    '🧺': ['basket', 'shopping', 'laundry', 'ঝুড়ি'],
    '🍎': ['fruit', 'apple', 'healthy', 'ফল', 'আপেল'],
    '🥚': ['egg', 'grocery', 'breakfast', 'ডিম', 'নাস্তা'],
    '🥐': ['croissant', 'bakery', 'bread', 'রুটি', 'বেকরি'],
    '🧊': ['ice', 'fridge', 'cold', 'বরফ', 'ফ্রিজ'],
    '🥛': ['milk', 'dairy', 'drink', 'দুধ'],
    '🐟': ['fish', 'grocery', 'bazaar', 'মাছ', 'বাজার'],
    '👚': ['clothes', 'shirt', 'dress', 'clothing', 'পোশাক', 'জামা'],
    '👕': ['tshirt', 'clothing', 'পোশাক', 'টিশার্ট'],
    '⌚': ['watch', 'clock', 'smartwatch', 'ঘড়ি'],
    '💎': ['diamond', 'jewelry', 'expensive', 'হীরা', 'গহনা'],
    '🛍️': ['shopping', 'bags', 'mall', 'কেনাকাটা', 'শপিং'],
    '🚶': ['walk', 'shopping', 'lifestyle', 'হাঁটা'],
    '👜': ['bag', 'handbag', 'fashion', 'ব্যাগ', 'হ্যান্ডব্যাগ'],
    '👟': ['shoes', 'sneakers', 'sports', 'জুতো', 'স্নিকার্স'],
    '🎩': ['hat', 'cap', 'fashion', 'টুপি'],
    '👓': ['glasses', 'spectacles', 'vision', 'চশমা'],
    '👗': ['dress', 'clothing', 'fashion', 'পোশাক', 'জামা'],
  },
  'FOOD & DINING': {
    '🍴': ['fork', 'knife', 'cutlery', 'dine', 'restaurant', 'খাবার', 'রেস্টুরেন্ট'],
    '🍔': ['burger', 'fastfood', 'junk', 'খাবার', 'বার্গার'],
    '☕': ['coffee', 'tea', 'cafe', 'চা', 'কফি', 'ক্যাফে'],
    '🍕': ['pizza', 'fastfood', 'খাবার', 'পিজ্জা'],
    '🍰': ['cake', 'dessert', 'sweet', 'মিষ্টি', 'কেক'],
    '🍸': ['cocktail', 'drink', 'bar', 'পানীয়'],
    '🥤': ['soda', 'drink', 'juice', 'জুস', 'কোল্ড ড্রিংক'],
    '🚜': ['tractor', 'farm', 'agriculture', 'কৃষি', 'ট্রাক্টর'],
    '🍣': ['sushi', 'fish', 'dining', 'সুশি'],
    '🍦': ['icecream', 'sweet', 'dessert', 'আইসক্রিম'],
    '🍜': ['noodles', 'ramen', 'pasta', 'নুডলস'],
    '🍷': ['wine', 'alcohol', 'drink', 'মদ', 'ওয়াইন'],
    '🍩': ['donut', 'sweet', 'খাবার', 'ডোনাট'],
    '🥑': ['avocado', 'healthy', 'diet', 'অ্যাভোকাডো'],
    '🍳': ['egg', 'cooking', 'breakfast', 'ডিম', 'রান্না'],
    '🥩': ['meat', 'beef', 'chicken', 'মাংস'],
  },
  'GENERAL & COMMON': {
    '⭐': ['star', 'favorite', 'rating', 'তারকা', 'প্রিয়'],
    '📄': ['document', 'file', 'paper', 'দলিল', 'কাগজ'],
    '⏰': ['clock', 'alarm', 'time', 'সময়', 'ঘড়ি'],
    '⚙️': ['gear', 'settings', 'config', 'সেটিংস', 'গিয়ার'],
    '🔍': ['search', 'find', 'zoom', 'খোঁজা', 'সার্চ'],
    '📅': ['calendar', 'date', 'schedule', 'ক্যালেন্ডার', 'তারিখ'],
    '🛡️': ['shield', 'insurance', 'safety', 'বীমা', 'নিরাপত্তা'],
    '🔔': ['bell', 'notification', 'alert', 'ঘণ্টা', 'নোটিফিকেশন'],
    '📎': ['clip', 'paperclip', 'attachment', 'ক্লিপ'],
    '🔒': ['lock', 'secure', 'privacy', 'তালা', 'সুরক্ষা'],
  },
  'MONEY & INCOME': {
    '💵': ['cash', 'money', 'income', 'salary', 'টাকা', 'ক্যাশ', 'বেতন'],
    '🏦': ['bank', 'deposit', 'transfer', 'ব্যাংক', 'জমা'],
    '👛': ['wallet', 'purse', 'money', 'মানিব্যাগ'],
    '💼': ['job', 'office', 'salary', 'চাকরি', 'বেতন'],
    '💱': ['exchange', 'forex', 'currency', 'বিনিময়', 'মুদ্রা'],
    '🐷': ['piggybank', 'savings', 'সঞ্চয়', 'ব্যাংক'],
    '🪙': ['coin', 'cash', 'money', 'কয়েন', 'পয়সা'],
    '📈': ['chart', 'growth', 'profit', 'লাভ', 'গ্রোথ'],
    '📉': ['loss', 'expense', 'decrease', 'ক্ষতি', 'লস'],
    '%': ['percent', 'interest', 'discount', 'শতকরা', 'সুদ'],
    '🤲': ['charity', 'donation', 'zakat', 'দান', 'যাকাত'],
    '💸': ['send', 'transfer', 'expense', 'টাকা', 'খরচ'],
    '💳': ['card', 'credit', 'debit', 'কার্ড', 'ক্রেডিট'],
  },
  'EDUCATION & WORK': {
    '🎓': ['graduation', 'education', 'university', 'শিক্ষা', 'বিশ্ববিদ্যালয়'],
    '📖': ['book', 'read', 'study', 'বই', 'পড়া'],
    '🎒': ['backpack', 'school', 'bag', 'স্কুল', 'ব্যাগ'],
    '✒️': ['pen', 'ink', 'write', 'কলম'],
    '✏️': ['pencil', 'write', 'draw', 'পেন্সিল'],
    '🔬': ['science', 'lab', 'research', 'বিজ্ঞান', 'গবেষণা'],
    '📋': ['clipboard', 'board', 'tasks', 'তালিকা', 'বোর্ড'],
    '📐': ['ruler', 'math', 'measure', 'রুলার', 'পরিমাপ'],
    '🖌️': ['brush', 'art', 'paint', 'তুলি', 'আর্ট'],
    '🏫': ['school', 'college', 'education', 'স্কুল', 'কলেজ'],
  },
  'BUSINESS & OFFICE': {
    '📊': ['chart', 'analytics', 'report', 'গ্রাফ', 'রিপোর্ট'],
    '🚪': ['door', 'office', 'entry', 'দরজা', 'অফিস'],
    '🖨️': ['printer', 'print', 'office', 'প্রিন্টার', 'অফিস'],
    '🏪': ['store', 'shop', 'business', 'দোকান', 'ব্যবসা'],
    '📦': ['box', 'package', 'delivery', 'বাক্স', 'পার্সেল'],
    '📛': ['badge', 'id', 'name', 'ব্যাজ', 'আইডি'],
    '📢': ['megaphone', 'announcement', 'marketing', 'ঘোষণা', 'প্রচার'],
    '🧮': ['abacus', 'calculator', 'math', 'হিসাব', 'ক্যালকুলেটর'],
    '✉️': ['envelope', 'mail', 'email', 'চিঠি', 'ইমেইল'],
    '🏢': ['building', 'office', 'company', 'অফিস', 'বিল্ডিং'],
    '📂': ['folder', 'files', 'office', 'ফোল্ডার', 'ফাইল'],
  }
};

class _IconPickerBottomSheet extends StatefulWidget {
  const _IconPickerBottomSheet();

  @override
  State<_IconPickerBottomSheet> createState() => _IconPickerBottomSheetState();
}

class _IconPickerBottomSheetState extends State<_IconPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Filter emojis based on search query
    final Map<String, List<String>> filteredLibrary = {};
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      final List<String> matchingEmojis = [];
      _emojiLibrary.forEach((category, emojis) {
        emojis.forEach((emoji, keywords) {
          if (keywords.any((kw) => kw.contains(query))) {
            matchingEmojis.add(emoji);
          }
        });
      });
      if (matchingEmojis.isNotEmpty) {
        filteredLibrary[isBn ? 'অনুসন্ধান ফলাফল' : 'Search Results'] = matchingEmojis;
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Top drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isBn ? 'আইকন নির্বাচন করুন' : 'Select Icon',
                      style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: isBn
                        ? 'আইকন খুঁজুন (যেমন: খাবার, গাড়ি)'
                        : 'Search icons (e.g. food, car)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ),
              // Emoji Grid List
              Expanded(
                child: _searchQuery.trim().isNotEmpty
                    ? (filteredLibrary.isEmpty
                        ? Center(
                            child: Text(
                              isBn ? 'কোনো ফলাফল পাওয়া যায়নি' : 'No results found',
                              style: AppTextStyles.body2.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : GridView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredLibrary.values.first.length,
                            itemBuilder: (context, idx) {
                              final emoji = filteredLibrary.values.first[idx];
                              return _buildEmojiButton(context, emoji);
                            },
                          ))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _emojiLibrary.length,
                        itemBuilder: (context, index) {
                          final category = _emojiLibrary.keys.elementAt(index);
                          final emojisMap = _emojiLibrary[category]!;
                          
                          final String displayCategory = isBn 
                              ? _translateCategoryNameBn(category) 
                              : category;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  displayCategory,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: emojisMap.length,
                                itemBuilder: (context, idx) {
                                  final emoji = emojisMap.keys.elementAt(idx);
                                  return _buildEmojiButton(context, emoji);
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmojiButton(BuildContext context, String emoji) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => Navigator.pop(context, emoji),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 26),
        ),
      ),
    );
  }

  String _translateCategoryNameBn(String category) {
    switch (category) {
      case 'BILLS & UTILITIES':
        return 'বিল ও ইউটিলিটি';
      case 'TRANSPORTATION':
        return 'যাতায়াত ও পরিবহন';
      case 'TRAVEL & VACATION':
        return 'ভ্রমণ ও অবকাশ';
      case 'HEALTH & FITNESS':
        return 'স্বাস্থ্য ও ফিটনেস';
      case 'ENTERTAINMENT':
        return 'বিনোদন';
      case 'FAMILY & PERSONAL':
        return 'পরিবার ও ব্যক্তিগত';
      case 'SHOPPING & LIFESTYLE':
        return 'কেনাকাটা ও জীবনধারা';
      case 'FOOD & DINING':
        return 'খাবার ও ডাইনিং';
      case 'GENERAL & COMMON':
        return 'সাধারণ';
      case 'MONEY & INCOME':
        return 'অর্থ ও আয়';
      case 'EDUCATION & WORK':
        return 'শিক্ষা ও কাজ';
      case 'BUSINESS & OFFICE':
        return 'ব্যবসা ও অফিস';
      default:
        return category;
    }
  }
}
