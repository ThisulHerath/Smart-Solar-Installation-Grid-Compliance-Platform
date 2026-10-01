import 'package:flutter/material.dart';
import 'package:smart_solar_mobile/core/notifications/models/app_notification.dart';
import 'package:smart_solar_mobile/core/api/api_service.dart';
import 'package:smart_solar_mobile/core/theme/solar_theme.dart';
import 'package:smart_solar_mobile/features/field_operations/screens/job_detail_screen.dart';
import 'package:smart_solar_mobile/features/assessment/screens/survey_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiService();
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _api.getNotifications();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _open(AppNotification item) async {
    if (!item.isRead) {
      await _api.markNotificationRead(item.id);
    }
    if (!mounted) return;

    final hasDestination = item.entityId != null &&
        (item.entityType == 'FieldJob' || item.entityType == 'SolarSurvey');
    final openDestination = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _NotificationDetails(
            item: item,
            time: _time(item.createdAt),
            hasDestination: hasDestination));

    if (!mounted) return;
    if (openDestination == true &&
        item.entityType == 'FieldJob' &&
        item.entityId != null) {
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => JobDetailScreen(jobId: item.entityId!)));
    } else if (openDestination == true && item.entityType == 'SolarSurvey') {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SurveyScreen()));
    }
    await _load();
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'FIELD_JOB_ASSIGNED':
        return Icons.engineering_rounded;
      case 'FIELD_VISIT_SCHEDULED':
      case 'VISIT_CONFIRMED':
        return Icons.event_available_rounded;
      case 'TECHNICIAN_ON_THE_WAY':
        return Icons.directions_car_filled_rounded;
      case 'TECHNICIAN_ARRIVED':
        return Icons.location_on_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  String _time(DateTime date) {
    final difference = DateTime.now().difference(date.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: SolarColors.background,
      appBar: AppBar(
          backgroundColor: SolarColors.surface,
          title: const Text('Notifications'),
          actions: [
            if (_items.any((item) => !item.isRead))
              TextButton(
                  onPressed: () async {
                    await _api.markAllNotificationsRead();
                    _load();
                  },
                  child: const Text('Mark all read'))
          ]),
      body: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(children: [
                      Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!,
                              style: const TextStyle(color: SolarColors.error)))
                    ])
                  : _items.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 180),
                          Icon(Icons.notifications_none_rounded,
                              size: 54, color: SolarColors.muted),
                          SizedBox(height: 12),
                          Center(
                              child: Text('No notifications yet',
                                  style: TextStyle(color: SolarColors.muted)))
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final item = _items[index];
                            return Material(
                                color: item.isRead
                                    ? SolarColors.surface
                                    : const Color(0xFFF0F8EC),
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => _open(item),
                                    child: Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                  width: 42,
                                                  height: 42,
                                                  decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFE3F1DC),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              11)),
                                                  child: Icon(
                                                      _iconFor(item.type),
                                                      color:
                                                          SolarColors.primary)),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                    Text(item.title,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: SolarColors
                                                                .text)),
                                                    const SizedBox(height: 4),
                                                    Text(item.message,
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            height: 1.4,
                                                            color: SolarColors
                                                                .muted)),
                                                    const SizedBox(height: 7),
                                                    Text(_time(item.createdAt),
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            color: SolarColors
                                                                .muted))
                                                  ])),
                                              if (!item.isRead)
                                                Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                            color: SolarColors
                                                                .primary,
                                                            shape: BoxShape
                                                                .circle)),
                                            ]))));
                          })));
}

class _NotificationDetails extends StatelessWidget {
  final AppNotification item;
  final String time;
  final bool hasDestination;

  const _NotificationDetails(
      {required this.item, required this.time, required this.hasDestination});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
        padding: EdgeInsets.fromLTRB(22, 12, 22, 22 + bottomInset),
        decoration: const BoxDecoration(
            color: SolarColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFD8DDD5),
                      borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 22),
              Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE7F3E1),
                      borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.notifications_active_rounded,
                      color: SolarColors.primary, size: 28)),
              const SizedBox(height: 16),
              Text(item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      color: SolarColors.text)),
              const SizedBox(height: 10),
              Text(item.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, height: 1.55, color: SolarColors.muted)),
              const SizedBox(height: 10),
              Text(time,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: SolarColors.muted)),
              const SizedBox(height: 22),
              if (hasDestination)
                SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(item.entityType == 'FieldJob'
                            ? 'View assigned job'
                            : 'View my projects'))),
              if (hasDestination) const SizedBox(height: 8),
              SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Close')))
            ])));
  }
}
