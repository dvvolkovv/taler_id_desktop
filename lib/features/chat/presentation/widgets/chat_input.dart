import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/platform_utils.dart';

class ChatInput extends StatefulWidget {
  final void Function(String text) onSend;
  final bool enabled;

  const ChatInput({
    super.key,
    required this.onSend,
    this.enabled = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _accumulated = '';

  @override
  void initState() {
    super.initState();
    // Speech recognition crashes on macOS sandbox (TCC kills app)
    if (isMobilePlatform) _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (_) => setState(() => _isListening = false),
      );
    } catch (e) {
      _speechAvailable = false;
      debugPrint('SpeechToText not available: $e');
    }
    if (mounted) setState(() {});
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
    _accumulated = '';
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _accumulated = _controller.text.trim();
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords;
          final newText = _accumulated.isEmpty ? words : '$_accumulated $words';
          _controller.text = newText;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: newText.length),
          );
          if (result.finalResult) {
            _accumulated = newText.trim();
            setState(() => _isListening = false);
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
        localeId: 'ru_RU',
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    try { _speech.stop(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        border: Border(top: BorderSide(color: AppColors.of(context).border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Mic button
          if (_speechAvailable)
            GestureDetector(
              onTap: widget.enabled ? _toggleListening : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isListening
                      ? AppColors.of(context).error.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic_outlined,
                  color: _isListening ? AppColors.of(context).error : AppColors.of(context).textSecondary,
                  size: 22,
                ),
              ),
            ),
          const SizedBox(width: 4),
          // Text field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              maxLines: 4,
              minLines: 1,
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: _isListening ? '...' : null,
                hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
                filled: true,
                fillColor: AppColors.of(context).card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Send button
          GestureDetector(
            onTap: widget.enabled ? _send : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.of(context).primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.send,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
