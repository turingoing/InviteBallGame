import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// import 'package:flutter_application_1/utils/json_reader.dart'; //工具类
import 'package:flutter_application_1/model/main/dynamic_model.dart';
import 'package:flutter_application_1/widgets/dynamic_card.dart';
import 'package:flutter_application_1/widgets/ranking_entry_card.dart'; // 排行榜卡片

// 动态列表页
// 注意：改成StatefulWidget，因为要异步读取JSON文件
class DynamicPage extends StatefulWidget {
  const DynamicPage({super.key});

  @override
  State<DynamicPage> createState() => _DynamicPageState();
}

class _DynamicPageState extends State<DynamicPage> {
  // 异步加载JSON数据后的模型列表
  late Future<List<DynamicModel>> _dynamicListFuture;

  @override
  void initState() {
    super.initState();
    // 初始化时读取JSON并解析成模型列表
    _dynamicListFuture = _loadDynamicList();
  }

  // 封装：从服务器获取动态数据 + 解析成模型列表
  Future<List<DynamicModel>> _loadDynamicList() async {
    try {
      // 构建请求URL
      final url = Uri.parse(
        'https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=05&itcid=11805',
      );
      print('请求动态数据URL: $url');

      // 发送请求
      var response = await http.get(url);
      print('动态数据响应状态码: ${response.statusCode}');
      print('动态数据响应内容: ${response.body}');

      if (response.statusCode == 200) {
        // 解析响应数据
        Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['code'] == '0' && responseData['data'] is List) {
          List<dynamic> rawDataList = responseData['data'];

          // 按postid分组，将相同postid的图片放在一起
          Map<String, Map<String, dynamic>> groupedPosts = {};

          for (var item in rawDataList) {
            String postid = item['postid'] ?? '';

            if (postid.isEmpty) continue;

            if (!groupedPosts.containsKey(postid)) {
              // 新帖子，初始化数据
              groupedPosts[postid] = {
                'postid': postid,
                'userid': item['userid'],
                'username': item['username'],
                'headimg': item['headimg'],
                'content': item['content'],
                'create_time': item['create_time'] ?? item['time'] ?? '',
                'imageUrls': [],
              };
            }

            if (item['username'] != null &&
                item['username'].toString().trim().isNotEmpty) {
              groupedPosts[postid]!['username'] = item['username'];
            }

            if (item['headimg'] != null &&
                item['headimg'].toString().trim().isNotEmpty) {
              groupedPosts[postid]!['headimg'] = item['headimg'];
            }

            // 处理图片：imgname字段包含逗号分隔的图片名列表
            if (item['imgname'] != null) {
              String imgNames = item['imgname'].toString().trim();
              // 移除可能包含的反引号(`)
              imgNames = imgNames.replaceAll('`', '');
              if (imgNames.isNotEmpty) {
                // 按逗号分割图片名
                List<String> imgNameList = imgNames.split(',');
                for (String imgName in imgNameList) {
                  imgName = imgName.trim();
                  if (imgName.isNotEmpty) {
                    // 拼接完整的图片URL路径
                    String fullImgUrl =
                        'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/$imgName';
                    groupedPosts[postid]!['imageUrls'].add(fullImgUrl);
                  }
                }
              }
            }
          }

          // 将分组后的数据转换为DynamicModel列表
          List<DynamicModel> dynamicList = [];
          groupedPosts.forEach((postid, data) {
            String userName = data['username']?.toString().trim() ?? '';
            userName = userName.replaceAll('`', '');

            String avatarName = data['headimg']?.toString().trim() ?? '';
            avatarName = avatarName.replaceAll('`', '');

            // 构建DynamicModel对象
            DynamicModel dynamicModel = DynamicModel(
              avatarUrl: avatarName.isNotEmpty
                  ? 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/$avatarName'
                  : 'https://www.example.com/avatar.jpg',
              userName: userName.isNotEmpty
                  ? userName
                  : '用户${data['userid'] ?? '未知'}',
              location: '', // 接口没有返回位置信息
              content: data['content'] ?? '',
              imageUrls: data['imageUrls'] is List
                  ? List<String>.from(data['imageUrls'])
                  : [], // 确保是List类型
              likeCount: 0, // 接口没有返回点赞数
              collectCount: 0, // 接口没有返回收藏数
              commentCount: 0, // 接口没有返回评论数
              isOnline: true, // 默认在线状态
            );
            dynamicList.add(dynamicModel);
          });

          return dynamicList;
        } else {
          throw Exception('数据格式错误: ${response.body}');
        }
      } else {
        throw Exception('请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      print('加载动态列表失败: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DynamicModel>>(
      future: _dynamicListFuture,
      builder: (context, snapshot) {
        // 1. 加载中状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. 加载失败状态
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("加载动态列表失败"));
        }

        // 3. 数据加载成功，渲染列表
        final dynamicList = snapshot.data!;
        return ListView.builder(
          cacheExtent: 1200,
          // padding: const EdgeInsets.symmetric(vertical: 2),
          itemCount: dynamicList.length + 1, // 排行榜+动态列表
          itemBuilder: (context, index) {
            // 显示排行榜卡片
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: RankingEntryCard(),
              );
            }
            // 显示动态卡片（索引减1，跳过排行榜）
            final dynamicData = dynamicList[index - 1];
            return DynamicCard(dynamicData: dynamicData);
          },
        );
      },
    );
  }
}
