import 'package:flutter/foundation.dart';

import '../../common/network.dart';
import '../../common/pub.dart';
import '../../common/models.dart';
import '../model/post.dart';
import '../model/m.dart';
import '../vm/others.dart';

/// 获取关注人列表 [targetUserId]查看的是谁的关注人列表，null表示登陆人
Future<Result<List<ForumUser>>> getFollowings(
  String searchContent, [
  String targetUserId,
]) async {
  final result = await network.get(
    '/forum/get_followings',
    params: {'search_content': searchContent, 'target_user_id': targetUserId},
  );
  if (result.fail)
    return Result<List<ForumUser>>(code: result.code, msg: result.msg);
  return Result.success(
    result.data.map<ForumUser>((e) => ForumUserExt.fromApiData(e)).toList(),
  );
}

/// 获取粉丝列表 [targetUserId]查看的是谁的粉丝列表，null表示登陆人
Future<Result<DataWidthPageInfo<ForumUser>>> getFollowers(
  String searchContent,
  int dataIdx,
  int dataPageSize, [
  String targetUserId,
]) async {
  final result = await network.get(
    '/forum/get_followers',
    params: {
      'search_content': searchContent,
      'data_idx': dataIdx,
      'data_count': dataPageSize,
      'target_user_id': targetUserId,
    },
  );
  if (result.fail)
    return Result<DataWidthPageInfo<ForumUser>>(
      code: result.code,
      msg: result.msg,
    );
  final list = result.data['list']
      .map<ForumUser>((u) => ForumUserExt.fromApiData(u))
      .toList();
  return Result.success(DataWidthPageInfo(
      list,
      result.data['total_count'] ?? list.length,
      result.data['last_data_index'],
      list.length));
}

/// 关注用户
Future<Result> follow(String userId, bool follow) async {
  return await network.put(
    '/forum/follow',
    params: {'user_id': userId, 'follow': follow},
  );
}

/// 获取帖子标签列表
Future<Result<List<String>>> getPostLabels(String searchContent) async {
  final result = await network.get(
    '/forum/get_post_labels',
    params: {'search_content': searchContent},
  );
  if (result.fail)
    return Result<List<String>>(code: result.code, msg: result.msg);
  return Result.success(
    result.data.map<String>((e) => e['label'] as String).toList(),
  );
}

/// 帖子点赞
Future<Result> changeLikeState({
  String postId,
  String floorId,
  String innerFloorId,
  bool like,
}) async {
  return await network.put(
    '/forum/change_like_state',
    params: {
      'post_id': postId,
      'floor_id': floorId,
      'inner_floor_id': innerFloorId,
      'like': like
    },
  );
}

/// 获取帖子列表
Future<Result<DataWidthPageInfo<Post>>> getPosts(
  int dataIdx,
  int dataPageSize,
  PostsFilter filter,
) async {
  final result = await network.get(
    '/forum/get_posts',
    params: {
      'data_idx': dataIdx,
      'data_count': dataPageSize,
      'sort_by': filter.sortBy,
      'search_content': filter.searchContent,
      'labels': filter.labels.join(','),
      'users': filter.userIds.join(',')
    },
  );
  if (result.fail)
    return Result<DataWidthPageInfo<Post>>(code: result.code, msg: result.msg);
  final list = result.data['list']
      .map<Post>((e) => Post(
            id: e['id']?.toString() ?? '',
            posterId: e['poster_id']?.toString() ?? '',
            avatar: e['avatar'] ?? '',
            avatarThumb: e['avatar_thumb'] ?? '',
            name: e['name'] ?? '',
            date: e['date'] ?? '',
            content: e['text'] ?? '',
            label: e['label'] ?? '',
            likeCnt: e['like_count'] ?? 0,
            dislikeCnt: e['dislike_count'] ?? 0,
            replyCnt: e['reply_count'] ?? 0,
            myAttitude: e['attitude'],
            posterFollowed: e['poster_followed'] == true,
            medias: _mapMedias(e['medias']),
          ))
      .toList();
  return Result.success(DataWidthPageInfo(
      list,
      result.data['total_count'] ?? list.length,
      result.data['last_data_index'],
      list.length));
}

/// 获取帖子内的楼层列表，dataIdx和floorStartIdx不是一个意思，因为有可能有的楼层被删了，这时dataIdx和floorStartIdx的值不一样
Future<Result<FloorResultData>> getFloors({
  @required String postId,
  int dataIdx,
  int dataPageSize = 100,
  int floorStartIdx,
  int floorEndIdx,
}) async {
  final result = await network.get(
    '/forum/get_floors',
    params: {
      'post_id': postId,
      'data_idx': dataIdx,
      'data_count': dataPageSize,
      'floor_start_idx': floorStartIdx,
      'floor_end_idx': floorEndIdx,
    },
  );
  if (result.fail)
    return Result<FloorResultData>(code: result.code, msg: result.msg);
  final list = result.data['list']
      .map<Floor>((e) => Floor(
            id: e['id']?.toString() ?? '',
            posterId: e['poster_id']?.toString() ?? '',
            avatar: e['avatar'] ?? '',
            avatarThumb: e['avatar_thumb'] ?? '',
            name: e['name'] ?? '',
            date: e['date'] ?? '',
            content: e['text'] ?? '',
            replyCnt: e['reply_count'] ?? 0,
            likeCnt: e['like_count'] ?? 0,
            dislikeCnt: e['dislike_count'] ?? 0,
            myAttitude: e['attitude'],
            medias: _mapMedias(e['medias']),
            floor: e['floor'],
            postId: e['post_id']?.toString(),
          ))
      .toList();
  return Result.success(FloorResultData(
      list,
      result.data['total_count'] ?? list.length,
      result.data['last_data_index'],
      list.length,
      // 楼层数量和数据数量不一样，因为有楼层删除的情况
      result.data['total_floor_count'] ?? list.length));
}

