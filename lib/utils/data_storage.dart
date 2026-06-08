import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// 数据存储服务
class DataStorage {
  // 本地缓存文件名
  static const String _inviteListFileName = 'invite_list.json';
  static const String _itsidFileName = 'itsid.txt';

  // 获取应用文档目录路径
  static Future<String> get _documentPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // 获取缓存文件路径
  static Future<String> get _inviteListFilePath async {
    final path = await _documentPath;
    return '$path/$_inviteListFileName';
  }

  // 保存约球列表到本地
  static Future<void> saveInviteList(List<Map<String, dynamic>> data) async {
    try {
      final filePath = await _inviteListFilePath;
      final file = File(filePath);
      await file.writeAsString(jsonEncode(data));
      print('✅ 约球列表已保存到本地: $filePath');
    } catch (e) {
      print('❌ 保存约球列表失败: $e');
    }
  }

  // 从本地读取约球列表
  static Future<List<Map<String, dynamic>>?> loadInviteList() async {
    try {
      final filePath = await _inviteListFilePath;
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as List;
        print('✅ 从本地读取约球列表成功');
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('❌ 读取约球列表失败: $e');
      return null;
    }
  }

  // 检查本地是否有缓存数据
  static Future<bool> hasLocalData() async {
    final filePath = await _inviteListFilePath;
    final file = File(filePath);
    return await file.exists();
  }

  /// 从远程接口获取全局帖子 ID
  static Future<int> getAndIncrementPostId() async {
    String? itsid = await loadItsid();
    final url = Uri.parse('https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=16&itcid=11816&itsid=${itsid ?? ""}');
    
    print('正在获取全局帖子 ID: $url');
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['maxid'] != null) {
        int maxid = int.tryParse(data['maxid'].toString()) ?? 0;
        if (maxid > 0) {
          int currentPostId = maxid + 1;
          print('✅ 成功获取全局最大 ID: $maxid, 当前发布帖子 ID 将使用: $currentPostId');
          return currentPostId;
        }
      }
    }
    
    print('❌ 获取全局帖子 ID 失败: ${response.statusCode} - ${response.body}');
    throw Exception('无法从服务器获取帖子 ID，请检查网络连接或稍后重试');
  }

  // 获取 itsid 文件路径
  static Future<String> get _itsidFilePath async {
    final path = await _documentPath;
    return '$path/$_itsidFileName';
  }

  // 保存 itsid 到本地
  static Future<bool> saveItsid(String itsid) async {
    try {
      final filePath = await _itsidFilePath;
      final file = File(filePath);
      await file.writeAsString(itsid);
      print('✅ itsid 已保存到本地: $filePath');
      return true;
    } catch (e) {
      print('❌ 保存 itsid 失败: $e');
      return false;
    }
  }

  // 从本地读取 itsid
  static Future<String?> loadItsid() async {
    try {
      final filePath = await _itsidFilePath;
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          print('✅ 从本地读取 itsid 成功');
          return content;
        }
      }
      return null;
    } catch (e) {
      print('❌ 读取 itsid 失败: $e');
      return null;
    }
  }

  // 清除本地 itsid（用于退出登录）
  static Future<void> clearItsid() async {
    try {
      final filePath = await _itsidFilePath;
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('✅ itsid 已清除');
      }
    } catch (e) {
      print('❌ 清除 itsid 失败: $e');
    }
  }
}
