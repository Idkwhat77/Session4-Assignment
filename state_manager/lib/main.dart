// lib/main.dart
/// A Flutter counter application demonstrating global state management.
///
/// This app showcases the use of Provider for state management, allowing
/// users to create, modify, reorder, and delete multiple counters with
/// customizable colors and titles.
///
/// Run with: flutter pub get && flutter run

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:global_state_manager/global_state_manager.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// Application entry point.
void main() {
  runApp(const MyEphemeralApp());
}

/// Root application widget that provides [GlobalState] to descendant widgets.
///
/// This widget sets up the Provider pattern for state management and
/// configures the MaterialApp with the counter list as the home page.
class MyEphemeralApp extends StatelessWidget {
  /// Creates the root application widget.
  const MyEphemeralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GlobalState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const CounterListPage(),
      ),
    );
  }
}

/// Main page displaying a reorderable list of counters with add functionality.
///
/// This page allows users to:
/// - View all counters in a scrollable, reorderable list
/// - Add new counters using the floating action button
/// - Reorder counters by dragging and dropping
class CounterListPage extends StatelessWidget {
  /// Creates a counter list page.
  const CounterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final counters = context.watch<GlobalState>().counters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counters counters counters'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              itemCount: counters.length,
              onReorder: (oldIndex, newIndex) =>
                  context.read<GlobalState>().reorderCounter(oldIndex, newIndex),
              itemBuilder: (context, index) {
                final counter = counters[index];
                return CounterTile(
                  key: ValueKey(counter.id),
                  counterId: counter.id,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () => context.read<GlobalState>().addCounter(),
              icon: const Icon(Icons.add),
              label: const Text('Add Counter'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual counter tile with increment/decrement, color picker, and delete.
///
/// This widget demonstrates performance optimization using [Provider.select()]
/// to rebuild only when this specific counter's properties change, rather than
/// when any counter in the global list changes.
///
/// Features:
/// - Editable title with text field
/// - Increment/decrement buttons
/// - Color picker for background customization  
/// - Delete functionality
/// - Animated value transitions
class CounterTile extends StatefulWidget {
  /// Creates a counter tile for the given [counterId].
  ///
  /// The [counterId] must match an existing counter in the global state.
  const CounterTile({
    super.key,
    required this.counterId,
  });

  /// Unique identifier for the counter this tile represents.
  final String counterId;

  @override
  State<CounterTile> createState() => _CounterTileState();
}

class _CounterTileState extends State<CounterTile> {
  /// Controller for the editable title text field.
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final title = context
        .read<GlobalState>()
        .counters
        .firstWhere((c) => c.id == widget.counterId)
        .title;
    _controller = TextEditingController(text: title);
  }

  @override
  void didUpdateWidget(covariant CounterTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync controller if title changed elsewhere in the app
    final title = context
        .read<GlobalState>()
        .counters
        .firstWhere((c) => c.id == widget.counterId)
        .title;
    if (_controller.text != title) {
      _controller.text = title;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Shows a color picker dialog and updates the counter's color.
  ///
  /// Displays a [BlockPicker] in an [AlertDialog] with cancel and select
  /// options. If a color is selected, updates the counter's color in global state.
  ///
  /// Parameters:
  /// - [ctx]: Build context for showing the dialog
  /// - [current]: Currently selected color to show as default
  Future<void> _pickColor(BuildContext ctx, Color current) async {
    Color temp = current;
    final picked = await showDialog<Color?>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Pick color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: current,
            onColorChanged: (c) => temp = c,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(temp),
            child: const Text('Select'),
          ),
        ],
      ),
    );
    
    if (picked != null) {
      context
          .read<GlobalState>()
          .updateCounterColorById(widget.counterId, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Provider.select() for performance - only rebuild when specific
    // counter properties change, not when any counter changes
    final title = context.select<GlobalState, String?>(
      (s) => s.getCounterById(widget.counterId)?.title,
    );
    final value = context.select<GlobalState, int?>(
      (s) => s.getCounterById(widget.counterId)?.value,
    );
    final color = context.select<GlobalState, Color?>(
      (s) => s.getCounterById(widget.counterId)?.color,
    );

    // Handle case where counter was deleted
    if (title == null || value == null || color == null) {
      return const SizedBox.shrink();
    }

    // Sync controller if title changed elsewhere
    if (_controller.text != title) {
      _controller.text = title;
    }

    return ListTile(
      key: ValueKey(widget.counterId),
      tileColor: color.withValues(alpha: 0.2),
      title: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(border: InputBorder.none),
              onSubmitted: (v) => context
                  .read<GlobalState>()
                  .updateCounterTitleById(widget.counterId, v),
            ),
          ),
          const SizedBox(width: 12),
          // Animated counter value with scale transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              '$value',
              key: ValueKey(value),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.remove),
        onPressed: () => context
            .read<GlobalState>()
            .decrementCounterById(widget.counterId),
        tooltip: 'Decrement counter',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: () => _pickColor(context, color),
            tooltip: 'Change color',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context
                .read<GlobalState>()
                .incrementCounterById(widget.counterId),
            tooltip: 'Increment counter',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => context
                .read<GlobalState>()
                .removeCounterById(widget.counterId),
            tooltip: 'Delete counter',
          ),
        ],
      ),
    );
  }
}

/// Simple counter widget demonstrating local state management.
///
/// This widget is included for comparison with the global state approach
/// used in the main application. It uses [setState] for local state management.
///
/// **Note:** This widget is not currently used in the app's widget tree.
class CounterWidget extends StatefulWidget {
  /// Creates a simple counter widget with local state.
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  /// Current counter value stored in local widget state.
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Counter Value: $_counter'),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _counter++;
              });
            },
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}