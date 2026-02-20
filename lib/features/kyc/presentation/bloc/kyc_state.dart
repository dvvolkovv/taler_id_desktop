import 'package:equatable/equatable.dart';

abstract class KycState extends Equatable {
  @override
  List<Object?> get props => [];
}

class KycInitial extends KycState {}
class KycLoading extends KycState {}

class KycStatusLoaded extends KycState {
  final String status;
  final String? rejectionReason;
  final String? verifiedAt;
  KycStatusLoaded({required this.status, this.rejectionReason, this.verifiedAt});
  @override
  List<Object?> get props => [status, rejectionReason, verifiedAt];
}

class KycSdkReady extends KycState {
  final String sdkToken;
  KycSdkReady(this.sdkToken);
  @override
  List<Object?> get props => [sdkToken];
}

class KycSdkDone extends KycState {} // SDK finished, waiting for webhook
class KycError extends KycState {
  final String message;
  KycError(this.message);
  @override
  List<Object?> get props => [message];
}
