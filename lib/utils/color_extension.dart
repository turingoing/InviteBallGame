import 'package:flutter/material.dart';

// 通用的十六进制颜色扩展方法
extension HexColor on Color {
  static Color fromHex(String hexString) {
    // 增强容错：处理空值、位数不足的情况
    final hex = hexString.replaceAll('#', '').padLeft(6, '0');
    if (hex.length != 6) {
      throw ArgumentError('无效的十六进制颜色格式，需为 #RRGGBB 或 RRGGBB');
    }
    return Color(int.parse('FF$hex', radix: 16));
  }

  // 拓展：支持带透明度的十六进制（#AARRGGBB）
  static Color fromHexWithAlpha(String hexString) {
    final hex = hexString.replaceAll('#', '').padLeft(8, '0');
    if (hex.length != 8) {
      throw ArgumentError('无效的带透明度十六进制颜色格式，需为 #AARRGGBB 或 AARRGGBB');
    }
    return Color(int.parse(hex, radix: 16));
  }
}