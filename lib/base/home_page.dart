import 'package:flutter/material.dart';

import '../chatroom/chatroom.dart';
import '../forum/view/forum_page.dart';
import 'me_page.dart';

/// 首页
class HomePage extends StatelessWidget {
  static const routeName = 'home';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 社区
            _forum(context),
            Row(
              children: [
                // 聊天室
                Expanded(child: _chatroom(context)),
                // 我的
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _me(context),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem({
    @required BuildContext context,
    @required List<Color> gradient,
    @required Widget child,
    @required VoidCallback onTap,
  }) {
    const borderRadius = BorderRadius.all(Radius.circular(5.0));
    return Container(
      height: 100.0,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: gradient,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.black26,
          highlightColor: Colors.black12,
          borderRadius: borderRadius,
          child: Container(child: child, alignment: Alignment.center),
          onTap: onTap,
        ),
      ),
    );
  }

  // 社区入口
  Widget _forum(BuildContext context) {
    Widget child = RichText(
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
    );
    return _buildItem(
      context: context,
      gradient: [Colors.cyan, Colors.indigo, Colors.blue],
      child: child,
      onTap: () => Navigator.pushNamed(context, ForumPage.routeName),
    );
  }

  // 聊天室
  Widget _chatroom(BuildContext context) {
    return _buildItem(
      context: context,
      gradient: [Colors.blue[100], Colors.blue[800], Colors.blue],
      child: Text(
        '聊天室',
        style: TextStyle(
          color: Colors.white,
          fontSize: 25.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () => Navigator.pushNamed(context, Chatroom.routeName),
    );
  }

  // 我的入口
  Widget _me(BuildContext context) {
    return _buildItem(
      context: context,
      gradient: [Colors.green[100], Colors.green[800], Colors.green],
      child: Text(
        '我的',
        style: TextStyle(
          color: Colors.white,
          fontSize: 25.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () => Navigator.pushNamed(context, MePage.routeName),
    );
  }
}
