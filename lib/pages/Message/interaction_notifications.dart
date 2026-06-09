import 'package:flutter/material.dart';

class InteractionNotificationItem {
  final String avatarUrl;
  final String userName;
  final String description;
  final String time;
  final String? imageUrl;
  final InteractionType type;
  final bool hasActionButtons;

  InteractionNotificationItem({
    required this.avatarUrl,
    required this.userName,
    required this.description,
    required this.time,
    this.imageUrl,
    required this.type,
    this.hasActionButtons = false,
  });
}

enum InteractionType {
  mention,
  visit,
  like,
  comment,
  follow,
}

class InteractionNotificationsPage extends StatefulWidget {
  const InteractionNotificationsPage({super.key});

  @override
  State<InteractionNotificationsPage> createState() => _InteractionNotificationsPageState();
}

class _InteractionNotificationsPageState extends State<InteractionNotificationsPage> {
  final List<InteractionNotificationItem> _items = [
    InteractionNotificationItem(
      avatarUrl: 'assets/images/dt/Ellipse 1.png',
      userName: 'cn雨林（被限流版',
      description: '提到了你: 快把这显眼包拉走#盗墓笔记cos #乐队私设 #oo...',
      time: '5月29日',
      imageUrl: 'assets/images/dt/Rectangle 28.png',
      type: InteractionType.mention,
    ),
    InteractionNotificationItem(
      avatarUrl: 'assets/images/dt/Ellipse 2.png',
      userName: '瑶瑶杏花村（努力更新中',
      description: '提到了你: 瓶（左上1）@白菜不等于菜',
      time: '',
      imageUrl: 'assets/images/dt/Rectangle 30.png',
      type: InteractionType.mention,
      hasActionButtons: true,
    ),
    InteractionNotificationItem(
      avatarUrl: 'assets/images/dt/Ellipse 2.png',
      userName: '瑶瑶杏花村（努力更新中',
      description: '提到了你: 当团建当天花儿爷临时有事来不了 瞎子就变成...',
      time: '5月23日',
      imageUrl: 'assets/images/dt/Rectangle 34.png',
      type: InteractionType.mention,
    ),
    InteractionNotificationItem(
      avatarUrl: 'assets/images/dt/Ellipse 2.png',
      userName: '瑶瑶杏花村（努力更新中',
      description: '提到了你: 云彩@ayayi',
      time: '5月23日',
      imageUrl: 'assets/images/dt/Rectangle 35.png',
      type: InteractionType.mention,
      hasActionButtons: true,
    ),
    InteractionNotificationItem(
      avatarUrl: 'assets/images/dt/Ellipse 6.png',
      userName: '齐冬森',
      description: '近期访问过你的主页',
      time: '5月1日',
      imageUrl: 'assets/images/dt/Rectangle 12.png',
      type: InteractionType.visit,
    ),
    InteractionNotificationItem(
      avatarUrl: 'assets/images/dt/Ellipse 12.png',
      userName: '金鱼',
      description: '赞了你的图文',
      time: '2月27日',
      imageUrl: 'assets/images/dt/Rectangle 8.png',
      type: InteractionType.like,
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
          '互动消息',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          return _buildNotificationItem(_items[index]);
        },
      ),
    );
  }

  Widget _buildNotificationItem(InteractionNotificationItem item) {
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
                      item.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (item.type == InteractionType.like)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '粉丝',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE67E22),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    item.time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.hasActionButtons) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '回复评论',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '赞',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (item.imageUrl != null) ...[
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              image: DecorationImage(
                image: AssetImage(item.imageUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLeadingIcon(InteractionNotificationItem item) {
    Widget avatar = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(item.avatarUrl),
          fit: BoxFit.cover,
        ),
      ),
    );

    IconData? badgeIcon;
    Color badgeColor = const Color(0xFFE8E5FF);
    Color iconColor = const Color(0xFF6A5AE0);

    switch (item.type) {
      case InteractionType.mention:
        badgeIcon = Icons.alternate_email;
        badgeColor = const Color(0xFFFFFBE0);
        iconColor = const Color(0xFFFFB800);
        break;
      case InteractionType.visit:
        badgeIcon = Icons.people;
        badgeColor = const Color(0xFFE5F0FF);
        iconColor = const Color(0xFF1E88E5);
        break;
      case InteractionType.like:
        badgeIcon = Icons.favorite;
        badgeColor = const Color(0xFFFFE5E5);
        iconColor = const Color(0xFFFF3B30);
        break;
      case InteractionType.comment:
      case InteractionType.follow:
        badgeIcon = Icons.person_add;
        break;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              badgeIcon,
              size: 10,
              color: iconColor,
            ),
          ),
        ),
      ],
    );
  }
}
