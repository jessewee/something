import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../base/user_page.dart';
import '../common/extensions.dart';
import '../common/models.dart';
import 'chatroom_vm.dart';

/// 聊天室页面
class ChatRoom extends StatelessWidget {
  static const routeName = 'chatroom';
  @override
  Widget build(BuildContext context) {
    final userName = context.watch<UserVM>().user.name;
    return ChangeNotifierProvider<ChatroomVM>(
      create: (_) => ChatroomVM(userName),
      child: Builder(
        builder: (context) => Scaffold(
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
                arguments: UserPageArg(
                    userName:
                        context.select<ChatroomVM, String>((vm) => vm.name)),
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
    final contents =
        context.select<ChatroomVM, List<Message>>((vm) => vm.contents);
    final loginUser = context.select<UserVM, String>((vm) => vm.user.name);
    return ListView.builder(
      itemCount: contents.length,
      itemBuilder: (context, index) {
        final msg = contents[index];
        final time = formatTime(msg.time);
        final self = msg.sender == loginUser;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 消息时间
            if (time.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(time, textAlign: TextAlign.center),
              ),
            // 消息发送人
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                msg.sender,
                textAlign: self ? TextAlign.right : TextAlign.left,
              ),
            ),
            // 消息内容
            Container(
              margin: self
                  ? const EdgeInsets.only(left: 50.0)
                  : const EdgeInsets.only(right: 50.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: self ? Colors.green : Colors.blue,
              ),
              child: Text(
                msg.content,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String formatTime(int seconds) {
    final curSeconds = DateTime.now().millisecondsSinceEpoch / 1000;
    final diff = curSeconds - seconds;
    if (diff < 60) return '';
    if (diff < 3600) return '${diff ~/ 60}分钟前';
    final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    if (diff < 86400)
      return '${dateTime.hour.toStringWithTwoMinLength()}'
          ':${dateTime.minute.toStringWithTwoMinLength()}'
          ':${dateTime.second.toStringWithTwoMinLength()}';
    return dateTime.format();
  }
}

/// 输入框
class _Input extends StatefulWidget {
  @override
  __InputState createState() => __InputState();
}

class __InputState extends State<_Input> {
  TextEditingController _controller;
  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ChatroomVM>(context, listen: false);
    return Container(
      color: Colors.grey[200],
      child: TextField(
        decoration: InputDecoration(
          hintText: '请输入消息',
          contentPadding: const EdgeInsets.all(8.0),
        ),
        onSubmitted: (text) {
          vm.sendMsg(text);
          _controller.text = '';
        },
        controller: _controller,
      ),
    );
  }
}
