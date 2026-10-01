import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/api_service.dart';
import '../theme/solar_theme.dart';

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer =
        Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final messages = await _api.getChatMessages(widget.conversation.id);
      await _api.markChatRead(widget.conversation.id);
      if (!mounted) return;
      final changed = messages.length != _messages.length ||
          (messages.isNotEmpty &&
              _messages.isNotEmpty &&
              messages.last.id != _messages.last.id);
      setState(() {
        _messages = messages;
        _error = null;
      });
      if (changed || !silent) _scrollToBottom();
    } catch (error) {
      if (!silent && mounted) {
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      final message = await _api.sendChatMessage(widget.conversation.id, body);
      if (mounted) {
        setState(() {
          _messages = [..._messages, message];
          _error = null;
        });
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        _controller.text = body;
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SolarColors.background,
        appBar: AppBar(
          backgroundColor: SolarColors.surface,
          titleSpacing: 0,
          title: Row(children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0x1872B83E),
              child: Icon(Icons.engineering_rounded,
                  color: SolarColors.limeDark, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.conversation.otherParticipantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: SolarColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    const Text(
                        'Project support · replies may take a few minutes',
                        style:
                            TextStyle(color: SolarColors.muted, fontSize: 8)),
                  ]),
            ),
          ]),
        ),
        body: SafeArea(
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              color: const Color(0x0F07536A),
              child: Text(
                  widget.conversation.propertyAddress.isEmpty
                      ? 'Solar project conversation'
                      : widget.conversation.propertyAddress,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: SolarColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ),
            Expanded(child: _buildMessages()),
            if (_error != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: SolarColors.errorSoft,
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: SolarColors.error, fontSize: 9)),
              ),
            _Composer(
                controller: _controller, sending: _sending, onSend: _send),
          ]),
        ),
      );

  Widget _buildMessages() {
    if (_loading && _messages.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: SolarColors.lime));
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.waving_hand_outlined,
                color: SolarColors.limeDark, size: 36),
            SizedBox(height: 12),
            Text('Start the conversation',
                style: TextStyle(
                    color: SolarColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 5),
            Text('Ask about your survey, visit schedule or installation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: SolarColors.muted, fontSize: 10)),
          ]),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _MessageBubble(
        message: _messages[index],
        showName: index == 0 ||
            _messages[index - 1].senderId != _messages[index].senderId,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showName;
  const _MessageBubble({required this.message, required this.showName});

  @override
  Widget build(BuildContext context) => Align(
        alignment:
            message.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .76),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(13, 9, 13, 7),
          decoration: BoxDecoration(
            color: message.isMine ? SolarColors.primary : SolarColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(message.isMine ? 16 : 4),
              bottomRight: Radius.circular(message.isMine ? 4 : 16),
            ),
            border:
                message.isMine ? null : Border.all(color: SolarColors.border),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (showName && !message.isMine) ...[
              Text(message.senderName,
                  style: const TextStyle(
                      color: SolarColors.limeDark,
                      fontSize: 8,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
            ],
            Text(message.body,
                style: TextStyle(
                    color: message.isMine ? Colors.white : SolarColors.text,
                    fontSize: 12,
                    height: 1.35)),
            const SizedBox(height: 4),
            Text(_time(message.createdAt),
                style: TextStyle(
                    color: message.isMine
                        ? Colors.white.withValues(alpha: .68)
                        : SolarColors.muted,
                    fontSize: 7)),
          ]),
        ),
      );
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _Composer(
      {required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
        decoration: const BoxDecoration(
            color: SolarColors.surface,
            border: Border(top: BorderSide(color: SolarColors.border))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  hintText: 'Write a message…',
                  counterText: '',
                  filled: true,
                  fillColor: SolarColors.background,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            height: 46,
            child: FilledButton(
              onPressed: sending ? null : onSend,
              style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: SolarColors.lime,
                  foregroundColor: SolarColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: SolarColors.primary))
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ]),
      );
}

String _time(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
          ? local.hour - 12
          : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
}
