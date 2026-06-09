import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/model/messages/list_model.dart'; // model路径
import 'package:flutter_application_1/utils/json_reader.dart'; // 工具类路径
import 'package:flutter_application_1/utils/data_storage.dart';
import 'package:flutter_application_1/pages/Message/interaction_notifications.dart';
import 'package:flutter_application_1/pages/Message/booking_notifications.dart';


class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white
      ),
      home: Message(),
    );
  }
}

//主要区域
class Message extends StatefulWidget {
  const Message({super.key});

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {

// 从JSON加载的消息列表
List<MessageItem> _messageList = [];

@override
void initState() {
  super.initState();
  _loadMessageData(); // 页面一打开就加载JSON并请求接口
}

Future<void> _loadMessageData() async {
  // 读取你的JSON文件作为基础结构
  final jsonList = await JsonReader.readJsonList('assets/json/messages/list.json');
  
  List<MessageItem> initialList = jsonList.map((json) => MessageItem.fromJson(json)).toList();

  if (mounted) {
    setState(() {
      _messageList = initialList;
    });
  }

  try {
    String? itsid = await DataStorage.loadItsid();
    if (itsid == null || itsid.isEmpty) return;

    final url = Uri.parse(
      'https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=04&itcid=11817&itsid=$itsid',
    );

    print('获取消息列表URL: $url');

    final response = await http.get(url);
    print('获取消息列表数据: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['code'] == '0' && responseData['data'] is List) {
        final List<dynamic> rawData = responseData['data'];

        // 分类存储最新的通知，假设列表中排在前面的是最新的
        Map<String, dynamic> latestMsgClass1 = {};
        Map<String, dynamic> latestMsgClass2 = {};
        Map<String, dynamic> latestMsgClass3 = {};
        Map<String, dynamic> latestMsgClass4 = {};

        for (var item in rawData) {
          String classname = item['classname']?.toString() ?? '';
          if (classname == '1' && latestMsgClass1.isEmpty) latestMsgClass1 = item;
          if (classname == '2' && latestMsgClass2.isEmpty) latestMsgClass2 = item;
          if (classname == '3' && latestMsgClass3.isEmpty) latestMsgClass3 = item;
          if (classname == '4' && latestMsgClass4.isEmpty) latestMsgClass4 = item;
        }

        // 截取18个字
        String formatText(String? text) {
          if (text == null || text.isEmpty) return '';
          if (text.length > 18) {
            return '${text.substring(0, 18)}...';
          }
          return text;
        }

        List<MessageItem> updatedList = [];
        for (var item in initialList) {
          if (item.title == '系统维护公告' && latestMsgClass1.isNotEmpty) {
            updatedList.add(item.copyWith(
              content: formatText(latestMsgClass1['text']),
              time: latestMsgClass1['time']?.toString() ?? item.time,
              hasBadge: latestMsgClass1['isread']?.toString() == '0',
            ));
          } else if (item.title == '约球报名成功' && latestMsgClass2.isNotEmpty) {
            updatedList.add(item.copyWith(
              content: formatText(latestMsgClass2['text']),
              time: latestMsgClass2['time']?.toString() ?? item.time,
              hasBadge: latestMsgClass2['isread']?.toString() == '0',
            ));
          } else if (item.title == '新增互动提醒' && latestMsgClass3.isNotEmpty) {
            updatedList.add(item.copyWith(
              content: formatText(latestMsgClass3['text']),
              time: latestMsgClass3['time']?.toString() ?? item.time,
              hasBadge: latestMsgClass3['isread']?.toString() == '0',
            ));
          } else if (item.title == '客服反馈回复' && latestMsgClass4.isNotEmpty) {
            updatedList.add(item.copyWith(
              content: formatText(latestMsgClass4['text']),
              time: latestMsgClass4['time']?.toString() ?? item.time,
              hasBadge: latestMsgClass4['isread']?.toString() == '0',
            ));
          } else {
            updatedList.add(item);
          }
        }

        if (mounted) {
          setState(() {
            _messageList = updatedList;
          });
        }
      }
    }
  } catch (e) {
    print('获取消息列表失败: $e');
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            // 搜索栏
            _buildSearchBar(),
            const SizedBox(height: 12),
            // 消息列表
            _buildMessageList(),
            const SizedBox(height: 80), // 底部导航预留空间
          ],
        ),
      ),
    );
  }

  // 搜索栏
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.grey, size: 20),
          SizedBox(width: 8),
          Text(
            '搜索消息',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

//========================================================================================

  // 消息列表
  Widget _buildMessageList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _messageList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildMessageItem(_messageList[index]);
      },
    );
  }

  // 单个消息列表项
  Widget _buildMessageItem(MessageItem item) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (item.title == '新增互动提醒') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InteractionNotificationsPage(),
            ),
          );
        } else if (item.title == '约球状态通知') {
          Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookingNotificationPage(),
                    ),
                  );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // 左侧图标
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  size: 24,
                  color: Colors.black87,
                ),
              ),
              // 小红点角标
              if (item.hasBadge)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // 中间内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题 + 时间
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      item.time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 内容
                Text(
                  item.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}