import 'package:base/base/event_bus.dart';
import 'package:base/base/pub.dart';
import 'package:forum/model/post.dart';
import 'package:forum/repository/repository.dart';
import 'package:forum/view/post_list_item.dart';

import 'forum_vm.dart';

/// 帖子详情数据和逻辑
class PostVM {
  final Post post;
  List<Floor> _floors = [];
  int _dataIdx = 0; // 当前数据索引
  int _totalCnt = 0; // 总数据数量
  int _totalFloorCnt = 0; // 总楼层数量，不算层内回复

  /// 总楼层数量，不算层内回复
  get totalFloorCnt => _totalFloorCnt;

  get noMoreData => _floors.length >= _totalCnt;

  PostVM(this.post);

  /// 获取数据
  Future<Result<List<Floor>>> getFloors({
    bool refresh = true,
    int dataSize = 100,
    int floorStartIdx,
    int floorEndIdx,
  }) async {
    if (floorStartIdx == null || floorEndIdx == null) {
      floorStartIdx = null;
      floorEndIdx = null;
    }
    if (refresh) {
      _dataIdx = 0;
    } else {
      _dataIdx += dataSize;
    }
    final result = await Repository.getFloors(
      dataIdx: floorStartIdx == null ? _dataIdx : null,
      dataPageSize: dataSize,
      floorStartIdx: floorStartIdx,
      floorEndIdx: floorEndIdx,
    );
    if (result.fail) return Result(code: result.code, msg: result.msg);
    _totalCnt = result.data.totalCount;
    if (_dataIdx == 0 || floorStartIdx != null) {
      _floors = result.data.list;
    } else {
      _floors.addAll(result.data.list);
    }
    if (floorStartIdx != null) _dataIdx = result.data.lastDataIndex;
    return Result.success(_floors);
  }

  /// 点赞 [like] null 表示中立
  Future<Result> changeLikeState({
    String postId,
    String floorId,
    bool like,
  }) async {
    if (postId != null) {
      Result result = await Repository.changeLikeState(
        postId: postId,
        like: like,
      );
      if (result.success) {
        changePostBaseLikeStatus(post, like);
        eventBus.sendEvent(PostItem.eventBusEventType, {
          'postId': postId,
          'likeCnt': post.likeCnt,
          'dislikeCnt': post.dislikeCnt,
        });
      }
      return result;
    }
    Result result = await Repository.changeLikeState(
      floorId: floorId,
      like: like,
    );
    if (result.success) {
      for (var f in _floors.where((e) => e.id == floorId)) {
        changePostBaseLikeStatus(f, like);
      }
    }
    return result;
  }
}
