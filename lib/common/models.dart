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
        return 'unknown';
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
  final String id;

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
  final String registerDate;

  /// 备注
  String remark;

  User({
    this.id = '',
    this.name = '',
    this.avatar = '',
    this.avatarThumb = '',
    this.gender = Gender.unknown,
    this.birthday = '',
    this.registerDate = '',
    this.remark = '',
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

/// 文件类型
enum FileType { image, video, voice, unknown }

extension FileTypeExt on FileType {
  String get name {
    switch (index) {
      case 0:
        return 'image';
      case 1:
        return 'video';
      case 2:
        return 'voice';
      default:
        return 'unknow';
    }
  }

  static FileType fromName(String name) {
    switch (name) {
      case 'image':
        return FileType.image;
      case 'video':
        return FileType.video;
      case 'voice':
        return FileType.voice;
      default:
        return FileType.unknown;
    }
  }
}

/// 上传的文件对象
class UploadedFile {
  final String id;
  final FileType type;
  final String url;

  /// 图片缩略图或者视频封面
  final String thumbUrl;

  /// 图片的宽高
  final int width;
  final int height;

  double get aspectRatio {
    if (width == null || height == null || width <= 0 || height <= 0) return 1;
    return width / height;
  }

  const UploadedFile({
    this.id = '',
    @required this.type,
    @required this.url,
    this.thumbUrl = '',
    this.width,
    this.height,
  });
}
