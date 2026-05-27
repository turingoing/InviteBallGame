import 'package:flutter/material.dart';

//导入底部导航栏页面
import 'package:flutter_application_1/pages/VenueList/index.dart';
import 'package:flutter_application_1/pages/Message/index.dart';
import 'package:flutter_application_1/pages/Add/index.dart';
import 'package:flutter_application_1/pages/Mine/index.dart';

//首页组件
import 'package:flutter_application_1/pages/Main/Conponents/Surroundings.dart';
import 'package:flutter_application_1/pages/Main/Conponents/dynamic.dart';
import 'package:flutter_application_1/pages/Main/Conponents/focus.dart';


// 底部导航容器页
class MainTabPage extends StatefulWidget {
  final bool autoLogin;
  
  const MainTabPage({super.key, this.autoLogin = false});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentBottomIndex = 0;
  bool _showAutoLoginMessage = false;
  bool? _saveSuccess;

  @override
  void initState() {
    super.initState();
    // 检查是否是自动登录
    if (widget.autoLogin) {
      _showAutoLoginMessage = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 接收路由参数
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      // 检查是否是正常登录后的保存状态
      if (arguments.containsKey('saveSuccess')) {
        _saveSuccess = arguments['saveSuccess'];
      }
      // 检查是否是自动登录
      if (arguments.containsKey('autoLogin') && arguments['autoLogin']) {
        _showAutoLoginMessage = true;
      }
    }
    
    // 显示消息提示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showAutoLoginMessage) {
        _showMessage('已自动登录');
      } else if (_saveSuccess != null) {
        _showMessage(_saveSuccess! ? '登录信息已保存' : '登录信息保存失败');
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  final List<Widget> _pages = const [
    HomePage(),
    VenueListPage(),
    PublishContentPage(),
    MessagePage(),
    MinePage(),
  ];

  @override   // 底部导航栏
  Widget build(BuildContext context) {
    return Scaffold(

      body:  SafeArea(
        top: false,
        bottom: true, // 自动避开底部虚拟按键栏 ✅
        child: _pages[_currentBottomIndex],   //跳转的页面列表
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
            // alignment: Alignment.topLeft,
            height: 64,
          child:BottomNavigationBar(
              currentIndex: _currentBottomIndex,   //底部导航栏下方跳转的索引(上方以声明)

              backgroundColor: Colors.white,   //背景颜色
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.blue,   //选中颜色
              unselectedItemColor: Colors.grey,   //未选中颜色
            // 选中 状态下label的文字大小
              selectedLabelStyle: const TextStyle(
                fontSize: 10, 
              ),
            // 未选中 状态下label的文字大小
              unselectedLabelStyle: const TextStyle(
                fontSize: 10, 
              ),
              onTap: (index) {
                  if (index == 2) {
                    Navigator.pushNamed(context,"/add");
                    return;
                  }
                
                setState(() => _currentBottomIndex = index);
              },
            items: [
              BottomNavigationBarItem(
                icon: Image.asset('assets/images/dt/Union(2).png',width: 24,height: 24,),
                activeIcon: Image.asset(
                  'assets/images/dt/Union(2).png',
                  width: 24,
                  height: 24,
                  color: Colors.blue, // 高亮颜色（和 selectedItemColor 一致）
                  colorBlendMode: BlendMode.srcIn, // 保证颜色只应用到图片内容，背景透明
                ),
                label: '首页',
              ),
              BottomNavigationBarItem(
              icon: Image.asset('assets/images/dt/Union(3).png',width: 24,height: 24,),
              activeIcon: Image.asset(
                'assets/images/dt/Union(3).png',
                width: 24,
                height: 24,
                color: Colors.blue, // 高亮颜色（和 selectedItemColor 一致）
                colorBlendMode: BlendMode.srcIn, // 保证颜色只应用到图片内容，背景透明
              ),
              label: '约球',
            ),
              BottomNavigationBarItem(
              // backgroundColor:Color(0xFFFFC0CB),
              label: '',
              icon: Container(
                // margin: EdgeInsets.only(top: 1),
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
              BottomNavigationBarItem(
              icon: Stack(
                children: [
                  // const Icon(Icons.chat_bubble_outline,color: Colors.black,),
                  Image.asset('assets/images/dt/Union(4).png',width: 24,height: 24,),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '99',
                        style: TextStyle(color: Colors.white, fontSize: 6),
                      ),
                    ),
                  ),
                ],
              ),
              activeIcon: Stack(
                children: [
                  Image.asset(
                    'assets/images/dt/Union(4).png',
                    width: 24,
                    height: 24,
                    color: Colors.blue, // 高亮颜色
                    colorBlendMode: BlendMode.srcIn, // 保证只给图片上色
                  ),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '99',
                        style: TextStyle(color: Colors.white, fontSize: 6),
                      ),
                    ),
                  ),
                ],
              ),
              label: '消息',
            ),
              BottomNavigationBarItem(
                icon: Image.asset('assets/images/dt/Union(5).png',width: 24,height: 24,),
                activeIcon: Image.asset(
                  'assets/images/dt/Union(5).png',
                  width: 24,
                  height: 24,
                  color: Colors.blue, // 高亮颜色（和 selectedItemColor 一致）
                  colorBlendMode: BlendMode.srcIn, // 保证颜色只应用到图片内容，背景透明
                ),
                label: '我的',
              ),
            ],
          ),
        ),       
      )
    );
  }
}





// 首页（含关注/动态/周边 Tab）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.grey[200],

      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,   

        toolbarHeight: 40,  // 数值越小，整体高度越小

        // backgroundColor: Colors.white,
        elevation: 0,
//搜索图标
        leading: Padding(     //左边组件
          padding: const EdgeInsets.only(top: 1), // 想更右就把16改成20、24
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.grey,),
            onPressed: () {
              final textStyle = Theme.of(context).textTheme.bodyLarge!;
            print("当前全局字体 = ${textStyle.fontFamily}");
            },
          ),
        ),
        title: TabBar(
          controller: _tabController,
          // indicatorColor: Colors.blue,
          //蓝色下划线
          indicator: const UnderlineTabIndicator(

            borderSide: BorderSide(
              color: Colors.blue,
              width: 3, // 线条粗细
            ),
            insets: EdgeInsets.only(bottom: 6), // 控制距离文字的位置
          ),



          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,

          labelStyle: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 17),
          
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,

        //调整tab的间距，
          // 这三行 = 缩小间距 + 居中紧凑排列
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16), // 越小越紧凑
          tabs: const [
            Tab(text: '关注'),
            Tab(text: '动态'),
            Tab(text: '周边'),
          ],
        ),
//消息图标
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.grey),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const DynamicFocus(),
          DynamicPage(),
          const SurroundingsPage(),
        ],
      ),
    );
  }
}