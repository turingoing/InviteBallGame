// 动态卡片数据模型---model
class DynamicModel {
  final String avatarUrl; // 头像URL
  final String userName; // 用户名
  final String location; // 地理位置（如"南通 160km"）
  final String content; // 动态文本内容
  final String? iconUrl;
  final List<String> imageUrls; // 图片URL列表
  final int likeCount; // 点赞数
  final int collectCount; // 收藏数
  final int commentCount; // 评论数
  final bool isOnline; // 是否在线（头像右下角绿点）
  final String createTime; // 发布时间
  final String postid; // 帖子ID

  // 构造函数，支持可选参数+默认值
  DynamicModel({
    required this.avatarUrl,
    required this.userName,
    required this.location,
    required this.content,
    this.iconUrl,
    required this.imageUrls,
    this.likeCount = 0,
    this.collectCount = 0,
    this.commentCount = 0,
    this.isOnline = true,
    this.createTime = '',
    this.postid = '',
  });

  // 核心：新增从JSON Map解析成模型的方法（关键！）
  factory DynamicModel.fromJson(Map<String, dynamic> json) {
    return DynamicModel(
      avatarUrl: json['avatarUrl'] ?? "", // 空值兜底，避免崩溃
      userName: json['userName'] ?? "",
      location: json['location'] ?? "",
      content: json['content'] ?? "",
      iconUrl:json['iconUrl'],
      imageUrls: (json['imageUrls'] as List?)?.map((url) => url.toString()).toList() ?? [],
      likeCount: json['likeCount'] ?? 0,
      collectCount: json['collectCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      isOnline: json['isOnline'] ?? true,
      createTime: json['createTime'] ?? "",
      postid: json['postid'] ?? "",
    );
  }
}