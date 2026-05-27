import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import './data_storage.dart';

// 网络请求工具类
class HttpClient {
  // 上传数据用的服务器地址
  static const String uploadUrl = 'https://www.ruanzi.net/jy/go/phone.aspx';
  
  // 获取数据用的服务器地址
  static const String fetchUrl = 'https://www.ruanzi.net/jy/go/we.aspx';

  // 固定的ituid参数
  static const String ituid = '118';

  // POST请求（文字表单数据）- 使用 mbid=5101
  static Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    // 获取本地存储的 itsid
    String? itsid = await DataStorage.loadItsid();
    
    final uri = Uri.parse(uploadUrl).replace(queryParameters: {
      'mbid': '11801',  // 文字表单用 11801
      'ituid': ituid,
      if (itsid != null && itsid.isNotEmpty) 'itsid': itsid,
      if (path.isNotEmpty) ..._parsePathParams(path),
    });

    return await _postRequest(uri, body, headers);
  }

  // POST请求（自定义mbid）- 用于特定接口
  static Future<Map<String, dynamic>> postWithMbid(
    String mbid,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    Map<String, String>? extraParams,
  }) async {
    // 获取本地存储的 itsid
    String? itsid = await DataStorage.loadItsid();
    
    final uri = Uri.parse(uploadUrl).replace(queryParameters: {
      'mbid': mbid,
      'ituid': ituid,
      if (itsid != null && itsid.isNotEmpty) 'itsid': itsid,
      ...?extraParams,
    });

    return await _postRequest(uri, body, headers);
  }

  // 内部POST请求实现
  static Future<Map<String, dynamic>> _postRequest(
    Uri uri,
    Map<String, dynamic> body,
    Map<String, String>? headers,
  ) async {

    print('========== 网络请求开始 ==========');
    print('📌 请求URL: $uri');
    print('📌 请求方法: POST');
    print('📌 请求数据: ${jsonEncode(body)}');
    print('=====================================');

    try {
      final client = http.Client();
      final request = http.Request('POST', uri);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      });
      request.body = jsonEncode(body);

      // 发送请求并自动跟随重定向
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      print('========== 网络响应 ==========');
      print('📌 响应状态码: ${response.statusCode}');
      print('📌 响应内容: ${response.body}');
      print('================================');

      // 如果是重定向（302, 301, 303, 307, 308），检查最终响应
      if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
        print('⚠️ 检测到重定向，最终响应码: ${response.statusCode}');
        // 重定向可能表示成功，继续处理响应
      }

      return _handleResponse(response);
    } catch (e) {
      print('❌ 网络请求异常: $e');
      rethrow;
    }
  }

  // 解析path中的参数
  static Map<String, String> _parsePathParams(String path) {
    if (path.isEmpty) return {};
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return {
        'action': parts[0],
        'type': parts[1],
      };
    } else if (parts.length == 1) {
      return {
        'action': parts[0],
      };
    }
    return {};
  }

  // 图片上传 - 使用 mbid=5013
  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    final uri = Uri.parse(uploadUrl).replace(queryParameters: {
      'mbid': '5013',  // 图片上传用 5013
      'ituid': ituid,
      'action': 'upload',
    });

    print('========== 图片上传开始 ==========');
    print('📌 上传URL: $uri');
    print('📌 文件路径: ${imageFile.path}');
    print('===================================');

    try {
      final client = http.Client();
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      print('📌 上传响应状态: ${response.statusCode}');
      print('📌 上传响应内容: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('服务器拒绝访问，请检查API权限');
      } else {
        throw Exception('图片上传失败 [${response.statusCode}]: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ 图片上传异常: $e');
      rethrow;
    }
  }

  // 处理响应
  static Map<String, dynamic> _handleResponse(http.Response response) {
    // 200-299 都是成功状态码
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return {'success': true, 'message': '请求成功'};
        }
        return jsonDecode(response.body);
      } catch (e) {
        // 如果响应不是JSON格式，也视为成功
        return {'success': true, 'message': '请求成功', 'rawResponse': response.body};
      }
    } else if (response.statusCode == 403) {
      throw Exception('服务器拒绝访问，请检查API权限或联系管理员');
    } else if (response.statusCode == 404) {
      throw Exception('请求的接口不存在');
    } else if (response.statusCode == 500) {
      throw Exception('服务器内部错误，请稍后重试');
    } else if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
      // 重定向通常也表示成功
      return {'success': true, 'message': '请求成功（重定向）', 'statusCode': response.statusCode};
    } else {
      throw Exception('请求失败 [${response.statusCode}]');
    }
  }

  // GET请求
  static Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    // 获取本地存储的 itsid
    String? itsid = await DataStorage.loadItsid();
    
    final uri = Uri.parse(fetchUrl).replace(queryParameters: {
      'ituid': ituid,
      'itjid': '04',
      'itcid': '11803',
      if (itsid != null && itsid.isNotEmpty) 'itsid': itsid,
    });

    print('========== GET请求开始 ==========');
    print('📌 请求URL: $uri');
    print('=====================================');

    try {
      final response = await http.get(uri);

      print('📌 响应状态码: ${response.statusCode}');
      print('📌 响应内容: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ 请求失败: $e');
      rethrow;
    }
  }
}
