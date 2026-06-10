import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/utils/data_storage.dart';

class InteractionNotificationModel {
  final String infoid;
  final String notified;
  final String notifyingid;
  final String postid;
  final String type;
  final String classname;
  final String isread;
  final String location;
  final String text;
  final String imgname;
  final String typetext;
  final String time;
  final String headimg;
  final String username;

  InteractionNotificationModel({
    required this.infoid,
    required this.notified,
    required this.notifyingid,
    required this.postid,
    required this.type,
    required this.classname,
    required this.isread,
    required this.location,
    required this.text,
    required this.imgname,
    required this.typetext,
    required this.time,
    required this.headimg,
    required this.username,
  });

  factory InteractionNotificationModel.fromJson(Map<String, dynamic> json) {
    return InteractionNotificationModel(
      infoid: json['infoid']?.toString() ?? '',
      notified: json['notified']?.toString() ?? '',
      notifyingid: json['notifyingid']?.toString() ?? '',
      postid: json['postid']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      classname: json['classname']?.toString() ?? '',
      isread: json['isread']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      imgname: json['imgname']?.toString() ?? '',
      typetext: json['typetext']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      headimg: json['headimg']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }
}

class InteractionNotificationsPage extends StatefulWidget {
  const InteractionNotificationsPage({super.key});

  @override
  State<InteractionNotificationsPage> createState() => _InteractionNotificationsPageState();
}

class _InteractionNotificationsPageState extends State<InteractionNotificationsPage> {
  List<InteractionNotificationModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      String? itsid = await DataStorage.loadItsid();
      if (itsid == null || itsid.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final url = Uri.parse('https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=04&itcid=11818&infotype=3&itsid=$itsid');
      print('请求互动提醒 URL: $url');
      final response = await http.get(url);
      print('获取互动提醒数据: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['code'] == '0' && data['data'] is List) {
          final List<dynamic> listData = data['data'];
          setState(() {
            _items = listData.map((e) => InteractionNotificationModel.fromJson(e)).toList();
            // 按照时间从近到远排序
            _items.sort((a, b) {
              try {
                DateTime parseTime(String t) {
                  List<String> p = t.split(' ');
                  if (p.length != 2) return DateTime.now();
                  List<String> dp = p[0].split('/');
                  if (dp.length != 3) return DateTime.now();
                  String formatted = '${dp[0]}-${dp[1].padLeft(2, '0')}-${dp[2].padLeft(2, '0')} ${p[1]}';
                  return DateTime.parse(formatted);
                }
                DateTime timeA = parseTime(a.time);
                DateTime timeB = parseTime(b.time);
                return timeB.compareTo(timeA);
              } catch (e) {
                return 0;
              }
            });
            _isLoading = false;
          });
          
          // 加载完成后调用额外的接口
          _callPhoneApi(itsid);

        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching interaction notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _callPhoneApi(String itsid) async {
    try {
      final phoneUrl = Uri.parse('https://www.ruanzi.net/jy/go/phone.aspx?ituid=118&mbid=11816&itsid=$itsid');
      print('请求 phone 接口 URL: $phoneUrl');
      final phoneResponse = await http.get(phoneUrl);
      print('获取 phone 接口数据: ${phoneResponse.body}');
    } catch (e) {
      print('Error calling phone api: $e');
    }
  }

  String formatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      // Dart 的 DateTime.parse 无法直接解析 "2026/6/9 13:53:37" 这种格式 (缺少前导零)，需要进行处理
      List<String> parts = timeStr.split(' ');
      if (parts.length != 2) return timeStr;

      List<String> dateParts = parts[0].split('/');
      if (dateParts.length != 3) return timeStr;

      String year = dateParts[0];
      String month = dateParts[1].padLeft(2, '0');
      String day = dateParts[2].padLeft(2, '0');

      String formattedDateStr = '$year-$month-$day ${parts[1]}';
      
      DateTime parsedTime = DateTime.parse(formattedDateStr);
      DateTime now = DateTime.now();
      bool isToday = parsedTime.year == now.year && parsedTime.month == now.month && parsedTime.day == now.day;
      if (isToday) {
        return '${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${parsedTime.month.toString().padLeft(2, '0')}-${parsedTime.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      print('Time parsing error: $e for $timeStr');
      return timeStr;
    }
  }

  String getContentByType(String type, String text) {
    String truncatedText = text;
    if (text.length > 10) {
      truncatedText = '${text.substring(0, 10)}...';
    }

    switch (type) {
      case '4':
        return '赞了你的动态：$truncatedText';
      case '5':
        return '评论了你的动态：$truncatedText';
      case '7':
        return '收藏了你的动态：$truncatedText';
      default:
        return text;
    }
  }

  String getAvatarUrl(String img) {
    if (img.isEmpty) return '';
    return 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/$img';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '互动消息',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('暂无互动消息', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _buildNotificationItem(_items[index]);
                  },
                ),
    );
  }

  Widget _buildNotificationItem(InteractionNotificationModel item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeadingIcon(item),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      item.username,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatTime(item.time),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                getContentByType(item.type, item.text),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (item.imgname.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey[200],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              getAvatarUrl(item.imgname),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image, color: Colors.grey);
              },
            ),
          ),
        ],
        if (item.isread == '0')
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 8, top: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF9E9E9E),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _buildLeadingIcon(InteractionNotificationModel item) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200],
      ),
      clipBehavior: Clip.antiAlias,
      child: item.headimg.isNotEmpty
          ? Image.network(
              getAvatarUrl(item.headimg),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.person, color: Colors.grey);
              },
            )
          : const Icon(Icons.person, color: Colors.grey),
    );
  }
}
