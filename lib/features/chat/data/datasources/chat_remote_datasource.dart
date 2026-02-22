import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

class ChatRemoteDataSource {
  static const _baseUrl = 'https://travel-n8n.up.railway.app/webhook/talerid/chat';

  final Dio _dio;

  ChatRemoteDataSource()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 120),
          headers: {'Content-Type': 'application/json'},
        ));

  /// Sends a message and returns a stream of text chunks (NDJSON format).
  Stream<String> sendMessage({
    required String prompt,
    required String userId,
  }) async* {
    final response = await _dio.post<ResponseBody>(
      _baseUrl,
      data: {
        'prompt': prompt,
        'user_id': userId,
      },
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data!.stream;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);

      // Split by newlines — each line is a JSON object
      while (buffer.contains('\n')) {
        final idx = buffer.indexOf('\n');
        final line = buffer.substring(0, idx).trim();
        buffer = buffer.substring(idx + 1);

        if (line.isEmpty) continue;

        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final type = json['type'] as String?;

          if (type == 'item') {
            final content = json['content'] as String? ?? '';
            if (content.isNotEmpty) {
              yield content;
            }
          } else if (type == 'error') {
            final content = json['content'] as String? ?? 'Unknown error';
            throw Exception(content);
          }
          // 'begin' and 'end' types are ignored
        } catch (e) {
          if (e is Exception && e.toString().contains('Unknown error')) {
            rethrow;
          }
          // Skip malformed lines
        }
      }
    }

    // Process remaining buffer
    if (buffer.trim().isNotEmpty) {
      try {
        final json = jsonDecode(buffer.trim()) as Map<String, dynamic>;
        if (json['type'] == 'item') {
          final content = json['content'] as String? ?? '';
          if (content.isNotEmpty) {
            yield content;
          }
        }
      } catch (_) {}
    }
  }
}
