import 'media.dart';

/// 帖子、动态、回复的基类
class Post {
  final String id;

  /// 标签
  final String label;

  /// 发布人id
  final String posterId;

  /// 发布人头像
  final String avatar;
  final String avatarThumb;

  /// 发布人名字
  final String name;

  /// 日期
  final String date;

  /// 文本
  final String content;

  /// 图片音视频
  final List<Media> medias;

  /// 回复数
  int replyCnt;

  /// 点赞数
  int likeCnt;

  /// 点踩数
  int dislikeCnt;

  /// 我的态度-1:踩、0:中、1:赞
  int myAttitude;

  /// 是否已关注发布人
  bool posterFollowed;

  Post({
    this.id = '',
    this.label = '',
    this.posterId = '',
    this.avatar = '',
    this.avatarThumb = '',
    this.name = '',
    this.date = '',
    this.content = '',
    this.medias = const [],
    this.replyCnt = 0,
    this.likeCnt = 0,
    this.dislikeCnt = 0,
    this.myAttitude = 0,
    this.posterFollowed = false,
  });
}
