import 'package:flutter/material.dart';

class MessageItem {
  final IconData icon;
  final Color bgColor;
  final String title;
  final String content;
  final String time;
  final bool hasBadge;

  MessageItem({
    required this.icon,
    required this.bgColor,
    required this.title,
    required this.content,
    required this.time,
    required this.hasBadge,
  });

  // 关键：这里定义了 fromJson，你之前缺少这个！
  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      icon: _getIcon(json['icon']),
      bgColor: Color(int.parse(json['bgColor'], radix: 16)),
      title: json['title'],
      content: json['content'],
      time: json['time'],
      hasBadge: json['hasBadge'] ?? false,
    );
  }

  // 图标名称转 IconData
  static IconData _getIcon(String name) {
    switch (name) {
      case 'check_circle':
        return Icons.check_circle;
      case 'notifications_active':
        return Icons.notifications_active;
      case 'thumb_up':
        return Icons.thumb_up;
      case 'chat':
        return Icons.chat;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.info;
    }
  }
}