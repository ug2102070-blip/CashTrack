// lib/presentation/tools/notes_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_text_styles.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const _boxName = 'settingsBox';
  static const _notesKey = 'notes_list_v1';
  static const _legacyKey = 'quick_notes';

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  bool _loading = true;
  Box? _box;
  List<_NoteEntry> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);

    if (!mounted) return;

    final raw = box.get(_notesKey);
    List<_NoteEntry> items = [];
    if (raw is List) {
      items = raw
          .whereType<Map>()
          .map((e) => _NoteEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    // migrate legacy single note if present
    final legacy = (box.get(_legacyKey, defaultValue: '') as String?) ?? '';
    if (items.isEmpty && legacy.trim().isNotEmpty) {
      final now = DateTime.now();
      items.add(_NoteEntry(
        id: now.microsecondsSinceEpoch.toString(),
        title: context.t('note'),
        content: legacy.trim(),
        createdAt: now,
        updatedAt: now,
      ));
      await box.put(_notesKey, items.map((e) => e.toMap()).toList());
    }

    if (!mounted) return;
    setState(() {
      _box = box;
      _notes = items;
      _loading = false;
    });
  }

  Future<void> _saveNotesList() async {
    final box = _box ??
        (Hive.isBoxOpen(_boxName)
            ? Hive.box(_boxName)
            : await Hive.openBox(_boxName));
    await box.put(_notesKey, _notes.map((e) => e.toMap()).toList());
  }

  void _addNote() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty && content.isEmpty) return;

    final now = DateTime.now();
    final note = _NoteEntry(
      id: now.microsecondsSinceEpoch.toString(),
      title: title.isEmpty ? context.t('untitled') : title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );

    setState(() {
      _notes.insert(0, note);
      _titleCtrl.clear();
      _contentCtrl.clear();
    });
    await _saveNotesList();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.t('note_saved')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _deleteNote(_NoteEntry note) async {
    setState(() => _notes.removeWhere((n) => n.id == note.id));
    await _saveNotesList();
  }

  void _editNote(_NoteEntry note) {
    final titleCtrl = TextEditingController(text: note.title);
    final contentCtrl = TextEditingController(text: note.content);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(context.t('edit_note'),
                  style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: context.t('title'),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: context.t('note'),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(context.t('cancel')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        setState(() {
                          final idx = _notes.indexWhere((n) => n.id == note.id);
                          if (idx >= 0) {
                            _notes[idx] = note.copyWith(
                              title: titleCtrl.text.trim().isEmpty
                                  ? context.t('untitled')
                                  : titleCtrl.text.trim(),
                              content: contentCtrl.text.trim(),
                              updatedAt: now,
                            );
                          }
                        });
                        await _saveNotesList();
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                      },
                      child: Text(context.t('save')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<_NoteEntry>> _groupByDate(List<_NoteEntry> items) {
    final map = <String, List<_NoteEntry>>{};
    for (final n in items) {
      final key = DateFormat('yyyy-MM-dd').format(n.updatedAt);
      map.putIfAbsent(key, () => []).add(n);
    }
    return map;
  }

  String _dateHeader(String key) {
    final d = DateFormat('yyyy-MM-dd').parse(key);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) return context.t('today');
    if (date == today.subtract(const Duration(days: 1))) {
      return context.t('yesterday');
    }
    return DateFormat('dd MMM yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final list = [..._notes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final grouped = _groupByDate(list);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/tools');
                              }
                            },
                            icon: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.07)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.t('notes'),
                            style: AppTextStyles.h2.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // New note composer
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _contentFocus.hasFocus
                              ? primary.withValues(alpha: 0.35)
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : Colors.black.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.15 : 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.t('new_note'),
                              style: AppTextStyles.h5.copyWith(
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _titleCtrl,
                            focusNode: _titleFocus,
                            decoration: InputDecoration(
                              hintText: context.t('title'),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _contentCtrl,
                            focusNode: _contentFocus,
                            minLines: 4,
                            maxLines: 6,
                            decoration: InputDecoration(
                              hintText: context.t('write_something'),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addNote,
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: Text(context.t('save_note')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Notes list
                  if (list.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                        child: Text(
                          context.t('no_notes_yet'),
                          style: AppTextStyles.body2.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    )
                  else
                    ...grouped.entries.map((entry) {
                      final header = _dateHeader(entry.key);
                      final items = entry.value;
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            if (i == 0) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                                child: Text(
                                  header,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    letterSpacing: 0.6,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              );
                            }
                            final note = items[i - 1];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: InkWell(
                                onTap: () => _editNote(note),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.07)
                                          : Colors.black.withValues(alpha: 0.05),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              note.title == 'Untitled'
                                                  ? context.t('untitled')
                                                  : note.title,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            DateFormat('hh:mm a')
                                                .format(note.updatedAt),
                                            style: AppTextStyles.caption.copyWith(
                                              fontSize: 10,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () => _deleteNote(note),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        note.content.isEmpty
                                            ? context.t('no_content')
                                            : note.content,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: items.length + 1,
                        ),
                      );
                    }),

                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
      ),
    );
  }
}

class _NoteEntry {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  _NoteEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  _NoteEntry copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return _NoteEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static _NoteEntry fromMap(Map<String, dynamic> map) {
    return _NoteEntry(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? 'Untitled',
      content: (map['content'] as String?) ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
