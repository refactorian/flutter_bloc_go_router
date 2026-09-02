import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/post.dart';
import '../../../router/route_names.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../favorites/cubit/favorites_cubit.dart';
import '../../history/cubit/history_cubit.dart';
import '../../posts/bloc/posts_bloc.dart';
import '../../posts/bloc/posts_event.dart';
import '../../users/cubit/users_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = context.watch<AuthCubit>().state;
    final favCount = context.watch<FavoritesCubit>().state.favoriteIds.length;
    final userCount = context.watch<UsersCubit>().state.users.length;
    final postsState = context.watch<PostsBloc>().state;
    final historyState = context.watch<HistoryCubit>().state;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final usersFuture = context.read<UsersCubit>().fetchUsers();
          context.read<PostsBloc>().add(const PostsRefreshRequested());
          context.read<HistoryCubit>().loadRecentHistory();
          await usersFuture;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Floating App Bar ──────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.gradientPurple,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.flutter_dash,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Flutter Architecture Hub',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0D0D1A),
                    ),
                  ),
                ],
              ),
              actions: [
                _IconBadge(
                  icon: Icons.bookmark_rounded,
                  color: AppColors.warning,
                  badgeCount: favCount,
                  onTap: () => context.push(AppRoutes.favorites),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Hero Banner ──────────────────────────────────────────
                  _HeroBanner(authState: authState),
                  const SizedBox(height: 16),

                  // ── Live Stat Cards ──────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _GradientStatCard(
                          gradient: AppColors.gradientIndigo,
                          icon: Icons.people_alt_rounded,
                          label: 'Authors',
                          value: userCount > 0 ? '$userCount' : '10',
                          onTap: () => context.go(AppRoutes.users),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GradientStatCard(
                          gradient: AppColors.gradientCoral,
                          icon: Icons.article_rounded,
                          label: 'Posts',
                          value: postsState.posts.isNotEmpty
                              ? '${postsState.posts.length}'
                              : '100',
                          onTap: () => context.go(AppRoutes.posts),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GradientStatCard(
                          gradient: AppColors.gradientAmber,
                          icon: Icons.bookmark_rounded,
                          label: 'Saved',
                          value: '$favCount',
                          onTap: () => context.push(AppRoutes.favorites),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Recently Viewed ──────────────────────────────────────
                  if (historyState.recentPosts.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Recently Viewed',
                      actionLabel: 'Clear',
                      onAction: () =>
                          context.read<HistoryCubit>().clearHistory(),
                    ),
                    const SizedBox(height: 8),
                    for (
                      int i = 0;
                      i < historyState.recentPosts.length;
                      i++
                    ) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _RecentPostItem(post: historyState.recentPosts[i]),
                    ],
                    const SizedBox(height: 20),
                  ],

                  // ── Feature Grid ─────────────────────────────────────────
                  _SectionHeader(title: 'Explore Features'),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.3,
                    children: [
                      _FeatureCard(
                        gradient: AppColors.gradientIndigo,
                        icon: Icons.people_alt_rounded,
                        title: 'Users Directory',
                        subtitle: 'Authors & Search',
                        onTap: () => context.go(AppRoutes.users),
                      ),
                      _FeatureCard(
                        gradient: AppColors.gradientCoral,
                        icon: Icons.article_rounded,
                        title: 'Posts Feed',
                        subtitle: 'BLoC + Pagination',
                        onTap: () => context.go(AppRoutes.posts),
                      ),
                      _FeatureCard(
                        gradient: AppColors.gradientAmber,
                        icon: Icons.bookmark_rounded,
                        title: 'Bookmarks ($favCount)',
                        subtitle: 'Saved storage',
                        onTap: () => context.push(AppRoutes.favorites),
                      ),
                      _FeatureCard(
                        gradient: AppColors.gradientTeal,
                        icon: Icons.post_add_rounded,
                        title: 'Create Post',
                        subtitle: 'Form & Auth Guard',
                        onTap: () => context.push(AppRoutes.createPost),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Architecture Overview ─────────────────────────────────
                  _ArchitectureCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Private sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int badgeCount;
  final VoidCallback onTap;

  const _IconBadge({
    required this.icon,
    required this.color,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon, color: color),
          onPressed: onTap,
        ),
        if (badgeCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final AuthState authState;

  const _HeroBanner({required this.authState});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF48D6F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + greeting
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.flutter_dash,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  authState.isAuthenticated
                      ? 'Welcome back,\n${authState.username}! 👋'
                      : 'Flutter BLoC\n& GoRouter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'GoRouter · BLoC/Cubit · Repositories · Pagination · Debounced Search · Bookmarks · Forms',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Pill tags
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _PillTag('GoRouter'),
              _PillTag('BLoC/Cubit'),
              _PillTag('Dio'),
              _PillTag('SharedPrefs'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final String label;

  const _PillTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GradientStatCard extends StatelessWidget {
  final List<Color> gradient;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _GradientStatCard({
    required this.gradient,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class _RecentPostItem extends StatelessWidget {
  final Post post;

  const _RecentPostItem({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFav = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.state.isFavorite(post.id),
    );
    final colors = AppColors.avatarGradientFor(post.id);

    return InkWell(
      onTap: () => context.push(AppRoutes.postDetailsPath(post.id)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '#${post.id}',
                  style: const TextStyle(
                    fontSize: 11,
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
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Author #${post.userId}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context
                            .read<FavoritesCubit>()
                            .toggleFavorite(post.id),
                        child: Icon(
                          isFav
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isFav
                              ? AppColors.warning
                              : (isDark ? Colors.white38 : Colors.black38),
                          size: 18,
                        ),
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

class _FeatureCard extends StatelessWidget {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchitectureCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.gradientPurple,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Architecture Layer Flow',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LayerRow(
            step: 'UI (Views)',
            description:
                'Dispatches events, debounces search, handles safe navigation.',
            color: AppColors.gradientPurple[0],
          ),
          _LayerRow(
            step: 'Bloc / Cubit',
            description:
                'Manages pagination, forms, bookmarks, and theme switching.',
            color: AppColors.gradientCyan[0],
          ),
          _LayerRow(
            step: 'Repositories',
            description: 'Coordinates network data, caches, and local storage.',
            color: AppColors.gradientTeal[0],
          ),
          _LayerRow(
            step: 'Service / Dio',
            description:
                'HTTP client with timeouts, safe logging, error mapping.',
            color: AppColors.gradientAmber[0],
          ),
          _LayerRow(
            step: 'API & Storage',
            description:
                'JSONPlaceholder REST API & SharedPreferences persistence.',
            color: AppColors.gradientCoral[0],
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  final String step;
  final String description;
  final Color color;
  final bool isLast;

  const _LayerRow({
    required this.step,
    required this.description,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
