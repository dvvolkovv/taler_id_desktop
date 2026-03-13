import 'package:google_mlkit_translation/google_mlkit_translation.dart';

abstract class ITranslatorRepository {
  /// Translate [text] from [source] to [target] language.
  Future<String> translate(String text, TranslateLanguage source, TranslateLanguage target);

  /// Check if model for [language] is already downloaded.
  Future<bool> isModelDownloaded(TranslateLanguage language);

  /// Download translation model for [language].
  Future<void> downloadModel(TranslateLanguage language);

  /// Delete translation model for [language].
  Future<void> deleteModel(TranslateLanguage language);

  /// Get list of downloaded models.
  Future<List<TranslateLanguage>> getDownloadedModels();

  void dispose();
}
