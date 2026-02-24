import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {}

class ProfileUpdateSubmitted extends ProfileEvent {
  final Map<String, dynamic> data;
  const ProfileUpdateSubmitted(this.data);
  @override
  List<Object?> get props => [data];
}
