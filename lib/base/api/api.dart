import '../../common/pub.dart';
import '../../common/models.dart';

/// 登录
Future<Result> login(String account, String pwd) async {
  // TODO
  await Future.delayed(Duration(seconds: 1));
  return Future.value(Result
      .success()); // 登录成功应该在header里返回refreshToken和token，然后通过token调用接口获取用户信息
}

/// 获取用户数据
Future<Result<User>> getUserInfo() async {
  // TODO
  await Future.delayed(Duration(seconds: 1));
  // if (Random.secure().nextBool()) {
  //   return Future.value(Result(msg: "获取用户信息失败"));
  // } else {
  return Future.value(
    Result.success(
      User(
        id: '0',
        name: '名字',
        avatar: '',
        gender: Gender.male,
        birthday: '',
        registerDate: '',
      ),
    ),
  );
  // }
}
