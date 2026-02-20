import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserEntity user;
  ProfileLoaded(this.user);
  @override
  List<Object?> get props => [user];
}

class ProfileUpdating extends ProfileState {
  final UserEntity user;
  ProfileUpdating(this.user);
  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;
  final UserEntity? user; // keep stale data
  ProfileError({required this.message, this.user});
  @override
  List<Object?> get props => [message, user];
}
