import 'package:google_mlkit_translation/google_mlkit_translation.dart';

abstract class TranslatorEvent {}

/// Initialize: check/download models for the selected language pair.
class TranslatorInit extends TranslatorEvent {}

/// User changed source language.
class TranslatorSourceChanged extends TranslatorEvent {
  final TranslateLanguage language;
  TranslatorSourceChanged(this.language);
}

/// User changed target language.
class TranslatorTargetChanged extends TranslatorEvent {
  final TranslateLanguage language;
  TranslatorTargetChanged(this.language);
}

/// Swap source ↔ target languages.
class TranslatorSwapLanguages extends TranslatorEvent {}

/// Start listening via STT (microphone).
class TranslatorStartListening extends TranslatorEvent {}

/// Stop listening.
class TranslatorStopListening extends TranslatorEvent {}

/// Partial STT result (real-time display).
class TranslatorSttPartial extends TranslatorEvent {
  final String text;
  TranslatorSttPartial(this.text);
}

/// Final STT result → trigger translation.
class TranslatorSttFinal extends TranslatorEvent {
  final String text;
  TranslatorSttFinal(this.text);
}

/// User typed text manually → translate.
class TranslatorTextSubmitted extends TranslatorEvent {
  final String text;
  TranslatorTextSubmitted(this.text);
}

/// Toggle TTS auto-speak on translation.
class TranslatorToggleAutoSpeak extends TranslatorEvent {}

/// Speak the current translation via TTS.
class TranslatorSpeak extends TranslatorEvent {}

/// Clear all input/output.
class TranslatorClear extends TranslatorEvent {}
