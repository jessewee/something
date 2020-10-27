import 'package:base/base/pub.dart';
import 'package:forum/model/post.dart';
import 'package:forum/repository/repository.dart';

/// PostBase的扩展，主要是点赞点踩
extension PostBaseExt on PostBase {
  /// 点赞 [like] null 表示中立。返回结果空字符串表示成功，非空字符串表示失败
  Future<String> changeLikeState([bool like]) async {
    Result result;
    if (this is Post) {
      result = await Repository.changeLikeState(postId: id, like: like);
    } else if (this is Floor) {
      result = await Repository.changeLikeState(floorId: id, like: like);
    } else if (this is InnerFloor) {
      result = await Repository.changeLikeState(innerFloorId: id, like: like);
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
    if (oa == na) return '';
    if (oa == 0) {
      if (na == 1) {
        likeCnt++;
      } else {
        dislikeCnt++;
      }
    } else if (oa == -1) {
      dislikeCnt--;
      if (na == 1) likeCnt++;
    } else {
      likeCnt--;
      if (na == -1) dislikeCnt++;
    }
    return '';
  }
}

/// Post的扩展，主要是点关注
extension PostExt on Post {
  /// 关注、取消关注发帖人。返回结果空字符串表示成功，非空字符串表示失败
  Future<String> changeFollowPosterStatus() async {
    final result = await Repository.follow(posterId, !posterFollowed);
    if (result.fail) return result.msg;
    posterFollowed = !posterFollowed;
    return '';
  }
}
