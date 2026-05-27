import 'package:flutter/material.dart';

class BallReservationItem {
  final String avatarUrl;
  final String name;
  final String levelTag;
  final Color tagColor; // 保留你要的 Color 类型
  final double score;
  final String location;
  final String time;
  final int lackCount;
  final int joinedCount;
  final int totalCount;
  final String feeType;
  final String roomNo;
  final String gameType; // 约球类型
  final String note; // 备注
  final String inviteId; // 约球ID

  BallReservationItem({
    required this.avatarUrl,
    required this.name,
    required this.levelTag,
    required this.tagColor,
    required this.score,
    required this.location,
    required this.time,
    required this.lackCount,
    required this.joinedCount,
    required this.totalCount,
    required this.feeType,
    required this.roomNo,
    this.gameType = '中式八球',
    this.note = '',
    this.inviteId = '',
  });

  // JSON → Model 自动解析（颜色自动转）
  factory BallReservationItem.fromJson(Map<String, dynamic> json) {
    return BallReservationItem(
      avatarUrl: json['avatarUrl'] ?? '',
      name: json['name'] ?? '',
      levelTag: json['levelTag'] ?? '',
      tagColor: _getColorFromHex(json['tagColor'] ?? '#FF3B30'),
      score: (json['score'] ?? 0.0).toDouble(),
      location: json['location'] ?? '',
      time: json['time'] ?? '',
      lackCount: json['lackCount'] ?? 0,
      joinedCount: json['joinedCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      feeType: json['feeType'] ?? '',
      roomNo: json['roomNo'] ?? '',
      gameType: json['gameType'] ?? '中式八球',
      note: json['note'] ?? '',
      inviteId: json['inviteId'] ?? '',
    );
  }

  // 工具：十六进制颜色 → Flutter Color
  static Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}