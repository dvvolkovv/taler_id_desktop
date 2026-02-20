import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {}

class ProfileUpdateSubmitted extends ProfileEvent {
  final Map<String, dynamic> data;
  ProfileUpdateSubmitted(this.data);
  @override
  List<Object?> get props => [data];
}

class ProfileDocumentUpload extends ProfileEvent {
  final File file;
  final DocumentType type;
  ProfileDocumentUpload({required this.file, required this.type});
  @override
  List<Object?> get props => [file.path, type];
}

class ProfileDocumentDelete extends ProfileEvent {
  final String documentId;
  ProfileDocumentDelete(this.documentId);
  @override
  List<Object?> get props => [documentId];
}
