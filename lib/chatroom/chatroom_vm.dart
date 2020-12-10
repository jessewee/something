import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../configs.dart';

class ChatroomVM with ChangeNotifier {
  final String name;
  int _strangerCnt = 0;
  List<String> _members = [];
  List<Message> _contents = [];
  WebSocketChannel _webSocketChannel;

  /// 总数量
  int get totalMemberCount => _strangerCnt + _members.length;

  /// 非成员数量
  int get strangerCnt => _strangerCnt;

  /// 成员列表
  List<String> get members => _members;

  /// 内容列表
  List<Message> get contents => _contents;

  ChatroomVM(this.name) {
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
          _contents.add(Message(msg['sender'], msg['time'], msg['content']));
          notifyListeners();
          break;
        case 'message':
          _contents.add(Message(msg['sender'], msg['time'], msg['content']));
          notifyListeners();
          break;
      }
    });
    _webSocketChannel?.sink?.add(json.encode({'type': 'join', 'name': name}));
  }
  @override
  void dispose() {
    super.dispose();
    _webSocketChannel?.sink?.add(json.encode({'type': 'leave', 'name': name}));
    _webSocketChannel?.sink?.close();
    _webSocketChannel = null;
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
  Message(this.sender, this.time, this.content);
}
