import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_kyc_repository.dart';
import '../../../../core/api/api_exception.dart';
import 'kyc_event.dart';
import 'kyc_state.dart';

class KycBloc extends Bloc<KycEvent, KycState> {
  final IKycRepository repo;

  KycBloc({required this.repo}) : super(KycInitial()) {
    on<KycStatusRequested>(_onStatus);
    on<KycStartRequested>(_onStart);
    on<KycSdkCompleted>(_onSdkComplete);
    on<KycSdkFailed>(_onSdkFailed);
    on<KycApplicantDataRequested>(_onApplicantData);
  }

  Future<void> _onStatus(KycStatusRequested event, Emitter<KycState> emit) async {
    emit(KycLoading());
    try {
      final data = await repo.getKycStatus();
      final status = data['status'] as String;
      emit(KycStatusLoaded(
        status: status,
        rejectionReason: data['rejectionReason'] as String?,
        verifiedAt: data['verifiedAt'] as String?,
      ));
      // Auto-fetch applicant data when verified
      if (status == 'VERIFIED') {
        add(KycApplicantDataRequested());
      }
    } on ApiException catch (e) {
      emit(KycError(e.message));
    } catch (_) {
      emit(KycError('Не удалось загрузить статус верификации'));
    }
  }

  Future<void> _onApplicantData(KycApplicantDataRequested event, Emitter<KycState> emit) async {
    final currentState = state;
    String status = 'VERIFIED';
    String? verifiedAt;
    if (currentState is KycStatusLoaded) {
      status = currentState.status;
      verifiedAt = currentState.verifiedAt;
    }
    emit(KycApplicantDataLoading(status: status, verifiedAt: verifiedAt));
    try {
      final data = await repo.getApplicantData();
      emit(KycStatusLoaded(
        status: status,
        verifiedAt: verifiedAt,
        applicantData: data,
      ));
    } on ApiException catch (e) {
      emit(KycError(e.message));
    } catch (_) {
      emit(KycError('Не удалось загрузить данные верификации'));
    }
  }

  Future<void> _onStart(KycStartRequested event, Emitter<KycState> emit) async {
    emit(KycLoading());
    try {
      final token = await repo.startKyc();
      emit(KycSdkReady(token));
    } on ApiException catch (e) {
      emit(KycError(e.message));
    } catch (_) {
      emit(KycError('Не удалось запустить верификацию'));
    }
  }

  Future<void> _onSdkComplete(KycSdkCompleted event, Emitter<KycState> emit) async {
    emit(KycSdkDone());
  }

  Future<void> _onSdkFailed(KycSdkFailed event, Emitter<KycState> emit) async {
    emit(KycError('Ошибка верификации: ${event.errorCode}'));
  }
}
