import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/listing.dart';

/// Wraps all listing-side endpoints. Pagination is paginated by the backend
/// (`{count, next, previous, results}`), but for the prototype we only read
/// the first page — pagination can be wired into the controllers later.
class ListingsRepository {
  ListingsRepository(this._api);

  final ApiClient _api;

  Future<List<Listing>> fetchJobs({
    String? search,
    String? sort,
    Map<String, dynamic>? filters,
  }) async {
    final res = await _api.get(
      ApiEndpoints.jobListings,
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (sort != null) 'ordering': sort,
        ...?filters,
      },
    );
    return _parseList(res.data, ListingType.job);
  }

  Future<List<Listing>> fetchBiz({
    String? search,
    String? sort,
    Map<String, dynamic>? filters,
  }) async {
    final res = await _api.get(
      ApiEndpoints.bizListings,
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (sort != null) 'ordering': sort,
        ...?filters,
      },
    );
    return _parseList(res.data, ListingType.biz);
  }

  Future<Listing> fetchListing(ListingType type, String uid) async {
    final path = type == ListingType.job
        ? '${ApiEndpoints.jobListings}$uid/'
        : '${ApiEndpoints.bizListings}$uid/';
    final res = await _api.get(path);
    return Listing.fromJson(res.data as Map<String, dynamic>, type);
  }

  Future<Map<String, dynamic>> fetchHomeFeed() async {
    final res = await _api.get(ApiEndpoints.homeFeed);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchProfileStats() async {
    final res = await _api.get(ApiEndpoints.meStats);
    return res.data as Map<String, dynamic>;
  }

  Future<bool> toggleUpvote(Listing l) async {
    final path = l.type == ListingType.job
        ? ApiEndpoints.jobUpvote(l.uid)
        : ApiEndpoints.bizUpvote(l.uid);
    if (l.upvotedByMe) {
      await _api.delete(path);
      return false;
    }
    await _api.post(path);
    return true;
  }

  Future<bool> toggleSave(Listing l) async {
    final path = l.type == ListingType.job
        ? ApiEndpoints.jobSave(l.uid)
        : ApiEndpoints.bizSave(l.uid);
    if (l.savedByMe) {
      await _api.delete(path);
      return false;
    }
    await _api.post(path);
    return true;
  }

  Future<void> markApplied(Listing l) async {
    final path = l.type == ListingType.job
        ? ApiEndpoints.jobApply(l.uid)
        : ApiEndpoints.bizApply(l.uid);
    await _api.post(path);
  }

  Future<void> trackView(Listing l) async {
    final path = l.type == ListingType.job
        ? ApiEndpoints.jobView(l.uid)
        : ApiEndpoints.bizView(l.uid);
    try {
      await _api.post(path);
    } catch (_) {/* views are fire-and-forget */}
  }

  Future<List<ListingComment>> fetchComments(ListingType type, String uid) async {
    final res = await _api.get(
      ApiEndpoints.comments,
      query: {
        'listing_type': type.wire,
        type == ListingType.job ? 'job_listing__uid' : 'biz_listing__uid': uid,
      },
    );
    final results = _resultsList(res.data);
    return results.map((j) => ListingComment.fromJson(j)).toList();
  }

  Future<ListingComment> postComment({
    required ListingType type,
    required String listingUid,
    required String text,
    String? parentUid,
  }) async {
    final res = await _api.post(
      ApiEndpoints.comments,
      data: {
        'listing_type': type.wire,
        'target_listing_uid': listingUid,
        'text': text,
        if (parentUid != null) 'parent_comment_uid': parentUid,
      },
    );
    return ListingComment.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> reportListing({
    required ListingType type,
    required String uid,
    required String reason,
  }) async {
    await _api.post(
      ApiEndpoints.reports,
      data: {
        'listing_type': type.wire,
        'target_listing_uid': uid,
        'reason': reason,
      },
    );
  }

  Future<Map<String, dynamic>> canSubmit() async {
    final res = await _api.get(ApiEndpoints.canSubmit);
    return res.data as Map<String, dynamic>;
  }

  Future<Listing> createListing({
    required ListingType type,
    required Map<String, dynamic> payload,
  }) async {
    final path =
        type == ListingType.job ? ApiEndpoints.jobListings : ApiEndpoints.bizListings;
    final res = await _api.post(path, data: payload);
    return Listing.fromJson(res.data as Map<String, dynamic>, type);
  }

  // ── helpers ──

  List<Listing> _parseList(dynamic data, ListingType type) {
    return _resultsList(data).map((j) => Listing.fromJson(j, type)).toList();
  }

  List<Map<String, dynamic>> _resultsList(dynamic data) {
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map<String, dynamic>) {
      final results = data['results'];
      if (results is List) return results.cast<Map<String, dynamic>>();
    }
    return const [];
  }
}

final listingsRepositoryProvider =
    Provider<ListingsRepository>((ref) => ListingsRepository(ref.watch(apiClientProvider)));
