import '../../models/habit_category.dart';
import 'habit_category_palette.dart';

List<HabitCategory> buildDefaultHabitCategories({DateTime? now}) {
  final timestamp = now ?? DateTime.now();
  return [
    HabitCategory(
      id: 'habit-category-education',
      name: 'Educação',
      emoji: '📚',
      colorToken: HabitCategoryPalette.secondary,
      createdAt: timestamp,
      updatedAt: timestamp,
    ),
    HabitCategory(
      id: 'habit-category-health',
      name: 'Saúde',
      emoji: '💪',
      colorToken: HabitCategoryPalette.primary,
      createdAt: timestamp,
      updatedAt: timestamp,
    ),
    HabitCategory(
      id: 'habit-category-work',
      name: 'Trabalho',
      emoji: '💼',
      colorToken: HabitCategoryPalette.accent,
      createdAt: timestamp,
      updatedAt: timestamp,
    ),
    HabitCategory(
      id: 'habit-category-home',
      name: 'Casa',
      emoji: '🏠',
      colorToken: HabitCategoryPalette.secondary,
      createdAt: timestamp,
      updatedAt: timestamp,
    ),
    HabitCategory(
      id: 'habit-category-wellness',
      name: 'Bem-estar',
      emoji: '🌿',
      colorToken: HabitCategoryPalette.primary,
      createdAt: timestamp,
      updatedAt: timestamp,
    ),
    HabitCategory(
      id: 'habit-category-finance',
      name: 'Finanças',
      emoji: '💰',
      colorToken: HabitCategoryPalette.accent,
      createdAt: timestamp,
      updatedAt: timestamp,
    ),
  ];
}
