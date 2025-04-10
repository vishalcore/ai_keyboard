import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Box _conversationsBox = Hive.box('conversations');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Dating Assistant'),
      ),
      body: ValueListenableBuilder(
        valueListenable: _conversationsBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text("No conversations yet. Start one!"),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final key = box.keyAt(index);
              final value = box.get(key);
              return ListTile(
                title: Text(value['message'] ?? ''),
                subtitle: Text(value['reply'] ?? ''),
                onTap: () {
                  // (Optional) Load into conversation screen later
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/conversation');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}