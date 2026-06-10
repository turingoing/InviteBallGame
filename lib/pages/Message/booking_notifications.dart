import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/utils/data_storage.dart';

import 'package:flutter_application_1/pages/Mine/components/invite_detail.dart';
import 'package:flutter_application_1/pages/VenueList/components/payment_page.dart';

class BookingNotificationModel {
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

  BookingNotificationModel({
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

  factory BookingNotificationModel.fromJson(Map<String, dynamic> json) {
    return BookingNotificationModel(
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

class BookingNotificationPage extends StatefulWidget {
  const BookingNotificationPage({super.key});

  @override
  State<BookingNotificationPage> createState() => _BookingNotificationPageState();
}

class _BookingNotificationPageState extends State<BookingNotificationPage> {
  List<BookingNotificationModel> _items = [];
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

      final url = Uri.parse('https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=04&itcid=11818&infotype=2&itsid=$itsid');
      print('请求约球通知 URL: $url');
      final response = await http.get(url);
      print('获取约球通知数据: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['code'] == '0' && data['data'] is List) {
          final List<dynamic> listData = data['data'];
          setState(() {
            _items = listData.map((e) => BookingNotificationModel.fromJson(e)).toList();
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
      print('Error fetching booking notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _callPhoneApi(String itsid) async {
    try {
      final phoneUrl = Uri.parse('https://www.ruanzi.net/jy/go/phone.aspx?ituid=118&mbid=11817&itsid=$itsid');
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

  String getContentByType(String type) {
    switch (type) {
      case '1':
        return '用户申请加入约球，等待您的操作';
      case '2':
        return '加入约球申请已通过，等待支付押金';
      case '8':
        return '您的约球加入申请被拒绝';
      case '9':
        return '用户成功支付，已加入约球列表';
      default:
        return '';
    }
  }

  String getAvatarUrl(String headimg) {
    if (headimg.isEmpty) return '';
    return 'https://www.ruanzi.net/jy/wxuser/118/images/singeravatar/$headimg';
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
          '约球通知',
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
              ? const Center(child: Text('暂无通知', style: TextStyle(color: Colors.grey)))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  children: _items.map((item) => _buildStatusItem(item)).toList(),
                ),
    );
  }

  Widget _buildStatusItem(BookingNotificationModel item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.username,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      formatTime(item.time),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        getContentByType(item.type),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (item.type == '1')
                      GestureDetector(
                        onTap: () {
                          if (item.postid.isNotEmpty) {
                            // 使用 pushReplacement 避免返回到通知页面
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InviteDetailPage(
                                  inviteId: item.postid,
                                  location: item.location,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '去操作',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else if (item.type == '2')
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPage(
                                 inviteid: item.postid,
                                 location: item.location,
                                 publisherid: item.notifyingid, // 使用 notifyingid 作为 publisherid
                               ),
                            ),
                          );

                          if (result == true) {
                            // 支付成功后返回到当前页面，再调用 11807 接口
                            try {
                              String? itsid = await DataStorage.loadItsid();
                              if (itsid != null && itsid.isNotEmpty) {
                                final url = Uri.parse(
                                    'https://www.ruanzi.net/jy/go/phone.aspx?ituid=118&mbid=11807&itsid=$itsid');
                                
                                final response = await http.post(
                                  url,
                                  headers: {'Content-Type': 'application/json'},
                                  body: json.encode({
                                    'inviteid': item.postid,
                                    'location': item.location,
                                    'publisherid': item.notifyingid,
                                  }),
                                );

                                if (response.statusCode == 200) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('加入确认成功')),
                                    );
                                    // 刷新通知列表
                                      _fetchData();
                                    }
                                }
                              }
                            } catch (e) {
                              print('调用 11807 接口异常: $e');
                            }
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9500),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '去付款',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    if (item.isread == '0')
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF9E9E9E),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
