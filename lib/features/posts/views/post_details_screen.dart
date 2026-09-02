import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../data/models/comment.dart';
import '../../../data/models/post.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../router/route_names.dart';
import '../../favorites/cubit/favorites_cubit.dart';
import '../../history/cubit/history_cubit.dart';
import '../cubit/post_details_cubit.dart';

class PostDetailsScreen extends StatefulWidget {
  final int postId;

  const PostDetailsScreen({super.key, required this.postId});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Record view in recently viewed history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HistoryCubit>().recordViewedPost(widget.postId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PostDetailsCubit(postRepository: context.read<PostRepository>())
            ..fetchPostDetails(widget.postId),
      child: _PostDetailsView(postId: widget.postId),
    );
  }
}

class _PostDetailsView extends StatelessWidget {
  final int postId;

  const _PostDetailsView({required this.postId});

  void _onNavigateBack(BuildContext context) {
    try {
      if (context.canPop()) {
        context.pop();
        return;
      }
    } catch (_) {}
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.go(AppRoutes.posts);
      } catch (_) {}
    }
  }

  void _copyPostToClipboard(BuildContext context, Post post) {
    final text = '${post.title}\n\n${post.body}';
    Clipboard.setData(ClipboardData(text: text));
    AppFeedback.showSuccessSnackBar(
      context,
      'Post details copied to clipboard!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFav = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.state.isFavorite(postId),
    );
    final accentColors = AppColors.avatarGradientFor(postId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Post #$postId Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _onNavigateBack(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy Post',
            onPressed: () {
              final post = context.read<PostDetailsCubit>().state.post;
              if (post != null) {
                _copyPostToClipboard(context, post);
              }
            },
          ),
          IconButton(
            icon: Icon(
              isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isFav ? AppColors.warning : null,
            ),
            tooltip: isFav ? 'Remove Bookmark' : 'Bookmark Post',
            onPressed: () {
              context.read<FavoritesCubit>().toggleFavorite(postId);
              AppFeedback.showInfoSnackBar(
                context,
                isFav
                    ? 'Post removed from bookmarks.'
                    : 'Post added to bookmarks!',
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.accent,
            ),
            tooltip: 'Delete Post',
            onPressed: () async {
              final confirmed = await AppDialogs.showConfirmDialog(
                context,
                title: 'Delete Post',
                message:
                    'Are you sure you want to delete post #$postId? This action cannot be undone.',
                confirmLabel: 'Delete',
                isDestructive: true,
              );
              if (confirmed && context.mounted) {
                await context.read<PostRepository>().deletePost(postId);
                if (context.mounted) {
                  AppFeedback.showSuccessSnackBar(
                    context,
                    'Post #$postId deleted.',
                  );
                  _onNavigateBack(context);
                }
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<PostDetailsCubit, PostDetailsState>(
        builder: (context, state) {
          switch (state.status) {
            case PostDetailsStatus.initial:
            case PostDetailsStatus.loading:
              return const AppLoadingIndicator(
                message: 'Loading post content and comments...',
              );

            case PostDetailsStatus.failure:
              return AppErrorState(
                message: state.errorMessage ?? 'Failed to load post.',
                onRetry: () =>
                    context.read<PostDetailsCubit>().fetchPostDetails(postId),
              );

            case PostDetailsStatus.success:
              final post = state.post;
              if (post == null) {
                return AppErrorState(
                  message: 'Post not found.',
                  onRetry: () =>
                      context.read<PostDetailsCubit>().fetchPostDetails(postId),
                );
              }
              final comments = state.comments;

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    context.read<PostDetailsCubit>().fetchPostDetails(postId),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Main Post Card ─────────────────────────────────────
                      _PostHeaderCard(
                        post: post,
                        accentColors: accentColors,
                        onCopy: () => _copyPostToClipboard(context, post),
                      ),
                      const SizedBox(height: 24),

                      // ── Comments Section Header ────────────────────────────
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.gradientPurple,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Comments (${comments.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (comments.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'No comments yet for this post.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return _CommentCard(comment: comment, index: index);
                          },
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

class _PostHeaderCard extends StatelessWidget {
  final Post post;
  final List<Color> accentColors;
  final VoidCallback onCopy;

  const _PostHeaderCard({
    required this.post,
    required this.accentColors,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient Top Accent Strip ──────────────────────────────────
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: accentColors),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColors[0].withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Post #${post.id}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: accentColors[0],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.push(AppRoutes.userDetailsPath(post.userId));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Author #${post.userId}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Body
                Text(
                  post.body,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.6,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 18),
                Divider(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                const SizedBox(height: 8),

                // Copy Action Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    label: const Text('Copy Post Text'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: onCopy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final Comment comment;
  final int index;

  const _CommentCard({required this.comment, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarColors = AppColors.avatarGradientFor(comment.id + index);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: avatarColors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    comment.name.isNotEmpty
                        ? comment.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.email,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.body,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
