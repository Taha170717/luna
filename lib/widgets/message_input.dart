import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final void Function(String) onSend;
  final void Function() onImagePick;
  final FocusNode focusNode;
  final String? initialText; // New: Accept initial text

  const MessageInput({
    Key? key,
    required this.onSend,
    required this.onImagePick,
    required this.focusNode,
    this.initialText, // New
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void didUpdateWidget(covariant MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When initialText changes (from speech), update the controller
    if (widget.initialText != null && widget.initialText != _controller.text) {
      _controller.text = widget.initialText!;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  void _submit() {
    final enteredText = _controller.text.trim();
    if (enteredText.isEmpty) return;


    widget.onSend(enteredText);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFA726), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFFFFA726)),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
