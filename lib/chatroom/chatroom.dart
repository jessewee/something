import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:something/base/login_page.dart';

import '../base/user_page.dart';
import '../common/extensions.dart';
import '../common/models.dart';
import 'chatroom_vm.dart';

/// 聊天室页面
class Chatroom extends StatefulWidget {
  static const routeName = 'chatroom';

  @override
  _ChatroomState createState() => _ChatroomState();
}

class _ChatroomState extends State<Chatroom> {
  ChatroomVM _vm;

  @override
  void initState() {
    _vm = ChatroomVM(context.read<UserVM>().user.name);
    _vm.init();
    super.initState();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('聊天室'),
        actions: [
          TextButton(
            onPressed: () => _showMembers(context),
            child: StreamBuilder<int>(
              initialData: _vm.totalCount.value,
              stream: _vm.totalCount.stream,
              builder: (_, snapshot) => Text(
                '成员${snapshot.data}',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              initialData: _vm.contents.value,
              stream: _vm.contents.stream,
              builder: (context, snapshot) => _Content(snapshot.data),
            ),
          ),
          _Input(_vm),
        ],
      ),
    );
  }

  void _showMembers(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2.0)),
      ),
      context: context,
      builder: (context) => _Members(_vm),
    );
  }
}

/// 成员列表
class _Members extends StatelessWidget {
  final ChatroomVM _vm;
  const _Members(this._vm);
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
                StreamBuilder<int>(
                  initialData: _vm.totalCount.value,
                  stream: _vm.totalCount.stream,
                  builder: (_, snapshot) => Text('成员${snapshot.data}'),
                ),
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
          StreamBuilder<int>(
            initialData: _vm.strangerCnt.value,
            stream: _vm.strangerCnt.stream,
            builder: (context, snapshot) => Visibility(
              visible: snapshot.data > 0,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text('观众${snapshot.data}'),
              ),
            ),
          ),
          // 成员列表
          Expanded(
            child: StreamBuilder<List<String>>(
                initialData: _vm.members.value,
                stream: _vm.members.stream,
                builder: (_, snapshot) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        runSpacing: 5.0,
                        spacing: 5.0,
                        children: snapshot.data
                            .map<Widget>(
                              (m) => ActionChip(
                                label: Text(m),
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  UserPage.routeName,
                                  arguments: UserPageArg(userName: m),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )),
          ),
        ],
      ),
    );
  }
}

/// 聊天内容
class _Content extends StatelessWidget {
  final List<Message> contents;
  const _Content(this.contents);
  @override
  Widget build(BuildContext context) {
    final loginUser = context.select<UserVM, String>((vm) => vm.user.name);
    String lastTime = '';
    final captionStyle = Theme.of(context).textTheme.caption;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      itemCount: contents.length,
      itemBuilder: (context, index) {
        final msg = contents[index];
        final time = formatTime(msg.time);
        final self = msg.sender == loginUser;
        final result = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 消息时间
            if (time.isNotEmpty && time != lastTime)
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(time, textAlign: TextAlign.center),
              ),
            // 消息发送人
            if (!msg.systemMsg)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  msg.sender,
                  textAlign: self ? TextAlign.right : TextAlign.left,
                  style: captionStyle,
                ),
              ),
            // 消息内容
            if (msg.systemMsg)
              Container(
                padding: const EdgeInsets.all(12.0),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25.0),
                    color: Colors.grey,
                  ),
                  child: Text(
                    msg.content,
                    style: captionStyle.copyWith(color: Colors.white),
                  ),
                ),
              )
            else
              Container(
                margin: self
                    ? const EdgeInsets.only(left: 80.0)
                    : const EdgeInsets.only(right: 80.0),
                alignment: self ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
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
              ),
          ],
        );
        lastTime = time;
        return result;
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
  final ChatroomVM vm;
  const _Input(this.vm);
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
    final loginUser = context.watch<UserVM>();
    widget.vm.name = loginUser.user.name;
    if (loginUser.user.id.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: TextButton(
          child: Text('登录后可参与聊天'),
          onPressed: () => Navigator.pushNamed(context, LoginPage.routeName),
        ),
      );
    }
    return Container(
      color: Colors.grey[200],
      child: TextField(
        decoration: InputDecoration(
          hintText: '请输入消息',
          contentPadding: const EdgeInsets.all(8.0),
        ),
        onSubmitted: (text) {
          widget.vm.sendMsg(text);
          _controller.text = '';
        },
        controller: _controller,
      ),
    );
  }
}
