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
  static final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _toggleTts() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _tts.speak(widget.message.content);
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
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary.withValues(alpha: 0.15) : AppColors.card,
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    )
                  else ...[
                    if (widget.message.content.isNotEmpty)
                      MarkdownBody(
                        data: widget.message.content,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                          code: TextStyle(
                            color: AppColors.primary,
                            backgroundColor: AppColors.background.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          a: const TextStyle(color: AppColors.secondary),
                          h1: const TextStyle(color: AppColors.textPrimary, fontSize: 20),
                          h2: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
                          h3: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                          listBullet: const TextStyle(color: AppColors.textSecondary),
                          blockquoteDecoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              left: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 3),
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
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                  // TTS button for completed assistant messages
                  if (!isUser &&
                      !widget.message.isStreaming &&
                      widget.message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: GestureDetector(
                        onTap: _toggleTts,
                        child: Icon(
                          _isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
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
              color: AppColors.textSecondary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
