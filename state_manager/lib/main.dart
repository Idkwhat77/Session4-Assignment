import 'package:flutter/material.dart'; 
import 'package:provider/provider.dart';
import 'package:global_state_manager/global_state_manager.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const MyEphemeralApp());
}

class MyEphemeralApp extends StatelessWidget {
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

class CounterListPage extends StatelessWidget {
  const CounterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // watch the list snapshot only (tiles individually select their fields)
    final counters = context.watch<GlobalState>().counters;

    return Scaffold(
      appBar: AppBar(title: const Text('Counters counters counters')),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              itemCount: counters.length,
              onReorder: (oldIndex, newIndex) => context.read<GlobalState>().reorderCounter(oldIndex, newIndex),
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
          )
        ],
      ),
    );
  }
}

class CounterTile extends StatefulWidget {
  final String counterId;
  const CounterTile({super.key, required this.counterId});

  @override
  State<CounterTile> createState() => _CounterTileState();
}

class _CounterTileState extends State<CounterTile> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // initialize controller with current title from state (read, not watch)
    final title = context.read<GlobalState>().counters.firstWhere((c) => c.id == widget.counterId).title;
    _controller = TextEditingController(text: title);
  }

  @override
  void didUpdateWidget(covariant CounterTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if title changed elsewhere, sync controller
    final title = context.read<GlobalState>().counters.firstWhere((c) => c.id == widget.counterId).title;
    if (_controller.text != title) _controller.text = title;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(temp), child: const Text('Select')),
        ],
      ),
    );
    if (picked != null) context.read<GlobalState>().updateCounterColorById(widget.counterId, picked);
  }

  @override
  Widget build(BuildContext context) {

    final title = context.select<GlobalState, String?>(
      (s) => s.getCounterById(widget.counterId)?.title,
    );
    final value = context.select<GlobalState, int?>(
      (s) => s.getCounterById(widget.counterId)?.value,
    );
    final color = context.select<GlobalState, Color?>(
      (s) => s.getCounterById(widget.counterId)?.color,
    );

    if (title == null || value == null || color == null) return const SizedBox.shrink();

    // sync controller text if changed externally
    if (_controller.text != title) _controller.text = title;

    return ListTile(
      key: ValueKey(widget.counterId),
      tileColor: color.withValues(alpha: 0.2),
      title: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(border: InputBorder.none),
              onSubmitted: (v) => context.read<GlobalState>().updateCounterTitleById(widget.counterId, v),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Text(
              '$value',
              key: ValueKey(value),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.remove),
        onPressed: () => context.read<GlobalState>().decrementCounterById(widget.counterId),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.color_lens), onPressed: () => _pickColor(context, color)),
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.read<GlobalState>().incrementCounterById(widget.counterId)),
          IconButton(icon: const Icon(Icons.delete), onPressed: () => context.read<GlobalState>().removeCounterById(widget.counterId)),
        ],
      ),
    );
  }
}

// Not used, just for comparison
class CounterWidget extends StatefulWidget {
  
  const CounterWidget({super.key});

  @override 
  _CounterWidgetState createState() => _CounterWidgetState(); 

} 

class _CounterWidgetState extends State<CounterWidget> { 
  
  int _counter = 0; 
  
  @override 
  Widget build(BuildContext context) { 
    return Center( 
      child: Column( 
        mainAxisAlignment: MainAxisAlignment.center, 
        children: <Widget>[ 
          Text('Counter Value: $_counter'), 
          SizedBox(height: 10), 
          ElevatedButton( 
            onPressed: () { 
              setState(() { _counter++; }); 
            }, 
            child: const Text('Increment'), 
          ), 
        ], 
      ), 
    ); 
  } 
}