import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/call_state_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';

const _kIncomingColor = Color(0xFF4CAF50);

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  late Future<List<_CallEntry>> _future;
  bool _calling = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_CallEntry>> _load() async {
    final data = await sl<DioClient>().get<dynamic>(
      '/voice/call-history',
      queryParameters: {'page': 0, 'limit': 50},
    );
    final items = data as List? ?? [];
    return items.map((e) => _CallEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _callBack(_CallEntry e) async {
    if (_calling) return;
    if (CallStateService.instance.isInCall) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Уже идёт звонок'), backgroundColor: AppColors.of(context).error),
      );
      return;
    }
    // AI-only calls don't need a conversationId; peer calls require one.
    if (!e.withAi && (e.conversationId == null || e.conversationId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось определить собеседника'),
          backgroundColor: AppColors.of(context).error,
        ),
      );
      return;
    }

    setState(() => _calling = true);
    try {
      final res = await sl<DioClient>().post<Map<String, dynamic>>(
        '/voice/rooms',
        data: {
          'withAi': e.withAi,
          if (e.conversationId != null && e.conversationId!.isNotEmpty)
            'conversationId': e.conversationId,
        },
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final roomName = res['roomName'] as String;
      if (e.conversationId != null && e.conversationId!.isNotEmpty) {
        sl<MessengerRemoteDataSource>().sendCallInvite(e.conversationId!, roomName);
      }
      if (mounted) {
        context.push(
          '/dashboard/voice?room=$roomName'
          '${e.conversationId != null && e.conversationId!.isNotEmpty ? "&convId=${e.conversationId}" : ""}',
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $err'), backgroundColor: AppColors.of(context).error),
        );
      }
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: const Text('История звонков')),
      body: FutureBuilder<List<_CallEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.of(context).primary));
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: AppColors.of(context).error, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Ошибка загрузки',
                    style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _future = _load()),
                    child: Text('Повторить', style: TextStyle(color: AppColors.of(context).primary)),
                  ),
                ],
              ),
            );
          }
          final entries = snap.data ?? [];
          if (entries.isEmpty) {
            return Center(
              child: Text(
                'Нет звонков',
                style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 15),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.of(context).primary,
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _buildCard(entries[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(_CallEntry e) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: e.isOutgoing
                  ? AppColors.of(context).primary.withOpacity(0.12)
                  : _kIncomingColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              e.isOutgoing ? Icons.call_made_rounded : Icons.call_received_rounded,
              color: e.isOutgoing ? AppColors.of(context).primary : _kIncomingColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.otherPartyName,
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(e.startedAt),
                  style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (e.durationSec != null) ...[
            Text(
              _formatDuration(e.durationSec!),
              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
            ),
            const SizedBox(width: 8),
          ],
          // Call-back button
          _calling
              ? SizedBox(
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.of(context).primary),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.call_outlined, color: AppColors.of(context).primary, size: 22),
                  tooltip: 'Позвонить снова',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => _callBack(e),
                ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 0) return 'Сегодня, $time';
    if (diff.inDays == 1) return 'Вчера, $time';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}, $time';
  }

  String _formatDuration(int sec) {
    if (sec < 60) return '${sec}с';
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m < 60) return '${m}м ${s.toString().padLeft(2, '0')}с';
    final h = m ~/ 60;
    final mm = m % 60;
    return '${h}ч ${mm.toString().padLeft(2, '0')}м';
  }
}

class _CallEntry {
  final String id;
  final String otherPartyName;
  final DateTime startedAt;
  final int? durationSec;
  final bool isOutgoing;
  final bool withAi;
  final String? conversationId;

  const _CallEntry({
    required this.id,
    required this.otherPartyName,
    required this.startedAt,
    this.durationSec,
    required this.isOutgoing,
    required this.withAi,
    this.conversationId,
  });

  factory _CallEntry.fromJson(Map<String, dynamic> json) {
    // Backend returns: { id, conversationId, isOutgoing, startedAt, durationSec, withAi,
    //   participants: [{ userId, displayName }] }
    final participants = json['participants'] as List? ?? [];
    final withAi = json['withAi'] as bool? ?? false;
    String name;
    if (withAi && participants.isEmpty) {
      name = 'AI-ассистент';
    } else {
      name = participants
          .map((p) => (p as Map)['displayName'] as String? ?? 'Неизвестный')
          .join(', ');
      if (name.isEmpty) name = 'Неизвестный';
    }
    return _CallEntry(
      id: json['id'] as String? ?? '',
      otherPartyName: name,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
      durationSec: json['durationSec'] as int?,
      isOutgoing: json['isOutgoing'] as bool? ?? true,
      withAi: withAi,
      conversationId: json['conversationId'] as String?,
    );
  }
}
