import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/translator_bloc.dart';
import '../bloc/translator_event.dart';
import '../bloc/translator_state.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TranslatorBloc>().add(TranslatorInit());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.translatorTitle),
        backgroundColor: colors.surface.withOpacity(0.80),
        actions: [
          BlocBuilder<TranslatorBloc, TranslatorState>(
            buildWhen: (p, c) => p.autoSpeak != c.autoSpeak,
            builder: (ctx, state) => IconButton(
              icon: Icon(
                state.autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: state.autoSpeak ? colors.primary : colors.textSecondary,
              ),
              tooltip: l10n.translatorAutoSpeak,
              onPressed: () => ctx.read<TranslatorBloc>().add(TranslatorToggleAutoSpeak()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Language selector bar
          _LanguageBar(),
          // Main content
          Expanded(
            child: BlocBuilder<TranslatorBloc, TranslatorState>(
              builder: (context, state) {
                if (state.isDownloading) {
                  return _DownloadingView();
                }
                if (state.status == TranslatorStatus.error) {
                  return _ErrorView(message: state.errorMessage);
                }
                return _TranslationBody(textController: _textController);
              },
            ),
          ),
          // Bottom mic bar
          _MicBar(),
        ],
      ),
    );
  }
}

// ── Language selector ──

class _LanguageBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return BlocBuilder<TranslatorBloc, TranslatorState>(
      buildWhen: (p, c) =>
          p.sourceLanguage != c.sourceLanguage || p.targetLanguage != c.targetLanguage,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(color: colors.border.withOpacity(0.3)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _LanguageChip(
                  language: state.sourceLanguage,
                  onTap: () => _showLanguagePicker(context, isSource: true),
                ),
              ),
              const SizedBox(width: 8),
              _SwapButton(),
              const SizedBox(width: 8),
              Expanded(
                child: _LanguageChip(
                  language: state.targetLanguage,
                  onTap: () => _showLanguagePicker(context, isSource: false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context, {required bool isSource}) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final bloc = context.read<TranslatorBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.translatorSelectLanguage,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _supportedLanguages.map((lang) {
                    return ListTile(
                      leading: Text(
                        _languageFlag(lang),
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        _languageDisplayName(lang, l10n),
                        style: TextStyle(color: colors.textPrimary),
                      ),
                      onTap: () {
                        if (isSource) {
                          bloc.add(TranslatorSourceChanged(lang));
                        } else {
                          bloc.add(TranslatorTargetChanged(lang));
                        }
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final TranslateLanguage language;
  final VoidCallback onTap;

  const _LanguageChip({required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.glassColor.withOpacity(colors.glassOpacity),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.glassColor.withOpacity(colors.glassBorderOpacity),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_languageFlag(language), style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _languageDisplayName(language, l10n),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: () => context.read<TranslatorBloc>().add(TranslatorSwapLanguages()),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.swap_horiz_rounded, color: colors.primary, size: 22),
      ),
    );
  }
}

// ── Downloading view ──

class _DownloadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colors.primary),
          const SizedBox(height: 20),
          Text(
            l10n.translatorDownloading,
            style: TextStyle(color: colors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translatorDownloadingHint,
            style: TextStyle(color: colors.textSecondary.withOpacity(0.7), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Error view ──

class _ErrorView extends StatelessWidget {
  final String? message;
  const _ErrorView({this.message});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              message ?? l10n.error,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<TranslatorBloc>().add(TranslatorInit()),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Translation body (source + result) ──

class _TranslationBody extends StatelessWidget {
  final TextEditingController textController;
  const _TranslationBody({required this.textController});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<TranslatorBloc, TranslatorState>(
      builder: (context, state) {
        final displaySource = state.isListening
            ? (state.partialStt.isNotEmpty ? state.partialStt : '...')
            : state.sourceText;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Source text input card
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _languageDisplayName(state.sourceLanguage, l10n),
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (state.sourceText.isNotEmpty)
                          GestureDetector(
                            onTap: () => context.read<TranslatorBloc>().add(TranslatorClear()),
                            child: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (state.isListening || state.sourceText.isNotEmpty)
                      Text(
                        displaySource,
                        style: TextStyle(
                          color: state.isListening
                              ? colors.primary
                              : colors.textPrimary,
                          fontSize: 18,
                          fontStyle: state.isListening ? FontStyle.italic : FontStyle.normal,
                        ),
                      )
                    else
                      TextField(
                        controller: textController,
                        style: TextStyle(color: colors.textPrimary, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: l10n.translatorTypeHint,
                          hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: 5,
                        minLines: 2,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            context.read<TranslatorBloc>().add(TranslatorTextSubmitted(text));
                            textController.clear();
                          }
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Translation status
              if (state.status == TranslatorStatus.translating)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),

              // Translated text card
              if (state.translatedText.isNotEmpty)
                _GlassCard(
                  highlight: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _languageDisplayName(state.targetLanguage, l10n),
                            style: TextStyle(
                              color: colors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: state.translatedText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.translatorCopied),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Icon(Icons.copy_rounded, size: 18, color: colors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => context.read<TranslatorBloc>().add(TranslatorSpeak()),
                            child: Icon(Icons.volume_up_rounded, size: 20, color: colors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.translatedText,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Mic bar (bottom) ──

class _MicBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<TranslatorBloc, TranslatorState>(
      buildWhen: (p, c) => p.status != c.status,
      builder: (context, state) {
        if (!state.isReady && !state.isListening && state.status != TranslatorStatus.translating) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            top: 16,
          ),
          decoration: BoxDecoration(
            color: colors.surface.withOpacity(0.5),
            border: Border(
              top: BorderSide(color: colors.border.withOpacity(0.3)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isListening)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.translatorListening,
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () {
                  final bloc = context.read<TranslatorBloc>();
                  if (state.isListening) {
                    bloc.add(TranslatorStopListening());
                  } else {
                    bloc.add(TranslatorStartListening());
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: state.isListening ? 72 : 64,
                  height: state.isListening ? 72 : 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isListening ? colors.error : colors.primary,
                    boxShadow: state.isListening
                        ? [
                            BoxShadow(
                              color: colors.error.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: colors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                  ),
                  child: Icon(
                    state.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.isListening ? l10n.translatorTapToStop : l10n.translatorTapToSpeak,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Glass card ──

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool highlight;

  const _GlassCard({required this.child, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: highlight
                ? colors.primary.withOpacity(0.08)
                : colors.glassColor.withOpacity(colors.glassOpacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight
                  ? colors.primary.withOpacity(0.2)
                  : colors.glassColor.withOpacity(colors.glassBorderOpacity),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Supported languages ──

const _supportedLanguages = [
  TranslateLanguage.russian,
  TranslateLanguage.english,
  TranslateLanguage.german,
  TranslateLanguage.french,
  TranslateLanguage.spanish,
  TranslateLanguage.italian,
  TranslateLanguage.portuguese,
  TranslateLanguage.turkish,
  TranslateLanguage.chinese,
  TranslateLanguage.japanese,
  TranslateLanguage.korean,
  TranslateLanguage.arabic,
];

String _languageFlag(TranslateLanguage lang) {
  switch (lang) {
    case TranslateLanguage.russian:
      return '\u{1F1F7}\u{1F1FA}';
    case TranslateLanguage.english:
      return '\u{1F1EC}\u{1F1E7}';
    case TranslateLanguage.german:
      return '\u{1F1E9}\u{1F1EA}';
    case TranslateLanguage.french:
      return '\u{1F1EB}\u{1F1F7}';
    case TranslateLanguage.spanish:
      return '\u{1F1EA}\u{1F1F8}';
    case TranslateLanguage.italian:
      return '\u{1F1EE}\u{1F1F9}';
    case TranslateLanguage.portuguese:
      return '\u{1F1F5}\u{1F1F9}';
    case TranslateLanguage.turkish:
      return '\u{1F1F9}\u{1F1F7}';
    case TranslateLanguage.chinese:
      return '\u{1F1E8}\u{1F1F3}';
    case TranslateLanguage.japanese:
      return '\u{1F1EF}\u{1F1F5}';
    case TranslateLanguage.korean:
      return '\u{1F1F0}\u{1F1F7}';
    case TranslateLanguage.arabic:
      return '\u{1F1F8}\u{1F1E6}';
    default:
      return '\u{1F310}';
  }
}

String _languageDisplayName(TranslateLanguage lang, AppLocalizations l10n) {
  switch (lang) {
    case TranslateLanguage.russian:
      return l10n.translatorLangRu;
    case TranslateLanguage.english:
      return l10n.translatorLangEn;
    case TranslateLanguage.german:
      return l10n.translatorLangDe;
    case TranslateLanguage.french:
      return l10n.translatorLangFr;
    case TranslateLanguage.spanish:
      return l10n.translatorLangEs;
    case TranslateLanguage.italian:
      return l10n.translatorLangIt;
    case TranslateLanguage.portuguese:
      return l10n.translatorLangPt;
    case TranslateLanguage.turkish:
      return l10n.translatorLangTr;
    case TranslateLanguage.chinese:
      return l10n.translatorLangZh;
    case TranslateLanguage.japanese:
      return l10n.translatorLangJa;
    case TranslateLanguage.korean:
      return l10n.translatorLangKo;
    case TranslateLanguage.arabic:
      return l10n.translatorLangAr;
    default:
      return lang.bcpCode;
  }
}
