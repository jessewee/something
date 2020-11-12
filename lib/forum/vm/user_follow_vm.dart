import '../repository/repository.dart' as repository;
import '../model/m.dart';

/// 关注列表和粉丝列表的一些操作
class UserFollowVM {
  String searchContent;
  int _dataIdx = 0;
  int _dataSize = 1000;
  bool _noMoreData = false;
  int _totalFollowerCnt = 0;
  // 当前查看的是谁的关注列表和粉丝列表
  String _targetUserId;
  // true:关注列表、false:粉丝列表
  bool _flag = true;
  // 关注列表
  List<ForumUser> _followings = [];
  // 粉丝列表
  List<ForumUser> _followers = [];

  /// true:关注列表、false:粉丝列表
  bool get flag => _flag;

  /// 对外的数据列表，根据flag来判断是粉丝列表还是关注列表
  List<ForumUser> get list => _flag ? _followings : _followers;

  /// 没有下一页数据了
  bool get noMoreData => _noMoreData;

  UserFollowVM(this._targetUserId, this._flag);

  /// 关注列表的数量
  int get totalFollowingCount => _followings.length;

  /// 粉丝列表的数量
  int get totalFollowerCnt => _totalFollowerCnt;

  /// 搜索，返回错误信息，空字符串表示成功
  Future<String> search(String searchContent) async {
    this.searchContent = searchContent;
    return loadData(true);
  }

  /// 加载数据，返回错误信息，空字符串表示成功
  Future<String> loadData([bool refresh = true]) async {
    if (refresh) {
      _dataIdx = 0;
    } else {
      _dataIdx += _dataSize;
    }
    if (_flag) {
      final result = await repository.getFollowings(
        searchContent,
        _targetUserId,
      );
      if (result.fail) return result.msg;
      _followings = result.data;
      _noMoreData = true;
    } else {
      final result = await repository.getFollowers(
        searchContent,
        _dataIdx,
        _dataSize,
        _targetUserId,
      );
      if (result.fail) return result.msg;
      _followers = result.data.list;
      _totalFollowerCnt = result.data.totalCount;
      _noMoreData = _dataIdx + _followers.length >= _totalFollowerCnt;
    }
    return '';
  }

  /// 关注、取消关注，返回错误信息，空字符串表示成功。这个列表显示的不一定是登陆人的关注列表和粉丝列表，登陆人可以对这个列表里的人点关注
  Future<String> changeFollowState(String userId) async {
    final user = list.firstWhere((u) => u.id == userId, orElse: () => null);
    if (user == null) return '用户信息错误';
    final result = await repository.follow(userId, !user.followed);
    if (result.fail) return result.msg;
    user.followed = !user.followed;
    final otherList = _flag ? _followers : _followings;
    otherList.forEach((u) {
      if (u.id == userId) u.followed = user.followed;
    });
    return '';
  }
}
