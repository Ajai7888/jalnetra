// lib/screens/public_user/kubo_chat_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';

class KuboChatScreen extends StatefulWidget {
  const KuboChatScreen({super.key});

  @override
  State<KuboChatScreen> createState() => _KuboChatScreenState();
}

class _KuboChatScreenState extends State<KuboChatScreen> {
  final String apiUrl = "https://ericjeevan-chatbot-space.hf.space/chat";

  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  bool _isLoading = false;
  bool _isListening = false;

  late stt.SpeechToText _speech;
  final translator = GoogleTranslator();
  final FlutterTts flutterTts = FlutterTts();

  String selectedLanguage = "English"; // Dropdown language

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _controller.dispose();
    flutterTts.stop();
    super.dispose();
  }

  // Speech output
  Future _speak(String text) async {
    if (selectedLanguage == "Tamil") {
      await flutterTts.setLanguage("ta-IN");
    } else {
      await flutterTts.setLanguage("en-US");
    }

    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  // Tamil speech → English text (input)
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint("Status: $val"),
        onError: (val) => debugPrint("Error: $val"),
      );

      if (available) {
        setState(() => _isListening = true);

        _speech.listen(
          localeId: "ta-IN",
          onResult: (val) async {
            String tamilText = val.recognizedWords;

            if (tamilText.isNotEmpty) {
              var translation = await translator.translate(tamilText, to: "en");

              setState(() {
                _controller.text = translation.text;
              });
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Universal response parser
  String _extractReply(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is List && decoded.isNotEmpty) {
        return decoded.first.toString();
      }
      if (decoded is Map && decoded.isNotEmpty) {
        return decoded.values.first.toString();
      }
      return responseBody;
    } catch (_) {
      return responseBody;
    }
  }

  // Send message to API
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
    });

    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": text}),
      );

      if (response.statusCode == 200) {
        String botReply = _extractReply(response.body);

        if (selectedLanguage == "Tamil") {
          var translated = await translator.translate(botReply, to: "ta");
          botReply = translated.text;
        }

        setState(() {
          _messages.add({"role": "bot", "text": botReply});
        });

        _speak(botReply);
      } else {
        setState(() {
          _messages.add({
            "role": "bot",
            "text": "Server error: ${response.statusCode}",
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "bot", "text": "Connection failed: $e"});
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔥 App bar changed to BLACK
      appBar: AppBar(
        title: const Text(
          "Chat AI 🤖",
          style: TextStyle(
            color: Colors.white, // Title text white on black
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black, // Black app bar
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          DropdownButton<String>(
            value: selectedLanguage,
            dropdownColor: Colors.black, // Black dropdown background
            style: const TextStyle(color: Colors.white, fontSize: 16),
            icon: const Icon(Icons.language, color: Colors.white),
            items: <String>["English", "Tamil"].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedLanguage = value!;
              });
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // Chat list
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg["role"] == "user";

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blueAccent : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        msg["text"]!,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),

          // Input row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Mic button
                CircleAvatar(
                  backgroundColor: Colors.black87,
                  child: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    ),
                    onPressed: _listen,
                  ),
                ),
                const SizedBox(width: 10),

                // Text field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask Chat AI...",
                      hintStyle: const TextStyle(
                        color: Colors.black87, // 🔥 Hint text now black
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                CircleAvatar(
                  backgroundColor: Colors.black87,
                  child: IconButton(
                    onPressed: () => sendMessage(_controller.text),
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
