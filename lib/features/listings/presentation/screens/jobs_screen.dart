import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../listings_controller.dart';
import '../widgets/listing_card.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/sort_control.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key, required this.onScroll});
  final ValueChanged<double> onScroll;

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  final _searchCtl = TextEditingController();

  static const _filters = ['All', 'Remote', 'Full-time', 'Entry Level', 'Design', 'Marketing', 'Tech'];
  static const _sortOpts = ['Most Recent', 'Most Upvoted', 'Salary High→Low'];

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(jobsQueryProvider);
    final async = ref.watch(jobsListProvider);

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollUpdateNotification) widget.onScroll(n.metrics.pixels);
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              title: 'Job Listings',
              hint: 'Search jobs, roles, companies…',
              search: _searchCtl,
              onSearch: (v) =>
                  ref.read(jobsQueryProvider.notifier).state = query.copyWith(search: v),
              filters: _filters,
              activeFilter: query.filter,
              onFilter: (f) =>
                  ref.read(jobsQueryProvider.notifier).state = query.copyWith(filter: f),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      async.when(
                        data: (l) => '${l.length} results',
                        loading: () => '…',
                        error: (_, __) => '0 results',
                      ),
                      style: AppText.captionMuted.copyWith(fontSize: 11, color: AppColors.ink400),
                    ),
                  ),
                  SortControl(
                    options: _sortOpts,
                    value: query.sort,
                    onChanged: (v) =>
                        ref.read(jobsQueryProvider.notifier).state = query.copyWith(sort: v),
                  ),
                ],
              ),
            ),
          ),
          async.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: SkeletonCard(),
                  ),
                  childCount: 3,
                ),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Failed to load: $e', style: AppText.body),
                ),
              ),
            ),
            data: (jobs) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: jobs.isEmpty
                  ? const SliverToBoxAdapter(child: _EmptyResults())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ListingCard(
                            listing: jobs[i],
                            onOpen: () => context.push('/detail/job/${jobs[i].uid}'),
                          ),
                        ),
                        childCount: jobs.length,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.hint,
    required this.search,
    required this.onSearch,
    required this.filters,
    required this.activeFilter,
    required this.onFilter,
  });

  final String title;
  final String hint;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final List<String> filters;
  final String activeFilter;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.ink50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.pageTitle),
          const SizedBox(height: 10),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 15, color: Color(0xFFC0C0C0)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: search,
                    onSubmitted: onSearch,
                    style: AppText.body.copyWith(fontSize: 13),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: AppText.body.copyWith(fontSize: 13, color: const Color(0xFFC0C0C0)),
                    ),
                  ),
                ),
                const Icon(Icons.tune, size: 15, color: Color(0xFF888888)),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = filters[i];
                final active = f == activeFilter;
                return GestureDetector(
                  onTap: () => onFilter(f),
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.ink900 : Colors.white,
                      border: Border.all(
                        color: active ? AppColors.ink900 : const Color(0xFFEBEBEB),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      f,
                      style: AppText.captionMuted.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: active ? Colors.white : const Color(0xFF666666),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.ink300),
          const SizedBox(height: 12),
          Text('No matches yet', style: AppText.h3),
          const SizedBox(height: 4),
          Text(
            'Try a different filter or search term.',
            style: AppText.captionMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
