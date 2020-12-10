import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../configs.dart';
import '../common/pub.dart';

class ChatroomVM {
  String name;
  int _strangerCnt = 0;
  List<String> _members = [];
  List<Message> _contents = [];
  WebSocketChannel _webSocketChannel;

  /// 总人数
  StreamControllerWithData<int> totalCount;

  /// 非成员数量
  StreamControllerWithData<int> strangerCnt;

  /// 成员列表
  StreamControllerWithData<List<String>> members;

  /// 内容列表
  StreamControllerWithData<List<Message>> contents;

  ChatroomVM(this.name);

  void init() {
    totalCount = StreamControllerWithData(0, broadcast: true);
    strangerCnt = StreamControllerWithData(0, broadcast: true);
    members = StreamControllerWithData([], broadcast: true);
    contents = StreamControllerWithData([]);
    _webSocketChannel = IOWebSocketChannel.connect(chatServer);
    _webSocketChannel.stream.listen((event) {
      print('------------------------------------------------');
      print(event);
      if (event is! String) return;
      final msg = json.decode(event);
      switch (msg['type']) {
        case 'join':
        case 'leave':
          _strangerCnt = msg['stranger_count'] ?? 0;
          _members =
              msg['members']?.map<String>((m) => m as String)?.toList() ?? [];
          totalCount?.add(_strangerCnt + _members.length,
              ignoreIfSameValue: true);
          strangerCnt?.add(_strangerCnt, ignoreIfSameValue: true);
          members?.add(_members);
          _contents.add(Message(msg['sender'], msg['time'], msg['content']));
          contents?.add(_contents);
          break;
        case 'message':
          _contents.add(Message(msg['sender'], msg['time'], msg['content']));
          contents?.add(_contents);
          break;
      }
    });
    _webSocketChannel?.sink?.add(json.encode({'type': 'join', 'name': name}));
  }

  void dispose() {
    totalCount?.dispose();
    totalCount = null;
    strangerCnt?.dispose();
    strangerCnt = null;
    members?.dispose();
    members = null;
    contents?.dispose();
    contents = null;
    _webSocketChannel?.sink?.add(json.encode({'type': 'leave', 'name': name}));
    _webSocketChannel?.sink?.close();
    _webSocketChannel = null;
  }

  /// 用户切换
  void updateUser(String name) {
    if (this.name.isEmpty == name.isEmpty) {
      this.name = name;
      return;
    }
    _webSocketChannel?.sink?.add(json.encode({'type': 'leave', 'name': name}));
    this.name = name;
    _webSocketChannel?.sink?.add(json.encode({'type': 'join', 'name': name}));
  }

  /// 发送消息
  void sendMsg(String msg) {
    _webSocketChannel?.sink
        ?.add(json.encode({'type': 'message', 'content': msg}));
  }
}

/// 聊天消息
class Message {
  final String sender;
  final int time; // 秒数
  final String content;
  bool get systemMsg => sender == 'system';
  Message(this.sender, this.time, this.content);
}
