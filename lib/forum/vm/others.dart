import '../../common/pub.dart';
import '../model/m.dart';
import '../model/post.dart';

/// 帖子列表筛选条件
class PostsFilter {
  /// 标签
  List<String> labels = [];

  /// 关注人
  List<ForumUser> users = [];

  /// 搜索
  String searchContent = '';

  /// 1最新、2最热
  int sortBy = 1;
}

/// 楼层返回数据
class FloorResultData extends DataWidthPageInfo<Floor> {
  /// 楼层数量和数据数量不一样，因为有楼层删除的情况
  final int totalFloorCnt;

  FloorResultData(
    List<Floor> list,
    int totalCount,
    int lastDataIndex,
    int pageSize,
    this.totalFloorCnt,
  ) : super(
          list,
          totalCount,
          lastDataIndex,
          pageSize,
        );
}
