library forum;

import 'package:flutter/widgets.dart';

import 'view/forum_page.dart';
import 'view/search_content_page.dart';

final Map<String, WidgetBuilder> forumRoutes = {
  ForumPage.routeName: (_) => ForumPage(),
  SearchContentPage.routeName: (_) => SearchContentPage(),
};
