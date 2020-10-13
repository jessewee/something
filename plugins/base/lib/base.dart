library base;

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

class BaseApp extends StatelessWidget {
  final String initialRoute;
  final Map<String, WidgetBuilder> routes;
  final RouteFactory onGenerateRoute;

  const BaseApp({
    @required this.initialRoute,
    @required this.routes,
    @required this.onGenerateRoute,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: initialRoute,
      routes: routes,
      onGenerateRoute: onGenerateRoute,
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
    );
  }
}
