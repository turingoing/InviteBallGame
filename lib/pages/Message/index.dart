import 'package:flutter/material.dart';

import 'package:flutter_application_1/model/messages/list_model.dart'; // model路径
import 'package:flutter_application_1/utils/json_reader.dart'; // 工具类路径


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


// 分类-数据模型
class MessageCategory {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color bgColor;
  final bool hasBadge;

  MessageCategory({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.bgColor,
    required this.hasBadge,
  });
}


//主要区域
class Message extends StatefulWidget {
  const Message({super.key});

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {

  // 分类-json数据
  final List<MessageCategory> _categoryList = [
    MessageCategory(
      icon: Icons.favorite,
      title: '互动消息',
      iconColor: const Color(0xFF007AFF),
      bgColor: const Color(0xFFF0F4FF),
      hasBadge: true,
    ),
    MessageCategory(
      icon: Icons.sports_tennis,
      title: '约球通知',
      iconColor: const Color(0xFF5856D6),
      bgColor: const Color(0xFFF5F3FF),
      hasBadge: false,
    ),
    MessageCategory(
      icon: Icons.notifications,
      title: '系统通知',
      iconColor: const Color(0xFFFF9500),
      bgColor: const Color(0xFFFFF7E6),
      hasBadge: true,
    ),
    MessageCategory(
      icon: Icons.headphones,
      title: '在线客服',
      iconColor: const Color(0xFF007AFF),
      bgColor: const Color(0xFFF0F4FF),
      hasBadge: false,
    ),
  ];



// 从JSON加载的消息列表
List<MessageItem> _messageList = [];

@override
void initState() {
  super.initState();
  _loadMessageData(); // 页面一打开就加载JSON
}

Future<void> _loadMessageData() async {
  // 读取你的JSON文件
  final jsonList = await JsonReader.readJsonList('assets/json/messages/list.json');
  
  setState(() {
    // 转成模型
    _messageList = jsonList.map((json) => MessageItem.fromJson(json)).toList();
  });
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
            const SizedBox(height: 24),
            // 分类入口栏
            _buildCategoryBar(),
            // const SizedBox(height: 18),
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

  // 分类入口栏
  Widget _buildCategoryBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _categoryList.map((category) {
        return _buildCategoryItem(category);
      }).toList(),
    );
  }

  // 单个分类入口项
  Widget _buildCategoryItem(MessageCategory category) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: category.bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                category.icon,
                size: 32,
                color: category.iconColor,
              ),
            ),
        // 小红点角标
            if (category.hasBadge)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          category.title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
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
    );
  }
}