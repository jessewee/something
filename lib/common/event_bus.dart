import 'dart:async';

EventBus get eventBus => EventBus();

typedef void EventBusCallback(arg);

/// 监听、触发全局事件
class EventBus {
  static EventBus _singleton;

  // 事件分发StreamController
  final StreamController<_Event> _controller;

  EventBus._init() : _controller = StreamController<_Event>() {
    _controller.stream.listen((e) {
      callbacks.where((c) => c.type == e.type).forEach((c) => c.cb(e.arg));
    });
  }

  factory EventBus() {
    if (_singleton == null) _singleton = EventBus._init();
    return _singleton;
  }

  // 监听的回调方法
  final callbacks = List<_Callback>();

  /// 监听事件
  void on(EventBusType type, EventBusCallback cb, [tag = 'all']) {
    assert(type != null && cb != null, 'EventBug监听必须传入type和cb');
    callbacks.add(_Callback(type, tag, cb));
  }

  /// 取消监听
  void off({EventBusType type, String tag, EventBusCallback cb}) {
    assert(
      type != null || tag != null || cb != null,
      '取消EventBug监听必须传入type、tag或者cb',
    );
    if (type != null) callbacks.removeWhere((c) => c.type == type);
    if (tag != null) callbacks.removeWhere((c) => c.tag == tag);
    if (cb != null) callbacks.removeWhere((c) => c.cb == cb);
  }

  /// 发送事件
  void sendEvent(EventBusType type, [dynamic arg]) {
    assert(type != null, 'EventBug发送事件必须传入type');
    _controller.add(_Event(type, arg));
  }
}

class _Event {
  final EventBusType type;
  final dynamic arg;

  _Event(this.type, [this.arg]);
}

class _Callback {
  final EventBusType type;
  final String tag;
  final EventBusCallback cb;

  _Callback(this.type, this.tag, this.cb);
}

enum EventBusType {
  /// 登录失效
  loginInvalid,

  /// 帖子列表里的信息改变
  forumPostItemChanged
}
