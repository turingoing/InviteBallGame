import 'package:flutter/material.dart';

class BookingStatusItem {
  final String iconAsset;
  final String title;
  final String content;
  final String date;
  final bool hasUnread;

  BookingStatusItem({
    required this.iconAsset,
    required this.title,
    required this.content,
    required this.date,
    this.hasUnread = false,
  });
}

class BookingNotificationPage extends StatefulWidget {
  const BookingNotificationPage({super.key});

  @override
  State<BookingNotificationPage> createState() => _BookingNotificationPageState();
}

class _BookingNotificationPageState extends State<BookingNotificationPage> {
  final List<BookingStatusItem> _items = [
    BookingStatusItem(
      iconAsset: 'assets/images/zb/Group 35.png',
      title: '库诺克进阶赛',
      content: '您的库诺克进阶赛报名已通过，请准时参加',
      date: '05/06',
      hasUnread: true,
    ),
    BookingStatusItem(
      iconAsset: 'assets/images/zb/Group 56.png',
      title: '周末友谊赛',
      content: '比赛时间调整通知：本周六下午2点准时开赛',
      date: '05/06',
      hasUnread: true,
    ),
    BookingStatusItem(
      iconAsset: 'assets/images/zb/Group 57.png',
      title: '会员专属赛',
      content: '恭喜您获得会员专属赛参赛资格',
      date: '04/29',
    ),
    BookingStatusItem(
      iconAsset: 'assets/images/zb/Group 58.png',
      title: '月度积分赛',
      content: '本月积分赛即将开始，期待您的参与',
      date: '04/04',
      hasUnread: true,
    ),
    BookingStatusItem(
      iconAsset: 'assets/images/zb/AppShow.png',
      title: '新手训练营',
      content: '[报名进度] 您的报名正在审核中',
      date: '03/14',
    ),
    BookingStatusItem(
      iconAsset: 'assets/images/dt/Ellipse 1.png',
      title: '年度总决赛',
      content: '尊敬的选手，您已成功晋级年度总决赛',
      date: '02/13',
      hasUnread: true,
    ),
    BookingStatusItem(
      iconAsset: 'assets/images/dt/Ellipse 2.png',
      title: '新春杯',
      content: '比赛场地变更通知：改至A馆2号台',
      date: '2025/12/25',
    ),
    BookingStatusItem(
      iconAsset: 'assets/images/dt/Ellipse 6.png',
      title: '秋季公开赛',
      content: '比赛结果公示：您获得季军，奖金已发放',
      date: '2025/09/19',
    ),
    BookingStatusItem(
      iconAsset: 'assets/images/dt/Ellipse 12.png',
      title: '夏季联赛',
      content: '赛事回顾：精彩瞬间集锦已发布',
      date: '2025/08/08',
    ),
  ];

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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        children: [
          const Text(
            '两周前消息',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ..._items.map((item) => _buildStatusItem(item)),
        ],
      ),
    );
  }

  Widget _buildStatusItem(BookingStatusItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(item.iconAsset),
                fit: BoxFit.cover,
              ),
            ),
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
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      item.date,
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
                        item.content,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (item.hasUnread)
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
