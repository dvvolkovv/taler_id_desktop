import 'package:equatable/equatable.dart';
import '../../domain/entities/tenant_entity.dart';

abstract class TenantState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TenantInitial extends TenantState {}
class TenantLoading extends TenantState {}

class TenantsLoaded extends TenantState {
  final List<TenantEntity> tenants;
  TenantsLoaded(this.tenants);
  @override
  List<Object?> get props => [tenants];
}

class TenantDetailLoaded extends TenantState {
  final TenantEntity tenant;
  TenantDetailLoaded(this.tenant);
  @override
  List<Object?> get props => [tenant];
}

class TenantActionSuccess extends TenantState {
  final String message;
  TenantActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class TenantError extends TenantState {
  final String message;
  TenantError(this.message);
  @override
  List<Object?> get props => [message];
}
