import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../configs.dart';

class ChatroomVM with ChangeNotifier {
  final String name;
  int _viewerCnt = 0;
  List<String> _members = [];
  List<Message> _contents = [];
  WebSocketChannel _webSocketChannel;

  /// 总数量
  int get totalMemberCount => _viewerCnt + _members.length;

  /// 非成员数量
  int get viewerCnt => _viewerCnt;

  /// 成员列表
  List<String> get members => _members;

  /// 内容列表
  List<Message> get contents => _contents;

  ChatroomVM(this.name) {
    _webSocketChannel = IOWebSocketChannel.connect('${apiServer}chatroom');
    _webSocketChannel.stream.listen((event) {
      print('------------------------------------------------');
      print(event);
    });
  }
  @override
  void dispose() {
    super.dispose();
    _webSocketChannel.sink.close();
    _webSocketChannel = null;
  }

  /// 发送消息
  void sendMsg(String msg) {
    _webSocketChannel?.sink?.add(msg);
  }
}

/// 聊天消息
class Message {
  final String sender;
  final int time; // 秒数
  final String content;
  Message(this.sender, this.time, this.content);
}
