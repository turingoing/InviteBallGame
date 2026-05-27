import 'dart:convert';
import 'dart:io';
import '../utils/http_client.dart';

// 比赛相关API服务
class CompetitionApi {
  // 修复不规范的 JSON 格式
  static String _fixJsonFormat(String jsonStr) {
    print('🔧 开始修复 JSON 格式...');
    print('🔧 原始字符串: $jsonStr');
    
    // 1. 修复数组格式错误: [ {"location" 改为 [{"location"
    jsonStr = jsonStr.replaceAll(r'\[\s*\{', '[{');
    
    // 2. 修复数组元素之间缺少逗号的问题: }{" 改为 },{"
    jsonStr = jsonStr.replaceAll(r'}{', '},{');
    
    // 3. 修复键值分隔符: "key"="value" 改为 "key":"value"
    // 使用 replaceAllMapped 来正确处理捕获组
    jsonStr = jsonStr.replaceAllMapped(
      RegExp(r'"([^"]+)"\s*=\s*"([^"]*)"'),
      (match) => '"${match.group(1)}":"${match.group(2)}"'
    );
    
    // 4. 修复可能存在的 {[ 格式问题
    jsonStr = jsonStr.replaceAll(r'{[', '[');
    
    // 5. 修复可能存在的 }]} 格式问题
    jsonStr = jsonStr.replaceAll(r'}]}', '}]');
    
    print('🔧 修复后字符串: $jsonStr');
    return jsonStr;
  }
  // 上传比赛宣传图
  static Future<String> uploadPoster(File imageFile) async {
    try {
      final response = await HttpClient.uploadImage(imageFile);
      return response['data']['url'] ?? response['url'] ?? '';
    } catch (e) {
      throw Exception('上传宣传图失败: $e');
    }
  }

  // 提交比赛表单（提交到同一个URL）
  static Future<Map<String, dynamic>> submitCompetition(Map<String, dynamic> data) async {
    try {
      // 传入 action=competition 来区分类型
      final response = await HttpClient.postJson('/competition', data);
      return response;
    } catch (e) {
      throw Exception('提交比赛失败: $e');
    }
  }

  // 提交比赛数据到指定接口
  // 接口: https://www.ruanzi.net/jy/go/phone.aspx?mbid=11802&ituid=118
  static Future<Map<String, dynamic>> submitMatch({
    required String location,
    required String compname,
    required String note,
    required DateTime starttime,
    required DateTime endtime,
    required int participantcount,
    required int skilllevel,
    required int gametype,
    required int compid,
    String? imgurl,
  }) async {
    try {
      final body = {
        'location': location, // 球馆名称 varchar
        'compname': compname, // 比赛名称 varchar
        'note': note, // 活动备注 varchar
        'starttime': starttime.toIso8601String().split('.')[0], // 开始时间 datetime
        'endtime': endtime.toIso8601String().split('.')[0], // 结束时间 datetime
        'participantcount': participantcount, // 参与人数 int
        'skilllevel': skilllevel, // 球技要求 int
        'gametype': gametype, // 约球类型 int
        'compid': compid, // 比赛帖子id int
        if (imgurl != null && imgurl.isNotEmpty) 'imgurl': imgurl, // 宣传图（可选）
      };

      final response = await HttpClient.postWithMbid('11802', body);
      return response;
    } catch (e) {
      throw Exception('提交比赛失败: $e');
    }
  }

  // 约球类型转数字编码
  static int getGameTypeCode(String gameType) {
    switch (gameType) {
      case '中式八球':
        return 0;
      case '斯诺克':
        return 1;
      case '九球':
        return 2;
      case '四球':
        return 3;
      case '六球':
        return 4;
      case '其他':
      default:
        return 5;
    }
  }

  // 提交约球表单（提交到同一个URL）
  static Future<Map<String, dynamic>> submitInvite(Map<String, dynamic> data) async {
    try {
      // 传入 action=invite 来区分类型
      final response = await HttpClient.postJson('/invite', data);
      return response;
    } catch (e) {
      throw Exception('提交约球失败: $e');
    }
  }

  // 获取约球列表
  static Future<List<Map<String, dynamic>>> getInviteList(String userId) async {
    try {
      final response = await HttpClient.getJson('/getInviteList');
      
      // 输出完整的响应数据到控制台
      print('=====================================');
      print('📋 从接口获取到的数据:');
      print('📋 完整响应: $response');
      
      // 解析格式: {"success":true,"message":"请求成功","rawResponse":"{\"code\":\"0\",\"data\":[...]}"}
      if (response.containsKey('rawResponse')) {
        var rawResponse = response['rawResponse'] as String;
        print('📋 rawResponse 内容: $rawResponse');
        
        try {
          // 修复不规范的 JSON 格式
          rawResponse = _fixJsonFormat(rawResponse);
          print('📋 修复后的 JSON: $rawResponse');
          
          // 解析 rawResponse 字符串为 JSON
          final parsed = jsonDecode(rawResponse) as Map<String, dynamic>;
          
          if (parsed.containsKey('data') && parsed['data'] is List) {
            final data = parsed['data'] as List;
            print('📋 data 字段内容: $data');
            print('📋 数据长度: ${data.length}');
            
            final result = List<Map<String, dynamic>>.from(data);
            if (result.isNotEmpty) {
              print('📋 第一条数据: ${result[0]}');
            }
            return result;
          }
        } catch (e) {
          print('❌ 解析 rawResponse 失败: $e');
        }
      }
      
      // 备用：直接从 response 获取 data
      if (response.containsKey('data')) {
        final data = response['data'];
        print('📋 data 字段内容: $data');
        if (data is List) {
          final result = List<Map<String, dynamic>>.from(data);
          print('📋 转换后的列表长度: ${result.length}');
          return result;
        }
      }
      
      print('📋 没有找到 data 字段或数据为空');
      return [];
    } catch (e) {
      print('❌ 获取约球列表失败: $e');
      throw Exception('获取约球列表失败: $e');
    }
  }
}
