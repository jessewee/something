import 'package:base/base.dart';
import 'package:flutter/material.dart';
import 'package:forum/forum.dart';

import 'home_page.dart';
import 'launcher_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'retrieve_pwd_page.dart';

void main() {
  debugProfileBuildsEnabled = true;
  BaseApp.registerRoutes({
    LauncherPage.routeName: (_) => LauncherPage(),
    LoginPage.routeName: (_) => LoginPage(),
    RegisterPage.routeName: (_) => RegisterPage(),
    RetrievePwdPage.routeName: (_) => RetrievePwdPage(),
    HomePage.routeName: (_) => HomePage()
  });
  BaseApp.registerRoutes(forumRoutes);
  runApp(BaseApp(initialRoute: LauncherPage.routeName));
}
