import 'package:flutter/material.dart';

class ExpenseCategory {
  final String name;
  final IconData icon;
  final Color color;
  final String emoji;

  const ExpenseCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.emoji,
  });
}

class AppCategories {
  static const List<ExpenseCategory> categories = [
    ExpenseCategory(
      name: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF6B6B),
      emoji: '🍽️',
    ),
    ExpenseCategory(
      name: 'Transport',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF4ECDC4),
      emoji: '🚘',
    ),
    ExpenseCategory(
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFFFBE0B),
      emoji: '🛒',
    ),
    ExpenseCategory(
      name: 'Entertainment',
      icon: Icons.movie_rounded,
      color: Color(0xFFA855F7),
      emoji: '🎭',
    ),
    ExpenseCategory(
      name: 'Health',
      icon: Icons.favorite_rounded,
      color: Color(0xFFEC4899),
      emoji: '⚕️',
    ),
    ExpenseCategory(
      name: 'Education',
      icon: Icons.school_rounded,
      color: Color(0xFF3B82F6),
      emoji: '🎓',
    ),
    ExpenseCategory(
      name: 'Bills & Utilities',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF06B6D4),
      emoji: '⚡',
    ),
    ExpenseCategory(
      name: 'Groceries',
      icon: Icons.local_grocery_store_rounded,
      color: Color(0xFF10B981),
      emoji: '🧾',
    ),
    ExpenseCategory(
      name: 'Travel',
      icon: Icons.flight_rounded,
      color: Color(0xFFF59E0B),
      emoji: '🌍',
    ),
    ExpenseCategory(
      name: 'Personal Care',
      icon: Icons.spa_rounded,
      color: Color(0xFFD946EF),
      emoji: '✨',
    ),
    ExpenseCategory(
      name: 'Gifts',
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFEF4444),
      emoji: '🎗️',
    ),
    ExpenseCategory(
      name: 'Rent',
      icon: Icons.home_rounded,
      color: Color(0xFF8B5CF6),
      emoji: '🏛️',
    ),
    ExpenseCategory(
      name: 'Insurance',
      icon: Icons.security_rounded,
      color: Color(0xFF059669),
      emoji: '🛡️',
    ),
    ExpenseCategory(
      name: 'Subscriptions',
      icon: Icons.subscriptions_rounded,
      color: Color(0xFFE11D48),
      emoji: '🔔',
    ),
    ExpenseCategory(
      name: 'Fitness',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFF0891B2),
      emoji: '🏋️',
    ),
    ExpenseCategory(
      name: 'Pets',
      icon: Icons.pets_rounded,
      color: Color(0xFFD97706),
      emoji: '🐾',
    ),
    ExpenseCategory(
      name: 'Other',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF6B7280),
      emoji: '📎',
    ),
  ];

  // Income categories
  static const List<ExpenseCategory> incomeCategories = [
    ExpenseCategory(
      name: 'Salary',
      icon: Icons.work_rounded,
      color: Color(0xFF10B981),
      emoji: '💼',
    ),
    ExpenseCategory(
      name: 'Freelance',
      icon: Icons.laptop_mac_rounded,
      color: Color(0xFF3B82F6),
      emoji: '⌨️',
    ),
    ExpenseCategory(
      name: 'Business',
      icon: Icons.business_center_rounded,
      color: Color(0xFF8B5CF6),
      emoji: '🏦',
    ),
    ExpenseCategory(
      name: 'Investment',
      icon: Icons.trending_up_rounded,
      color: Color(0xFFF59E0B),
      emoji: '📊',
    ),
    ExpenseCategory(
      name: 'Rental Income',
      icon: Icons.house_rounded,
      color: Color(0xFF06B6D4),
      emoji: '🔑',
    ),
    ExpenseCategory(
      name: 'Gift Received',
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFEC4899),
      emoji: '🎗️',
    ),
    ExpenseCategory(
      name: 'Refund',
      icon: Icons.replay_rounded,
      color: Color(0xFF4ECDC4),
      emoji: '↩️',
    ),
    ExpenseCategory(
      name: 'Side Hustle',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFFFF6B6B),
      emoji: '⚡',
    ),
    ExpenseCategory(
      name: 'Other Income',
      icon: Icons.attach_money_rounded,
      color: Color(0xFF059669),
      emoji: '💎',
    ),
  ];

  static ExpenseCategory getByName(String name) {
    // Search expense categories first
    final expMatch = categories.where((c) => c.name == name);
    if (expMatch.isNotEmpty) return expMatch.first;
    // Then search income categories
    final incMatch = incomeCategories.where((c) => c.name == name);
    if (incMatch.isNotEmpty) return incMatch.first;
    return categories.last;
  }
}
