import 'dart:ui';

import 'package:base/base.dart';
import 'package:flutter/material.dart';
import 'package:forum/forum.dart';
import 'package:provider/provider.dart';
import 'package:base/model/m.dart';

void main() {
  debugProfileBuildsEnabled = true;
  BaseApp.registerRoutes({'/': (_) => HomePage()});
  BaseApp.registerRoutes(forumRoutes);
  runApp(MultiProvider(
    providers: [ChangeNotifierProvider<User>(create: (_) => User())],
    child: BaseApp(initialRoute: '/'),
  ));
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(5.0));
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 100.0,
              decoration: const BoxDecoration(
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Colors.cyan, Colors.indigo, Colors.blue],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: Colors.black26,
                  highlightColor: Colors.black12,
                  borderRadius: borderRadius,
                  child: Container(
                    alignment: Alignment.center,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25.0,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(text: '社 '),
                          TextSpan(
                            text: '畜',
                            style: TextStyle(
                              fontSize: 16.0,
                              decoration: TextDecoration.lineThrough,
                              decorationStyle: TextDecorationStyle.double,
                              decorationColor: Colors.red,
                              decorationThickness: 2.5,
                            ),
                          ),
                          TextSpan(text: ' 区'),
                        ],
                      ),
                    ),
                  ),
                  onTap: () => Navigator.pushNamed(context, '/forum'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
