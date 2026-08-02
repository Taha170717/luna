import 'package:flutter/material.dart';
import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onSpeak;

  const ChatBubble({Key? key, required this.message, this.onSpeak}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == 'User';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        // Luna's Avatar
        if (!isUser)
          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/lunalogo.png'),
          ),
        if (!isUser) const SizedBox(width: 8),

        // Chat Bubble with Speak Button for Luna
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFFFFA726) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
                if (!isUser && onSpeak != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.volume_up, color: Color(0xFFFFA726)),
                      onPressed: onSpeak,
                      tooltip: 'Listen',
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (isUser) const SizedBox(width: 8),
        // User Avatar
        if (isUser)
          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/user.png'),
          ),
      ],
    );
  }
}
