import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'pages/main_tab_page.dart';

//导入页面
import 'package:flutter_application_1/pages/Main/index.dart';
import 'package:flutter_application_1/pages/Message/index.dart';
import 'package:flutter_application_1/pages/Mine/index.dart';
import 'package:flutter_application_1/pages/VenueList/index.dart';
import 'package:flutter_application_1/pages/Add/index.dart';
import 'package:flutter_application_1/pages/Auth/login.dart';
import 'package:flutter_application_1/pages/Auth/register.dart';
import 'package:flutter_application_1/pages/splash.dart';

Widget getRootWidget(){
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
        // 核心：设置系统导航栏样式
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            // 导航栏背景色：白色
            systemNavigationBarColor: Colors.white,
            // 导航栏图标/文字颜色：黑色（白色背景配黑色图标才看得清）
            systemNavigationBarIconBrightness: Brightness.dark,
            // 可选：同步设置状态栏样式
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        // 其他主题配置...
        primarySwatch: Colors.blue,
      ),

    initialRoute: "/splash",
    routes: getRootRoutes(),
  );
}

//返回该App的路由配置
Map<String, Widget Function(BuildContext)> getRootRoutes (){
  return {
    "/splash":(context)=>const SplashScreen(),
    "/login":(context)=>const LoginPage(),
    "/register":(context)=>const RegisterPage(),
    "/main":(context)=>MainTabPage(),
    "/venue":(context)=>VenueListPage(),
    "/add":(context)=>PublishContentPage(),
    "/message":(context)=>MessagePage(),
    "/mine":(context)=>MinePage(),
  };
}