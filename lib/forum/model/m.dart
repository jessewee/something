import 'package:flutter/foundation.dart';

import '../../common/models.dart';

/// 社区用户信息
class ForumUser extends User {
  int followerCount; // 关注此用户的人数
  int followingCount; // 被此用户关注的人数
  bool followed; // 登录人是否已关注此用户

  ForumUser({
    String id = '',
    String name = '',
    String avatar = '',
    String avatarThumb = '',
    Gender gender = Gender.unknown,
    String birthday = '',
    String registerDate = '',
    this.followerCount = 0,
    this.followingCount = 0,
    this.followed = false,
  }) : super(
          id: id,
          name: name,
          avatar: avatar,
          avatarThumb: avatarThumb,
          gender: gender,
          birthday: birthday,
          registerDate: registerDate,
        );
}

/// 类型
enum MediaType { image, video, voice }

extension MediaTypeExt on MediaType {
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

  static MediaType fromName(String name) {
    switch (name) {
      case 'image':
        return MediaType.image;
      case 'video':
        return MediaType.video;
      case 'voice':
        return MediaType.voice;
      default:
        return null;
    }
  }
}

/// 媒体对象
class Media {
  final MediaType type;
  final String url;

  /// 图片缩略图或者视频封面
  final String thumbUrl;

  const Media({@required this.type, @required this.url, this.thumbUrl = ''});
}
