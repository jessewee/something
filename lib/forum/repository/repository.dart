import 'package:flutter/foundation.dart';

import '../../common/models.dart';
import '../../common/pub.dart';
import '../model/m.dart';
import '../model/post.dart';
import '../vm/others.dart';
import '../api/api.dart' as api;
import '../../base/api/api.dart' as baseApi;

/// 上传
Future<Result<UploadedFile>> upload(
  String path,
  FileType type, {
  String tag,
}) async {
  return await baseApi.upload(path, type, tag: tag);
}

/// 获取用户信息
Future<Result<ForumUser>> getUserInfo(String userId) async {
  return await api.getUserInfo(userId);
}

/// 获取关注人列表 [targetUserId]查看的是谁的粉丝列表，null表示登陆人
Future<Result<List<ForumUser>>> getFollowings(
  String searchContent, [
  String targetUserId,
]) async {
  return await api.getFollowings(searchContent, targetUserId);
}

/// 获取粉丝列表 [targetUserId]查看的是谁的粉丝列表，null表示登陆人
Future<Result<DataWidthPageInfo<ForumUser>>> getFollowers(
  String searchContent,
  int dataIdx,
  int dataPageSize, [
  String targetUserId,
]) async {
  return await api.getFollowers(
    searchContent,
    dataIdx,
    dataPageSize,
    targetUserId,
  );
}

/// 获取帖子标签列表
Future<Result<List<String>>> getPostLabels(String searchContent) async {
  return await api.getPostLabels(searchContent);
}

/// 获取帖子列表
Future<Result<DataWidthPageInfo<Post>>> getPosts({
  int dataIdx = 0,
  int dataPageSize = 100,
  PostsFilter filter,
}) async {
  return await api.getPosts(dataIdx, dataPageSize, filter);
}

/// 关注用户
Future<Result> follow(String userId, bool follow) async {
  return await api.follow(userId, follow);
}

/// 点赞 [like] null 表示中立
Future<Result> changeLikeState({
  String postId,
  String floorId,
  String innerFloorId,
  bool like,
}) async {
  assert(
    postId != null || floorId != null || innerFloorId != null,
    'changeLikeState---postId、floorId和innerFloorId必须传一个',
  );
  return await api.changeLikeState(
    postId: postId,
    floorId: floorId,
    innerFloorId: innerFloorId,
    like: like,
  );
}

/// 获取帖子内的楼层列表，dataIdx和floorStartIdx不是一个意思，因为有可能有的楼层被删了，这时dataIdx和floorStartIdx的值不一样
Future<Result<FloorResultData>> getFloors({
  @required String postId,
  int dataIdx,
  int dataPageSize = 100,
  int floorStartIdx,
  int floorEndIdx,
}) async {
  assert(
    dataIdx != null || (floorStartIdx != null && floorEndIdx != null),
    'getFloors---dataIdx和floorIdx必须传一个',
  );
  return await api.getFloors(
    postId: postId,
    dataIdx: dataIdx,
    dataPageSize: dataPageSize,
    floorStartIdx: floorStartIdx,
    floorEndIdx: floorEndIdx,
  );
}

/// 获取楼层内的回复列表
Future<Result<DataWidthPageInfo<InnerFloor>>> getInnerFloors({
  @required String floorId,
  int dataIdx,
  int dataPageSize = 100,
}) async {
  return await api.getInnerFloors(
    floorId: floorId,
    dataIdx: dataIdx,
    dataPageSize: dataPageSize,
  );
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
  assert(
    postId != null || floorId != null || innerFloorId != null,
    'reply---postId、floorId和innerFloorId必须传一个',
  );
  assert(
    content?.isNotEmpty == true || mediaIds?.isNotEmpty == true,
    'reply---content和medias必须传一个',
  );
  return await api.reply(
    postId: postId,
    floorId: floorId,
    innerFloorId: innerFloorId,
    content: content,
    mediaIds: mediaIds,
  );
}

/// 发帖，返回post_id
Future<Result<String>> post({
  String label,
  String content,
  List<String> mediaIds,
}) async {
  return await api.post(label: label, content: content, mediaIds: mediaIds);
}
