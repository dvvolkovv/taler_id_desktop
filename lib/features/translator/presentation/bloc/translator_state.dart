import 'package:google_mlkit_translation/google_mlkit_translation.dart';

enum TranslatorStatus { initial, downloading, ready, listening, translating, error }

class TranslatorState {
  final TranslatorStatus status;
  final TranslateLanguage sourceLanguage;
  final TranslateLanguage targetLanguage;
  final String sourceText;
  final String translatedText;
  final String partialStt;
  final bool autoSpeak;
  final String? errorMessage;
  final double? downloadProgress;

  const TranslatorState({
    this.status = TranslatorStatus.initial,
    this.sourceLanguage = TranslateLanguage.russian,
    this.targetLanguage = TranslateLanguage.english,
    this.sourceText = '',
    this.translatedText = '',
    this.partialStt = '',
    this.autoSpeak = true,
    this.errorMessage,
    this.downloadProgress,
  });

  TranslatorState copyWith({
    TranslatorStatus? status,
    TranslateLanguage? sourceLanguage,
    TranslateLanguage? targetLanguage,
    String? sourceText,
    String? translatedText,
    String? partialStt,
    bool? autoSpeak,
    String? errorMessage,
    double? downloadProgress,
  }) {
    return TranslatorState(
      status: status ?? this.status,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      partialStt: partialStt ?? this.partialStt,
      autoSpeak: autoSpeak ?? this.autoSpeak,
      errorMessage: errorMessage,
      downloadProgress: downloadProgress,
    );
  }

  bool get isListening => status == TranslatorStatus.listening;
  bool get isReady => status == TranslatorStatus.ready;
  bool get isDownloading => status == TranslatorStatus.downloading;
}
