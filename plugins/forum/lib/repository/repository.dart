import 'dart:math';

import 'package:base/base/pub.dart';
import 'package:base/model/m.dart';
import 'package:base/test_generator.dart';
import 'package:forum/model/m.dart';
import 'package:forum/model/media.dart';
import 'package:forum/model/post.dart';
import 'package:forum/vm/others.dart';

/// 数据仓库

/// 获取关注人列表
Future<Result<List<ForumUser>>> getFollowings(String searchContent) async {
  // TODO
  return Result.success(
    List.generate(
      TestGenerator.generateNumber(100),
      (index) => ForumUser(
        id: TestGenerator.generateId(10),
        name: TestGenerator.generateChinese(20),
        avatar: TestGenerator.generateImg(),
        avatarThumb: TestGenerator.generateImg(),
        gender: Random.secure().nextBool() ? Gender.male : Gender.female,
        birthday: TestGenerator.generateDate(),
        registerDate: TestGenerator.generateDate(),
        followerCount: TestGenerator.generateNumber(9999),
        followingCount: TestGenerator.generateNumber(9999),
        followed: Random.secure().nextBool(),
      ),
    ),
  );
}

/// 获取帖子标签列表
Future<Result<List<String>>> getPostLabels(String searchContent) async {
  // TODO
  return Result.success(
    List.generate(
      TestGenerator.generateNumber(100),
      (index) => TestGenerator.generateChinese(10),
    ),
  );
}

/// 获取帖子列表
Future<Result<DataWidthPageInfo<Post>>> getPosts({
  int dataIdx = 0,
  int dataPageSize = 100,
  PostsFilter filter,
}) async {
  // TODO
  await Future.delayed(Duration(seconds: 3));
  return Result.success(
    DataWidthPageInfo(
      List.generate(
        dataPageSize,
        (index) => Post(
          id: (dataIdx + index).toString(),
          label: TestGenerator.generateChinese(5),
          posterId: TestGenerator.generateId(12),
          avatar: TestGenerator.generateImg(),
          avatarThumb: TestGenerator.generateImg(),
          name: TestGenerator.generateChinese(20),
          date: TestGenerator.generateDate(),
          content: TestGenerator.generateChinese(500),
          replyCnt: TestGenerator.generateNumber(9999),
          likeCnt: TestGenerator.generateNumber(9999),
          myAttitude: TestGenerator.generateNumber(1, -1),
          medias: TestGenerator.generateImgs()
              .map((e) => ImageMedia(
                    thumbUrl: e,
                    url: TestGenerator.generateImg(),
                    width: TestGenerator.generateNumber(100, 50),
                    height: TestGenerator.generateNumber(100, 50),
                  ))
              .toList(),
        ),
      ),
      TestGenerator.generateNumber(9999),
      dataIdx,
      dataPageSize,
    ),
  );
}

/// 关注用户
Future<Result> follow(String userId, bool follow) async {
  // TODO
  await Future.delayed(Duration(seconds: 1));
//    return Random.secure().nextBool() ? Result.success() : Result(msg: '随便出错');
  return Result.success();
}

/// 点赞 [like] null 表示中立
Future<Result> changeLikeState({
  String postId,
  String floorId,
  String innerFloorId,
  bool like,
}) async {
  // TODO
  await Future.delayed(Duration(seconds: 1));
//    return Random.secure().nextBool() ? Result.success() : Result(msg: '随便出错');
  return Result.success();
}

/// 获取帖子内的楼层列表
Future<Result<FloorResultData>> getFloors({
  int dataIdx,
  int dataPageSize = 100,
  int floorStartIdx,
  int floorEndIdx,
}) async {
  assert(
    dataIdx != null || (floorStartIdx != null && floorEndIdx != null),
    'getFloors---dataIdx和floorIdx必须传其中一个',
  );
  // TODO
  await Future.delayed(Duration(seconds: 3));
  return Result.success(
    FloorResultData(
      List.generate(
        dataPageSize,
        (index) => Floor(
          id: (dataIdx + index).toString(),
          posterId: TestGenerator.generateId(12),
          avatar: TestGenerator.generateImg(),
          avatarThumb: TestGenerator.generateImg(),
          name: TestGenerator.generateChinese(20),
          date: TestGenerator.generateDate(),
          content: TestGenerator.generateChinese(500),
          replyCnt: TestGenerator.generateNumber(9999),
          likeCnt: TestGenerator.generateNumber(9999),
          myAttitude: TestGenerator.generateNumber(1, -1),
          medias: TestGenerator.generateImgs()
              .map((e) => ImageMedia(
                    thumbUrl: e,
                    url: TestGenerator.generateImg(),
                    width: TestGenerator.generateNumber(100, 50),
                    height: TestGenerator.generateNumber(100, 50),
                  ))
              .toList(),
          floor: index,
        ),
      ),
      TestGenerator.generateNumber(9999),
      dataIdx,
      dataPageSize,
      TestGenerator.generateNumber(9999),
    ),
  );
}

/// 获取楼层内的回复列表
Future<Result<DataWidthPageInfo<InnerFloor>>> getInnerFloors({
  int dataIdx,
  int dataPageSize = 100,
}) async {
  // TODO
  await Future.delayed(Duration(seconds: 3));
  return Result.success(
    DataWidthPageInfo<InnerFloor>(
      List.generate(
        dataPageSize,
        (index) => InnerFloor(
          id: (dataIdx + index).toString(),
          posterId: TestGenerator.generateId(12),
          avatar: TestGenerator.generateImg(),
          avatarThumb: TestGenerator.generateImg(),
          name: TestGenerator.generateChinese(20),
          date: TestGenerator.generateDate(),
          content: TestGenerator.generateChinese(500),
          likeCnt: TestGenerator.generateNumber(9999),
          myAttitude: TestGenerator.generateNumber(1, -1),
          medias: TestGenerator.generateImgs()
              .map((e) => ImageMedia(
                    thumbUrl: e,
                    url: TestGenerator.generateImg(),
                    width: TestGenerator.generateNumber(100, 50),
                    height: TestGenerator.generateNumber(100, 50),
                  ))
              .toList(),
          innerFloor: index,
          targetId: TestGenerator.generateChinese(20),
          targetName: TestGenerator.generateChinese(20),
        ),
      ),
      TestGenerator.generateNumber(9999),
      dataIdx,
      dataPageSize,
    ),
  );
}

/// 回复 [postId]表示回复楼主、[floorId]表示回复层主、[innerFloorId]表示层内回复
Future<Result<String>> reply(
  String postId,
  String floorId,
  String innerFloorId,
) async {
  // TODO
  await Future.delayed(Duration(seconds: 3));
  return Result.success(TestGenerator.generateId(10));
}
