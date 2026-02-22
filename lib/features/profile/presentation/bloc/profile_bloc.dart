import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../../../../core/api/api_exception.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final IProfileRepository repo;

  ProfileBloc({required this.repo}) : super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileDocumentUpload>(_onUpload);
    on<ProfileDocumentDelete>(_onDelete);
  }

  Future<void> _onLoad(ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final user = await repo.getProfile();
      emit(ProfileLoaded(user));
    } on ApiException catch (e) {
      emit(ProfileError(message: e.message));
    } catch (e) {
      emit(ProfileError(message: 'Не удалось загрузить профиль'));
    }
  }

  Future<void> _onUpload(ProfileDocumentUpload event, Emitter<ProfileState> emit) async {
    final current = state is ProfileLoaded ? (state as ProfileLoaded).user : null;
    if (current != null) emit(ProfileUpdating(current));
    try {
      final doc = await repo.uploadDocument(file: event.file, type: event.type);
      final updated = current?.copyWith(
        documents: [...(current.documents ?? []), doc],
      );
      if (updated != null) emit(ProfileLoaded(updated));
    } on ApiException catch (e) {
      emit(ProfileError(message: e.message, user: current));
    } catch (e) {
      emit(ProfileError(message: 'Не удалось загрузить документ', user: current));
    }
  }

  Future<void> _onDelete(ProfileDocumentDelete event, Emitter<ProfileState> emit) async {
    final current = state is ProfileLoaded ? (state as ProfileLoaded).user : null;
    if (current == null) return;
    emit(ProfileUpdating(current));
    try {
      await repo.deleteDocument(event.documentId);
      final updated = current.copyWith(
        documents: current.documents?.where((d) => d.id != event.documentId).toList(),
      );
      emit(ProfileLoaded(updated));
    } on ApiException catch (e) {
      emit(ProfileError(message: e.message, user: current));
    } catch (e) {
      emit(ProfileError(message: 'Не удалось удалить документ', user: current));
    }
  }
}
