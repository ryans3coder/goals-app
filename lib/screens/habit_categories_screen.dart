import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/habits/habit_category_form_options.dart';
import '../domain/habits/habit_category_palette.dart';
import '../models/habit_category.dart';
import '../services/data_provider.dart';
import '../theme/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state_widget.dart';

class HabitCategoriesScreen extends StatefulWidget {
  const HabitCategoriesScreen({super.key});

  @override
  State<HabitCategoriesScreen> createState() => _HabitCategoriesScreenState();
}

class _HabitCategoriesScreenState extends State<HabitCategoriesScreen> {
  Future<void> _openCategoryForm({HabitCategory? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final isEditing = category != null;
    String selectedEmoji = category?.emoji.isNotEmpty == true
        ? category!.emoji
        : HabitCategoryFormOptions.emojiOptions.first;
    String selectedColorToken = category?.colorToken.isNotEmpty == true
        ? category!.colorToken
        : HabitCategoryFormOptions.defaultColorToken;
    String? nameError;
    String? emojiError;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.modalBackgroundColor ??
          Theme.of(context).colorScheme.surface,
      shape: Theme.of(context).bottomSheetTheme.shape,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.xl,
                bottom:
                    AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing
                        ? AppStrings.habitCategoryEditTitle
                        : AppStrings.habitCategoryCreateTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: AppStrings.habitCategoryNameLabel,
                      errorText: nameError,
                    ),
                    onChanged: (_) {
                      if (nameError == null) {
                        return;
                      }
                      setModalState(() {
                        nameError = null;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    AppStrings.habitCategoryEmojiLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final emoji in HabitCategoryFormOptions.emojiOptions)
                        ChoiceChip(
                          label: Text(emoji),
                          selected: selectedEmoji == emoji,
                          onSelected: (_) {
                            setModalState(() {
                              selectedEmoji = emoji;
                              emojiError = null;
                            });
                          },
                        ),
                    ],
                  ),
                  if (emojiError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      emojiError!,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    AppStrings.habitCategoryColorLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final token in HabitCategoryPalette.tokens)
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedColorToken = token;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: HabitCategoryPalette.resolveColor(token),
                              border: Border.all(
                                color: selectedColorToken == token
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppPrimaryButton(
                    label: AppStrings.save,
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        setModalState(() {
                          nameError = AppStrings.nameRequired;
                        });
                        return;
                      }
                      if (selectedEmoji.isEmpty) {
                        setModalState(() {
                          emojiError = AppStrings.habitEmojiRequired;
                        });
                        return;
                      }
                      Navigator.of(context).pop(true);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSecondaryButton(
                    label: AppStrings.cancel,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != true) {
      nameController.dispose();
      return;
    }

    try {
      await context.read<DataProvider>().addCategory(
            HabitCategory(
              id: category?.id ?? '',
              name: nameController.text.trim(),
              emoji: selectedEmoji,
              colorToken: selectedColorToken,
              createdAt: category?.createdAt,
              updatedAt: category?.updatedAt,
            ),
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.habitCategorySaveError)),
        );
      }
    } finally {
      nameController.dispose();
    }
  }

  Future<void> _confirmDelete(HabitCategory category) async {
    final theme = Theme.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.habitCategoryDeleteTitle),
          content: const Text(AppStrings.habitCategoryDeleteMessage),
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
              child: const Text(AppStrings.habitCategoryDeleteAction),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await context.read<DataProvider>().deleteCategory(category);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.habitCategoryDeleteError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.habitCategoryManageLabel),
      ),
      body: StreamBuilder<List<HabitCategory>>(
        stream: context.read<DataProvider>().watchCategories(),
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          final sortedCategories = [...categories]
            ..sort((a, b) => a.name.compareTo(b.name));
          if (sortedCategories.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.label_outline,
              title: AppStrings.habitCategoryEmptyTitle,
              description: AppStrings.habitCategoryEmptyMessage,
              actionLabel: AppStrings.habitCategoryCreateTitle,
              onAction: () => _openCategoryForm(),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.page),
            itemCount: sortedCategories.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final category = sortedCategories[index];
              return AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: HabitCategoryPalette.resolveColor(
                          category.colorToken,
                        ).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          category.emoji,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        category.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.habitEditAction,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openCategoryForm(category: category),
                    ),
                    IconButton(
                      tooltip: AppStrings.habitCategoryDeleteAction,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(category),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCategoryForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
