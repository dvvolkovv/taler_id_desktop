import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../../../../core/api/api_exception.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final IProfileRepository repo;

  ProfileBloc({required this.repo}) : super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
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
}
