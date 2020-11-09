import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../configs.dart';
import 'event_bus.dart';
import 'pub.dart';

Network get network => Network();

/// 接口请求
class Network {
  Dio _dio;
  static Network _singleton;

  factory Network() {
    if (_singleton == null) _singleton = Network._init();
    return _singleton;
  }

  // tag和CancelToken
  final _cancelTokens = Map<String, CancelToken>();

  // token，验证账号
  var _token = '';

  // 用来更新token
  var __refreshToken = '';

  set _refreshToken(value) {
    __refreshToken = value;
    SharedPreferences.getInstance()
        .then((sp) => sp.setString('login_solid_token', value));
  }

  Future<String> get _refreshToken async {
    if (__refreshToken.isEmpty) {
      var sp = await SharedPreferences.getInstance();
      __refreshToken = sp.getString('login_refresh_token') ?? '';
    }
    return __refreshToken;
  }

  Network._init() {
    _dio = Dio();
    _dio.options.baseUrl = apiServer;
    // _dio.options.connectTimeout = 5000;
    // _dio.options.receiveTimeout = 5000;
    _dio.interceptors.add(CookieManager(CookieJar()));
    _dio.interceptors
        .add(LogInterceptor(requestBody: true, responseBody: true));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options) async {
        // 给header赋值token，或者发送refreshToken来刷新token
        if (_token.isNotEmpty) {
          options.headers['token'] = _token;
        } else {
          final tmp = await _refreshToken;
          if (tmp.isNotEmpty) options.headers['refresh_token'] = tmp;
        }
        return options;
      },
      onResponse: (e) async {
        // 保存服务器返回的token
        final token = e.headers?.value('token') ?? '';
        if (token.isNotEmpty) _token = token;
        final refreshToken = e.headers?.value('refresh_token') ?? '';
        if (refreshToken.isNotEmpty) _refreshToken = refreshToken;
        return e;
      },
      onError: (e) {
        showToast('网络出错：${e.message}');
        return Response();
      },
    ));
    eventBus.on('base_leave_page', (arg) {
      if (arg == null || !(arg is String)) return;
      CancelToken ct = _cancelTokens[arg];
      if (ct != null) {
        _cancelTokens.remove(arg);
        ct.cancel('离开页面：$arg');
      }
    });
  }

  /// GET请求 [tag]用来标记请求，取消时用到，比如离开页面时取消网络请求
  Future<Result> get(
    String path, {
    Map<String, dynamic> params = const {},
    String tag,
  }) async {
    Response<String> response = await _dio.get(
      path,
      queryParameters: params,
      cancelToken: _getCancelTokenByTag(tag),
    );
    var result = toResult(response);
    // null表示需要重新请求接口
    if (result == null) {
      return get(path, params: params, tag: tag);
    }
    return result;
  }

  /// POST请求
  Future<Result> post(String path, {var params = const {}, String tag}) async {
    Response response = await _dio.post(
      path,
      data: params,
      cancelToken: _getCancelTokenByTag(tag),
    );
    var result = toResult(response);
    // null表示需要重新请求接口
    if (result == null) {
      return post(path, params: params, tag: tag);
    }
    return result;
  }

  /// PUT请求
  Future<Result> put(String path, {var params = const {}, String tag}) async {
    Response response = await _dio.put(
      path,
      data: params,
      cancelToken: _getCancelTokenByTag(tag),
    );
    var result = toResult(response);
    // null表示需要重新请求接口
    if (result == null) {
      return put(path, params: params, tag: tag);
    }
    return result;
  }

  /// DELETE请求
  Future<Result> delete(String path,
      {Map<String, dynamic> params = const {}, String tag}) async {
    Response response = await _dio.delete(
      path,
      queryParameters: params,
      cancelToken: _getCancelTokenByTag(tag),
    );
    var result = toResult(response);
    // null表示需要重新请求接口
    if (result == null) {
      return delete(path, params: params, tag: tag);
    }
    return result;
  }

  /// 通过tag获取CancelToken
  CancelToken _getCancelTokenByTag(String tag) {
    CancelToken cancelToken;
    if (tag?.isNotEmpty == true) {
      cancelToken = _cancelTokens[tag];
      if (cancelToken == null) {
        cancelToken = CancelToken();
        _cancelTokens[tag] = cancelToken;
      }
    }
    return cancelToken;
  }

  // null表示需要重新请求接口
  Future<Result> toResult(Response response) async {
    if (response.data == null || response.data is! String)
      return const Result();
    var resp = json.decode(response.data);
    if (resp["code"] == null) return const Result();
    var result = Result(
      code: resp["code"],
      msg: resp["message"],
      data: resp["data"],
    );
    // 需要重新登录
    if (result.code == 10000 ||
        (result.code == 10001 && (await _refreshToken).isEmpty)) {
      eventBus.sendEvent('base_login_invalid');
      return result;
    }
    // token失效，refreshToken存在，需要重新请求
    if (result.code == 10001) {
      _token = '';
      return null;
    }
    return result;
  }
}
