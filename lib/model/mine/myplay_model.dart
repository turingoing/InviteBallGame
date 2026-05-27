/// 我的约玩 - 活动数据模型
class PlayActivity {
  final String title;
  final String activityName;
  final String date;
  final String location;
  final bool isUsed;
  final int? participantCount;
  final int? totalCount;
  final bool? depositReturned;

  PlayActivity({
    required this.title,
    required this.activityName,
    required this.date,
    required this.location,
    required this.isUsed,
    this.participantCount,
    this.totalCount,
    this.depositReturned,
  });

  // JSON 转 Model
  factory PlayActivity.fromJson(Map<String, dynamic> json) {
    return PlayActivity(
      title: json['title'] as String,
      activityName: json['activityName'] as String,
      date: json['date'] as String,
      location: json['location'] as String,
      isUsed: json['isUsed'] as bool,
      participantCount: json['participantCount'] != null
          ? json['participantCount'] as int
          : null,
      totalCount: json['totalCount'] != null
          ? json['totalCount'] as int
          : null,
      depositReturned: json['depositReturned'] != null
          ? json['depositReturned'] as bool
          : null,
    );
  }
}