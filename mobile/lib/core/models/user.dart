class UserProfile {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int contributionsCount;
  final int bookmarksCount;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.contributionsCount,
    required this.bookmarksCount,
  });
}

enum ContributionStatus { pending, approved, rejected }

class UserContribution {
  final String id;
  final String placeName;
  final String placeAddress;
  final DateTime date;
  final int totalAmount;
  final ContributionStatus status;
  final String? rejectionReason;

  const UserContribution({
    required this.id,
    required this.placeName,
    required this.placeAddress,
    required this.date,
    required this.totalAmount,
    required this.status,
    this.rejectionReason,
  });
}
