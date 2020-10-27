library base;

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

// ignore: must_be_immutable
class BaseApp extends StatelessWidget {
  final String initialRoute;
  static Map<String, WidgetBuilder> _routes = {};
  RouteFactory onGenerateRoute;

  static void registerRoutes(Map<String, WidgetBuilder> routes) {
    final exited = routes.keys.where((k) => _routes.containsKey(k));
    assert(exited.isEmpty, '以下页面路由名字已经存在：$exited');
    _routes.addAll(routes);
  }

  BaseApp({@required this.initialRoute}) {
    this.onGenerateRoute = (RouteSettings settings) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => NotFoundPage(settings.name),
      );
    };
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: initialRoute,
      routes: _routes,
      onGenerateRoute: onGenerateRoute,
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
    );
  }
}

class NotFoundPage extends StatelessWidget {
  final String path;

  const NotFoundPage(this.path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('页面未找到')),
      body: Center(child: Text('$path')),
    );
  }
}

class ParamErrorPage extends StatelessWidget {
  final dynamic arg;

  const ParamErrorPage(this.arg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('参数错误')),
      body: Center(child: Text('$arg')),
    );
  }
}
