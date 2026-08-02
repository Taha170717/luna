import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chat_screen.dart';

class ChatHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat History'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color(0xFFFFA726)),
        titleTextStyle: TextStyle(
          color: Color(0xFFFFA726),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('chats')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFFFFA726)));
          }

          final chatDocs = snapshot.data!.docs;

          if (chatDocs.isEmpty) {
            return Center(child: Text('No chat history found.'));
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final chatId = chatDocs[index].id;
              final chatTitle = chatData['title'] ?? 'Chat ${index + 1}';
              final Timestamp createdAt = chatData['createdAt'] ?? Timestamp.now();
              final String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(createdAt.toDate());

              return Dismissible(
                key: Key(chatId),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white, size: 30),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  await _deleteChat(userId, chatId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chat deleted')),
                  );
                },
                child: ListTile(
                  title: Text(
                    chatTitle,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2, // Allow up to 2 lines
                    overflow: TextOverflow.ellipsis, // Show ... if it's still too long
                  ),
                  subtitle: Text('Created on: $formattedDate'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(chatId: chatId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteChat(String userId, String chatId) async {
    final chatRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId);

    // Delete all messages in this chat
    final messagesSnapshot = await chatRef.collection('messages').get();
    for (var doc in messagesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete the chat document itself
    await chatRef.delete();
  }
}
