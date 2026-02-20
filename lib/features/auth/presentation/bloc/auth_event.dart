import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  LoginSubmitted({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;
  RegisterSubmitted({required this.email, required this.password, this.firstName, this.lastName});
  @override
  List<Object?> get props => [email, password, firstName, lastName];
}

class TwoFASubmitted extends AuthEvent {
  final String email;
  final String code;
  final String tempToken;
  TwoFASubmitted({required this.email, required this.code, required this.tempToken});
  @override
  List<Object?> get props => [email, code, tempToken];
}

class LogoutRequested extends AuthEvent {}
