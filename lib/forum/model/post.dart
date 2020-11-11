import 'm.dart';

/// 帖子、动态、回复的基类
class PostBase {
  /// 帖子id、动态id、回复id
  final String id;

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

  /// 点赞数
  int likeCnt;

  /// 点踩数
  int dislikeCnt;

  /// 我的态度-1:踩、0:中、1:赞
  int myAttitude;

  PostBase.essential({
    this.id = '',
    this.posterId = '',
    this.avatar = '',
    this.avatarThumb = '',
    this.name = '',
    this.date = '',
    this.content = '',
    this.medias = const [],
    this.likeCnt = 0,
    this.dislikeCnt = 0,
    this.myAttitude = 0,
  });
}

/// 帖子、动态
class Post extends PostBase {
  /// 标签
  final String label;

  /// 回复数
  int replyCnt;

  /// 是否已关注发布人
  bool posterFollowed;

  Post({
    String id = '',
    String posterId = '',
    String avatar = '',
    String avatarThumb = '',
    String name = '',
    String date = '',
    String content = '',
    List<Media> medias = const [],
    int likeCnt = 0,
    int dislikeCnt = 0,
    int myAttitude = 0,
    this.label = '',
    this.replyCnt = 0,
    this.posterFollowed = false,
  }) : super.essential(
          id: id,
          posterId: posterId,
          avatar: avatar,
          avatarThumb: avatarThumb,
          name: name,
          date: date,
          content: content,
          medias: medias,
          likeCnt: likeCnt,
          dislikeCnt: dislikeCnt,
          myAttitude: myAttitude,
        );
}

/// 楼层回复
class Floor extends PostBase {
  /// 楼层
  final int floor;

  /// 回复数
  int replyCnt;

  Floor({
    String id = '',
    String posterId = '',
    String avatar = '',
    String avatarThumb = '',
    String name = '',
    String date = '',
    String content = '',
    List<Media> medias = const [],
    int likeCnt = 0,
    int dislikeCnt = 0,
    int myAttitude = 0,
    this.floor = 0,
    this.replyCnt = 0,
  }) : super.essential(
          id: id,
          posterId: posterId,
          avatar: avatar,
          avatarThumb: avatarThumb,
          name: name,
          date: date,
          content: content,
          medias: medias,
          likeCnt: likeCnt,
          dislikeCnt: dislikeCnt,
          myAttitude: myAttitude,
        );
}

/// 楼中回复，跟楼层差不多，为了区分还是单独吧
class InnerFloor extends PostBase {
  /// 楼层
  final int innerFloor;

  /// 回复对象id，直接回复层主的时候这个参数没有
  final String targetId;

  /// 回复对象名字，直接回复层主的时候这个参数没有
  final String targetName;

  InnerFloor({
    String id = '',
    String posterId = '',
    String avatar = '',
    String avatarThumb = '',
    String name = '',
    String date = '',
    String content = '',
    List<Media> medias = const [],
    int likeCnt = 0,
    int dislikeCnt = 0,
    int myAttitude = 0,
    this.innerFloor = 0,
    this.targetId = '',
    this.targetName = '',
  }) : super.essential(
          id: id,
          posterId: posterId,
          avatar: avatar,
          avatarThumb: avatarThumb,
          name: name,
          date: date,
          content: content,
          medias: medias,
          likeCnt: likeCnt,
          dislikeCnt: dislikeCnt,
          myAttitude: myAttitude,
        );
}
