import 'package:flutter/foundation.dart';

import '../../common/network.dart';
import '../../common/pub.dart';
import '../model/post.dart';
import '../model/m.dart';
import '../vm/others.dart';

/// 上传文件
Future<Result<Media>> upload(
  String path,
  MediaType type, {
  String tag,
}) async {
  final result = await network.post(
    '/upload',
    params: {'type': type.name},
    filePaths: [path],
    tag: tag,
  );
  if (result.fail) return result;
  return Result.success(Media(
      id: result.data['id'],
      type: MediaTypeExt.fromName(result.data['type']),
      url: result.data['url'],
      thumbUrl: result.data['thumb_url']));
}

/// 获取关注人列表
Future<Result<List<ForumUser>>> getFollowings(String searchContent) async {
  final result = await network.get(
    '/forum/get_followings',
    params: {'search_content': searchContent},
  );
  if (result.fail) return result;
  return Result.success(result.data
      .map<ForumUser>((e) => ForumUser(
            id: e['id'] ?? '',
            name: e['name'] ?? '',
            avatar: e['avatar'] ?? '',
            avatarThumb: e['avatar_thumb'] ?? '',
            gender: e['gender'] ?? '',
            birthday: e['birthday'] ?? '',
            registerDate: e['register_date'] ?? '',
            followerCount: e['follower_count'] ?? 0,
            followingCount: e['following_count'] ?? 0,
            followed: true,
          ))
      .toList());
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
  if (result.fail) return result;
  return Result.success(result.data.map<String>((e) => e['label']).toList());
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
      'users': filter.users.map((u) => u.id).join(',')
    },
  );
  if (result.fail) return result;
  final list = result.data['list']
      .map<Post>((e) => Post(
            id: e['id'] ?? '',
            posterId: e['poster_id'] ?? '',
            avatar: e['avatar'] ?? '',
            avatarThumb: e['avatar_thumb'] ?? '',
            name: e['name'] ?? '',
            date: e['date'] ?? '',
            content: e['text'] ?? '',
            label: e['label'] ?? '',
            likeCnt: e['like_count'] ?? 0,
            dislikeCnt: e['dislike_count'] ?? 0,
            replyCnt: e['reply_count'] ?? 0,
            myAttitude: e['attitude'] ?? 0,
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
  if (result.fail) return result;
  final list = result.data['list']
      .map<Floor>((e) => Floor(
            id: e['id'] ?? '',
            posterId: e['poster_id'] ?? '',
            avatar: e['avatar'] ?? '',
            avatarThumb: e['avatar_thumb'] ?? '',
            name: e['name'] ?? '',
            date: e['date'] ?? '',
            content: e['text'] ?? '',
            replyCnt: e['reply_count'] ?? 0,
            likeCnt: e['like_count'] ?? 0,
            dislikeCnt: e['dislike_count'] ?? 0,
            myAttitude: e['attitude'] ?? 0,
            medias: _mapMedias(e['medias']),
            floor: e['floor'],
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
    '/forum/get_innser_floors',
    params: {
      'floor_id': floorId,
      'data_idx': dataIdx,
      'data_count': dataPageSize,
    },
  );
  if (result.fail) return result;
  final list = result.data['list']
      .map<InnerFloor>((e) => InnerFloor(
            id: e['id'] ?? '',
            posterId: e['poster_id'] ?? '',
            avatar: e['avatar'] ?? '',
            avatarThumb: e['avatar_thumb'] ?? '',
            name: e['name'] ?? '',
            date: e['date'] ?? '',
            content: e['text'] ?? '',
            likeCnt: e['like_count'] ?? 0,
            dislikeCnt: e['dislike_count'] ?? 0,
            myAttitude: e['attitude'] ?? 0,
            medias: _mapMedias(e['medias']),
            innerFloor: e['innser_floor'],
            targetId: e['target_id'],
            targetName: e['target_name'],
          ))
      .toList();
  return Result.success(DataWidthPageInfo<InnerFloor>(
      list,
      result.data['total_count'] ?? list.length,
      result.data['last_data_index'],
      list.length));
}

// 转换Media
List<Media> _mapMedias(data) {
  if (data is! Iterable) return [];
  return data
      .map<Media>((m) {
        final type = MediaTypeExt.fromName(m['type']);
        if (type == null) return null;
        return Media(
          type: type,
          url: m['url'] ?? '',
          thumbUrl: m['thumb_url'] ?? '',
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
    'medias': mediaIds,
  });
  if (result.fail) return Result(code: result.code, msg: result.msg);
  return Result.success(ReplyResultData(
    floorId: result.data['floor_id'] ?? '',
    floor: result.data['floor'] ?? '',
    innerFloorId: result.data['inner_floor_id'] ?? '',
    innerFloor: result.data['inner_floor'] ?? '',
  ));
}
