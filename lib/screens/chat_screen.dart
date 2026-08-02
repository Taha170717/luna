import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:luna/widgets/drawer_widget.dart';
import 'package:luna/widgets/message_bubble.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/message.dart';
import '../widgets/message_input.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;

  const ChatScreen({Key? key, this.chatId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}


class _ChatScreenState extends State<ChatScreen> {
  final List<Message> messages = [
    Message(sender: 'Luna', text: 'How can I help you today? 🐱'),
  ];

  File? _selectedImage;
  final FlutterTts _flutterTts = FlutterTts();

  bool _loading = false;
  final FocusNode _focusNode = FocusNode();
  String? _currentChatId;
  String? _currentChatTitle;
  final user = FirebaseAuth.instance.currentUser;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    if (widget.chatId != null) {
      _currentChatId = widget.chatId;
      _loadChatHistory();
    } else {
      _startNewChat();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }
  void _loadChatHistory() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('chats')
        .doc(_currentChatId)
        .collection('messages')
        .orderBy('timestamp')
        .get();

    final loadedMessages = snapshot.docs.map((doc) {
      final data = doc.data();
      return Message(sender: data['sender'], text: data['text']);
    }).toList();

    setState(() {
      messages.addAll(loadedMessages);
    });
  }



  void _startNewChat() async {
    _currentChatId = null; // Reset the chat to allow a new one
    _currentChatTitle = null;
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

  String generateChatTitle(String userInput) {
    if (userInput.trim().isEmpty) return "Chat with Luna";

    // Limit the title to a max of 100 characters for Firebase safety
    String cleanedInput = userInput.trim();
    if (cleanedInput.length > 100) {
      cleanedInput = cleanedInput.substring(0, 100) + '...';
    }

    return cleanedInput;
  }


  Future<void> _sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    setState(() {
      messages.add(Message(sender: 'User', text: userText));
      _loading = true;
    });

    if (_currentChatId == null) {
      String title = generateChatTitle(userText);
      _currentChatId = Uuid().v4();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('chats')
          .doc(_currentChatId)
          .set({
        'createdAt': Timestamp.now(),
        'title': title,
      });
    }


    await _saveMessageToFirestore('User', userText);

    print('🔑 GROQ_API_KEY = ${dotenv.env['GROQ_API_KEY']}');

    String? base64Image;
    if (_selectedImage != null) {
      base64Image = await _selectedImage!.readAsBytes().then(base64Encode);
    }

    final body = {
      "model": "meta-llama/llama-4-scout-17b-16e-instruct",
      "messages": [
        {
          "role": "system",
          "content": "You are Luna, an expert animal health assistant."
        },
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
      debugPrint('➡️ Sending body: $body');
      final resp = await http.post(
        Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['GROQ_API_KEY']}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('⬅️ Response status: ${resp.statusCode}');
      debugPrint('⬅️ Response body: ${resp.body}');

      final data = jsonDecode(resp.body);
      final choices = data['choices'];

      if (choices is List && choices.isNotEmpty) {
        final first = choices[0];
        final message = first['message'];
        final responseText = message is Map ? message['content'] : null;

        if (responseText is String) {
          setState(() {
            messages.add(Message(sender: 'Luna', text: responseText));
          });

          await _saveMessageToFirestore('Luna', responseText);
        } else {
          throw Exception('Invalid content structure in response');
        }
      } else {
        throw Exception('No "choices" returned from API');
      }
    } catch (e) {
      debugPrint('🚨 Chat error: $e');
      final errorMessage = 'Sorry, something went wrong: $e';

      setState(() {
        messages.add(Message(sender: 'Luna', text: errorMessage));
      });

      await _saveMessageToFirestore('Luna', errorMessage);
    } finally {
      setState(() {
        _loading = false;
        _selectedImage = null;
        _spokenText = '';
      });
    }
  }

  Future<void> _saveMessageToFirestore(String sender, String text) async {
    if (_currentChatId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('chats')
        .doc(_currentChatId)
        .collection('messages')
        .add({
      'sender': sender,
      'text': text,
      'timestamp': Timestamp.now(),
    });
  }
  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1);
    await _flutterTts.speak(text);
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _selectedImage = File(img.path));
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
      drawer: LunaDrawer(onNewChat: _startNewChat),
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
                        children: const [
                          SizedBox(height: 30),
                          Text(
                            'Welcome to Luna 🐶',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFA726),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ask me anything about your pet’s health!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 30),
                        ],
                      );
                    } else {
                      return ChatBubble(
                        message: messages[messages.length - 1 - i],
                        onSpeak: messages[messages.length - 1 - i].sender == 'Luna'
                            ? () => _speak(messages[messages.length - 1 - i].text)
                            : null,
                      );
                      ;
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
                    icon: const Icon(Icons.image, color: Color(0xFFFFA726)),
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
