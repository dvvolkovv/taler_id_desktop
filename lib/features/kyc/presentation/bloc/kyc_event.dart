import 'package:equatable/equatable.dart';

abstract class KycEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class KycStatusRequested extends KycEvent {}
class KycStartRequested extends KycEvent {}
class KycSdkCompleted extends KycEvent {}
class KycSdkFailed extends KycEvent {
  final String errorCode;
  KycSdkFailed(this.errorCode);
  @override
  List<Object?> get props => [errorCode];
}

class KycApplicantDataRequested extends KycEvent {}
