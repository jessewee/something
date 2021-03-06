import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:something/common/pub.dart';

import 'base/home_page.dart';
import 'base/launcher_page.dart';
import 'base/login_page.dart';
import 'base/me_page.dart';
import 'base/register_page.dart';
import 'base/retrieve_pwd_page.dart';
import 'base/user_page.dart';
import 'chatroom/chatroom.dart';
import 'common/event_bus.dart';
import 'forum/forum.dart';

import 'common/models.dart';
import 'common/widgets.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

/// 应用入口
class MyApp extends StatefulWidget {
  final Map<String, WidgetBuilder> _mappedRoutes;

  /// routeName是路径格式的话，会把前边的也push进去，比如要显示/a/b页面时，会依次把/、/a、/a/b三个页面都push到页面栈里，所以routeName就不要带/了
  /// 详见MaterialApp的initialRoute说明
  final List<RouteInfo> _routes = [
    RouteInfo(LauncherPage.routeName, false, (_) => LauncherPage()),
    RouteInfo(HomePage.routeName, false, (_) => HomePage()),
    RouteInfo(RegisterPage.routeName, false, (_) => RegisterPage()),
    RouteInfo(LoginPage.routeName, false, (_) => LoginPage()),
    RouteInfo(RetrievePwdPage.routeName, false, (_) => RetrievePwdPage()),
    RouteInfo(MePage.routeName, true, (_) => MePage()),
    RouteInfo(UserPage.routeName, false, (context) {
      final arg = ModalRoute.of(context).settings.arguments;
      if (arg == null || arg is! UserPageArg) return ParamErrorPage(arg);
      final userPageArg = arg as UserPageArg;
      if (userPageArg.userId?.isNotEmpty != true &&
          userPageArg.userName.isNotEmpty != true) {
        return ParamErrorPage(arg);
      }
      return UserPage(userPageArg);
    }),
    RouteInfo(Chatroom.routeName, false, (_) => Chatroom()),
  ];

  MyApp() : _mappedRoutes = {} {
    final exited = forumRoutes
        .where((f) => _routes.indexWhere((r) => f.name == r.name) >= 0);
    assert(exited.isEmpty, '以下页面路由名字已经存在：$exited');
    _routes.addAll(forumRoutes);
    for (final r in _routes) {
      // 进入页面要先登录的情况
      if (r.needLogin) {
        _mappedRoutes[r.name] = (context) {
          final user = context.watch<UserVM>().user;
          if (user.id?.isNotEmpty == true) {
            return r.builder(context);
          } else {
            showToast('请先登录');
            return LoginPage();
          }
        };
      } else {
        _mappedRoutes[r.name] = r.builder;
      }
    }
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // 注册监听
    eventBus.on(EventBusType.loginInvalid, (_) {
      Navigator.pushNamed(navigatorKey.currentContext, LoginPage.routeName);
    });
    super.initState();
  }

  @override
  void dispose() {
    eventBus.off(type: EventBusType.loginInvalid);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider<UserVM>(create: (_) => UserVM())],
      child: MaterialApp(
        initialRoute: widget._routes.first.name,
        routes: widget._mappedRoutes,
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (context) => NotFoundPage(settings.name),
        ),
        navigatorKey: navigatorKey,
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          inputDecorationTheme: InputDecorationTheme(
            isDense: true,
            isCollapsed: true,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

/// 页面路由信息
class RouteInfo {
  final String name;
  final bool needLogin;
  final WidgetBuilder builder;
  RouteInfo(this.name, this.needLogin, this.builder);
}
