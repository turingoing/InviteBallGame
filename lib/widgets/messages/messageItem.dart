// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/model/messages/list_model.dart';


// // 单个消息列表项
//   Widget MessageItem(MessageItem item) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 左侧图标
//           Stack(
//             clipBehavior: Clip.none,
//             children: [
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   color: item.bgColor,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   item.icon,
//                   size: 24,
//                   color: Colors.black87,
//                 ),
//               ),
//               // 小红点角标
//               if (item.hasBadge)
//                 Positioned(
//                   right: 2,
//                   top: 2,
//                   child: Container(
//                     width: 8,
//                     height: 8,
//                     decoration: const BoxDecoration(
//                       color: Color(0xFFFF3B30),
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(width: 12),
//           // 中间内容
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // 标题 + 时间
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       item.title,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black,
//                       ),
//                     ),
//                     Text(
//                       item.time,
//                       style: const TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 // 内容
//                 Text(
//                   item.content,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                     height: 1.4,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }