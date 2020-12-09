import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:something/forum/view/user_page.dart';

import '../common/extensions.dart';
import '../common/models.dart';
import 'chatroom_vm.dart';

/// 聊天室页面
class ChatRoom extends StatelessWidget {
  static const routeName = '/chatroom';
  @override
  Widget build(BuildContext context) {
    final userName = context.watch<UserVM>().user.name;
    return Provider<ChatroomVM>(
      create: (_) => ChatroomVM(userName),
      child: Scaffold(
        appBar: AppBar(
          title: Text('聊天室'),
          actions: [
            TextButton(
              onPressed: () => _showMembers(context),
              child: Text(
                '成员${context.select<ChatroomVM, int>((vm) => vm.totalMemberCount)}',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Expanded(child: _Content()), _Input()],
        ),
      ),
    );
  }

  // 显示成员列表
  void _showMembers(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2.0)),
      ),
      context: context,
      builder: (context) => _Members(),
    );
  }
}

/// 成员列表
class _Members extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH - 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 顶行
          Container(
            height: 60.0,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Text(
                    '成员${context.select<ChatroomVM, int>((vm) => vm.totalMemberCount)}'),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ).positioned(right: null),
              ],
            ),
          ),
          // 分割线
          Divider(height: 1.0, thickness: 1.0),
          // 观众
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
                '观众${context.select<ChatroomVM, int>((vm) => vm.viewerCnt)}'),
          ),
          // 成员列表
          ListView.builder(
            itemCount:
                context.select<ChatroomVM, int>((vm) => vm.members.length),
            itemBuilder: (context, index) => TextButton(
              child: Text(context
                  .select<ChatroomVM, List<String>>((vm) => vm.members)[index]),
              onPressed: () => Navigator.pushNamed(
                context,
                UserPage.routeName,
                arguments: "",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 聊天内容
class _Content extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

/// 输入框
class _Input extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
