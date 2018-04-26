import 'dart:async';
import 'dart:convert' show json;

import 'package:awesome_dev/api/articles.dart';
import 'package:awesome_dev/ui/widgets/article_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum IndicatorType { overscroll, refresh }

class FavoriteNews extends StatefulWidget {
  final String search;

  FavoriteNews({this.search});

  @override
  State<StatefulWidget> createState() => new FavoriteNewsState();
}

class FavoriteNewsState extends State<FavoriteNews> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  List<Article> _articles;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<Null> _fetchArticles() async {
    _refreshIndicatorKey.currentState.show();
    final articlesClient = new ArticlesClient();
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList("favs") ?? <String>[];
      final articlesToLookup = <Article>[];
      for (var fav in favorites) {
        final Map<String, dynamic> map = json.decode(fav);
        articlesToLookup
            .add(new Article(map['title'].toString(), map['url'].toString()));
      }
      final favoriteArticles =
          await articlesClient.getFavoriteArticles(articlesToLookup);
      for (var article in favoriteArticles) {
        article.starred = true;
      }
      setState(() {
        _articles = favoriteArticles;
      });
    } on Exception catch (e) {
      Scaffold.of(context).showSnackBar(new SnackBar(
            content: new Text("Internal Error: ${e.toString()}"),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return new RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _fetchArticles,
        child: new Container(
          padding: new EdgeInsets.all(8.0),
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              new Expanded(
                child: new ListView.builder(
                  padding: new EdgeInsets.all(8.0),
                  itemCount: _articles?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    return new ArticleWidget(
                      article: _articles[index],
//                    onCardClick: () {
//  //                      Navigator.of(context).push(
//  //                          new FadeRoute(
//  //                            builder: (BuildContext context) => new BookNotesPage(_items[index]),
//  //                            settings: new RouteSettings(name: '/notes', isInitialRoute: false),
//  //                          ));
//                    },
                      onStarClick: () {
                        setState(() {
                          _articles[index].starred = !_articles[index].starred;
                        });
                        //                      Repository.get().updateBook(_items[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ));
  }
}
