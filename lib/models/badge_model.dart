import 'package:flutter/material.dart';

class AppBadge {
  final String id;
  final String name;
  final String description; // shown when earned
  final String howToEarn;   // shown when locked
  final String emoji;
  final String series;
  final Color seriesColor;
  final Color seriesColorDark;
  final int points;

  /// Year this badge was introduced. Shown as a "NEW" chip in the badges
  /// screen during that year so returning users can spot what's new.
  final int sinceYear;

  const AppBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.howToEarn,
    required this.emoji,
    required this.series,
    required this.seriesColor,
    required this.seriesColorDark,
    required this.points,
    this.sinceYear = 2026,
  });
}
