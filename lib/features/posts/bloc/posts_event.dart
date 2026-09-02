import 'package:equatable/equatable.dart';
import '../../../data/models/post.dart';

abstract class PostsEvent extends Equatable {
  const PostsEvent();

  @override
  List<Object?> get props => [];
}

/// Initial fetch or reload event
class PostsFetchRequested extends PostsEvent {
  final int? userId;
  final String? searchQuery;

  const PostsFetchRequested({this.userId, this.searchQuery});

  @override
  List<Object?> get props => [userId, searchQuery];
}

/// Event dispatched when user scrolls near the bottom of the list
class PostsNextPageRequested extends PostsEvent {
  const PostsNextPageRequested();
}

/// Event dispatched when searching or filtering
class PostsSearchChanged extends PostsEvent {
  final String query;

  const PostsSearchChanged({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Event dispatched when filtering posts by a specific user or clearing the filter
class PostsFilterByUserRequested extends PostsEvent {
  final int? userId;

  const PostsFilterByUserRequested({this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Event dispatched on pull-to-refresh
class PostsRefreshRequested extends PostsEvent {
  const PostsRefreshRequested();
}

/// Event dispatched when a new post is created
class PostAddedOptimistically extends PostsEvent {
  final Post post;

  const PostAddedOptimistically({required this.post});

  @override
  List<Object?> get props => [post];
}
