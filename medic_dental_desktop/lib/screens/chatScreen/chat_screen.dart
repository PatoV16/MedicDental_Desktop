import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = []; // {"role": "user"/"bot", "text": "..."}

  bool _isSending = false;

  Future<void> _sendMessage(String text) async {
    setState(() {
      _messages.add({"role": "user", "text": text});
      _isSending = true;
    });
    _controller.clear();

    final response = await _askChatGPT(text);

    setState(() {
      _messages.add({"role": "bot", "text": response});
      _isSending = false;
    });
  }

Future<String> _askChatGPT(String message) async {
  const apiKey = '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';
  const url = 'https://api.openai.com/v1/chat/completions';

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  final body = json.encode({
    "model": "gpt-3.5-turbo",
    "messages": [
      {"role": "system", "content": "Eres un asistente experto en odontología que responde consultas técnicas de dentistas."},
      {"role": "user", "content": message}
    ],
    "max_tokens": 300,
  });

  final res = await http.post(Uri.parse(url), headers: headers, body: body);
  if (res.statusCode == 200) {
    final data = json.decode(res.body);
    return data['choices'][0]['message']['content'];
  } else {
    // Mostrar el error exacto para depurar
    print('Código de estado: ${res.statusCode}');
    print('Respuesta del servidor: ${res.body}');
    return 'Error consultando al asistente.';
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Asistente Dental")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text'] ?? ""),
                  ),
                );
              },
            ),
          ),
          if (_isSending) const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _sendMessage,
                    decoration: const InputDecoration(
                      hintText: "Escribe tu consulta dental...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isSending ? null : () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
