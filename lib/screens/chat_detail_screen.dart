import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';

class ChatDetailScreen extends StatelessWidget {
  final String chatId;

  ChatDetailScreen({required this.chatId});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Chat Details')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final messageDocs = snapshot.data!.docs;

          if (messageDocs.isEmpty) {
            return Center(child: Text('No messages in this chat.'));
          }

          final messages = messageDocs.map((doc) {
            return Message(
              sender: doc['sender'],
              text: doc['text'],
            );
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return ChatBubble(message: messages[index]);
            },
          );
        },
      ),
    );
  }
}
