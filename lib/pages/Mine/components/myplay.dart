import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/mine/myplay_model.dart';
import 'package:flutter_application_1/utils/json_reader.dart';

class MyPlayPage extends StatefulWidget {
  const MyPlayPage({super.key});

  @override
  State<MyPlayPage> createState() => _MyPlayPageState();
}

class _MyPlayPageState extends State<MyPlayPage> {
  List<PlayActivity> activityList = [];

  @override
  void initState() {
    super.initState();
    loadPlayData();
  }

  // 加载JSON约玩数据
  Future<void> loadPlayData() async {
    final jsonList = await JsonReader.readJsonList(
      'assets/json/mine/myplay.json',
    );
    setState(() {
      activityList = jsonList
          .map((item) => PlayActivity.fromJson(item))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('我的约玩'),
        leading: const BackButton(),
        actions: const [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: null,
          ),
        ],
      ),
      body: activityList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _EntryTipCard(),
                  const SizedBox(height: 20),
                  // 动态渲染活动列表
                  ...activityList.map((activity) {
                    return Column(
                      children: [
                        _ActivitySection(
                          title: activity.title,
                          activityName: activity.activityName,
                          date: activity.date,
                          location: activity.location,
                          isUsed: activity.isUsed,
                          participantCount: activity.participantCount,
                          totalCount: activity.totalCount,
                          depositReturned: activity.depositReturned,
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}

// ===================== 以下是原有UI组件，保持不变 =====================

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
      )
    );
  }
}

class _ActivitySection extends StatelessWidget {
  final String title;
  final String activityName;
  final String date;
  final String location;
  final bool isUsed;
  final int? participantCount;
  final int? totalCount;
  final bool? depositReturned;

  const _ActivitySection({
    required this.title,
    required this.activityName,
    required this.date,
    required this.location,
    required this.isUsed,
    this.participantCount,
    this.totalCount,
    this.depositReturned,
  });

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
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0288D1),
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                isUsed ? '已结束' : '待核销',
                style: TextStyle(
                  color: isUsed
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
            activityName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, date),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on, location),
          const SizedBox(height: 16),
          if (!isUsed)
            _buildUsedActions()
          else
            _buildUnusedActions(depositReturned!),
        ],
      )
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ]
    );
  }

  Widget _buildUnusedActions(bool depositReturned) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (depositReturned)
          const Text(
            '保证金已退还',
            style: TextStyle(color: Color(0xFF4CAF50), fontSize: 14),
          )
        else
          const SizedBox(),
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

  Widget _buildUsedActions() {
    return Row(
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline, size: 16),
            const SizedBox(width: 4),
            Text('$participantCount/$totalCount'),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('数字码'),
              ),
              ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('核销码'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}