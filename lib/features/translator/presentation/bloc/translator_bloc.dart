import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/repositories/i_translator_repository.dart';
import 'translator_event.dart';
import 'translator_state.dart';

class TranslatorBloc extends Bloc<TranslatorEvent, TranslatorState> {
  final ITranslatorRepository _repo;
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttInitialized = false;

  TranslatorBloc({required ITranslatorRepository repo})
      : _repo = repo,
        super(const TranslatorState()) {
    on<TranslatorInit>(_onInit);
    on<TranslatorSourceChanged>(_onSourceChanged);
    on<TranslatorTargetChanged>(_onTargetChanged);
    on<TranslatorSwapLanguages>(_onSwap);
    on<TranslatorStartListening>(_onStartListening);
    on<TranslatorStopListening>(_onStopListening);
    on<TranslatorSttPartial>(_onSttPartial);
    on<TranslatorSttFinal>(_onSttFinal);
    on<TranslatorTextSubmitted>(_onTextSubmitted);
    on<TranslatorToggleAutoSpeak>(_onToggleAutoSpeak);
    on<TranslatorSpeak>(_onSpeak);
    on<TranslatorClear>(_onClear);
  }

  Future<void> _onInit(TranslatorInit event, Emitter<TranslatorState> emit) async {
    emit(state.copyWith(status: TranslatorStatus.downloading));
    try {
      // Download models for both languages if needed
      final srcReady = await _repo.isModelDownloaded(state.sourceLanguage);
      final tgtReady = await _repo.isModelDownloaded(state.targetLanguage);

      if (!srcReady) {
        await _repo.downloadModel(state.sourceLanguage);
      }
      if (!tgtReady) {
        await _repo.downloadModel(state.targetLanguage);
      }

      // Init STT
      _sttInitialized = await _stt.initialize();

      // Configure TTS
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.5);

      emit(state.copyWith(status: TranslatorStatus.ready));
    } catch (e) {
      debugPrint('[Translator] init error: $e');
      emit(state.copyWith(
        status: TranslatorStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _ensureModels(
    TranslateLanguage source,
    TranslateLanguage target,
    Emitter<TranslatorState> emit,
  ) async {
    final srcReady = await _repo.isModelDownloaded(source);
    final tgtReady = await _repo.isModelDownloaded(target);
    if (!srcReady || !tgtReady) {
      emit(state.copyWith(status: TranslatorStatus.downloading));
      if (!srcReady) await _repo.downloadModel(source);
      if (!tgtReady) await _repo.downloadModel(target);
      emit(state.copyWith(status: TranslatorStatus.ready));
    }
  }

  Future<void> _onSourceChanged(
    TranslatorSourceChanged event,
    Emitter<TranslatorState> emit,
  ) async {
    emit(state.copyWith(
      sourceLanguage: event.language,
      sourceText: '',
      translatedText: '',
      partialStt: '',
    ));
    await _ensureModels(event.language, state.targetLanguage, emit);
  }

  Future<void> _onTargetChanged(
    TranslatorTargetChanged event,
    Emitter<TranslatorState> emit,
  ) async {
    emit(state.copyWith(
      targetLanguage: event.language,
      translatedText: '',
    ));
    await _ensureModels(state.sourceLanguage, event.language, emit);
  }

  Future<void> _onSwap(
    TranslatorSwapLanguages event,
    Emitter<TranslatorState> emit,
  ) async {
    final newSource = state.targetLanguage;
    final newTarget = state.sourceLanguage;
    emit(state.copyWith(
      sourceLanguage: newSource,
      targetLanguage: newTarget,
      sourceText: state.translatedText,
      translatedText: state.sourceText,
      partialStt: '',
    ));
  }

  Future<void> _onStartListening(
    TranslatorStartListening event,
    Emitter<TranslatorState> emit,
  ) async {
    if (!_sttInitialized) {
      _sttInitialized = await _stt.initialize();
    }
    if (!_sttInitialized) {
      emit(state.copyWith(
        status: TranslatorStatus.error,
        errorMessage: 'Speech recognition not available',
      ));
      return;
    }

    await _tts.stop();
    emit(state.copyWith(
      status: TranslatorStatus.listening,
      partialStt: '',
    ));

    final localeId = _sttLocaleId(state.sourceLanguage);
    _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          add(TranslatorSttFinal(result.recognizedWords));
        } else {
          add(TranslatorSttPartial(result.recognizedWords));
        }
      },
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  Future<void> _onStopListening(
    TranslatorStopListening event,
    Emitter<TranslatorState> emit,
  ) async {
    await _stt.stop();
    // If there's partial text that didn't finalize, translate it
    if (state.partialStt.isNotEmpty) {
      add(TranslatorSttFinal(state.partialStt));
    } else {
      emit(state.copyWith(status: TranslatorStatus.ready));
    }
  }

  void _onSttPartial(TranslatorSttPartial event, Emitter<TranslatorState> emit) {
    emit(state.copyWith(partialStt: event.text));
  }

  Future<void> _onSttFinal(
    TranslatorSttFinal event,
    Emitter<TranslatorState> emit,
  ) async {
    if (event.text.trim().isEmpty) {
      emit(state.copyWith(status: TranslatorStatus.ready, partialStt: ''));
      return;
    }

    emit(state.copyWith(
      status: TranslatorStatus.translating,
      sourceText: event.text,
      partialStt: '',
    ));

    try {
      final result = await _repo.translate(
        event.text,
        state.sourceLanguage,
        state.targetLanguage,
      );
      emit(state.copyWith(
        status: TranslatorStatus.ready,
        translatedText: result,
      ));

      if (state.autoSpeak && result.isNotEmpty) {
        add(TranslatorSpeak());
      }
    } catch (e) {
      debugPrint('[Translator] translate error: $e');
      emit(state.copyWith(
        status: TranslatorStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onTextSubmitted(
    TranslatorTextSubmitted event,
    Emitter<TranslatorState> emit,
  ) async {
    if (event.text.trim().isEmpty) return;

    emit(state.copyWith(
      status: TranslatorStatus.translating,
      sourceText: event.text,
    ));

    try {
      final result = await _repo.translate(
        event.text,
        state.sourceLanguage,
        state.targetLanguage,
      );
      emit(state.copyWith(
        status: TranslatorStatus.ready,
        translatedText: result,
      ));

      if (state.autoSpeak && result.isNotEmpty) {
        add(TranslatorSpeak());
      }
    } catch (e) {
      debugPrint('[Translator] translate error: $e');
      emit(state.copyWith(
        status: TranslatorStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onToggleAutoSpeak(TranslatorToggleAutoSpeak event, Emitter<TranslatorState> emit) {
    emit(state.copyWith(autoSpeak: !state.autoSpeak));
  }

  Future<void> _onSpeak(TranslatorSpeak event, Emitter<TranslatorState> emit) async {
    if (state.translatedText.isEmpty) return;
    final lang = _ttsLanguageCode(state.targetLanguage);
    await _tts.setLanguage(lang);
    await _tts.speak(state.translatedText);
  }

  void _onClear(TranslatorClear event, Emitter<TranslatorState> emit) {
    _tts.stop();
    emit(state.copyWith(
      sourceText: '',
      translatedText: '',
      partialStt: '',
      status: TranslatorStatus.ready,
    ));
  }

  /// Map TranslateLanguage → STT locale ID.
  String _sttLocaleId(TranslateLanguage lang) {
    switch (lang) {
      case TranslateLanguage.russian:
        return 'ru_RU';
      case TranslateLanguage.english:
        return 'en_US';
      case TranslateLanguage.german:
        return 'de_DE';
      case TranslateLanguage.french:
        return 'fr_FR';
      case TranslateLanguage.spanish:
        return 'es_ES';
      case TranslateLanguage.italian:
        return 'it_IT';
      case TranslateLanguage.portuguese:
        return 'pt_PT';
      case TranslateLanguage.chinese:
        return 'zh_CN';
      case TranslateLanguage.japanese:
        return 'ja_JP';
      case TranslateLanguage.korean:
        return 'ko_KR';
      case TranslateLanguage.turkish:
        return 'tr_TR';
      case TranslateLanguage.arabic:
        return 'ar_SA';
      default:
        return lang.bcpCode;
    }
  }

  /// Map TranslateLanguage → TTS language code.
  String _ttsLanguageCode(TranslateLanguage lang) {
    switch (lang) {
      case TranslateLanguage.russian:
        return 'ru-RU';
      case TranslateLanguage.english:
        return 'en-US';
      case TranslateLanguage.german:
        return 'de-DE';
      case TranslateLanguage.french:
        return 'fr-FR';
      case TranslateLanguage.spanish:
        return 'es-ES';
      case TranslateLanguage.italian:
        return 'it-IT';
      case TranslateLanguage.portuguese:
        return 'pt-PT';
      case TranslateLanguage.chinese:
        return 'zh-CN';
      case TranslateLanguage.japanese:
        return 'ja-JP';
      case TranslateLanguage.korean:
        return 'ko-KR';
      case TranslateLanguage.turkish:
        return 'tr-TR';
      case TranslateLanguage.arabic:
        return 'ar-SA';
      default:
        return lang.bcpCode;
    }
  }

  @override
  Future<void> close() {
    _stt.stop();
    _tts.stop();
    _repo.dispose();
    return super.close();
  }
}
