/// 性别
enum Gender { unknown, male, female }

/// 用户信息
class User {
  String id;
  String name;
  String avatar;
  String avatarThumb;
  Gender gender;
  String birthday;
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
