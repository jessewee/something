import 'package:flutter/foundation.dart';

/// 性别
enum Gender { unknown, male, female }

/// 上传文件的类型
enum FileType { image, video, other }

/// 用户信息
class User with ChangeNotifier {
  /// 用户id
  String _id = '';

  /// 用户id
  get id => _id;

  /// 用户id
  set id(value) {
    _id = value;
    notifyListeners();
  }

  /// 用户名字
  String _name = '';

  /// 用户名字
  get name => _name;

  /// 用户名字
  set name(value) {
    _name = value;
    notifyListeners();
  }

  /// 用户头像
  String _avatar = '';

  /// 用户头像
  get avatar => _avatar;

  /// 用户头像
  set avatar(value) {
    _avatar = value;
    notifyListeners();
  }

  /// 用户头像缩略图
  String _avatarThumb = '';

  /// 用户头像缩略图
  get avatarThumb => _avatarThumb;

  /// 用户头像缩略图
  set avatarThumb(value) {
    _avatarThumb = value;
    notifyListeners();
  }

  /// 用户性别
  Gender _gender = Gender.unknown;

  /// 用户性别
  get gender => _gender;

  /// 用户性别
  set gender(value) {
    _gender = value;
    notifyListeners();
  }

  /// 用户生日
  String _birthday = '';

  /// 用户生日
  get birthday => _birthday;

  /// 用户生日
  set birthday(value) {
    _birthday = value;
    notifyListeners();
  }

  /// 用户注册日期
  String _registerDate = '';

  /// 用户注册日期
  get registerDate => _registerDate;

  /// 用户注册日期
  set registerDate(value) {
    _registerDate = value;
    notifyListeners();
  }
}
