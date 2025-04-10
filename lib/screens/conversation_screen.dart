import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:flutter/services.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _conversation = [];
  bool _loading = false;

  Future<void> _getAiResponse(String message) async {
    setState(() {
      _loading = true;
    });

    const apiKey = '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'; // Replace with your real key
    const endpoint = 'https://openrouter.ai/api/v1/chat/completions';

    final body = {
      "model": "meta-llama/llama-4-maverick",
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
    };

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final reply = decoded['choices'][0]['message']['content'];

        setState(() {
          _conversation.add({"user": message, "bot": reply});
        });

        final box = Hive.box('conversations');
        box.add({
          'message': message,
          'reply': reply,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        setState(() {
          _conversation.add({"user": message, "bot": 'Error: ${response.statusCode}'});
        });
      }
    } catch (e) {
      setState(() {
        _conversation.add({"user": message, "bot": 'Failed to connect: $e'});
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suggest a Reply')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _conversation.length,
                itemBuilder: (context, index) {
                  final chat = _conversation[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text("You: ${chat["user"]}"),
                      ),
                      GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: chat["bot"] ?? ""));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("AI reply copied to clipboard")),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.pink[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("AI: ${chat["bot"]}"),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Paste their message',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () {
                      final message = _controller.text.trim();
                      if (message.isNotEmpty) {
                        _getAiResponse(message);
                      }
                    },
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Get AI Reply'),
            ),
          ],
        ),
      ),
    );
  }
}