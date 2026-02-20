import 'package:equatable/equatable.dart';
import '../../domain/entities/tenant_entity.dart';

abstract class TenantEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TenantsLoadRequested extends TenantEvent {}

class TenantDetailRequested extends TenantEvent {
  final String tenantId;
  TenantDetailRequested(this.tenantId);
  @override
  List<Object?> get props => [tenantId];
}

class TenantCreateSubmitted extends TenantEvent {
  final Map<String, dynamic> data;
  TenantCreateSubmitted(this.data);
  @override
  List<Object?> get props => [data];
}

class TenantMemberInvited extends TenantEvent {
  final String tenantId;
  final String email;
  final TenantRole role;
  TenantMemberInvited({required this.tenantId, required this.email, required this.role});
  @override
  List<Object?> get props => [tenantId, email, role];
}

class TenantInviteAccepted extends TenantEvent {
  final String token;
  TenantInviteAccepted(this.token);
  @override
  List<Object?> get props => [token];
}

class TenantUpdateSubmitted extends TenantEvent {
  final String tenantId;
  final Map<String, dynamic> data;
  TenantUpdateSubmitted({required this.tenantId, required this.data});
  @override
  List<Object?> get props => [tenantId, data];
}

class TenantMemberRoleChanged extends TenantEvent {
  final String tenantId;
  final String memberId;
  final TenantRole role;
  TenantMemberRoleChanged({required this.tenantId, required this.memberId, required this.role});
  @override
  List<Object?> get props => [tenantId, memberId, role];
}

class TenantMemberRemoved extends TenantEvent {
  final String tenantId;
  final String userId;
  TenantMemberRemoved({required this.tenantId, required this.userId});
  @override
  List<Object?> get props => [tenantId, userId];
}

class TenantKybStartRequested extends TenantEvent {
  final String tenantId;
  TenantKybStartRequested(this.tenantId);
  @override
  List<Object?> get props => [tenantId];
}

class TenantKybSdkCompleted extends TenantEvent {
  final String tenantId;
  TenantKybSdkCompleted(this.tenantId);
  @override
  List<Object?> get props => [tenantId];
}
