import 'package:flutter/material.dart';

class LunaDrawer extends StatelessWidget {
  final VoidCallback onNewChat;

  const LunaDrawer({Key? key, required this.onNewChat}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFFFA726)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Luna 🐶', style: TextStyle(color: Colors.white, fontSize: 24)),
                SizedBox(height: 10),
                Text('Your Pet Health Assistant', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('New Chat'),
            onTap: onNewChat,
          ),
          // You can add more options here
        ],
      ),
    );
  }
}
