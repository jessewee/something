import 'package:flutter/foundation.dart';

import '../../common/models.dart';

/// 社区用户信息
class ForumUser extends User {
  int followerCount; // 关注此用户的人数
  int followingCount; // 被此用户关注的人数
  bool followed; // 登录人是否已关注此用户
  int postCount; // 发帖数量
  int replyCount; // 回复数量

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
    this.postCount = 0,
    this.replyCount = 0,
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

extension ForumUserExt on ForumUser {
  static ForumUser fromApiData(Map<String, dynamic> apiData) {
    return ForumUser(
      id: apiData['id'] ?? '',
      name: apiData['name'] ?? '',
      avatar: apiData['avatar'] ?? '',
      avatarThumb: apiData['avatar_thumb'] ?? '',
      gender: apiData['gender'] ?? '',
      birthday: apiData['birthday'] ?? '',
      registerDate: apiData['register_date'] ?? '',
      followerCount: apiData['follower_count'] ?? 0,
      followingCount: apiData['following_count'] ?? 0,
      followed: apiData['followed'] == true,
      postCount: apiData['post_count'] ?? 0,
      replyCount: apiData['reply_count'] ?? 0,
    );
  }
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
  final String id;
  final MediaType type;
  final String url;

  /// 图片缩略图或者视频封面
  final String thumbUrl;

  const Media({
    this.id = '',
    @required this.type,
    @required this.url,
    this.thumbUrl = '',
  });
}
