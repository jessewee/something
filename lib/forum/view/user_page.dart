import 'package:flutter/material.dart';

/// 用户信息页
class UserPage extends StatefulWidget {
  static const routeName = '/forum/user';

  UserPage(String userId);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String _title = '用户';

  @override
  Widget build(BuildContext context) {
    // TODO 名字加性别放到标题栏里
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 名字
              // 性别
              // 头像
              // 生日
              // 注册日期
              // 关注的人数
              // 粉丝数量
              // 发帖数量
              // 回复数量
            ],
          ),
        ),
      ),
    );
  }
}
