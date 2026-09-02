import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_exception.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';

enum UsersStatus { initial, loading, success, failure }

class UsersState extends Equatable {
  final UsersStatus status;
  final List<User> users;
  final List<User> filteredUsers;
  final String searchQuery;
  final String? errorMessage;

  const UsersState({
    this.status = UsersStatus.initial,
    this.users = const [],
    this.filteredUsers = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  UsersState copyWith({
    UsersStatus? status,
    List<User>? users,
    List<User>? filteredUsers,
    String? searchQuery,
    String? errorMessage,
  }) {
    return UsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    users,
    filteredUsers,
    searchQuery,
    errorMessage,
  ];
}

class UsersCubit extends Cubit<UsersState> {
  final UserRepository userRepository;

  UsersCubit({required this.userRepository}) : super(const UsersState());

  Future<void> fetchUsers() async {
    if (isClosed) return;
    emit(state.copyWith(status: UsersStatus.loading, errorMessage: null));
    try {
      final users = await userRepository.getUsers();
      if (isClosed) return;
      final filtered = _applySearch(users, state.searchQuery);
      emit(
        state.copyWith(
          status: UsersStatus.success,
          users: users,
          filteredUsers: filtered,
        ),
      );
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(status: UsersStatus.failure, errorMessage: e.message),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: UsersStatus.failure,
            errorMessage: 'An unexpected error occurred while fetching users.',
          ),
        );
      }
    }
  }

  void searchUsers(String query) {
    final filtered = _applySearch(state.users, query);
    emit(state.copyWith(searchQuery: query, filteredUsers: filtered));
  }

  List<User> _applySearch(List<User> users, String query) {
    if (query.trim().isEmpty) return users;
    final lower = query.toLowerCase();
    return users.where((u) {
      return u.name.toLowerCase().contains(lower) ||
          u.username.toLowerCase().contains(lower) ||
          u.email.toLowerCase().contains(lower);
    }).toList();
  }
}
