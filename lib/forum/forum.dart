library forum;

import 'package:flutter/widgets.dart';

import '../app.dart';
import '../common/widgets.dart';

import 'model/post.dart';
import 'view/forum_page.dart';
import 'view/select_following_page.dart';
import 'view/select_post_label_page.dart';
import 'view/search_content_page.dart';
import 'view/post_detail_page.dart';
import 'view/user_follow_page.dart';
import 'view/user_page.dart';
import 'view/user_post_page.dart';
import 'view/user_reply_page.dart';

final List<RouteInfo> forumRoutes = [
  RouteInfo(ForumPage.routeName, false, (_) => ForumPage()),
  RouteInfo(SearchContentPage.routeName, false, (_) => SearchContentPage()),
  RouteInfo(SelectPostLabelPage.routeName, false, (_) => SelectPostLabelPage()),
  RouteInfo(
    SelectFollowingPage.routeName,
    true,
    (context) {
      final arg = ModalRoute.of(context).settings.arguments;
      if (arg != null && arg is bool) {
        return SelectFollowingPage(singleSelect: arg);
      } else {
        return SelectFollowingPage();
      }
    },
  ),
  RouteInfo(
    PostDetailPage.routeName,
    false,
    (context) {
      final arg = ModalRoute.of(context).settings.arguments;
      if (arg == null || arg is! Post) return ParamErrorPage(arg);
      return PostDetailPage(arg);
    },
  ),
  RouteInfo(UserPage.routeName, false, (context) {
    final arg = ModalRoute.of(context).settings.arguments;
    if (arg == null || arg is! String) return ParamErrorPage(arg);
    return UserPage(arg);
  }),
  RouteInfo(
    UserFollowPage.routeName,
    false,
    (context) {
      final arg = ModalRoute.of(context).settings.arguments;
      if (arg == null || arg is! UserFollowPageArg) return ParamErrorPage(arg);
      return UserFollowPage(arg);
    },
  ),
  RouteInfo(
    UserPostPage.routeName,
    false,
    (context) {
      final arg = ModalRoute.of(context).settings.arguments;
      if (arg == null || arg is! UserPostPageArg) return ParamErrorPage(arg);
      return UserPostPage(arg);
    },
  ),
  RouteInfo(
    UserReplyPage.routeName,
    false,
    (context) {
      final arg = ModalRoute.of(context).settings.arguments;
      if (arg == null || arg is! String) return ParamErrorPage(arg);
      return UserReplyPage(arg);
    },
  ),
];
