import 'package:flutter/material.dart';

class SavedTimer {
  const SavedTimer({this.id, required this.name, required this.seconds});

  final int? id;
  final String name;
  final int seconds;

  SavedTimer copyWith({int? id, String? name, int? seconds}) {
    return SavedTimer(
      id: id ?? this.id,
      name: name ?? this.name,
      seconds: seconds ?? this.seconds,
    );
  }
}

class HistoryRecord {
  const HistoryRecord({
    this.id,
    required this.type,
    required this.label,
    required this.seconds,
    required this.date,
  });

  final int? id;
  final String type;
  final String label;
  final int seconds;
  final DateTime date;

  HistoryRecord copyWith({
    int? id,
    String? type,
    String? label,
    int? seconds,
    DateTime? date,
  }) {
    return HistoryRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      seconds: seconds ?? this.seconds,
      date: date ?? this.date,
    );
  }
}

class NavSpec {
  const NavSpec(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class AppPalette {
  const AppPalette({
    required this.name,
    required this.color,
    required this.tint,
    required this.softBorder,
  });

  final String name;
  final Color color;
  final Color tint;
  final Color softBorder;
}
