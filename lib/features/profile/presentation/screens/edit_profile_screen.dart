import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/utils/countries.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../domain/entities/user_entity.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedCountry;
  DateTime? _dateOfBirth;
  bool _initialized = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _dateCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  void _initialize(UserEntity user) {
    if (_initialized) return;
    _firstNameCtrl.text = user.firstName ?? '';
    _lastNameCtrl.text = user.lastName ?? '';
    _phoneCtrl.text = user.phone ?? '';
    _selectedCountry = user.country;
    if (_selectedCountry != null) {
      final locale = Localizations.localeOf(context).languageCode;
      _countryCtrl.text = countryName(_selectedCountry, locale) ?? _selectedCountry!;
    }
    if (user.dateOfBirth != null) {
      _dateOfBirth = DateTime.tryParse(user.dateOfBirth!);
      if (_dateOfBirth != null) {
        _dateCtrl.text = _formatDate(_dateOfBirth!);
      }
    }
    _initialized = true;
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.card,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dateCtrl.text = _formatDate(picked);
      });
    }
  }

  void _showCountryPicker() {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => StatefulBuilder(
          builder: (ctx, setModalState) {
            final query = searchCtrl.text.toLowerCase();
            final filtered = allCountries.where((c) {
              if (query.isEmpty) return true;
              return c.nameEn.toLowerCase().contains(query) ||
                  c.nameRu.toLowerCase().contains(query) ||
                  c.code.toLowerCase().contains(query);
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    l10n.country,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: TextField(
                    controller: searchCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: l10n.search,
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final country = filtered[i];
                      final isSelected = country.code == _selectedCountry;
                      return ListTile(
                        title: Text(
                          country.name(locale),
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                            : Text(
                                country.code,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                        onTap: () {
                          setState(() {
                            _selectedCountry = country.code;
                            _countryCtrl.text = country.name(locale);
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.editProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded && _initialized) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.profileUpdated), backgroundColor: AppColors.primary),
            );
            context.pop();
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          final user = state is ProfileLoaded
              ? state.user
              : state is ProfileUpdating
                  ? state.user
                  : null;

          if (user != null) _initialize(user);
          final loading = state is ProfileUpdating;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(labelText: l10n.firstName),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(labelText: l10n.lastName),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _dateCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: l10n.dateOfBirth,
                          prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary),
                          hintText: 'DD.MM.YYYY',
                          hintStyle: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showCountryPicker,
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _countryCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: l10n.country,
                          prefixIcon: const Icon(Icons.flag_outlined, color: AppColors.textSecondary),
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  LoadingButton(
                    text: l10n.save,
                    loading: loading,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final data = <String, dynamic>{
                          'firstName': _firstNameCtrl.text.trim(),
                          'lastName': _lastNameCtrl.text.trim(),
                          if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
                          if (_selectedCountry != null) 'country': _selectedCountry,
                          if (_dateOfBirth != null) 'dateOfBirth': _dateOfBirth!.toIso8601String().split('T').first,
                        };
                        context.read<ProfileBloc>().add(ProfileUpdateSubmitted(data));
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
