import 'package:base/base/pub.dart';
import 'package:forum/model/post.dart';
import 'package:forum/repository/repository.dart';

/// 社区帖子列表数据和逻辑处理
class ForumVM {
  /// 筛选条件
  PostsFilter filter = PostsFilter();

  int _dataIdx = 0; // 当前数据索引
  List<Post> _posts = []; // 帖子列表
  int _totalCnt = 0; // 总数据数量
  get noMoreData => _posts.length >= _totalCnt;

  /// 获取登录人对某个帖子当前的态度 null 表示中立
  bool getLikeStatus(String postId) {
    final post = _posts.firstWhere((p) => p.id == postId, orElse: () => null);
    if (post == null) return null;
    if (post.myAttitude == 1) return true;
    if (post.myAttitude == -1) return false;
    return null;
  }

  /// 获取数据
  Future<Result<List<Post>>> getPosts({
    bool refresh = true,
    int dataSize = 100,
    bool onePageData = false,
  }) async {
    if (refresh) {
      _dataIdx = 0;
    } else {
      _dataIdx += dataSize;
    }
    // 主要是列表里会加载比较多的数据，帖子墙显示的比较少，所以显示墙时可以复用一些数据
    if (refresh != true && _dataIdx + dataSize <= _posts.length) {
      return Result.success(
          _posts.sublist(onePageData ? _dataIdx : 0, _dataIdx + dataSize));
    }
    final result = await Repository.getPosts(
      dataIdx: _dataIdx,
      dataPageSize: dataSize,
      filter: filter,
    );
    if (result.fail) return Result(code: result.code, msg: result.msg);
    _totalCnt = result.data.totalCount;
    if (_dataIdx == 0) {
      _posts = result.data.list;
    } else {
      _posts.addAll(result.data.list);
    }
    return Result.success(onePageData ? result.data.list : _posts);
  }

  /// 点赞 [like] null 表示中立
  Future<Result> changeLikeState(String postId, [bool like]) async {
    Result result = await Repository.changeLikeState(postId, like);
    if (result.success) {
      for (var p in _posts.where((e) => e.id == postId)) {
        final old = p.myAttitude;
        p.myAttitude = like == null
            ? 0
            : like
                ? 1
                : -1;
        if (old == p.myAttitude) continue;
        if (old == 0) {
          if (p.myAttitude == 1) {
            p.likeCnt++;
          } else {
            p.dislikeCnt++;
          }
        } else if (old == -1) {
          p.dislikeCnt--;
          if (p.myAttitude == 1) p.likeCnt++;
        } else {
          p.likeCnt--;
          if (p.myAttitude == -1) p.dislikeCnt++;
        }
      }
    }
    return result;
  }
}
