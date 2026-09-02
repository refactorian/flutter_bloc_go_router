import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_exception.dart';
import '../../../data/models/post.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';

enum UserDetailsStatus { initial, loading, success, failure }

class UserDetailsState extends Equatable {
  final UserDetailsStatus status;
  final User? user;
  final List<Post> posts;
  final String? errorMessage;

  const UserDetailsState({
    this.status = UserDetailsStatus.initial,
    this.user,
    this.posts = const [],
    this.errorMessage,
  });

  UserDetailsState copyWith({
    UserDetailsStatus? status,
    User? user,
    List<Post>? posts,
    String? errorMessage,
  }) {
    return UserDetailsState(
      status: status ?? this.status,
      user: user ?? this.user,
      posts: posts ?? this.posts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, posts, errorMessage];
}

class UserDetailsCubit extends Cubit<UserDetailsState> {
  final UserRepository userRepository;

  UserDetailsCubit({required this.userRepository})
    : super(const UserDetailsState());

  Future<void> fetchUserDetails(int userId) async {
    if (isClosed) return;
    emit(state.copyWith(status: UserDetailsStatus.loading, errorMessage: null));
    try {
      final results = await Future.wait([
        userRepository.getUserById(userId),
        userRepository.getUserPosts(userId),
      ]);
      if (isClosed) return;

      final user = results[0] as User;
      final posts = results[1] as List<Post>;

      emit(
        state.copyWith(
          status: UserDetailsStatus.success,
          user: user,
          posts: posts,
        ),
      );
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: UserDetailsStatus.failure,
            errorMessage: e.message,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: UserDetailsStatus.failure,
            errorMessage: 'Failed to load user details.',
          ),
        );
      }
    }
  }
}
