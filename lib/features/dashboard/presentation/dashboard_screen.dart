import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/services/call_state_service.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import '../../../core/notifications/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../messenger/presentation/bloc/messenger_bloc.dart';
import '../../messenger/presentation/bloc/messenger_event.dart';
import '../../messenger/presentation/bloc/messenger_state.dart';

class DashboardScreen extends StatefulWidget {
  final Widget child;
  const DashboardScreen({super.key, required this.child});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  static const _tabs = [
    RouteConstants.assistant,
    RouteConstants.callHistory,
    RouteConstants.settings,
    RouteConstants.messenger,
  ];

  StreamSubscription? _disconnectSub;
  StreamSubscription? _callEndedSub;
  StreamSubscription? _callAnsweredSub;
  StreamSubscription? _callkitSub;
  String? _showingCallDialogRoom;
  String? _pendingCallRoute; // queued when accept fires while phone is locked

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen for CallKit events (accept / decline) at all times.
    _callkitSub = FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      final extra = event.body['extra'] as Map?;
      final roomName = extra?['roomName'] as String?;
      final convId = extra?['conversationId'] as String?;

      if (event.event == Event.actionCallAccept) {
        if (roomName != null && roomName.isNotEmpty && mounted) {
          final route = '/dashboard/voice?room=$roomName&convId=${convId ?? ''}&incoming=1';
          final lifecycle = WidgetsBinding.instance.lifecycleState;
          if (lifecycle == AppLifecycleState.resumed) {
            // App is in foreground — navigate immediately
            context.go(route);
          } else {
            // App is backgrounded / screen is locked — connect to LiveKit
            // immediately so the caller hears us, defer UI navigation until unlock
            CallStateService.connectInBackground(roomName, convId);
            _pendingCallRoute = route;
          }
        }
      } else if (event.event == Event.actionCallDecline ||
                 event.event == Event.actionCallTimeout) {
        // User declined from native CallKit UI — notify caller via socket
        if (roomName != null && convId != null) {
          try {
            sl<MessengerRemoteDataSource>().sendCallEnded(convId, roomName);
          } catch (_) {}
        }
        // Close in-app dialog if it's showing for this room
        if (mounted && _showingCallDialogRoom != null &&
            (_showingCallDialogRoom == roomName || roomName == null)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        // End only this specific call, not all calls
        final callId = (event.body['id'] ?? event.body['uuid']) as String?;
        if (callId != null) {
          FlutterCallkitIncoming.endCall(callId);
        } else {
          FlutterCallkitIncoming.endAllCalls();
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Handle CallKit accept that happened while app was cold-starting
      final pendingRoute = NotificationService.consumePendingCallRoute();
      if (pendingRoute != null && mounted) {
        context.go(pendingRoute);
        return;
      }
      // Handle FCM notification tap when app was terminated
      final initialMsg = await NotificationService.getInitialMessage();
      if (initialMsg != null) {
        final route = notificationToRoute(initialMsg);
        if (route != null && mounted) {
          context.go(route);
        }
      }
      // Re-register FCM token now that the user is authenticated.
      // NotificationService.init() runs before login so the initial save fails with 401.
      NotificationService.refreshToken();
      _connectMessenger();
      _listenForDisconnect();
      _listenForCallEnded();
      _listenForCallAnswered();
    });
  }

  void _listenForCallEnded() {
    _callEndedSub?.cancel();
    _callEndedSub = sl<MessengerRemoteDataSource>()
        .callEndedStream
        .listen((roomName) async {
      final wasInCallRoom = CallStateService.instance.roomName;
      final isOurCall = wasInCallRoom != null && wasInCallRoom == roomName;

      // Always dismiss a pending incoming call invite from the UI.
      if (mounted) context.read<MessengerBloc>().add(DismissCallInvite());
      // Dismiss CallKit ringing for this room.
      await _endCallKitCallForRoom(roomName, wasInCallRoom: wasInCallRoom);

      if (!isOurCall) return;

      // If user is currently on the voice screen — do NOT auto-navigate away.
      // Each participant ends the call themselves by pressing the hang-up button.
      // The participant list will reflect the other party leaving.
      if (!mounted) return;
      final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
      if (location.startsWith('/dashboard/voice')) return;

      // User is NOT on the voice screen (banner mode) — end call state and hide banner.
      CallStateService.instance.endCall();
    });
  }

