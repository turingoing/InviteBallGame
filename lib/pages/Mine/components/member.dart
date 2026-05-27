import 'package:flutter/material.dart';


class MemberCenterApp extends StatelessWidget {
  const MemberCenterApp({super.key});

  @override
  Widget build(BuildContext context) {


    
    return MemberCenterPage();
  }
}

class MemberCenterPage extends StatefulWidget {
  const MemberCenterPage({super.key});

  @override
  State<MemberCenterPage> createState() => _MemberCenterPageState();
}

class _MemberCenterPageState extends State<MemberCenterPage> {
  // 会员活动数据
  final List<ActivityModel> _activityList = [
    ActivityModel(
      title: '线下会员聚餐·交流会',
      time: '12月15日',
      address: '上海·瑞吉斯俱乐部',
      status: '报名中',
      statusColor: const Color(0xFFFF7D00),
      imageUrl: 'https://picsum.photos/seed/dog1/400/220',
    ),
    ActivityModel(
      title: '2024"黑金杯"线下公开赛',
      time: '11月25日',
      address: '上海·瑞吉斯俱乐部',
      status: '进行中',
      statusColor: const Color(0xFF2563EB),
      imageUrl: 'https://picsum.photos/seed/plant1/400/220',
    ),
    ActivityModel(
      title: '顶级教练：线下动作纠偏沙龙',
      time: '',
      address: '',
      status: '限额报名',
      statusColor: const Color(0xFF2563EB),
      imageUrl: 'https://picsum.photos/seed/plant2/120/80',
      isSmallCard: true,
      desc: '仅限黑金会员 20人',
      joinCount: '已有15人参加',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '会员中心',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.help_outline, color: Colors.black, size: 22),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. 黑金会员头部卡片
          _buildMemberHeader(),
          const SizedBox(height: 12),
          // 2. 成长值进度
          _buildGrowthProgress(),
          const SizedBox(height: 20),
          // 3. 会员专属特权
          _buildPrivilegeSection(),
          const SizedBox(height: 20),
          // 4. 会员专属活动
          _buildActivitySection(),
          const SizedBox(height: 30),
          // 5. 底部续费按钮
          _buildRenewButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 构建黑金会员头部卡片
  Widget _buildMemberHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '黑金会员',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.account_circle, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '会员有效期至',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '2025-12-31',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text(
                  '尊享特权',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


//---------------------------------------------------------------------------------
  /// 成长值进度
  Widget _buildGrowthProgress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '成长值进度',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              Text(
                '750 / 1000',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 750 / 1000,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '再获得 250 积分即可升级为"至尊龙爵会员"',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }


//---------------------------------------------------------------------------------
  /// 专属特权
  Widget _buildPrivilegeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '会员专属特权',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  '查看全部',
                  style: TextStyle(fontSize: 14, color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              PrivilegeItem(icon: Icons.badge_outlined, title: '身份标识'),
              PrivilegeItem(icon: Icons.discount_outlined, title: '报名优惠'),
              PrivilegeItem(icon: Icons.event_outlined, title: '专属活动'),
            ],
          ),
        ],
      ),
    );
  }


//---------------------------------------------------------------------------------
  /// 专属活动
  Widget _buildActivitySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '会员专属活动',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ..._activityList.map((item) => _buildActivityItem(item)).toList(),
        ],
      ),
    );
  }

  /// 构建单个活动项
  Widget _buildActivityItem(ActivityModel model) {
    if (model.isSmallCard) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                model.imageUrl,
                width: 100,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.desc ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: model.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          model.status,
                          style: TextStyle(fontSize: 11, color: model.statusColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        model.joinCount ?? '',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  model.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: model.statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    model.status,
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      model.time,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      model.address,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
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


//---------------------------------------------------------------------------------
  /// 构建底部续费按钮
  Widget _buildRenewButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF2563EB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 2,
        ),
        child: const Text(
          '立即续费 · ¥299/年 »',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

/// 特权项组件
class PrivilegeItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const PrivilegeItem({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            // borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// 活动数据模型
class ActivityModel {
  final String title;
  final String time;
  final String address;
  final String status;
  final Color statusColor;
  final String imageUrl;
  final bool isSmallCard;
  final String? desc;
  final String? joinCount;

  ActivityModel({
    required this.title,
    required this.time,
    required this.address,
    required this.status,
    required this.statusColor,
    required this.imageUrl,
    this.isSmallCard = false,
    this.desc,
    this.joinCount,
  });
}