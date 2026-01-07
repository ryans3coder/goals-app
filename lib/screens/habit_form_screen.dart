import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/habits/habit_form_options.dart';
import '../models/habit.dart';
import '../services/data_provider.dart';
import '../theme/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';

class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({super.key, this.habit});

  final Habit? habit;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _selectedEmoji;
  String? _selectedCategoryId;
  String? _emojiError;
  bool _isSaving = false;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _nameController = TextEditingController(text: habit?.title ?? '');
    _descriptionController =
        TextEditingController(text: habit?.description ?? '');
    _selectedEmoji = habit?.emoji.isNotEmpty == true
        ? habit?.emoji
        : HabitFormOptions.fallbackEmoji;
    _selectedCategoryId = habit?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState?.validate() ?? false;
    final emojiSelected = _selectedEmoji != null && _selectedEmoji!.isNotEmpty;
    setState(() {
      _emojiError = emojiSelected ? null : AppStrings.habitEmojiRequired;
    });

    if (!isValid || !emojiSelected) {
      return;
    }

    setState(() => _isSaving = true);
    final dataProvider = context.read<DataProvider>();
    final existingHabit = widget.habit;

    try {
      await dataProvider.addHabit(
        Habit(
          id: existingHabit?.id ?? '',
          userId: existingHabit?.userId ?? '',
          title: _nameController.text.trim(),
          frequency: existingHabit?.frequency ??
              HabitFormOptions.defaultFrequency,
          currentStreak: existingHabit?.currentStreak ?? 0,
          isCompletedToday: existingHabit?.isCompletedToday ?? false,
          categoryId: _selectedCategoryId,
          emoji: _selectedEmoji ?? HabitFormOptions.fallbackEmoji,
          description: _descriptionController.text.trim(),
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.habitSaveError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final habit = widget.habit;
    if (habit == null) {
      return;
    }

    final theme = Theme.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.habitDeleteTitle),
          content: const Text(AppStrings.habitDeleteMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: const Text(AppStrings.habitDeleteAction),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await context.read<DataProvider>().deleteHabit(habit);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.habitDeleteError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = context.watch<DataProvider>().categories;
    final sortedCategories = [...categories]
      ..sort((a, b) => a.name.compareTo(b.name));
    final availableCategoryIds = sortedCategories.map((item) => item.id).toSet();
    final missingCategory = _selectedCategoryId != null &&
        !availableCategoryIds.contains(_selectedCategoryId);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? AppStrings.habitEditTitle
              : AppStrings.habitCreateTitle,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: AppStrings.habitDeleteAction,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.nameLabel,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.nameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.habitEmojiLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final emoji in HabitFormOptions.emojiOptions)
                      ChoiceChip(
                        label: Text(emoji),
                        selected: _selectedEmoji == emoji,
                        onSelected: (_) {
                          setState(() {
                            _selectedEmoji = emoji;
                            _emojiError = null;
                          });
                        },
                      ),
                  ],
                ),
                if (_emojiError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _emojiError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: AppStrings.habitCategoryLabel,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(AppStrings.habitNoCategory),
                    ),
                    if (missingCategory)
                      DropdownMenuItem<String?>(
                        value: _selectedCategoryId,
                        child: Text(_selectedCategoryId ?? ''),
                      ),
                    for (final category in sortedCategories)
                      DropdownMenuItem<String?>(
                        value: category.id,
                        child: Text('${category.emoji} ${category.name}'),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.habitDescriptionLabel,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: AppStrings.save,
                  onPressed: _isSaving ? null : _saveHabit,
                  isLoading: _isSaving,
                ),
                const SizedBox(height: AppSpacing.md),
                AppSecondaryButton(
                  label: AppStrings.cancel,
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
