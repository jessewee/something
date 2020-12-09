import '../../common/pub.dart';
import '../model/post.dart';
import '../repository/repository.dart' as repository;
import 'extensions.dart';
import 'others.dart';

/// 社区帖子列表数据和逻辑处理
class PostsVM {
  /// 筛选条件
  ///
  PostsFilter filter = PostsFilter();

  int _dataIdx = 0; // 当前数据索引
  List<Post> _posts = []; // 帖子列表
  int _totalCnt = 0; // 总数据数量
  get noMoreData => _posts.length >= _totalCnt;

  /// 添加新数据，一般是登录人发帖后添加显示
  List<Post> addNewPostAndReturnList(Post post) {
    _posts.insert(0, post);
    return _posts;
  }

  /// 根据id获取post对象
  Post getPostById(String id) {
    return _posts.firstWhere((p) => p.id == id, orElse: () => null);
  }

  /// 获取登录人对某个帖子当前的态度 null 表示中立
  bool getLikeStatus(String postId) {
    final post = _posts.firstWhere((p) => p.id == postId, orElse: () => null);
    return post?.myAttitude;
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
    final result = await repository.getPosts(
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
  Future<String> changeLikeState(String postId, [bool like]) async {
    final p = _posts.firstWhere((e) => e.id == postId, orElse: () => null);
    if (p == null) return '没有找到数据';
    return p.changeLikeState(like);
  }
}
