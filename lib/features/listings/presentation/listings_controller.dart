import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/listings_repository.dart';
import '../data/models/listing.dart';

/// Filter+sort+search state for one listing tab. Held as a value object so
/// it can be persisted (or wired to the `/filter-prefs/` API later).
class ListingsQuery {
  const ListingsQuery({
    this.search = '',
    this.sort = 'Most Recent',
    this.filter = 'All',
  });

  final String search;
  final String sort;
  final String filter;

  ListingsQuery copyWith({String? search, String? sort, String? filter}) =>
      ListingsQuery(
        search: search ?? this.search,
        sort: sort ?? this.sort,
        filter: filter ?? this.filter,
      );

  Map<String, dynamic> toApi(ListingType type) {
    final ordering = switch (sort) {
      'Most Upvoted' => '-upvotes_count',
      'Salary High→Low' => '-salary_max',
      'Investment Low→High' => 'investment_min',
      _ => '-created_at',
    };
    final params = <String, dynamic>{'ordering': ordering};
    if (filter != 'All') {
      if (type == ListingType.job) {
        if (filter == 'Remote') {
          params['location'] = 'Remote';
        } else if (['Design', 'Marketing', 'Tech'].contains(filter)) {
          params['category'] = filter;
        } else {
          params['search'] = filter;
        }
      } else {
        if (['Franchise', 'Investment'].contains(filter)) {
          params['opportunity_type'] = filter.toLowerCase();
        } else {
          params['search'] = filter;
        }
      }
    }
    if (search.isNotEmpty) params['search'] = search;
    return params;
  }
}

final jobsQueryProvider = StateProvider<ListingsQuery>((_) => const ListingsQuery());
final bizQueryProvider = StateProvider<ListingsQuery>((_) => const ListingsQuery());

final jobsListProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  final q = ref.watch(jobsQueryProvider);
  final repo = ref.watch(listingsRepositoryProvider);
  return repo.fetchJobs(filters: q.toApi(ListingType.job));
});

final bizListProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  final q = ref.watch(bizQueryProvider);
  final repo = ref.watch(listingsRepositoryProvider);
  return repo.fetchBiz(filters: q.toApi(ListingType.biz));
});

final homeFeedProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(listingsRepositoryProvider).fetchHomeFeed();
});

final profileStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(listingsRepositoryProvider).fetchProfileStats();
});

final canSubmitProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(listingsRepositoryProvider).canSubmit();
});

final listingDetailProvider =
    FutureProvider.autoDispose.family<Listing, ({ListingType type, String uid})>((ref, args) {
  return ref.watch(listingsRepositoryProvider).fetchListing(args.type, args.uid);
});

final commentsProvider =
    FutureProvider.autoDispose.family<List<ListingComment>, ({ListingType type, String uid})>((
  ref,
  args,
) {
  return ref.watch(listingsRepositoryProvider).fetchComments(args.type, args.uid);
});
