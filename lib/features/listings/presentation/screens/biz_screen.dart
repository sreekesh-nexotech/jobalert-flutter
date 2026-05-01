import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../listings_controller.dart';
import '../widgets/listing_card.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/sort_control.dart';

/// Twin of `JobsScreen` for business opportunities — uses the biz query
/// provider, biz-specific filter set, and the same card widget which
/// re-renders the meta pills based on `Listing.type`.
class BizScreen extends ConsumerStatefulWidget {
  const BizScreen({super.key, required this.onScroll});
  final ValueChanged<double> onScroll;

  @override
  ConsumerState<BizScreen> createState() => _BizScreenState();
}

class _BizScreenState extends ConsumerState<BizScreen> {
  final _searchCtl = TextEditingController();

  static const _filters = ['All', 'Franchise', 'Investment', 'Partnership', 'Healthcare', 'Tech', 'Low Capital'];
  static const _sortOpts = ['Most Recent', 'Most Upvoted', 'Investment Low→High'];

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(bizQueryProvider);
    final async = ref.watch(bizListProvider);

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollUpdateNotification) widget.onScroll(n.metrics.pixels);
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _BizHeader(
              search: _searchCtl,
              activeFilter: query.filter,
              onSearch: (v) =>
                  ref.read(bizQueryProvider.notifier).state = query.copyWith(search: v),
              onFilter: (f) =>
                  ref.read(bizQueryProvider.notifier).state = query.copyWith(filter: f),
              filters: _filters,
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
                        ref.read(bizQueryProvider.notifier).state = query.copyWith(sort: v),
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
              child: Center(child: Text('Failed to load: $e', style: AppText.body)),
            ),
            data: (items) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ListingCard(
                      listing: items[i],
                      onOpen: () => context.push('/detail/biz/${items[i].uid}'),
                    ),
                  ),
                  childCount: items.length,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BizHeader extends StatelessWidget {
  const _BizHeader({
    required this.search,
    required this.activeFilter,
    required this.onSearch,
    required this.onFilter,
    required this.filters,
  });
  final TextEditingController search;
  final String activeFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onFilter;
  final List<String> filters;

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
          Text('Biz Opportunities', style: AppText.pageTitle),
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
                      hintText: 'Search opportunities, sectors…',
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
