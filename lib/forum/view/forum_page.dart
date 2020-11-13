import 'package:flutter/material.dart';

import 'follow_page.dart';
import 'me_page.dart';
import 'message_page.dart';
import 'posts_page.dart';

/// 社区页
class ForumPage extends StatefulWidget {
  static const routeName = '/forum';

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  int _curTabIdx = 0;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _curTabIdx,
        type: BottomNavigationBarType.shifting,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            backgroundColor: primaryColor,
            label: '社区',
            icon: Icon(Icons.mode_comment),
          ),
          BottomNavigationBarItem(
            backgroundColor: primaryColor,
            label: '关注',
            icon: Icon(Icons.center_focus_strong),
          ),
          BottomNavigationBarItem(
            backgroundColor: primaryColor,
            label: '消息',
            icon: Icon(Icons.notifications_none),
          ),
          BottomNavigationBarItem(
            backgroundColor: primaryColor,
            label: '我的',
            icon: Icon(Icons.menu),
          ),
        ],
        onTap: (index) => setState(() => _curTabIdx = index),
      ),
      body: IndexedStack(
        index: _curTabIdx,
        children: <Widget>[PostsPage(), FollowPage(), MessagePage(), MePage()],
      ),
    );
  }
}
