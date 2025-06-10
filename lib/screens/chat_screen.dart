import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:luna/widgets/drawer_widget.dart';
import 'package:luna/widgets/message_bubble.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/message.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> messages = [
    Message(sender: 'Luna', text: 'How can I help you today? 🐱'),
  ];

  File? _selectedImage;
  bool _loading = false;

  final FocusNode _focusNode = FocusNode();

  // Speech recognition
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _resetChat() {
    setState(() {
      messages.clear();
      messages.add(Message(sender: 'Luna', text: 'How can I help you today? 🐱'));
      _selectedImage = null;
      _spokenText = '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _selectedImage = File(img.path));
  }

  Future<void> _sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    setState(() {
      messages.add(Message(sender: 'User', text: userText));
      _loading = true;
    });

    String? base64Image;
    if (_selectedImage != null) {
      base64Image = base64Encode(await _selectedImage!.readAsBytes());
    }

    final body = {
      "model": "meta-llama/llama-4-scout-17b-16e-instruct",
      "messages": [
        {"role": "system", "content": "You are Luna, an expert animal health assistant."},
        if (base64Image != null)
          {
            "role": "user",
            "content": [
              {
                "type": "image_url",
                "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
              },
              {"type": "text", "text": userText}
            ]
          }
        else
          {"role": "user", "content": userText}
      ],
      "temperature": 0.7,
      "max_tokens": 1024
    };

    try {
      final resp = await http.post(
        Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['GROQ_API_KEY']}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(resp.body);
      final response = data['choices'][0]['message']['content'] as String;

      setState(() {
        messages.add(Message(sender: 'Luna', text: response));
      });
    } catch (e) {
      setState(() {
        messages.add(Message(sender: 'Luna', text: 'Sorry, something went wrong: $e'));
      });
    } finally {
      setState(() {
        _loading = false;
        _selectedImage = null;
        _spokenText = '';
      });
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (val) => setState(() => _isListening = false),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _spokenText = val.recognizedWords;
        }),
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: LunaDrawer(onNewChat: _resetChat),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFFFFA726)),
        title: const Text('Luna 🐶', style: TextStyle(color: Color(0xFFFFA726))),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  reverse: true,
                  itemCount: messages.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == messages.length) {
                      return Column(
                        children: [
                          const SizedBox(height: 30),
                          const Text(
                            'Welcome to Luna 🐶',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFA726),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ask me anything about your pet’s health!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      );
                    } else {
                      return ChatBubble(message: messages[messages.length - 1 - i]);
                    }
                  },
                ),
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_selectedImage!, height: 160),
                  ),
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(color: Color(0xFFFFA726)),
                ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image, color: Color(0xFFFFA726)),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : Color(0xFFFFA726),
                    ),
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                  Expanded(
                    child: MessageInput(
                      onSend: _sendMessage,
                      onImagePick: _pickImage,
                      focusNode: _focusNode,
                      initialText: _spokenText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
