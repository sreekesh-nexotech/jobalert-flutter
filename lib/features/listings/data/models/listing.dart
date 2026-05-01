import '../../../../app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Discriminator for the polymorphic listing endpoints (job vs biz).
enum ListingType {
  job('job'),
  biz('biz');

  const ListingType(this.wire);
  final String wire;

  static ListingType fromString(String s) =>
      s == 'biz' ? ListingType.biz : ListingType.job;
}

/// Card-style label rendered as a colored pill on the thumbnail. The four
/// styles (`Trending`, `New`, `Featured`, `Verified`) come from the design.
class CardLabel {
  const CardLabel(this.text, this.bg, this.fg);
  final String text;
  final Color bg;
  final Color fg;

  static const trending = CardLabel('Trending', AppColors.labelTrendingBg, AppColors.labelTrendingFg);
  static const newLabel = CardLabel('New', AppColors.labelNewBg, AppColors.labelNewFg);
  static const featured = CardLabel('Featured', AppColors.labelFeaturedBg, AppColors.labelFeaturedFg);
  static const verified = CardLabel('Verified', AppColors.labelVerifiedBg, AppColors.labelVerifiedFg);
  static const expired = CardLabel('Expired', AppColors.labelExpiredBg, AppColors.labelExpiredFg);

  static List<CardLabel> labelsFor({
    required bool isTrending,
    required bool isNew,
    required bool isFeatured,
    required bool isVerified,
    required bool isExpired,
  }) {
    if (isExpired) return const [expired];
    return [
      if (isTrending) trending,
      if (isNew) newLabel,
      if (isFeatured) featured,
      if (isVerified) verified,
    ];
  }
}

/// Unified card model used by both job and biz screens. Either-or fields
/// (salary vs investment, location vs venue) are filled depending on type.
class Listing {
  Listing({
    required this.uid,
    required this.type,
    required this.title,
    required this.category,
    required this.subCategory,
    required this.qualification,
    required this.description,
    required this.thumbnailUrl,
    required this.galleryUrls,
    required this.tags,
    required this.labels,
    required this.upvotesCount,
    required this.commentsCount,
    required this.savesCount,
    required this.viewsCount,
    required this.isExpired,
    required this.createdAt,
    required this.sourceName,
    required this.sourceUrl,
    this.location = '',
    this.experienceLevel = '',
    this.salaryDisplay = '',
    this.applicationDeadline,
    this.opportunityType = '',
    this.venue = '',
    this.investmentDisplay = '',
    this.dateInfo = '',
    this.savedByMe = false,
    this.upvotedByMe = false,
  });

  final String uid;
  final ListingType type;
  final String title;
  final String category;
  final String subCategory;
  final String qualification;
  final String description;
  final String thumbnailUrl;
  final List<String> galleryUrls;
  final List<String> tags;
  final List<CardLabel> labels;
  final int upvotesCount;
  final int commentsCount;
  final int savesCount;
  final int viewsCount;
  final bool isExpired;
  final DateTime createdAt;
  final String sourceName;
  final String sourceUrl;

  // Job-only
  final String location;
  final String experienceLevel;
  final String salaryDisplay;
  final DateTime? applicationDeadline;

  // Biz-only
  final String opportunityType;
  final String venue;
  final String investmentDisplay;
  final String dateInfo;

  // Per-user state
  final bool savedByMe;
  final bool upvotedByMe;

  Listing copyWith({bool? savedByMe, bool? upvotedByMe, int? upvotesCount}) {
    return Listing(
      uid: uid,
      type: type,
      title: title,
      category: category,
      subCategory: subCategory,
      qualification: qualification,
      description: description,
      thumbnailUrl: thumbnailUrl,
      galleryUrls: galleryUrls,
      tags: tags,
      labels: labels,
      upvotesCount: upvotesCount ?? this.upvotesCount,
      commentsCount: commentsCount,
      savesCount: savesCount,
      viewsCount: viewsCount,
      isExpired: isExpired,
      createdAt: createdAt,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      location: location,
      experienceLevel: experienceLevel,
      salaryDisplay: salaryDisplay,
      applicationDeadline: applicationDeadline,
      opportunityType: opportunityType,
      venue: venue,
      investmentDisplay: investmentDisplay,
      dateInfo: dateInfo,
      savedByMe: savedByMe ?? this.savedByMe,
      upvotedByMe: upvotedByMe ?? this.upvotedByMe,
    );
  }

