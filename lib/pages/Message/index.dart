import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

        Map<String, dynamic> latestMsgClass1 = {};
        Map<String, dynamic> latestMsgClass2 = {};
        Map<String, dynamic> latestMsgClass3 = {};
        Map<String, dynamic> latestMsgClass4 = {};
        
        DateTime? latestTime1, latestTime2, latestTime3, latestTime4;

        // 时间解析辅助函数
        DateTime? parseTime(String? timeStr) {
          if (timeStr == null || timeStr.isEmpty) return null;
          String cleaned = timeStr.trim().replaceAll('/', '-');
          
          // 常见的日期时间格式列表
          List<String> formats = [
            'yyyy-M-d H:m:s',
            'yyyy-M-d H:m',
            'yyyy-M-d',
            'M-d H:m:s',
            'M-d H:m',
            'M-d',
          ];

          for (String format in formats) {
            try {
              DateTime dt = DateFormat(format).parse(cleaned);
              // 如果格式中没有年份（比如 M-d），则补上当前年份
              if (!format.contains('yyyy')) {
                dt = DateTime(DateTime.now().year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
              }
              return dt;
            } catch (_) {}
          }
          
          // 最后的保底尝试
          return DateTime.tryParse(cleaned);
        }

        for (var item in rawData) {
          String classname = item['classname']?.toString() ?? '';
          String itemTimeStr = item['time']?.toString() ?? '';
          DateTime? itemTime = parseTime(itemTimeStr);
          
          if (itemTime == null) continue;

          if (classname == '1') {
            if (latestTime1 == null || itemTime.isAfter(latestTime1!)) {
              latestMsgClass1 = item;
              latestTime1 = itemTime;
            }
          } else if (classname == '2') {
            if (latestTime2 == null || itemTime.isAfter(latestTime2!)) {
              latestMsgClass2 = item;
              latestTime2 = itemTime;
            }
          } else if (classname == '3') {
            if (latestTime3 == null || itemTime.isAfter(latestTime3!)) {
              latestMsgClass3 = item;
              latestTime3 = itemTime;
            }
          } else if (classname == '4') {
            if (latestTime4 == null || itemTime.isAfter(latestTime4!)) {
              latestMsgClass4 = item;
              latestTime4 = itemTime;
            }
          }
        }
        
        // 截取18个字
        String formatText(String? text) {
          if (text == null || text.isEmpty) return '';
          if (text.length > 18) {
            return '${text.substring(0, 18)}...';
          }
          return text;
        }

        List<Map<String, dynamic>> sortableList = [];
        for (var item in initialList) {
          MessageItem updatedItem;
          if (item.title == '系统维护公告' && latestMsgClass1.isNotEmpty) {
            updatedItem = item.copyWith(
              content: formatText(latestMsgClass1['text']),
              time: latestMsgClass1['time']?.toString() ?? item.time,
              hasBadge: latestMsgClass1['isread']?.toString() == '0',
            );
          } else if (item.title == '约球状态通知' && latestMsgClass2.isNotEmpty) {
            String prefix = '';
            String type = latestMsgClass2['type']?.toString() ?? '';
            if (type == '1') {
              prefix = '新成员加入待操作：';
            } else if (type == '2') {
              prefix = '已通过待付款：';
            } else if (type == '6') {
              prefix = '活动已取消：';
            } else if (type == '8') {
              prefix = '您的申请被拒绝：';
            } else if (type == '9') {
              prefix = '成员支付成功已加入：';
            }
            updatedItem = item.copyWith(
              content: formatText('$prefix${latestMsgClass2['text'] ?? ''}'),
              time: latestMsgClass2['time']?.toString() ?? item.time,
              hasBadge: latestMsgClass2['isread']?.toString() == '0',
            );
          } else if (item.title == '新增互动提醒' && latestMsgClass3.isNotEmpty) {
            String prefix = '';
            String type = latestMsgClass3['type']?.toString() ?? '';
            if (type == '4') {
              prefix = '新点赞：';
            } else if (type == '5') {
              prefix = '新评论：';
            } else if (type == '7') {
              prefix = '新收藏：';
            }
            updatedItem = item.copyWith(
              content: formatText('$prefix${latestMsgClass3['text'] ?? ''}'),
              time: latestMsgClass3['time']?.toString() ?? item.time,
              hasBadge: latestMsgClass3['isread']?.toString() == '0',
            );
          } else if (item.title == '客服反馈回复' && latestMsgClass4.isNotEmpty) {
            updatedItem = item.copyWith(
              content: formatText(latestMsgClass4['text']),
              time: latestMsgClass4['time']?.toString() ?? item.time,
              hasBadge: latestMsgClass4['isread']?.toString() == '0',
            );
          } else {
            updatedItem = item;
          }
          
          sortableList.add({
            'item': updatedItem,
            'time': parseTime(updatedItem.time) ?? DateTime(0),
          });
        }

        // 格式化显示时间
        String formatDisplayTime(DateTime dt) {
          if (dt.year == 0 || dt.year < 2000) return ''; // 过滤无效或极旧时间
          DateTime now = DateTime.now();
          bool isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
          return isToday ? DateFormat('HH:mm').format(dt) : DateFormat('MM-dd').format(dt);
        }

        // 按时间倒序排序
        sortableList.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
        
        // 生成最终列表并应用时间显示格式
        List<MessageItem> updatedList = sortableList.map((e) {
          MessageItem item = e['item'] as MessageItem;
          DateTime dt = e['time'] as DateTime;
          return item.copyWith(time: formatDisplayTime(dt));
        }).toList();

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