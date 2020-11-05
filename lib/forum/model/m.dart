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
