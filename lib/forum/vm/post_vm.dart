import '../../common/pub.dart';
import '../model/post.dart';
import '../repository/repository.dart' as repository;
import 'extensions.dart';

/// 帖子详情数据和逻辑
class PostVM {
  final Post post;
  List<Floor> _floors = [];
  int _dataIdx = 0; // 当前数据索引
  int _totalCnt = 0; // 总数据数量
  int _totalFloorCnt = 0; // 总楼层数量，不算层内回复

  /// 总楼层数量，不算层内回复
  int get totalFloorCnt => _totalFloorCnt;

  bool get noMoreData => _floors.length >= _totalCnt;

  List<Floor> get floors => _floors;

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
    final result = await repository.getFloors(
      postId: post.id,
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
  Future<String> changeLikeState({
    String postId,
    String floorId,
    bool like,
  }) async {
    if (postId != null) {
      return await post.changeLikeState(like);
    }
    if (floorId != null) {
      final f = _floors.firstWhere((e) => e.id == floorId, orElse: () => null);
      if (f == null) return '没有找到数据';
      return await f.changeLikeState(like);
    }
    return '参数不正确';
  }

  /// 回复楼主后添加新数据到最上边
  void addNewReply(Floor floor) {
    _floors.insert(0, floor);
  }
}