  factory Listing.fromJson(Map<String, dynamic> json, ListingType type) {
    final isExpired = (json['is_expired'] as bool?) ?? false;
    return Listing(
      uid: json['uid'] as String,
      type: type,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      subCategory: json['sub_category'] as String? ?? '',
      qualification: (json['qualification'] as String?) ?? '',
      description: json['description'] as String? ?? '',
      thumbnailUrl: (json['thumbnail_url'] as String?) ?? '',
      galleryUrls: [
        for (final k in const ['image_2_url', 'image_3_url', 'image_4_url', 'image_5_url'])
          if ((json[k] as String?)?.isNotEmpty ?? false) json[k] as String,
      ],
      tags: ((json['tags'] as List?) ?? const []).map((e) => e.toString()).toList(),
      labels: CardLabel.labelsFor(
        isTrending: (json['is_trending'] as bool?) ?? false,
        isNew: (json['is_new'] as bool?) ?? false,
        isFeatured: (json['is_featured'] as bool?) ?? false,
        isVerified: (json['is_verified'] as bool?) ?? false,
        isExpired: isExpired,
      ),
      upvotesCount: (json['upvotes_count'] as int?) ?? 0,
      commentsCount: (json['comments_count'] as int?) ?? 0,
      savesCount: (json['saves_count'] as int?) ?? 0,
      viewsCount: (json['views_count'] as int?) ?? 0,
      isExpired: isExpired,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      sourceName: (json['source_name'] as String?) ?? '',
      sourceUrl: (json['source_url'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
      experienceLevel: _formatExp((json['experience_level'] as String?) ?? ''),
      salaryDisplay: (json['salary_display'] as String?) ?? '',
      applicationDeadline: DateTime.tryParse(json['application_deadline'] as String? ?? ''),
      opportunityType: _formatOpportunity((json['opportunity_type'] as String?) ?? ''),
      venue: (json['venue'] as String?) ?? '',
      investmentDisplay: (json['investment_display'] as String?) ?? '',
      dateInfo: (json['date_info'] as String?) ?? '',
    );
  }

  static String _formatExp(String wire) {
    return switch (wire) {
      'fresher' => 'Fresher',
      '1-3_yrs' => '1–3 yrs',
      '3-5_yrs' => '3–5 yrs',
      '5+_yrs' => '5+ yrs',
      _ => '',
    };
  }

  static String _formatOpportunity(String wire) {
    return switch (wire) {
      'franchise' => 'Franchise',
      'investment' => 'Investment',
      'channel_partner' => 'Channel Partner',
      'joint_venture' => 'Joint Venture',
      _ => wire.isEmpty ? '' : wire,
    };
  }
}

class ListingComment {
  ListingComment({
    required this.uid,
    required this.userName,
    required this.userInitials,
    required this.avatarColor,
    required this.text,
    required this.createdAt,
    required this.likesCount,
    required this.likedByMe,
  });

  final String uid;
  final String userName;
  final String userInitials;
  final Color avatarColor;
  final String text;
  final DateTime createdAt;
  final int likesCount;
  final bool likedByMe;

  factory ListingComment.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? const {};
    final name = ((user['first_name'] as String?) ?? user['email'] as String? ?? 'User').trim();
    final initials = name.isEmpty ? '?' : name[0].toUpperCase();
    return ListingComment(
      uid: json['uid'] as String,
      userName: name,
      userInitials: initials,
      avatarColor: AppColors.brand,
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      likesCount: (json['likes_count'] as int?) ?? 0,
      likedByMe: false,
    );
  }
}
