class ActivityModel {
  final String title;
  final String time;
  final String address;
  final String status;
  final String statusColor; // 存储16进制颜色字符串
  final String imageUrl;
  final bool isSmallCard;
  final String desc;
  final String joinCount;

  ActivityModel({
    required this.title,
    required this.time,
    required this.address,
    required this.status,
    required this.statusColor,
    required this.imageUrl,
    this.isSmallCard = false,
    this.desc = '',
    this.joinCount = '',
  });

  // JSON → Model
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      title: json['title'] ?? '',
      time: json['time'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? '',
      statusColor: json['statusColor'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isSmallCard: json['isSmallCard'] ?? false,
      desc: json['desc'] ?? '',
      joinCount: json['joinCount'] ?? '',
    );
  }

  // Model → JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'address': address,
      'status': status,
      'statusColor': statusColor,
      'imageUrl': imageUrl,
      'isSmallCard': isSmallCard,
      'desc': desc,
      'joinCount': joinCount,
    };
  }
}