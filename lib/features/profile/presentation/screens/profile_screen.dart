import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/utils/countries.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfileLoadRequested());
  }

  Color _kycColor(KycStatus status) {
    switch (status) {
      case KycStatus.verified: return AppColors.primary;
      case KycStatus.pending: return AppColors.warning;
      case KycStatus.rejected: return AppColors.error;
      case KycStatus.unverified: return AppColors.textSecondary;
    }
  }

  String _kycLabel(KycStatus status, AppLocalizations l10n) {
    switch (status) {
      case KycStatus.verified: return l10n.kycVerified;
      case KycStatus.pending: return l10n.kycPending;
      case KycStatus.rejected: return l10n.kycRejected;
      case KycStatus.unverified: return l10n.kycUnverified;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: const [],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return _buildSkeleton();
          }

          final user = state is ProfileLoaded
              ? state.user
              : state is ProfileUpdating
                  ? state.user
                  : state is ProfileError
                      ? state.user
                      : null;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state is ProfileError ? state.message : l10n.loadError,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileBloc>().add(ProfileLoadRequested()),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => context.read<ProfileBloc>().add(ProfileLoadRequested()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar + name
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(
                          _initials(user),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fullName(user),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 8),
                            StatusBadge(
                              label: _kycLabel(user.kycStatus, l10n),
                              color: _kycColor(user.kycStatus),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Personal info
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.personalData, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      _infoRow(Icons.phone_outlined, l10n.phone, user.phone ?? l10n.notSpecified),
                      const Divider(color: AppColors.border, height: 1),
                      _infoRow(Icons.flag_outlined, l10n.country, _countryDisplayName(user.country) ?? l10n.notSpecifiedFemale),
                      const Divider(color: AppColors.border, height: 1),
                      _infoRow(Icons.cake_outlined, l10n.dateOfBirth, _formatDateOfBirth(user.dateOfBirth) ?? l10n.notSpecifiedFemale),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _initials(UserEntity user) {
    final first = user.firstName?.isNotEmpty == true ? user.firstName![0] : '';
    final last = user.lastName?.isNotEmpty == true ? user.lastName![0] : '';
    return (first + last).toUpperCase().isEmpty ? user.email[0].toUpperCase() : (first + last).toUpperCase();
  }

  String _fullName(UserEntity user) {
    final parts = [user.firstName, user.lastName].where((s) => s != null && s.isNotEmpty).toList();
    return parts.isEmpty ? user.email : parts.join(' ');
  }

  String? _formatDateOfBirth(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  String? _countryDisplayName(String? code) {
    if (code == null || code.isEmpty) return null;
    final locale = Localizations.localeOf(context).languageCode;
    return countryName(code, locale);
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const Spacer(),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      );

  Widget _buildSkeleton() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppCard(
              child: Row(
                children: [
                  const SkeletonBox(width: 64, height: 64),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    SkeletonBox(width: 140, height: 18),
                    SizedBox(height: 8),
                    SkeletonBox(width: 100, height: 14),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const AppCard(child: SkeletonBox(width: double.infinity, height: 120)),
          ],
        ),
      );
}
