// lib/model/venue_model.dart
class VenueModel {
  final String imageUrl;       // 场馆主图URL
  final List<String> imageList; // 场馆图片列表
  final String name;           // 场馆名称
  final double score;          // 评分
  final List<String> tags;     // 标签列表
  final String address;        // 地址
  final String distance;       // 距离
  final String status;         // 营业状态（营业中/休息中）
  final String promotion;      // 促销信息
  final String buttonText;     // 按钮文字
  final bool buttonEnabled;    // 按钮是否可用
  final String? businessHours; // 营业时间（可选）

  // 构造函数，带默认值避免空指针
  VenueModel({
    required this.imageUrl,
    this.imageList = const [],
    required this.name,
    required this.score,
    required this.tags,
    required this.address,
    required this.distance,
    required this.status,
    required this.promotion,
    required this.buttonText,
    this.buttonEnabled = true,
    this.businessHours,
  });

  // 核心：从JSON Map解析成模型（空值兜底，避免崩溃）
  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      imageUrl: json['imageUrl'] ?? "",
      imageList: (json['imageList'] as List?)?.map((img) => img.toString()).toList() ?? [],
      name: json['name'] ?? "",
      score: (json['score'] ?? 0.0).toDouble(), // 确保是double类型
      tags: (json['tags'] as List?)?.map((tag) => tag.toString()).toList() ?? [],
      address: json['address'] ?? "",
      distance: json['distance'] ?? "",
      status: json['status'] ?? "营业中",
      promotion: json['promotion'] ?? "",
      buttonText: json['buttonText'] ?? "去约球",
      buttonEnabled: json['buttonEnabled'] ?? true,
      businessHours: json['businessHours'], // 可选字段，null则返回null
    );
  }
}