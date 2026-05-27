// lib/utils/json_reader.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class JsonReader {
  /// 读取本地JSON文件，返回List（对应JSON数组）
  static Future<List<dynamic>> readJsonList(String filePath) async {
    try {
      // 1. 读取JSON文件内容为字符串
      String jsonString = await rootBundle.loadString(filePath);
      // 2. 解析成List（对应你的dynamic_list.json数组）
      return jsonDecode(jsonString);
    } catch (e) {
      print("读取JSON列表失败：$e");
      return []; // 出错返回空列表，避免页面崩溃
    }
  }

  /// 读取本地JSON文件，返回Map（对应单个JSON对象）
  static Future<Map<String, dynamic>> readJsonMap(String filePath) async {
    try {
      String jsonString = await rootBundle.loadString(filePath);
      return jsonDecode(jsonString);
    } catch (e) {
      print("读取JSON对象失败：$e");
      return {};
    }
  }
}