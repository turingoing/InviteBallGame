import 'package:flutter/material.dart';

import 'package:flutter_application_1/utils/json_reader.dart'; //工具类
import 'package:flutter_application_1/model/main/dynamic_model.dart';
import 'package:flutter_application_1/widgets/dynamic_card.dart';

// 关注页
class DynamicFocus extends StatefulWidget {
  const DynamicFocus({super.key});

  @override
  State<DynamicFocus> createState() => _DynamicFocus();
}

class _DynamicFocus extends State<DynamicFocus> {
  // 异步加载JSON数据后的模型列表
  late Future<List<DynamicModel>> _dynamicListFuture;

  @override
  void initState() {
    super.initState();
    // 初始化时读取JSON并解析成模型列表
    _dynamicListFuture = _loadDynamicList();
  }

  // 封装：读取JSON + 解析成模型列表
  Future<List<DynamicModel>> _loadDynamicList() async {
    // 1. 读取JSON文件（返回List<dynamic>）
    List<dynamic> jsonList = await JsonReader.readJsonList('assets/json/main/dynamic_list.json');
    // 2. 把JSON List转成DynamicModel List
    return jsonList.map((json) => DynamicModel.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DynamicModel>>(
      future: _dynamicListFuture,
      builder: (context, snapshot) {
        // 1. 加载中状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. 加载失败状态
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("加载动态列表失败"));
        }

        // 3. 数据加载成功，渲染列表
        final dynamicList = snapshot.data!;
        return ListView.builder(
          // padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: dynamicList.length, // 排行榜+动态列表
          itemBuilder: (context, index) {
            final dynamicData = dynamicList[index];
            return DynamicCard(dynamicData: dynamicData);
          },
        );
      },
    );
  }
}

