import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:something/forum/forum.dart';

import 'base/home_page.dart';
import 'base/launcher_page.dart';
import 'base/login_page.dart';
import 'base/register_page.dart';
import 'base/retrieve_pwd_page.dart';
import 'common/models.dart';
import 'common/widgets.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

class MyApp extends StatelessWidget {
  final Map<String, WidgetBuilder> _routes = {
    LauncherPage.routeName: (_) => LauncherPage(),
    LoginPage.routeName: (_) => LoginPage(),
    RegisterPage.routeName: (_) => RegisterPage(),
    RetrievePwdPage.routeName: (_) => RetrievePwdPage(),
    HomePage.routeName: (_) => HomePage()
  };

  MyApp() {
    final exited = forumRoutes.keys.where((k) => _routes.containsKey(k));
    assert(exited.isEmpty, '以下页面路由名字已经存在：$exited');
    _routes.addAll(forumRoutes);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider<UserVM>(create: (_) => UserVM())],
      child: MaterialApp(
        initialRoute: _routes.keys.first,
        routes: _routes,
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
