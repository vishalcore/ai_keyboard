import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final Box _conversationsBox = Hive.box('conversations');
  final ScrollController _scrollController = ScrollController();
  
  String? _currentChatKey;
  String? _matchName;
  String? _lastUserMessage;
  bool _isGenerating = false;
  List<String> _currentSuggestions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _currentChatKey = args['chatKey'];
        _matchName = args['matchName'];
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generateResponses(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _lastUserMessage = message;
      _currentSuggestions = [];
    });

    const apiKey = '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';
    const endpoint = 'https://openrouter.ai/api/v1/chat/completions';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "model": "meta-llama/llama-4-maverick",
          "n": 3,
          "messages": [
            {
              "role": "system",
              "content": "You are a witty, funny, and flirty dating assistant. Craft charming, playful, and humorous replies to help users keep the conversation engaging and light-hearted."
            },
            {
              "role": "user",
              "content": message
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final replies = List<String>.from(
          decoded['choices'].map((c) => c['message']['content']),
        );

        setState(() {
          _currentSuggestions = replies;
          _isGenerating = false;
        });

        // Only save the message if it's not a regeneration request
        if (_currentChatKey != null && message == _messageController.text.trim()) {
          final chatData = _conversationsBox.get(_currentChatKey);
          if (chatData != null) {
            final messages = List.from(chatData['messages'] ?? []);
            messages.add({
              'content': message,
              'timestamp': DateTime.now().toIso8601String(),
              'isUser': true,
            });
            
            await _conversationsBox.put(_currentChatKey, {
              ...chatData,
              'messages': messages,
              'lastMessageAt': DateTime.now().toIso8601String(),
            });
          }
        }

        _scrollToBottom();
      } else {
        _showError('Failed to generate responses. Please try again.');
      }
    } catch (e) {
      _showError('An error occurred. Please check your internet connection.');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Response copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_matchName ?? 'Chat'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _conversationsBox.listenable(),
              builder: (context, Box box, _) {
                if (_currentChatKey == null) {
                  return const Center(child: Text('No chat selected'));
                }

                final chatData = box.get(_currentChatKey);
                if (chatData == null) {
                  return const Center(child: Text('Chat not found'));
                }

                final messages = List.from(chatData['messages'] ?? []);

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (_currentSuggestions.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < messages.length) {
                      final message = messages[index];
                      return _MessageBubble(
                        content: message['content'],
                        isUser: message['isUser'],
                        onTap: message['isUser'] ? null : () => _copyToClipboard(message['content']),
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Suggested Responses:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          ..._currentSuggestions.map((suggestion) => _SuggestionBubble(
                            content: suggestion,
                            onTap: () => _copyToClipboard(suggestion),
                          )),
                          if (_lastUserMessage != null) TextButton.icon(
                            onPressed: _isGenerating
                                ? null
                                : () => _generateResponses(_lastUserMessage!),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Generate New Responses'),
                          ),
                        ],
                      );
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Paste message here...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isGenerating
                      ? null
                      : () {
                          final message = _messageController.text.trim();
                          if (message.isNotEmpty) {
                            _generateResponses(message);
                            _messageController.clear();
                          }
                        },
                  child: _isGenerating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final VoidCallback? onTap;

  const _MessageBubble({
    required this.content,
    required this.isUser,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Material(
          color: isUser 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isUser 
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionBubble extends StatelessWidget {
  final String content;
  final VoidCallback onTap;

  const _SuggestionBubble({
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(content),
              ),
              const Icon(
                Icons.copy,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}