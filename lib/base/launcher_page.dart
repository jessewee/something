import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/models.dart';
import 'api/api.dart' as api;
import 'home_page.dart';
import 'login_page.dart';

/// 启动页
class LauncherPage extends StatefulWidget {
  static const routeName = '/launcher';
  @override
  _LauncherPageState createState() => _LauncherPageState();
}

class _LauncherPageState extends State<LauncherPage> {
  @override
  void initState() {
    api.getUserInfo().then((result) {
      if (result.success) {
        context.read<UserVM>().user = result.data;
        Navigator.of(context).pushReplacementNamed(HomePage.routeName);
      } else {
        Navigator.of(context).pushReplacementNamed(LoginPage.routeName);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        child: Center(child: FlutterLogo(size: 150.0)),
      ),
    );
  }
}
