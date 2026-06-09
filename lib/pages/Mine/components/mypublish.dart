import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/mine/mypublish.dart';
import 'package:flutter_application_1/api/competition_api.dart';
import 'package:flutter_application_1/utils/data_storage.dart';
import 'package:flutter_application_1/pages/Mine/components/invite_detail.dart';
import 'package:flutter_application_1/pages/Mine/components/qr_scanner_page.dart';
import 'package:flutter_application_1/pages/Mine/components/qr_code_dialog.dart';

class MyPublishPage extends StatefulWidget {
  const MyPublishPage({super.key});

  @override
  State<MyPublishPage> createState() => _MyPublishPageState();
}

class _MyPublishPageState extends State<MyPublishPage> {
  List<PublishActivity> activityList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('📱 MyPublishPage initState 被调用');
    loadPublishData();
  }

  // 加载发布数据
  Future<void> loadPublishData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 尝试从服务器获取约球列表...');
      final data = await CompetitionApi.getInviteList('118');
      
      if (data.isNotEmpty) {
        await DataStorage.saveInviteList(data);
        print('✅ 服务器数据获取成功，已保存到本地');
      }
      
      setState(() {
        activityList = data.map((item) => PublishActivity.fromJson(item)).toList();
        _sortActivities();
      });
      
    } catch (e) {
      print('❌ 服务器请求失败: $e');
      setState(() {
        _errorMessage = '网络请求失败，使用本地缓存';
      });
      
      await loadFromLocal();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 从本地读取缓存数据
  Future<void> loadFromLocal() async {
    try {
      final localData = await DataStorage.loadInviteList();
      if (localData != null && localData.isNotEmpty) {
        print('✅ 从本地缓存读取成功');
        setState(() {
          activityList = localData.map((item) => PublishActivity.fromJson(item)).toList();
          _sortActivities();
        });
      } else {
        loadMockData();
      }
    } catch (e) {
      print('❌ 本地读取失败，使用模拟数据: $e');
      loadMockData();
    }
  }

  // 加载模拟数据
  void loadMockData() {
    setState(() {
      activityList = [
        PublishActivity(
          itieId: '19',
          activityName: '斯诺克·竞技赛',
          date: '[#time]',
          location: 'sfafa',
          isUsed: false,
          participantCount: 6,
          totalCount: 6,
          depositReturned: false,
          gameType: '1',
          feeMode: '0',
          note: '123',
          skilllevel: '3',
          userid: '3',
          inviteid: '19',
        ),
        PublishActivity(
          itieId: '3',
          activityName: '下班后的快乐杆',
          date: '[#time]',
          location: 'ewrgwsf',
          isUsed: true,
          participantCount: 6,
          totalCount: 6,
          depositReturned: true,
          gameType: '0',
          feeMode: '0',
          note: 'fgfweg',
          skilllevel: '3',
          userid: '3',
          inviteid: '3',
        ),
      ];
      _sortActivities();
    });
  }

  // 排序逻辑：
  // 1. 未开始的约球（时间 > 当前时间）排在前面，且越接近当前时间的排在越前面。
  // 2. 已结束的约球（时间 <= 当前时间）排在后面，且越接近当前时间的排在越前面。
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
        return 1;  // A在过去，B在将来，B排前面
      } else if (isFutureA && isFutureB) {
        // 都在将来：越接近现在的排在越前面（升序）
        return dateA.compareTo(dateB);
      } else {
        // 都在过去：越接近现在的排在越前面（降序）
        return dateB.compareTo(dateA);
      }
    });
  }

  // 手动刷新数据
  Future<void> _refreshData() async {
    await loadPublishData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('我的发布'),
        leading: const BackButton(),
        actions: const [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: null,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : activityList.isEmpty
                ? const Center(child: Text('暂无发布记录'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _EntryTipCard(),
                        const SizedBox(height: 20),
                        ...activityList.map((activity) {
                          return Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InviteDetailPage(
                                        inviteId: activity.inviteid ?? '',
                                        location: activity.location,
                                      ),
                                    ),
                                  );
                                },
                                child: _ActivitySection(activity: activity),
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
  final PublishActivity activity;

  const _ActivitySection({required this.activity});

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
                activity.isUsed ? '已结束' : '待核销',
                style: TextStyle(
                  color: activity.isUsed
                      ? const Color(0xFF9E9E9E)
                      : const Color(0xFFFF9800),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            activity.activityName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, activity.location),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.access_time, activity.date),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.person_outline, '参与人数: ${activity.participantCount ?? 0}人'),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.star, '球技要求: ${activity.skillLevelName}'),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.payment, '费用模式: ${activity.feeModeName}'),
          if ((activity.note ?? '').isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 4),
                _buildInfoRow(Icons.note, activity.note ?? ''),
              ],
            ),
          const SizedBox(height: 16),
          if (!activity.isUsed)
            _buildUsedActions(context)
          else
            _buildUnusedActions(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildUnusedActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: null,
          child: const Text(
            '查看详情 >',
            style: TextStyle(color: Color(0xFF4285F4), fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildUsedActions(BuildContext context) {
    bool isExpired = activity.isExpired24h;
    
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isExpired ? const Color(0xFFE0E0E0) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '数字码',
                  style: TextStyle(
                    color: isExpired ? const Color(0xFF9E9E9E) : Colors.black,
                  ),
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: isExpired ? null : () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QRScannerPage()),
                      );
                      if (!context.mounted) return;
                      if (result != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('扫码结果: $result')),
                        );
                        // TODO: 处理扫码后的核销逻辑，比如调用API
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('扫一扫'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isExpired ? const Color(0xFF9E9E9E) : const Color(0xFF4285F4),
                      side: BorderSide(color: isExpired ? const Color(0xFF9E9E9E) : const Color(0xFF4285F4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isExpired ? null : () {
                      final qrData = 'verify_${activity.inviteid ?? activity.itieId}';
                      showDialog(
                        context: context,
                        builder: (context) => QrCodeDialog(qrData: qrData),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExpired ? const Color(0xFFE0E0E0) : const Color(0xFF4285F4),
                      foregroundColor: isExpired ? const Color(0xFF9E9E9E) : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('核销码'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
