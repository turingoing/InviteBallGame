import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 数据存储服务
class DataStorage {
  // 本地缓存文件名
  static const String _inviteListFileName = 'invite_list.json';
  static const String _postIdFileName = 'postid.txt';
  static const String _itsidFileName = 'itsid.txt';
  static const String _globalIdCounterKey = 'global_id_counter';

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

  static Future<String> get _postIdFilePath async {
    final path = await _documentPath;
    return '$path/$_postIdFileName';
  }

  static Future<int> getAndIncrementPostId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int currentPostId = prefs.getInt(_globalIdCounterKey) ?? 0;

      // 兼容旧版文件计数器，避免升级后又从 1 开始。
      if (currentPostId <= 0) {
        final filePath = await _postIdFilePath;
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          currentPostId = int.tryParse(content) ?? 0;
        }
      }

      // 确保帖子ID从30开始
      if (currentPostId < 29) {
        currentPostId = 29;
      }

      currentPostId++;
      await prefs.setInt(_globalIdCounterKey, currentPostId);

      // 同步写回旧文件，兼容仍依赖文件值的旧逻辑。
      final filePath = await _postIdFilePath;
      final file = File(filePath);
      await file.writeAsString(currentPostId.toString());

      print('✅ 全局帖子计数器自增成功: $currentPostId');
      return currentPostId;
    } catch (e) {
      print('获取帖子ID失败: $e');
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      return int.parse(timestamp.substring(timestamp.length - 4));
    }
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
