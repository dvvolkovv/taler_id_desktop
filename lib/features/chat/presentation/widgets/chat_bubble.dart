import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_message.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  static FlutterTts? _tts;
  static bool _ttsAvailable = false;
  static bool _ttsInitialized = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    if (_ttsInitialized) return;
    _ttsInitialized = true;
    try {
      _tts = FlutterTts();
      _ttsAvailable = true;
      _tts!.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts!.setCancelHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (e) {
      _ttsAvailable = false;
      debugPrint('FlutterTts not available: $e');
    }
  }

  Future<void> _toggleTts() async {
    if (!_ttsAvailable || _tts == null) return;
    if (_isSpeaking) {
      await _tts!.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      try {
        await _tts!.speak(widget.message.content);
      } catch (e) {
        setState(() => _isSpeaking = false);
        debugPrint('TTS speak error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.of(context).primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: AppColors.of(context).primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.of(context).primary.withValues(alpha: 0.15) : AppColors.of(context).card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    Text(
                      widget.message.content,
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 15,
                      ),
                    )
                  else ...[
                    if (widget.message.content.isNotEmpty)
                      MarkdownBody(
                        data: widget.message.content,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: AppColors.of(context).textPrimary,
                            fontSize: 15,
                          ),
                          code: TextStyle(
                            color: AppColors.of(context).primary,
                            backgroundColor: AppColors.of(context).background.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: AppColors.of(context).background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          a: TextStyle(color: AppColors.of(context).secondary),
                          h1: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 20),
                          h2: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 18),
                          h3: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 16),
                          listBullet: TextStyle(color: AppColors.of(context).textSecondary),
                          blockquoteDecoration: BoxDecoration(
                            color: AppColors.of(context).surface,
                            border: Border(
                              left: BorderSide(color: AppColors.of(context).primary.withValues(alpha: 0.5), width: 3),
                            ),
                          ),
                        ),
                        selectable: true,
                      ),
                    if (widget.message.isStreaming && widget.message.content.isEmpty)
                      _buildTypingIndicator(),
                    if (widget.message.isStreaming && widget.message.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.of(context).primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                  // TTS button for completed assistant messages
                  if (_ttsAvailable &&
                      !isUser &&
                      !widget.message.isStreaming &&
                      widget.message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: GestureDetector(
                        onTap: _toggleTts,
                        child: Icon(
                          _isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                          size: 18,
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1.0),
          duration: Duration(milliseconds: 600 + i * 200),
          builder: (_, value, child) => Opacity(opacity: value, child: child),
          child: Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.of(context).textSecondary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
