import '../../common/pub.dart';
import '../model/post.dart';
import '../repository/repository.dart' as repository;

/// 楼层回复数据和逻辑
class FloorVM {
  final Floor floor;
  List<InnerFloor> _innerFloors = [];
  int _dataIdx = 0; // 当前数据索引
  int _totalCnt = 0; // 总数据数量
  get totalCnt => _totalCnt;

  FloorVM(this.floor);

  get noMoreData => _innerFloors.length >= _totalCnt;

  get innerFloors => _innerFloors;

  /// 获取数据
  Future<Result<List<InnerFloor>>> getInnerFloors(
      {bool refresh = true, int dataSize = 100}) async {
    if (refresh) {
      _dataIdx = 0;
    } else {
      _dataIdx += dataSize;
    }
    final result = await repository.getInnerFloors(
      dataIdx: _dataIdx,
      dataPageSize: dataSize,
    );
    if (result.fail) return Result(code: result.code, msg: result.msg);
    _totalCnt = result.data.totalCount;
    if (_dataIdx == 0) {
      _innerFloors = result.data.list;
    } else {
      _innerFloors.addAll(result.data.list);
    }
    return Result.success(_innerFloors);
  }

  /// 回复层主后添加新数据到最上边
  void addNewReply(InnerFloor innerFloor) {
    _innerFloors.insert(0, innerFloor);
  }
}
