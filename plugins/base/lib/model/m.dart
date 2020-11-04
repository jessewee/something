import 'package:flutter/foundation.dart';

/// 性别
enum Gender { unknown, male, female }

/// 上传文件的类型
enum FileType { image, video, other }

/// 用户信息
class User {
  /// 用户id
  String id;

  /// 用户名字
  String name;

  /// 用户头像
  String avatar;

  /// 用户头像缩略图
  String avatarThumb;

  /// 用户性别
  Gender gender;

  /// 用户生日
  String birthday;

  /// 用户注册日期
  String registerDate;

  User({
    this.id = '',
    this.name = '',
    this.avatar = '',
    this.avatarThumb = '',
    this.gender = Gender.unknown,
    this.birthday = '',
    this.registerDate = '',
  });
}

class UserVM with ChangeNotifier {
  User _user;
  get user => _user;
  set user(value) {
    _user = value;
    notifyListeners();
  }

  UserVM({User user}) : _user = user ?? User();
}
