import '../../common/pub.dart';
import '../model/post.dart';
import '../repository/repository.dart' as repository;

/// PostBase的扩展，主要是点赞点踩
extension PostBaseExt on PostBase {
  /// 点赞 [like] null 表示中立。返回结果空字符串表示成功，非空字符串表示失败
  Future<String> changeLikeState([bool like]) async {
    Result result;
    if (this is Post) {
      result = await repository.changeLikeState(postId: id, like: like);
    } else if (this is Floor) {
      result = await repository.changeLikeState(floorId: id, like: like);
    } else if (this is InnerFloor) {
      result = await repository.changeLikeState(innerFloorId: id, like: like);
    } else {
      return '类型不支持';
    }
    if (result.fail) return result.msg;
    final oa = myAttitude;
    final na = like == null
        ? 0
        : like
            ? 1
            : -1;
    myAttitude = na;
    if (oa == na) return '';
    if (oa == 1) {
      likeCnt--;
      if (na == -1) dislikeCnt++;
    } else if (oa == -1) {
      dislikeCnt--;
      if (na == 1) likeCnt++;
    } else {
      if (na == 1) {
        likeCnt++;
      } else {
        dislikeCnt++;
      }
    }
    return '';
  }
}

/// Post的扩展，主要是点关注
extension PostExt on Post {
  /// 关注、取消关注发帖人。返回结果空字符串表示成功，非空字符串表示失败
  Future<String> changeFollowPosterStatus() async {
    final result = await repository.follow(posterId, !posterFollowed);
    if (result.fail) return result.msg;
    posterFollowed = !posterFollowed;
    return '';
  }
}