import 'package:flutter/material.dart';

class BillRecordPage extends StatefulWidget {
  const BillRecordPage({super.key});

  @override
  State<BillRecordPage> createState() => _BillRecordPageState();
}

class _BillRecordPageState extends State<BillRecordPage> {
  // 账单数据模型
  final List<BillItem> _billList = [
    BillItem(
      icon: '台球搭子',
      iconType: IconType.text,
      name: '台球搭子',
      amount: -10.00,
      date: '6月11日 09:18',
      status: null,
    ),
    BillItem(
      icon: '台球搭子',
      iconType: IconType.text,
      name: '台球搭子',
      amount: -10.00,
      date: '6月10日 20:32',
      status: null,
    ),
    BillItem(
      icon: '台球搭子',
      iconType: IconType.text,
      name: '台球搭子-退款',
      amount: 10.00,
      date: '6月10日 19:25',
      status: null,
    ),
    BillItem(
      icon: '台球搭子',
      iconType: IconType.text,
      name: '台球搭子',
      amount: -10.00,
      date: '6月10日 18:20',
      status: '已全额退款',
    ),
    BillItem(
      icon: '台球搭子',
      iconType: IconType.text,
      name: '台球搭子',
      amount: -10.00,
      date: '6月10日 18:09',
      status: null,
    ),
    BillItem(
      icon: '台球搭子',
      iconType: IconType.text,
      name: '台球搭子',
      amount: -10.00,
      date: '6月10日 17:03',
      status: null,
    ),
    BillItem(
      icon: '台球搭子',
      iconType: IconType.text,
      name: '台球搭子-退款',
      amount: 10.00,
      date: '6月10日 17:02',
      status: null,
    ),
    BillItem(
      icon: '台球搭子',
      iconType: IconType.text,
      name: '台球搭子',
      amount: -10.00,
      date: '6月10日 12:09',
      status: null,
    ),
    BillItem(
      icon: '台球搭子',
      iconType: IconType.text,
      name: '台球搭子',
      amount: -10.00,
      date: '6月10日 12:08',
      status: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '账单',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black, size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部筛选栏
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 全部账单下拉
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        '全部账单',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 搜索框
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, size: 16, color: Color(0xFF999999)),
                        SizedBox(width: 8),
                        Text(
                          '查找交易',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 收支统计
           
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 月份和统计
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text(
                      '2026年6月',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      '支出¥50.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                   
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 账单列表
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _billList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildBillItem(_billList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillItem(BillItem item) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 图标
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getIconBgColor(item.icon),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.icon.substring(0, 1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getIconTextColor(item.icon),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                    if (item.status != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.status!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // 金额
          Text(
            item.amount >= 0 ? '+¥${item.amount.toStringAsFixed(2)}' : '¥${item.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: item.amount >= 0 ? const Color(0xFF00C853) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Color _getIconBgColor(String icon) {
    switch (icon) {
      case '台球搭子':
        return const Color(0xFF2196F3);
      case '美团':
        return const Color(0xFFFFD100);
      case '羊城通':
        return const Color(0xFF00C853);
      case '小霞包点':
        return const Color(0xFF6750A4);
      case '潮式':
        return const Color(0xFF795548);
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  Color _getIconTextColor(String icon) {
    switch (icon) {
      case '台球搭子':
        return Colors.white;
      case '美团':
        return Colors.black;
      case '羊城通':
        return Colors.white;
      case '小霞包点':
        return Colors.white;
      case '潮式':
        return Colors.white;
      default:
        return Colors.black;
    }
  }
}

// 图标类型枚举
enum IconType {
  text,
  image,
}

// 账单项数据模型
class BillItem {
  final String icon;
  final IconType iconType;
  final String name;
  final double amount;
  final String date;
  final String? status;

  BillItem({
    required this.icon,
    required this.iconType,
    required this.name,
    required this.amount,
    required this.date,
    this.status,
  });
}