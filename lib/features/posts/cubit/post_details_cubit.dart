import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_exception.dart';
import '../../../data/models/comment.dart';
import '../../../data/models/post.dart';
import '../../../data/repositories/post_repository.dart';

enum PostDetailsStatus { initial, loading, success, failure }

class PostDetailsState extends Equatable {
  final PostDetailsStatus status;
  final Post? post;
  final List<Comment> comments;
  final String? errorMessage;

  const PostDetailsState({
    this.status = PostDetailsStatus.initial,
    this.post,
    this.comments = const [],
    this.errorMessage,
  });

  PostDetailsState copyWith({
    PostDetailsStatus? status,
    Post? post,
    List<Comment>? comments,
    String? errorMessage,
  }) {
    return PostDetailsState(
      status: status ?? this.status,
      post: post ?? this.post,
      comments: comments ?? this.comments,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, post, comments, errorMessage];
}

class PostDetailsCubit extends Cubit<PostDetailsState> {
  final PostRepository postRepository;

  PostDetailsCubit({required this.postRepository})
    : super(const PostDetailsState());

  Future<void> fetchPostDetails(int postId) async {
    if (isClosed) return;
    emit(state.copyWith(status: PostDetailsStatus.loading, errorMessage: null));
    try {
      final results = await Future.wait([
        postRepository.getPostById(postId),
        postRepository.getPostComments(postId),
      ]);
      if (isClosed) return;

      final post = results[0] as Post;
      final comments = results[1] as List<Comment>;

      emit(
        state.copyWith(
          status: PostDetailsStatus.success,
          post: post,
          comments: comments,
        ),
      );
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PostDetailsStatus.failure,
            errorMessage: e.message,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PostDetailsStatus.failure,
            errorMessage: 'Failed to load post details.',
          ),
        );
      }
    }
  }
}