/// 获取层内回复列表
Future<Result<DataWidthPageInfo<InnerFloor>>> getInnerFloors({
  @required String floorId,
  int dataIdx,
  int dataPageSize = 100,
}) async {
  final result = await network.get(
    '/forum/get_inner_floors',
    params: {
      'floor_id': floorId,
      'data_idx': dataIdx,
      'data_count': dataPageSize,
    },
  );
  if (result.fail)
    return Result<DataWidthPageInfo<InnerFloor>>(
      code: result.code,
      msg: result.msg,
    );
  final list = result.data['list']
      .map<InnerFloor>((e) => InnerFloor(
            id: e['id']?.toString() ?? '',
            posterId: e['poster_id']?.toString() ?? '',
            avatar: e['avatar'] ?? '',
            avatarThumb: e['avatar_thumb'] ?? '',
            name: e['name'] ?? '',
            date: e['date'] ?? '',
            content: e['text'] ?? '',
            likeCnt: e['like_count'] ?? 0,
            dislikeCnt: e['dislike_count'] ?? 0,
            myAttitude: e['attitude'],
            medias: _mapMedias(e['medias']),
            innerFloor: e['inner_floor'],
            targetId: e['target_id']?.toString() ?? '',
            targetName: e['target_name'] ?? '',
            postId: e['post_id']?.toString() ?? '',
            floorId: e['floor_id']?.toString() ?? '',
          ))
      .toList();
  return Result.success(DataWidthPageInfo<InnerFloor>(
      list,
      result.data['total_count'] ?? list.length,
      result.data['last_data_index'],
      list.length));
}

// 转换Media
List<UploadedFile> _mapMedias(data) {
  if (data is! Iterable) return [];
  return data
      .map<UploadedFile>((m) {
        final type = FileTypeExt.fromName(m['type']);
        if (type == null) return null;
        return UploadedFile(
          type: type,
          url: m['url'] ?? '',
          thumbUrl: m['thumb_url'] ?? '',
          width: m['width'],
          height: m['height'],
        );
      })
      .where((e) => e != null)
      .toList();
}

/// 回复
/// 回复楼主，返回值floor_id、floor
/// 回复层主，返回值inner_floor_id、inner_floor
/// 层内回复，返回值inner_floor_id、inner_floor、target_id、target_name（如果target是层主的话这两个参数没有值）
Future<Result<ReplyResultData>> reply({
  String postId,
  String floorId,
  String innerFloorId,
  String content,
  List<String> mediaIds,
}) async {
  final result = await network.post('/forum/reply', params: {
    'post_id': postId,
    'floor_id': floorId,
    'inner_floor_id': innerFloorId,
    'text': content,
    'medias': mediaIds.map<int>((e) => int.parse(e)).toList(),
  });
  if (result.fail) return Result(code: result.code, msg: result.msg);
  return Result.success(ReplyResultData(
    floorId: result.data['floor_id']?.toString() ?? '',
    floor: result.data['floor'] ?? 0,
    innerFloorId: result.data['inner_floor_id']?.toString() ?? '',
    innerFloor: result.data['inner_floor'] ?? 0,
  ));
}

/// 发帖，返回post_id
Future<Result<String>> post({
  String label,
  String content,
  List<String> mediaIds,
}) async {
  final result = await network.post('/forum/post', params: {
    'label': label,
    'text': content,
    'medias': mediaIds.map<int>((e) => int.parse(e)).toList(),
  });
  if (result.success) {
    return Result.success(result.data.toString());
  }
  return Result<String>(code: result.code, msg: result.msg);
}

/// 获取社区用户数据
Future<Result<ForumUser>> getUserInfo({String userId, String userName}) async {
  final tmp = await network.get(
    '/forum/get_user_info',
    params: {'user_id': userId, 'user_name': userName},
  );
  if (tmp.fail) return Result(code: tmp.code, msg: tmp.msg);
  final map = tmp.data;
  return Result.success(ForumUser(
    id: map['id']?.toString() ?? '',
    name: map['name'] ?? '',
    avatar: map['avatar'] ?? '',
    avatarThumb: map['avatar_thumb'] ?? '',
    gender: GenderExt.fromName(map['gender']),
    birthday: map['birthday'] ?? '',
    registerDate: map['register_date'] ?? '',
    remark: map['remark'] ?? '',
    followerCount: map['follower_count'] ?? 0,
    followingCount: map['following_count'] ?? 0,
    followed: map['followed'] == true,
    postCount: map['post_count'] ?? 0,
    replyCount: map['reply_count'] ?? 0,
  ));
}
