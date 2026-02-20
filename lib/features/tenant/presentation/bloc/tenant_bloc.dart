import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_tenant_repository.dart';
import '../../../../core/api/api_exception.dart';
import 'tenant_event.dart';
import 'tenant_state.dart';

class TenantBloc extends Bloc<TenantEvent, TenantState> {
  final ITenantRepository repo;

  TenantBloc({required this.repo}) : super(TenantInitial()) {
    on<TenantsLoadRequested>(_onLoad);
    on<TenantDetailRequested>(_onDetail);
    on<TenantCreateSubmitted>(_onCreate);
    on<TenantMemberInvited>(_onInvite);
    on<TenantInviteAccepted>(_onAcceptInvite);
  }

  Future<void> _onLoad(TenantsLoadRequested event, Emitter<TenantState> emit) async {
    emit(TenantLoading());
    try {
      final tenants = await repo.getMyTenants();
      emit(TenantsLoaded(tenants));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError('Не удалось загрузить список организаций'));
    }
  }

  Future<void> _onDetail(TenantDetailRequested event, Emitter<TenantState> emit) async {
    emit(TenantLoading());
    try {
      final tenant = await repo.getTenant(event.tenantId);
      emit(TenantDetailLoaded(tenant));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError('Не удалось загрузить данные организации'));
    }
  }

  Future<void> _onCreate(TenantCreateSubmitted event, Emitter<TenantState> emit) async {
    emit(TenantLoading());
    try {
      await repo.createTenant(event.data);
      final tenants = await repo.getMyTenants();
      emit(TenantsLoaded(tenants));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError('Не удалось создать организацию'));
    }
  }

  Future<void> _onInvite(TenantMemberInvited event, Emitter<TenantState> emit) async {
    try {
      await repo.inviteMember(
        tenantId: event.tenantId,
        email: event.email,
        role: event.role,
      );
      emit(TenantActionSuccess('Приглашение отправлено на ${event.email}'));
      add(TenantDetailRequested(event.tenantId));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError('Не удалось отправить приглашение'));
    }
  }

  Future<void> _onAcceptInvite(TenantInviteAccepted event, Emitter<TenantState> emit) async {
    emit(TenantLoading());
    try {
      await repo.acceptInvite(event.token);
      final tenants = await repo.getMyTenants();
      emit(TenantsLoaded(tenants));
    } on ApiException catch (e) {
      emit(TenantError(e.message));
    } catch (_) {
      emit(TenantError('Не удалось принять приглашение'));
    }
  }
}
