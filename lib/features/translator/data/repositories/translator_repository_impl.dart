import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../../domain/repositories/i_translator_repository.dart';

class TranslatorRepositoryImpl implements ITranslatorRepository {
  final _modelManager = OnDeviceTranslatorModelManager();

  /// Cache translators by language pair to avoid re-creating them.
  final Map<String, OnDeviceTranslator> _translators = {};

  OnDeviceTranslator _getTranslator(TranslateLanguage source, TranslateLanguage target) {
    final key = '${source.bcpCode}_${target.bcpCode}';
    return _translators.putIfAbsent(
      key,
      () => OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: target,
      ),
    );
  }

  @override
  Future<String> translate(
    String text,
    TranslateLanguage source,
    TranslateLanguage target,
  ) async {
    if (text.trim().isEmpty) return '';
    final translator = _getTranslator(source, target);
    return translator.translateText(text);
  }

  @override
  Future<bool> isModelDownloaded(TranslateLanguage language) {
    return _modelManager.isModelDownloaded(language.bcpCode);
  }

  @override
  Future<void> downloadModel(TranslateLanguage language) async {
    await _modelManager.downloadModel(language.bcpCode);
  }

  @override
  Future<void> deleteModel(TranslateLanguage language) async {
    await _modelManager.deleteModel(language.bcpCode);
  }

  @override
  Future<List<TranslateLanguage>> getDownloadedModels() async {
    final all = TranslateLanguage.values;
    final downloaded = <TranslateLanguage>[];
    for (final lang in all) {
      if (await _modelManager.isModelDownloaded(lang.bcpCode)) {
        downloaded.add(lang);
      }
    }
    return downloaded;
  }

  @override
  void dispose() {
    for (final t in _translators.values) {
      t.close();
    }
    _translators.clear();
  }
}
