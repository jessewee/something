import 'package:flutter/foundation.dart';

/// 性别
enum Gender { unknown, male, female }

extension GenderExt on Gender {
  String get name {
    switch (index) {
      case 1:
        return 'male';
      case 2:
        return 'female';
      default:
        return 'unknow';
    }
  }

  static Gender fromName(String name) {
    switch (name) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.unknown;
    }
  }
}

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

extension UserExt on User {
  bool get isMale => gender == Gender.male;
  bool get isFemale => gender == Gender.female;
  bool get isGenderClear => gender == Gender.male || gender == Gender.female;
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
