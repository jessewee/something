import 'package:base/model/other.dart';

/// 帖子标签
class PostLabel {
  final String id;
  final String title;
  PostLabel(this.id, this.title);
}

/// 社区用户信息
class ForumUser {
  final String id;
  final String name;
  final String avatar;
  final String avatarThumb;
  final Gender gender;
  final String birthday;
  final String registerDate;
  int followerCount; // 关注此用户的人数
  int followingCount; // 被此用户关注的人数
  bool followed; // 登录人是否已关注此用户

  ForumUser({
    this.id = '',
    this.name = '',
    this.avatar = '',
    this.avatarThumb = '',
    this.gender = Gender.unknown,
    this.birthday = '',
    this.registerDate = '',
    this.followerCount = 0,
    this.followingCount = 0,
    this.followed = false,
  });
}