  void _listenForCallAnswered() {
    _callAnsweredSub?.cancel();
    _callAnsweredSub = sl<MessengerRemoteDataSource>()
        .callAnsweredStream
        .listen((roomName) async {
      // Another device of the same user answered — dismiss this device's CallKit UI
      await _endCallKitCallForRoom(roomName, fallbackEndAll: true);
      if (mounted) context.read<MessengerBloc>().add(DismissCallInvite());
    });
  }

  /// Ends the CallKit call identified by [roomName] stored in its extra data.
  /// Falls back to endAllCalls() only when [wasInCallRoom] matches or [fallbackEndAll] is true.
  /// This prevents stale `call_ended` events from killing an unrelated incoming VoIP call.
  Future<void> _endCallKitCallForRoom(
    String roomName, {
    String? wasInCallRoom,
    bool fallbackEndAll = false,
  }) async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls() as List;
      for (final call in calls) {
        final callMap = call as Map;
        final extra = callMap['extra'] as Map?;
        final callRoom = extra?['roomName'] as String?;
        if (callRoom == roomName) {
          await FlutterCallkitIncoming.endCall(callMap['id'] as String);
          return;
        }
      }
      // No matching call found by roomName
      if (fallbackEndAll || wasInCallRoom == roomName) {
        await FlutterCallkitIncoming.endAllCalls();
      }
      // Otherwise: stale/unrelated event — leave other CallKit calls untouched
    } catch (_) {
      if (fallbackEndAll || wasInCallRoom == roomName) {
        FlutterCallkitIncoming.endAllCalls();
      }
    }
  }

  void _listenForDisconnect() {
    _disconnectSub?.cancel();
    _disconnectSub = sl<MessengerRemoteDataSource>()
        .disconnectStream
        .listen((_) => _reconnectMessenger());
  }

  Future<void> _reconnectMessenger() async {
    if (!mounted) return;
    // Wait to see if socket.io auto-reconnects on its own
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    // Skip if socket already reconnected automatically
    if (sl<MessengerRemoteDataSource>().isSocketConnected) return;
    try {
      final storage = sl<SecureStorageService>();
      final token = await storage.getAccessToken();
      final userId = await storage.getUserId();
      if (token != null && mounted) {
        context.read<MessengerBloc>().add(ConnectMessenger(token, userId: userId));
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingCallRoute != null && mounted) {
      final route = _pendingCallRoute!;
      _pendingCallRoute = null;
      // Use postFrameCallback so the router is ready after resume
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(route);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectSub?.cancel();
    _callEndedSub?.cancel();
    _callAnsweredSub?.cancel();
    _callkitSub?.cancel();
    super.dispose();
  }

  Future<void> _connectMessenger() async {
    if (!mounted) return;
    final bloc = context.read<MessengerBloc>();
    if (bloc.state.isConnected) return;
    try {
      final storage = sl<SecureStorageService>();
      final token = await storage.getAccessToken();
      final userId = await storage.getUserId();
      if (token != null && mounted) {
        bloc.add(ConnectMessenger(token, userId: userId));
      }
    } catch (_) {}
  }

  int _currentIndex(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  void _showIncomingCall(BuildContext context, Map<String, dynamic> data) {
    final fromName = data['fromUserName'] as String? ?? 'Пользователь';
    final roomName = data['roomName'] as String? ?? '';
    final convId = data['conversationId'] as String? ?? '';

    // If already in a call, silently dismiss incoming call invite
    if (CallStateService.instance.isInCall) {
      if (mounted) context.read<MessengerBloc>().add(DismissCallInvite());
      return;
    }

    // Check if app is in the foreground
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final isForegrounded = lifecycle == AppLifecycleState.resumed;

    if (isForegrounded) {
      // App is visible: show in-app dialog
      _showIncomingCallDialog(context, fromName: fromName, roomName: roomName, convId: convId);
    } else {
      // App is backgrounded/paused: use native CallKit UI
      showCallkitIncoming(
        fromName: fromName,
        roomName: roomName,
        convId: convId,
      );
    }
    if (mounted) context.read<MessengerBloc>().add(DismissCallInvite());
  }

  void _showIncomingCallDialog(
    BuildContext context, {
    required String fromName,
    required String roomName,
    required String convId,
  }) {
    // Deduplicate: don't show a second dialog for the same room
    if (_showingCallDialogRoom == roomName) return;
    _showingCallDialogRoom = roomName;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call_rounded, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('Входящий звонок',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('от $fromName',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              // Dismiss native CallKit ringing (may have started from FCM background handler)
              FlutterCallkitIncoming.endAllCalls();
              final uri = '/dashboard/voice?room=$roomName'
                  '${convId.isNotEmpty ? '&convId=$convId' : ''}';
              context.push(uri);
            },
            icon: const Icon(Icons.call, color: Colors.white),
            label: const Text('Принять'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              // Dismiss native CallKit ringing
              FlutterCallkitIncoming.endAllCalls();
              // Notify caller that the call was declined
              if (convId.isNotEmpty && roomName.isNotEmpty) {
                try {
                  sl<MessengerRemoteDataSource>().sendCallEnded(convId, roomName);
                } catch (_) {}
              }
            },
            icon: const Icon(Icons.call_end, color: Colors.white),
            label: const Text('Отклонить'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          ),
        ],
      ),
    ).whenComplete(() {
      if (_showingCallDialogRoom == roomName) _showingCallDialogRoom = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    final currentIndex = _currentIndex(location);

    return BlocListener<MessengerBloc, MessengerState>(
      listenWhen: (prev, curr) =>
          curr.pendingCallInvite != null &&
          prev.pendingCallInvite != curr.pendingCallInvite,
      listener: (context, state) {
        if (state.pendingCallInvite != null) {
          _showIncomingCall(context, state.pendingCallInvite!);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Active call banner — visible on all tabs
            StreamBuilder<bool>(
              stream: CallStateService.instance.stateStream,
              initialData: CallStateService.instance.isInCall,
              builder: (context, snapshot) {
                final inCall = snapshot.data ?? false;
                if (!inCall) return const SizedBox.shrink();
                final cs = CallStateService.instance;
                return GestureDetector(
                  onTap: () {
                    final room = cs.roomName;
                    final convId = cs.conversationId;
                    if (room != null) {
                      context.push(
                        '/dashboard/voice?room=$room${convId != null ? '&convId=$convId' : ''}',
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    color: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: const Row(
                      children: [
                        Icon(Icons.call_rounded, color: Colors.black, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Активный звонок — нажмите, чтобы вернуться',
                          style: TextStyle(color: Colors.black, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Expanded(child: widget.child),
          ],
        ),
        floatingActionButton: location.startsWith(RouteConstants.messenger)
            ? null
            : FloatingActionButton(
                onPressed: () => context.push(RouteConstants.chat),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.smart_toy_outlined, color: Colors.black),
              ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (i) => context.go(_tabs[i]),
            backgroundColor: Colors.transparent,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.headset_mic_outlined),
                activeIcon: const Icon(Icons.headset_mic),
                label: l10n.tabAssistant,
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.call_outlined),
                activeIcon: Icon(Icons.call),
                label: 'Звонки',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined),
                activeIcon: const Icon(Icons.settings),
                label: l10n.tabSettings,
              ),
              BottomNavigationBarItem(
                icon: BlocBuilder<MessengerBloc, MessengerState>(
                  buildWhen: (p, c) =>
                      p.conversations.fold<int>(0, (s, e) => s + e.unreadCount) !=
                      c.conversations.fold<int>(0, (s, e) => s + e.unreadCount),
                  builder: (ctx, state) {
                    final total =
                        state.conversations.fold<int>(0, (s, c) => s + c.unreadCount);
                    if (total == 0) {
                      return const Icon(Icons.chat_bubble_outline_rounded);
                    }
                    return Badge(
                      label: Text('$total'),
                      backgroundColor: AppColors.error,
                      child: const Icon(Icons.chat_bubble_outline_rounded),
                    );
                  },
                ),
                activeIcon: const Icon(Icons.chat_bubble_rounded),
                label: l10n.tabMessenger,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
