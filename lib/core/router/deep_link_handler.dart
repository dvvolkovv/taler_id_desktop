import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class DeepLinkHandler {
  static final _appLinks = AppLinks();

  static Future<void> init(GoRouter router) async {
    // Handle initial deep link (app opened via link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleUri(router, initialLink);
      }
    } catch (e) {
      debugPrint('Initial link error: $e');
    }

    // Handle subsequent deep links
    _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(router, uri),
      onError: (e) => debugPrint('Deep link error: $e'),
    );
  }

  static void _handleUri(GoRouter router, Uri uri) {
    debugPrint('Deep link received: $uri');

    // Handle invite links:
    // https://id.taler.tirol/ui/invite.html?token=X
    // talerid://invite?token=X
    if (uri.path.contains('invite') || uri.host == 'invite') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        router.go('/invite?token=$token');
        return;
      }
    }

    // Handle OAuth callback:
    // talerid://oauth/callback?code=X
    if (uri.path.contains('oauth/callback')) {
      final code = uri.queryParameters['code'];
      if (code != null) {
        debugPrint('OAuth callback code: $code');
        // Handle OAuth code exchange
      }
      return;
    }
  }
}
