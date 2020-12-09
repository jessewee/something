import 'package:flutter/foundation.dart';

class ChatroomVM with ChangeNotifier {
  final String name;
  int _viewerCnt = 0;
  List<String> _members = [];
  List<MapEntry<String, String>> _contents = [];

  ChatroomVM(this.name);

  /// 总数量
  int get totalMemberCount => _viewerCnt + _members.length;

  /// 非成员数量
  int get viewerCnt => _viewerCnt;

  /// 成员列表
  List<String> get members => _members;

  /// 内容列表
  List<MapEntry<String, String>> get contents => _contents;
}
