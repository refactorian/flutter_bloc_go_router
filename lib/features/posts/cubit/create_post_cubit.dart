import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_exception.dart';
import '../../../data/models/post.dart';
import '../../../data/repositories/post_repository.dart';

enum FormSubmissionStatus { initial, submitting, success, failure }

class CreatePostState extends Equatable {
  final String title;
  final String body;
  final int userId;
  final String? titleError;
  final String? bodyError;
  final FormSubmissionStatus status;
  final Post? createdPost;
  final String? errorMessage;

  const CreatePostState({
    this.title = '',
    this.body = '',
    this.userId = 1,
    this.titleError,
    this.bodyError,
    this.status = FormSubmissionStatus.initial,
    this.createdPost,
    this.errorMessage,
  });

  bool get isValid =>
      title.trim().length >= 5 &&
      body.trim().length >= 10 &&
      titleError == null &&
      bodyError == null;

  CreatePostState copyWith({
    String? title,
    String? body,
    int? userId,
    String? Function()? titleError,
    String? Function()? bodyError,
    FormSubmissionStatus? status,
    Post? createdPost,
    String? errorMessage,
  }) {
    return CreatePostState(
      title: title ?? this.title,
      body: body ?? this.body,
      userId: userId ?? this.userId,
      titleError: titleError != null ? titleError() : this.titleError,
      bodyError: bodyError != null ? bodyError() : this.bodyError,
      status: status ?? this.status,
      createdPost: createdPost ?? this.createdPost,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    title,
    body,
    userId,
    titleError,
    bodyError,
    status,
    createdPost,
    errorMessage,
  ];
}

class CreatePostCubit extends Cubit<CreatePostState> {
  final PostRepository postRepository;

  CreatePostCubit({required this.postRepository})
    : super(const CreatePostState());

  void onTitleChanged(String value) {
    String? error;
    if (value.trim().isEmpty) {
      error = 'Title is required';
    } else if (value.trim().length < 5) {
      error = 'Title must be at least 5 characters';
    }
    emit(
      state.copyWith(
        title: value,
        titleError: () => error,
        status: FormSubmissionStatus.initial,
      ),
    );
  }

  void onBodyChanged(String value) {
    String? error;
    if (value.trim().isEmpty) {
      error = 'Content is required';
    } else if (value.trim().length < 10) {
      error = 'Content must be at least 10 characters';
    }
    emit(
      state.copyWith(
        body: value,
        bodyError: () => error,
        status: FormSubmissionStatus.initial,
      ),
    );
  }

  void onUserIdChanged(int userId) {
    emit(state.copyWith(userId: userId));
  }

  Future<void> submit() async {
    // Validate fields before submitting
    onTitleChanged(state.title);
    onBodyChanged(state.body);

    if (!state.isValid) return;
    if (isClosed) return;

    emit(
      state.copyWith(
        status: FormSubmissionStatus.submitting,
        errorMessage: null,
      ),
    );

    try {
      final post = await postRepository.createPost(
        title: state.title.trim(),
        body: state.body.trim(),
        userId: state.userId,
      );
      if (isClosed) return;

      emit(
        state.copyWith(status: FormSubmissionStatus.success, createdPost: post),
      );
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: FormSubmissionStatus.failure,
            errorMessage: e.message,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: FormSubmissionStatus.failure,
            errorMessage: 'Failed to create post. Please try again.',
          ),
        );
      }
    }
  }
}
