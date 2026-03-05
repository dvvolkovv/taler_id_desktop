import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
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
  late Future<List<_CallEntry>> _historyFuture;
  Future<_PersonalRoom?>? _personalRoomFuture;
  bool _calling = false;
  bool _creatingTemp = false;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
    _personalRoomFuture = _loadPersonalRoom();
  }

  Future<List<_CallEntry>> _loadHistory() async {
    final data = await sl<DioClient>().get<dynamic>(
      '/voice/call-history',
      queryParameters: {'page': 0, 'limit': 50},
    );
    final items = data as List? ?? [];
    return items.map((e) => _CallEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<_PersonalRoom?> _loadPersonalRoom() async {
    try {
      final data = await sl<DioClient>().get<Map<String, dynamic>>(
        '/voice/rooms/my',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      return _PersonalRoom(
        code: data['code'] as String,
        link: data['link'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _createTemporaryRoom() async {
    if (_creatingTemp) return;
    setState(() => _creatingTemp = true);
    try {
      final data = await sl<DioClient>().post<Map<String, dynamic>>(
        '/voice/rooms/temporary',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final code = data['code'] as String;
      final link = data['link'] as String;
      if (mounted) _showTempRoomSheet(code, link);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $err'), backgroundColor: AppColors.of(context).error),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingTemp = false);
    }
  }

  void _showTempRoomSheet(String code, String link) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Временная встреча',
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _LinkRow(link: link),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.copy_rounded,
                    label: 'Скопировать',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Ссылка скопирована'),
                          backgroundColor: colors.primary,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_rounded,
                    label: 'Поделиться',
                    onTap: () => Share.share(link),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.videocam_rounded,
                    label: 'Войти',
                    filled: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/dashboard/voice?publicCode=$code');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ссылка скопирована'),
        backgroundColor: AppColors.of(context).primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _callBack(_CallEntry e) async {
    if (_calling) return;
    if (CallStateService.instance.isInCall) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Уже идёт звонок'), backgroundColor: AppColors.of(context).error),
      );
      return;
    }
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
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Звонки')),
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: () async {
          setState(() {
            _historyFuture = _loadHistory();
            _personalRoomFuture = _loadPersonalRoom();
          });
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Personal room section ──
            _buildPersonalRoomSection(colors),
            const SizedBox(height: 12),
            // ── Create meeting button ──
            _buildCreateMeetingButton(colors),
            const SizedBox(height: 24),
            // ── Call history ──
            Text(
              'История звонков',
              style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildHistoryList(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRoomSection(AppColorsExtension colors) {
    return FutureBuilder<_PersonalRoom?>(
      future: _personalRoomFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return AppCard(
            child: SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary)),
            ),
          );
        }
        final room = snap.data;
        if (room == null) {
          return AppCard(
            child: Row(
              children: [
                Icon(Icons.link_off_rounded, color: colors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Не удалось загрузить вашу комнату',
                    style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _personalRoomFuture = _loadPersonalRoom()),
                  child: Text('Повторить', style: TextStyle(color: colors.primary, fontSize: 13)),
                ),
              ],
            ),
          );
        }
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.videocam_rounded, color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ваша комната',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _LinkRow(link: room.link),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.copy_rounded,
                      label: 'Скопировать',
                      onTap: () => _copyLink(room.link),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.share_rounded,
                      label: 'Поделиться',
                      onTap: () => Share.share(room.link),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.videocam_rounded,
                      label: 'Войти',
                      filled: true,
                      onTap: () => context.push('/dashboard/voice?publicCode=${room.code}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateMeetingButton(AppColorsExtension colors) {
    return GestureDetector(
      onTap: _creatingTemp ? null : _createTemporaryRoom,
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: colors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _creatingTemp
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
                    )
                  : Icon(Icons.add_rounded, color: colors.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Создать встречу',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(AppColorsExtension colors) {
    return FutureBuilder<List<_CallEntry>>(
      future: _historyFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
            ),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: colors.error, size: 36),
                const SizedBox(height: 8),
                Text('Ошибка загрузки', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                TextButton(
                  onPressed: () => setState(() => _historyFuture = _loadHistory()),
                  child: Text('Повторить', style: TextStyle(color: colors.primary)),
                ),
              ],
            ),
          );
        }
        final entries = snap.data ?? [];
        if (entries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Нет звонков',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ),
          );
        }
        return Column(
          children: entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildCallCard(e, colors),
          )).toList(),
        );
      },
    );
  }

  Widget _buildCallCard(_CallEntry e, AppColorsExtension colors) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: e.isOutgoing
                  ? colors.primary.withOpacity(0.12)
                  : _kIncomingColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              e.isOutgoing ? Icons.call_made_rounded : Icons.call_received_rounded,
              color: e.isOutgoing ? colors.primary : _kIncomingColor,
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
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(e.startedAt),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (e.durationSec != null) ...[
            Text(
              _formatDuration(e.durationSec!),
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            const SizedBox(width: 8),
          ],
          _calling
              ? SizedBox(
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.call_outlined, color: colors.primary, size: 22),
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

// ─── Helper widgets ───

class _LinkRow extends StatelessWidget {
  final String link;
  const _LinkRow({required this.link});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      child: Text(
        link,
        style: TextStyle(color: colors.primary, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? colors.primary : colors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: filled ? Colors.white : colors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : colors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Models ───

class _PersonalRoom {
  final String code;
  final String link;
  const _PersonalRoom({required this.code, required this.link});
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
