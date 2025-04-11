import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Box _conversationsBox = Hive.box('conversations');
  final TextEditingController _matchNameController = TextEditingController();

  @override
  void dispose() {
    _matchNameController.dispose();
    super.dispose();
  }

  void _createNewChat() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Chat'),
          content: TextField(
            controller: _matchNameController,
            decoration: const InputDecoration(
              hintText: 'Enter match name',
              labelText: 'Match Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _matchNameController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final matchName = _matchNameController.text.trim();
                if (matchName.isNotEmpty) {
                  final chatKey = DateTime.now().millisecondsSinceEpoch.toString();
                  _conversationsBox.put(chatKey, {
                    'matchName': matchName,
                    'messages': [],
                    'createdAt': DateTime.now().toIso8601String(),
                    'lastMessageAt': DateTime.now().toIso8601String(),
                  });
                  _matchNameController.clear();
                  Navigator.of(context).pop();
                  Navigator.pushNamed(
                    context,
                    '/conversation',
                    arguments: {'chatKey': chatKey, 'matchName': matchName},
                  );
                }
              },
              child: const Text('Start Chat'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Dating Assistant'),
        centerTitle: true,
        elevation: 2,
      ),
      body: ValueListenableBuilder(
        valueListenable: _conversationsBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start a new chat with a match',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _createNewChat,
                    icon: const Icon(Icons.add),
                    label: const Text('New Chat'),
                  ),
                ],
              ),
            );
          }

          final sortedKeys = box.keys.toList()
            ..sort((a, b) {
              final aData = box.get(a) as Map?;
              final bData = box.get(b) as Map?;
              if (aData == null || bData == null) return 0;
              final aTime = aData['lastMessageAt'] as String? ?? '';
              final bTime = bData['lastMessageAt'] as String? ?? '';
              return bTime.compareTo(aTime);
            });

          return ListView.builder(
            itemCount: sortedKeys.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final key = sortedKeys[index];
              final data = box.get(key) as Map?;
              if (data == null) return const SizedBox.shrink();

              final matchName = data['matchName'] as String? ?? 'Unknown Match';
              final messages = List.from(data['messages'] ?? []);
              String lastMessage = '';
              
              if (messages.isNotEmpty) {
                final lastMsg = messages.last as Map?;
                if (lastMsg != null) {
                  lastMessage = lastMsg['content']?.toString() ?? '';
                }
              }
              
              return Dismissible(
                key: Key(key.toString()),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => box.delete(key),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      matchName.isNotEmpty ? matchName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(
                    matchName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: lastMessage.isNotEmpty
                      ? Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : const Text(
                          'No messages yet',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/conversation',
                      arguments: {
                        'chatKey': key,
                        'matchName': matchName,
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewChat,
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
      ),
    );
  }
}