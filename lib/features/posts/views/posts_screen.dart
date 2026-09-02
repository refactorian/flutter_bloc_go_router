import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_shimmer_skeleton.dart';
import '../../../data/models/post.dart';
import '../../../router/route_names.dart';
import '../../favorites/cubit/favorites_cubit.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_event.dart';
import '../bloc/posts_state.dart';

class PostsScreen extends StatefulWidget {
  final int? initialUserId;

  const PostsScreen({super.key, this.initialUserId});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(
    duration: const Duration(milliseconds: 300),
  );

  @override
  void initState() {
    super.initState();
    context.read<PostsBloc>().add(
      PostsFetchRequested(userId: widget.initialUserId),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PostsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUserId != widget.initialUserId) {
      context.read<PostsBloc>().add(
        PostsFetchRequested(userId: widget.initialUserId),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !context.read<PostsBloc>().state.isLoadingMore) {
      context.read<PostsBloc>().add(const PostsNextPageRequested());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    return _scrollController.offset >=
        _scrollController.position.maxScrollExtent * 0.85;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_rounded, color: AppColors.warning),
            tooltip: 'View Bookmarks',
            onPressed: () => context.push(AppRoutes.favorites),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Feed',
            onPressed: () =>
                context.read<PostsBloc>().add(const PostsRefreshRequested()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Post',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => context.push(AppRoutes.createPost),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // ── Search Bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search posts by title or keyword…',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<PostsBloc>().add(
                            const PostsSearchChanged(query: ''),
                          );
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E32) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                _debouncer.run(() {
                  context.read<PostsBloc>().add(
                    PostsSearchChanged(query: value),
                  );
                });
              },
            ),
          ),

          // ── Filter Banner ─────────────────────────────────────────────────
          BlocBuilder<PostsBloc, PostsState>(
            buildWhen: (prev, curr) =>
                prev.activeFilterUserId != curr.activeFilterUserId,
            builder: (context, state) {
              if (state.activeFilterUserId == null) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.secondary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_alt_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Author: User #${state.activeFilterUserId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.go(AppRoutes.posts);
                        context.read<PostsBloc>().add(
                          const PostsFilterByUserRequested(userId: null),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Posts List ────────────────────────────────────────────────────
          Expanded(
            child: BlocConsumer<PostsBloc, PostsState>(
              listener: (context, state) {
                if (state.paginationErrorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.paginationErrorMessage!),
                      action: SnackBarAction(
                        label: 'Retry',
                        onPressed: () {
                          context.read<PostsBloc>().add(
                            const PostsNextPageRequested(),
                          );
                        },
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                switch (state.status) {
                  case PostsStatus.initial:
                  case PostsStatus.loading:
                    return const AppListSkeleton(count: 6);

                  case PostsStatus.failure:
                    return AppErrorState(
                      message:
                          state.errorMessage ?? 'Failed to load posts feed.',
                      onRetry: () {
                        context.read<PostsBloc>().add(
                          PostsFetchRequested(userId: state.activeFilterUserId),
                        );
                      },
                    );

                  case PostsStatus.success:
                    if (state.filteredPosts.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.article_outlined,
                        title: 'No Posts Found',
                        message: state.searchQuery.isNotEmpty
                            ? 'No post matches "${state.searchQuery}".'
                            : 'No posts available to display.',
                        actionLabel: state.searchQuery.isNotEmpty
                            ? 'Clear Search'
                            : null,
                        onAction: state.searchQuery.isNotEmpty
                            ? () {
                                _searchController.clear();
                                context.read<PostsBloc>().add(
                                  const PostsSearchChanged(query: ''),
                                );
                                setState(() {});
                              }
                            : null,
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        context.read<PostsBloc>().add(
                          const PostsRefreshRequested(),
                        );
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount:
                            state.filteredPosts.length +
                            (state.isLoadingMore || state.hasReachedMax
                                ? 1
                                : 0),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index == state.filteredPosts.length) {
                            if (state.isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            if (state.hasReachedMax &&
                                state.filteredPosts.length > 8) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      '🎉 You\'ve reached the end!',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          return _PostCard(post: state.filteredPosts[index]);
                        },
                      ),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final Post post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFav = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.state.isFavorite(post.id),
    );
    final accentColors = AppColors.avatarGradientFor(post.id);

    return GestureDetector(
      onTap: () => context.pushNamed(
        AppRoutes.postDetailsName,
        pathParameters: {'id': post.id.toString()},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Colour top strip ───────────────────────────────────────────
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: accentColors),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ────────────────────────────────────────────
                  Row(
                    children: [
                      // Post ID badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accentColors[0].withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${post.id}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: accentColors[0],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Author chip
                      GestureDetector(
                        onTap: () => context.push(
                          AppRoutes.userDetailsPath(post.userId),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_rounded,
                                size: 11,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'User ${post.userId}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Bookmark icon
                      GestureDetector(
                        onTap: () => context
                            .read<FavoritesCubit>()
                            .toggleFavorite(post.id),
                        child: Icon(
                          isFav
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isFav ? AppColors.warning : Colors.grey,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ── Title ─────────────────────────────────────────────────
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // ── Body preview ──────────────────────────────────────────
                  Text(
                    post.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Footer ────────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Read Discussion',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accentColors[0],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: accentColors[0],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
