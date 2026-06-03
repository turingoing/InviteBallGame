import 'package:flutter/material.dart';

import 'package:flutter_application_1/model/main/surroundings_model.dart';   //model文件
import 'package:flutter_application_1/widgets/venue_card.dart';
import 'package:flutter_application_1/utils/json_reader.dart';   //解码文件

// 周边页面（独立的场馆列表页面）
class SurroundingsPage extends StatefulWidget {
  const SurroundingsPage({super.key});

  @override
  State<SurroundingsPage> createState() => _SurroundingsPageState();
}

class _SurroundingsPageState extends State<SurroundingsPage> {
  // 异步加载场馆列表数据
  late Future<List<VenueModel>> _venueListFuture;   //等效于创建一个空列表

  @override
  void initState() {
    super.initState();
    // 初始化时读取JSON并解析成模型列表
    _venueListFuture = _loadVenueList();
  }

  // 封装：读取JSON + 解析成场馆模型列表
  Future<List<VenueModel>> _loadVenueList() async {
    // 1. 读取JSON文件
    List<dynamic> jsonList = await JsonReader.readJsonList('assets/json/main/surroundings_list.json');
    // 2. 转成VenueModel列表
    return jsonList.map((json) => VenueModel.fromJson(json)).toList();
  }

  // 筛选栏按钮组件（复用原有逻辑）
  Widget _buildFilterChip(String text, {bool isDropdown = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 16, color: Colors.grey[600]),
          if (icon != null) const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.black87)),
          if (isDropdown) const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 筛选栏（复用原有UI）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('全城', isDropdown: true),
                const SizedBox(width: 8),
                _buildFilterChip('综合排序', isDropdown: true),
                const SizedBox(width: 8),
                _buildFilterChip('筛选', isDropdown: true),
                const Spacer(),
                _buildFilterChip('上海', isDropdown: true, icon: Icons.location_on),
              ],
            ),
          ),
          // 场馆列表（异步渲染）
          Expanded(
            child: FutureBuilder<List<VenueModel>>(
              future: _venueListFuture,
              builder: (context, snapshot) {
                // 1. 加载中状态
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. 加载失败状态
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("暂无场馆数据"));
                }

                // 3. 数据加载成功，渲染列表
                final venueList = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
                  children: [
                    // 遍历场馆列表生成卡片
                    ...venueList.map((venue) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: VenueCard(venueData: venue),
                    )),
                    // 底部提示文字
                    const Center(child: Text('没有更多商家了', style: TextStyle(color: Colors.grey))),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}