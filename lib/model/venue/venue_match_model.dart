// import 'package:flutter/material.dart';

class CommentItem {
  final String avatarUrl;
  final String userName;
  final int rating;
  final String time;
  final String content;

  CommentItem({
    required this.avatarUrl,
    required this.userName,
    required this.rating,
    required this.time,
    required this.content,
  });

  // 👇 解析 JSON 用这个
  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      avatarUrl: json['avatarUrl'] ?? "",
      userName: json['userName'] ?? "",
      rating: json['rating'] ?? 0,
      time: json['time'] ?? "",
      content: json['content'] ?? "",
    );
  }
}