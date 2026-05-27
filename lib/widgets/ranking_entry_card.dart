import 'package:flutter/material.dart';



// 独立的排行榜入口组件
class RankingEntryCard extends StatelessWidget {
  const RankingEntryCard({super.key});

   @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 0,left: 0,bottom: 3),
      padding: const EdgeInsets.only(right:16,left:16,top: 8,bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 头部：头像 + 用户名 + 位置
          Row(
            children: [
              // 头像（自定义URL + 在线状态）
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/images/dt/Group 43.png'),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户名（自定义）
                  Text(
                    '排行榜',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  // 地理位置（自定义）
                  Text(
                    "查看全服，区域及竞赛排名",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // 点击进入榜单页面
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // 按钮背景色
                  foregroundColor: Colors.white, // 文字颜色
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // 圆角按钮
                  ),
                  elevation: 0, // 去掉阴影
                ),
                child: const Text(
                  '进入榜单',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}