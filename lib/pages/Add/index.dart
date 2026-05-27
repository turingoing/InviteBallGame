import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Add/components/competition.dart';
import 'package:flutter_application_1/pages/Add/components/invite.dart';
import 'package:flutter_application_1/pages/Add/post.dart';
// import 'dart:io';
// import 'package:image_picker/image_picker.dart';

class PublishContentPage extends StatelessWidget {
  const PublishContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight:45,
        scrolledUnderElevation: 0, // 滚动时不抬高
        surfaceTintColor: Colors.transparent, // 取消滚动变色
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(      //标题
          '发布内容',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [Container(
          margin: EdgeInsets.only(right: 15),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Center(
            child: Text(
              '?',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
            ),
          ),
        ),],
        centerTitle: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20,right: 20,top: 0,bottom: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 发动态选项
              _PublishOption(
                iconData: Icons.flash_on,
                title: '发动态',
                subtitle: '记录你的进球瞬间',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PublishPostPage()));
                },
              ),
              const SizedBox(height: 24),
              // 发布约球选项 (蓝色高亮)
              _PublishOption(
                iconData: Icons.person_add_rounded,
                title: '发布约球',
                subtitle: '寻找身边的台球搭子',
                isPrimary: true,
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const InviteForm()));
                },
              ),
              const SizedBox(height: 24),
              // 发布比赛选项
              _PublishOption(
                iconData: Icons.emoji_events_outlined,
                title: '发布比赛',
                subtitle: '组织一场竞技对抗',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PublishCompetitionPage()));
                },
              ),
              const SizedBox(height: 32),
              // 关闭按钮
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.close, color: Color(0xFF757575)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// 发布选项组件   ===   模型model
class _PublishOption extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PublishOption({
    required this.iconData,
    required this.title,
    required this.subtitle,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = isPrimary ? colorScheme.primary : const Color(0xFF757575);
    final iconBgColor = isPrimary ? colorScheme.primary : const Color(0xFFF5F5F5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Column(
            children: [
              // 图标容器
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(
                  iconData,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              // 标题
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              // 副标题
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}










































