import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../router/route_names.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_event.dart';
import '../cubit/create_post_cubit.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CreatePostCubit(postRepository: context.read<PostRepository>()),
      child: const _CreatePostView(),
    );
  }
}

class _CreatePostView extends StatefulWidget {
  const _CreatePostView();

  @override
  State<_CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<_CreatePostView> {
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();

  @override
  void dispose() {
    _titleFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  void _onNavigateBack() {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BlocConsumer<CreatePostCubit, CreatePostState>(
        listener: (context, state) {
          if (state.status == FormSubmissionStatus.success &&
              state.createdPost != null) {
            AppFeedback.showSuccessSnackBar(
              context,
              'Post #${state.createdPost!.id} published! 🎉',
            );
            context.read<PostsBloc>().add(
              PostAddedOptimistically(post: state.createdPost!),
            );
            _onNavigateBack();
          } else if (state.status == FormSubmissionStatus.failure &&
              state.errorMessage != null) {
            AppFeedback.showErrorSnackBar(context, state.errorMessage!);
          }
        },
        builder: (context, state) {
          final isSubmitting = state.status == FormSubmissionStatus.submitting;

          return CustomScrollView(
            slivers: [
              // ── Gradient AppBar ─────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: _onNavigateBack,
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.gradientTeal,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const SafeArea(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 60, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Create New Post',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Share your ideas with the community.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Form ───────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Info Banner ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.info,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Submissions are validated locally before posting to JSONPlaceholder.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Title ────────────────────────────────────────────
                    _FormLabel('Post Title'),
                    const SizedBox(height: 8),
                    TextFormField(
                      focusNode: _titleFocus,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'e.g., Clean Architecture in Flutter',
                        errorText: state.titleError,
                        prefixIcon: const Icon(Icons.title_rounded),
                      ),
                      onChanged: (val) =>
                          context.read<CreatePostCubit>().onTitleChanged(val),
                      onFieldSubmitted: (_) => _bodyFocus.requestFocus(),
                    ),
                    const SizedBox(height: 20),

                    // ── Author ───────────────────────────────────────────
                    _FormLabel('Author'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: state.userId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      items: List.generate(10, (index) {
                        final id = index + 1;
                        return DropdownMenuItem(
                          value: id,
                          child: Text(
                            'User #$id',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }),
                      onChanged: isSubmitting
                          ? null
                          : (val) {
                              if (val != null) {
                                context.read<CreatePostCubit>().onUserIdChanged(
                                  val,
                                );
                              }
                            },
                    ),
                    const SizedBox(height: 20),

                    // ── Body ─────────────────────────────────────────────
                    _FormLabel('Post Content'),
                    const SizedBox(height: 8),
                    TextFormField(
                      focusNode: _bodyFocus,
                      enabled: !isSubmitting,
                      maxLines: 7,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Write the content of your post here…',
                        errorText: state.bodyError,
                        alignLabelWithHint: true,
                      ),
                      onChanged: (val) =>
                          context.read<CreatePostCubit>().onBodyChanged(val),
                    ),
                    const SizedBox(height: 32),

                    // ── Submit ────────────────────────────────────────────
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                context.read<CreatePostCubit>().submit();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Publish Post'),
                                ],
                              ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }
}
