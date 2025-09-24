import 'package:flutter/material.dart';

class Counter {
  final int value;
  final Color color;
  final String title;
  final String id;

  Counter({required this.id, required this.value, required this.color, required this.title});

  Counter copyWith({int? value, Color? color, String? title}) {
    return Counter(
      id: id,
      value: value ?? this.value,
      color: color ?? this.color,
      title: title ?? this.title,
    );
  }
}
