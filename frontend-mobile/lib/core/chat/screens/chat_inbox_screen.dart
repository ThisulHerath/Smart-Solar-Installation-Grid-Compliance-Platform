import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_solar_mobile/core/chat/models/chat.dart';
import 'package:smart_solar_mobile/features/assessment/models/solar_survey.dart';
import 'package:smart_solar_mobile/core/auth/providers/auth_provider.dart';
import 'package:smart_solar_mobile/core/api/api_service.dart';
import 'package:smart_solar_mobile/core/theme/solar_theme.dart';
import 'package:smart_solar_mobile/core/utils/constants.dart';
import 'package:smart_solar_mobile/core/chat/screens/chat_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final ApiService _api = ApiService();
  List<ChatConversation> _conversations = [];
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer =
        Timer.periodic(const Duration(seconds: 10), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final conversations = await _api.getChatConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _error = null;
        });
      }
    } catch (error) {
      if (!silent && mounted) {
        setState(() => _error = _friendlyError(error));
      }
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(ChatConversation conversation) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatScreen(conversation: conversation)));
    await _load();
  }

  Future<void> _startProjectChat() async {
    try {
      final response = await _api.getSurveys();
      final existingIds =
          _conversations.map((item) => item.solarSurveyId).toSet();
      final surveys = response
          .map((item) =>
              SolarSurvey.fromJson(Map<String, dynamic>.from(item as Map)))
          .where((survey) =>
              survey.surveyStatus.toUpperCase() != 'DRAFT' &&
              !existingIds.contains(survey.id))
          .toList();
      if (!mounted) return;
      if (surveys.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Every submitted project already has a chat.')));
        return;
      }
      final selected = await showModalBottomSheet<SolarSurvey>(
        context: context,
        showDragHandle: true,
        backgroundColor: SolarColors.surface,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            children: [
              const Text('Choose a project',
                  style: TextStyle(
                      color: SolarColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('A technician will be connected to this conversation.',
                  style: TextStyle(color: SolarColors.muted, fontSize: 10)),
              const SizedBox(height: 14),
              ...surveys.map((survey) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0x1872B83E),
                        child: Icon(Icons.home_work_outlined,
                            color: SolarColors.limeDark),
                      ),
                      title: Text(survey.propertyAddress.isEmpty
                          ? 'Solar project'
                          : survey.propertyAddress),
                      subtitle: Text(survey.surveyStatus),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(context, survey),
                    ),
                  )),
            ],
          ),
        ),
      );
      if (selected == null || !mounted) return;
      final conversation = await _api.createChatConversation(selected.id);
      if (!mounted) return;
      await _open(conversation);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('404')) {
      return 'Chat service is not loaded yet. Restart the backend API and try again.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<AuthProvider>().user?.roles ?? const <String>[];
    final homeowner = roles.contains(AppConstants.roleHomeowner);
    return Scaffold(
      backgroundColor: SolarColors.background,
      appBar: AppBar(
        backgroundColor: SolarColors.background,
        title: const Text('Messages',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              tooltip: 'Refresh messages',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded,
                  color: SolarColors.primary)),
        ],
      ),
      floatingActionButton: homeowner
          ? FloatingActionButton.extended(
              onPressed: _startProjectChat,
              backgroundColor: SolarColors.lime,
              foregroundColor: SolarColors.primary,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Project chat',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        color: SolarColors.primary,
        child: _buildBody(homeowner),
      ),
    );
  }

  Widget _buildBody(bool homeowner) {
    if (_loading && _conversations.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 220),
        Center(child: CircularProgressIndicator(color: SolarColors.lime)),
      ]);
    }
    if (_error != null && _conversations.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 80),
        const Icon(Icons.cloud_off_rounded, color: SolarColors.error, size: 42),
        const SizedBox(height: 12),
        Text(_error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: SolarColors.muted)),
        TextButton(onPressed: _load, child: const Text('Try again')),
      ]);
    }
    if (_conversations.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 70),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: SolarColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SolarColors.border)),
          child: Column(children: [
            const CircleAvatar(
              radius: 31,
              backgroundColor: Color(0x1872B83E),
              child: Icon(Icons.forum_outlined,
                  color: SolarColors.limeDark, size: 30),
            ),
            const SizedBox(height: 14),
            Text(homeowner ? 'Talk to your technician' : 'No messages yet',
                style: const TextStyle(
                    color: SolarColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
                homeowner
                    ? 'Start a conversation for one of your submitted solar projects.'
                    : 'Assigned homeowner conversations will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: SolarColors.muted, fontSize: 11, height: 1.45)),
          ]),
        ),
      ]);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [SolarColors.primary, SolarColors.heroEnd]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(children: [
            Icon(Icons.support_agent_rounded,
                color: SolarColors.lime, size: 27),
            SizedBox(width: 12),
            Expanded(
              child: Text('Project support in one secure conversation.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        ..._conversations.map((conversation) => _ConversationCard(
            conversation: conversation, onTap: () => _open(conversation))),
      ],
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;
  const _ConversationCard({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: SolarColors.surface,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: SolarColors.border)),
              child: Row(children: [
                Stack(clipBehavior: Clip.none, children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0x1872B83E),
                    child: Icon(Icons.engineering_rounded,
                        color: SolarColors.limeDark),
                  ),
                  if (conversation.unreadCount > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: SolarColors.error, shape: BoxShape.circle),
                        child: Text('${conversation.unreadCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                ]),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(conversation.otherParticipantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: SolarColors.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(
                            conversation.propertyAddress.isEmpty
                                ? 'Solar project support'
                                : conversation.propertyAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: SolarColors.primary, fontSize: 9)),
                        const SizedBox(height: 5),
                        Text(conversation.lastMessage ?? 'Conversation ready',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: SolarColors.muted,
                                fontSize: 10,
                                fontWeight: conversation.unreadCount > 0
                                    ? FontWeight.w700
                                    : FontWeight.w400)),
                      ]),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: SolarColors.muted),
              ]),
            ),
          ),
        ),
      );
}
