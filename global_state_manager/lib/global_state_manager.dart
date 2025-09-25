import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'counter.dart';
import 'dart:math';

class GlobalState extends ChangeNotifier {
  final List<Counter> _counters = [];

  List<Counter> get counters => List.unmodifiable(_counters);

  void addCounter() {
    _counters.add(
      Counter(
        color: _randomColor(),
        title: 'Counter ${_counters.length + 1}',
        id: UniqueKey().toString(),
        value: 0,
      ),
    );
    notifyListeners();
  }

  void removeCounterById(String id) {
    final index = _counters.indexWhere((counter) => counter.id == id);
    if (index != -1) {
      _counters.removeAt(index);
      notifyListeners();
    }
  }

  void incrementCounterById(String id) {
    final index = _counters.indexWhere((counter) => counter.id == id);
    if (index != -1) {
      _counters[index] = _counters[index].copyWith(value: _counters[index].value + 1);
      notifyListeners();
    }
  }

  void decrementCounterById(String id) {
    final index = _counters.indexWhere((counter) => counter.id == id);
    if (index != -1 && _counters[index].value > 0) {
      _counters[index] = _counters[index].copyWith(value: _counters[index].value - 1);
      notifyListeners();
    }
  }

  void updateCounterColorById(String id, Color color) {
    final index = _counters.indexWhere((counter) => counter.id == id);
    if (index != -1) {
      _counters[index] = _counters[index].copyWith(color: color);
      notifyListeners();
    }
  }

  void updateCounterTitleById(String id, String title) {
    final index = _counters.indexWhere((counter) => counter.id == id);
    if (index != -1) {
      _counters[index] = _counters[index].copyWith(title: title);
      notifyListeners();
    }
  }

  Color _randomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  void reorderCounter(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final counter = _counters.removeAt(oldIndex);
    _counters.insert(newIndex, counter);
    notifyListeners();
  }

  Counter? getCounterById(String id) {
    for (final c in _counters) {
      if (c.id == id) return c;
    }
    return null;
  }
}