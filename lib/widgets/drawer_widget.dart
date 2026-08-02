import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/chat_history_screen.dart';
import '../screens/loginscreen.dart';

class LunaDrawer extends StatelessWidget {
  final VoidCallback onNewChat;

  const LunaDrawer({Key? key, required this.onNewChat}) : super(key: key);

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

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
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Chat History'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatHistoryScreen()));
            },
          ),
        ],
      ),
    );
  }
}
