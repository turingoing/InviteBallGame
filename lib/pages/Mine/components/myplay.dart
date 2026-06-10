import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/utils/data_storage.dart';
import 'package:flutter_application_1/pages/VenueList/components/payment_page.dart';

// 数据模型
class PlayActivityData {
  final String userid;
  final String location;
  final String note;
  final String time;
  final String participantcount;
  final String skilllevel;
  final String gametype;
  final String feemode;
  final String inviteid;
  final String isconsent;

  PlayActivityData({
    required this.userid,
    required this.location,
    required this.note,
    required this.time,
    required this.participantcount,
    required this.skilllevel,
    required this.gametype,
    required this.feemode,
    required this.inviteid,
    required this.isconsent,
  });

  factory PlayActivityData.fromJson(Map<String, dynamic> json) {
    return PlayActivityData(
      userid: (json['userid'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      participantcount: (json['participantcount'] ?? '').toString(),
      skilllevel: (json['skilllevel'] ?? '').toString(),
      gametype: (json['gametype'] ?? '').toString(),
      feemode: (json['feemode'] ?? '').toString(),
      inviteid: (json['inviteid'] ?? '').toString(),
      isconsent: (json['isconsent'] ?? '').toString(),
    );
  }

  String get gameTypeName {
    switch (gametype) {
      case '0': return '中式八球';
      case '1': return '斯诺克';
      case '2': return '九球';
      case '3': return '四球';
      case '4': return '六球';
      default: return '其他';
    }
  }

  String get feeModeName {
    switch (feemode) {
      case '0': return 'AA制';
      case '1': return '败方付';
      case '2': return '胜方付';
      case '3': return '对方付';
      default: return '未知';
    }
  }

  String get skillLevelName {
    switch (skilllevel) {
      case '1': return '新手';
      case '2': return '业余';
      case '3': return '高手';
      default: return '不限';
    }
  }

  // 获取解析后的时间对象
  DateTime? get parsedDate {
    if (time.isEmpty) return null;
    try {
      String timeStr = time.replaceAll('/', '-');
      List<String> timeParts = timeStr.split(' ');
      if (timeParts.isNotEmpty) {
        List<String> dateParts = timeParts[0].split('-');
        if (dateParts.length == 3) {
          String y = dateParts[0];
          String m = dateParts[1].padLeft(2, '0');
          String d = dateParts[2].padLeft(2, '0');
          
          String h = '00', min = '00', sec = '00';
          if (timeParts.length >= 2) {
            List<String> clockParts = timeParts[1].split(':');
            h = clockParts.isNotEmpty ? clockParts[0].padLeft(2, '0') : '00';
            min = clockParts.length > 1 ? clockParts[1].padLeft(2, '0') : '00';
            sec = clockParts.length > 2 ? clockParts[2].padLeft(2, '0') : '00';
          }
          
          return DateTime.parse('$y-$m-$d $h:$min:$sec');
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  bool get isExpired {
    final parsed = parsedDate;
    if (parsed == null) return false;
    return DateTime.now().isAfter(parsed);
  }
}

class MyPlayPage extends StatefulWidget {
  const MyPlayPage({super.key});

  @override
  State<MyPlayPage> createState() => _MyPlayPageState();
}

class _MyPlayPageState extends State<MyPlayPage> {
  List<PlayActivityData> activityList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlayData();
  }

  Future<void> _loadPlayData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? itsid = await DataStorage.loadItsid();
      if (itsid == null || itsid.isEmpty) {
        setState(() {
          _errorMessage = '未登录或登录已过期';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('https://www.ruanzi.net/jy/go/we.aspx?ituid=118&itjid=04&itcid=11812&itsid=$itsid');
      final response = await http.get(url);

      print('我的加入列表接口响应 (11812): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic> listData = [];
        if (data is List) {
          listData = data;
        } else if (data is Map && data.containsKey('data') && data['data'] is List) {
          listData = data['data'];
        }

        setState(() {
          activityList = listData.map((item) => PlayActivityData.fromJson(item)).toList();
          _sortActivities();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '获取数据失败，状态码: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络请求失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadPlayData();
  }

  void _sortActivities() {
    if (activityList.isEmpty) return;

    final now = DateTime.now();
    activityList.sort((a, b) {
      final dateA = a.parsedDate;
      final dateB = b.parsedDate;

      // 如果日期解析失败，放在最后
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      bool isFutureA = dateA.isAfter(now);
      bool isFutureB = dateB.isAfter(now);

      if (isFutureA && !isFutureB) {
        return -1; // A在将来，B在过去，A排前面
      } else if (!isFutureA && isFutureB) {
        return 1; // A在过去，B在将来，B排前面
      } else if (isFutureA && isFutureB) {
        // 都在将来：越接近现在的排在越前面（升序）
        return dateA.compareTo(dateB);
      } else {
        // 都在过去：越接近现在的排在越前面（降序）
        return dateB.compareTo(dateA);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('我的约玩', style: TextStyle(color: Colors.black, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : activityList.isEmpty
                    ? const Center(child: Text('暂无报名记录'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _EntryTipCard(),
                            const SizedBox(height: 20),
                            ...activityList.map((activity) {
                              return Column(
                                children: [
                                  _ActivitySection(
                                    activity: activity,
                                    onRefresh: _refreshData,
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
      ),
    );
  }
}

class _EntryTipCard extends StatelessWidget {
  const _EntryTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF4285F4)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '入场提示',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  '到达现场后，请向商家出示"核销码"确认到场。核销成功后，系统将自动原路退还该笔活动的保证金。',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  final PlayActivityData activity;
  final VoidCallback onRefresh;

  const _ActivitySection({
    required this.activity,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // isconsent 状态解析
    String statusText = '';
    Color statusColor = Colors.grey;

    if (activity.isconsent == '-1') {
      statusText = '已拒绝加入';
      statusColor = Colors.red;
    } else if (activity.isconsent == '0') {
      statusText = '待审核';
      statusColor = Colors.orange;
    } else if (activity.isconsent == '1') {
      statusText = '已同意待支付';
      statusColor = Colors.blue;
    } else if (activity.isconsent == '2') {
      statusText = '已同意并支付';
      statusColor = Colors.green;
    } else {
      statusText = '状态未知';
      statusColor = Colors.grey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  activity.gameTypeName,
                  style: const TextStyle(
                    color: Color(0xFF0288D1),
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, activity.location),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.access_time, activity.time),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.person_outline, '参与人数: ${activity.participantcount}人'),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.star, '球技要求: ${activity.skillLevelName}'),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.payment, '费用模式: ${activity.feeModeName}'),
          if (activity.note.isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 4),
                _buildInfoRow(Icons.note, activity.note),
              ],
            ),
          const SizedBox(height: 16),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    if (activity.isconsent == '1') {
      bool expired = activity.isExpired;
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: expired ? null : () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentPage(
                    inviteid: activity.inviteid,
                    location: activity.location,
                    publisherid: activity.userid, // 使用发布者的userid
                  ),
                ),
              );

              if (result == true) {
                // 支付成功后，调用 11807 接口
                try {
                  String? itsid = await DataStorage.loadItsid();
                  if (itsid != null && itsid.isNotEmpty) {
                    final url = Uri.parse(
                        'https://www.ruanzi.net/jy/go/phone.aspx?ituid=118&mbid=11807&itsid=$itsid');
                    
                    final response = await http.post(
                      url,
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({
                        'inviteid': activity.inviteid,
                        'location': activity.location,
                        'publisherid': activity.userid,
                      }),
                    );

                    print('加入确认接口 (11807) 响应: ${response.body}');
                    
                    if (response.statusCode == 200) {
                      // 成功后刷新列表
                      onRefresh();
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('加入确认失败: ${response.statusCode}')),
                        );
                      }
                    }
                  }
                } catch (e) {
                  print('调用 11807 接口异常: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: expired ? Colors.grey : const Color(0xFF2962FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(expired ? '已截止支付' : '去支付'),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}