import 'package:flutter/material.dart';

/// Maps a seed doc/notif glyph name to a Material icon.
IconData docIcon(String name) => switch (name) {
  'shield' => Icons.shield,
  'sparkle' => Icons.auto_awesome,
  'heart' => Icons.favorite,
  'flag' => Icons.flag,
  'book' => Icons.menu_book,
  'trophy' => Icons.emoji_events,
  'bell' => Icons.notifications_none,
  _ => Icons.description,
};
