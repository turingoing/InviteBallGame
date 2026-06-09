import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/model/main/dynamic_model.dart';
import 'package:flutter_application_1/widgets/dynamic_card.dart';
import 'package:flutter_application_1/utils/data_storage.dart';
import 'package:flutter_application_1/pages/Main/Conponents/dynamic_detail.dart';

class MyDynamicPage extends StatefulWidget {
  const MyDynamicPage({super.key});

  @override
  State<MyDynamicPage> createState() => _MyDynamicPageState();
}

class _MyDynamicPageState extends State<MyDynamicPage> {
  late Future<List<DynamicModel>> _myDynamicListFuture;

  @override
  void initState() {
    super.initState();
    _myDynamicListFuture = _loadMyDynamicList();
  }

  Future<List<DynamicModel>> _loadMyDynamicList() async {
    try {
      String? itsid = await DataStorage.loadItsid();
      if (itsid == null || itsid.isEmpty) {
        throw Exception('未登录');
      }

      final url = Uri.parse(
        'https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=04&itcid=11813&itsid=$itsid',
      );
      print('请求我的动态数据URL: $url');

      var response = await http.get(url);
      print('我的动态数据响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['code'] == '0' && responseData['data'] is List) {
          List<dynamic> rawDataList = responseData['data'];

          // 按postid分组，将相同postid的图片放在一起 (参考 dynamic.dart)
          Map<String, Map<String, dynamic>> groupedPosts = {};

          for (var item in rawDataList) {
            String postid = (item['postid'] ?? '').toString();
            if (postid.isEmpty) continue;

            if (!groupedPosts.containsKey(postid)) {
              groupedPosts[postid] = {
                'postid': postid,
                'userid': item['userid'],
                'username': item['username'] ?? '我',
                'headimg': item['headimg'],
                'content': item['content'],
                'create_time': item['create_time'] ?? item['time'] ?? '',
                'i01': item['i01'], // 保存 i01 用于排序
                'like': item['like'], // 保存点赞量
                'comment': item['comment'], // 保存评论量
                'collect': item['collect'], // 保存收藏量
                'imageUrls': [],
              };
            }

            // 处理图片
            if (item['imgname'] != null) {
              String imgNames = item['imgname'].toString().trim().replaceAll('`', '');
              if (imgNames.isNotEmpty) {
                List<String> imgNameList = imgNames.split(',');
                for (String imgName in imgNameList) {
                  imgName = imgName.trim();
                  if (imgName.isNotEmpty) {
                    String fullImgUrl = 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/$imgName';
                    if (!groupedPosts[postid]!['imageUrls'].contains(fullImgUrl)) {
                      groupedPosts[postid]!['imageUrls'].add(fullImgUrl);
                    }
                  }
                }
              }
            }
          }

          // 将分组后的数据转换为列表并按 i01 从大到小排序
          final sortedEntries = groupedPosts.values.toList()
            ..sort((a, b) {
              int i01A = int.tryParse(a['i01']?.toString() ?? '0') ?? 0;
              int i01B = int.tryParse(b['i01']?.toString() ?? '0') ?? 0;
              return i01B.compareTo(i01A);
            });

          List<DynamicModel> dynamicList = [];
          for (var data in sortedEntries) {
            String avatarName = data['headimg']?.toString().trim().replaceAll('`', '') ?? '';
            
            dynamicList.add(DynamicModel(
              avatarUrl: avatarName.isNotEmpty
                  ? 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/$avatarName'
                  : 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/default.png',
              userName: data['username']?.toString().replaceAll('`', '') ?? '用户${data['userid']}',
              location: '',
              content: data['content'] ?? '',
              imageUrls: List<String>.from(data['imageUrls']),
              likeCount: int.tryParse(data['like']?.toString() ?? '0') ?? 0,
              commentCount: int.tryParse(data['comment']?.toString() ?? '0') ?? 0,
              collectCount: int.tryParse(data['collect']?.toString() ?? '0') ?? 0,
              isOnline: true,
              createTime: data['create_time']?.toString() ?? '',
              postid: data['postid']?.toString() ?? '',
              userid: data['userid']?.toString() ?? '',
            ));
          }

          return dynamicList;
        } else {
          return [];
        }
      } else {
        throw Exception('请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      print('加载我的动态失败: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的动态'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<List<DynamicModel>>(
        future: _myDynamicListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('加载失败: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _myDynamicListFuture = _loadMyDynamicList();
                      });
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final dynamicList = snapshot.data ?? [];
          if (dynamicList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无动态', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: dynamicList.length,
            itemBuilder: (context, index) {
              final dynamicData = dynamicList[index];
              return DynamicCard(
                dynamicData: dynamicData,
                showLikeAction: false, // 个人中心动态也仅作展示
                showCollectAction: false, // 个人中心动态也仅作展示
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DynamicDetailPage(dynamicData: dynamicData),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
