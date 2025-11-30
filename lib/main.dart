import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  void addFavorite(WordPair pair) {
    if (!favorites.contains(pair)) {
      favorites.add(pair);
      notifyListeners();
    }
  }

  void removeFavorite(WordPair pair) {
    if (favorites.contains(pair)) {
      favorites.remove(pair);
      notifyListeners();
    }
  }

  void setCurrent(WordPair pair) {
    current = pair;
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  void goToHome() {
    setState(() {
      selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.95),
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.03),
                    ],
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: page,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatefulWidget {
  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  final List<WordPair> _suggestions = [];
  static const int _maxSuggestions = 8;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _maxSuggestions; i++) {
      _suggestions.add(WordPair.random());
    }
  }

  void _onNext(MyAppState appState) {
    final current = appState.current;
    if (!_suggestions.contains(current)) {
      _suggestions.insert(0, current);
      if (_suggestions.length > _maxSuggestions) _suggestions.removeLast();
    }
    appState.getNext();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon = appState.favorites.contains(pair)
        ? Icons.favorite
        : Icons.favorite_border;

    final theme = Theme.of(context);

    final favs = List<WordPair>.from(appState.favorites.reversed);
    final others = _suggestions.where((p) => !favs.contains(p)).toList();
    final combined = [...favs, ...others];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 140,
            width: 320,
            child: combined.isEmpty
                ? Center(
                    child: Text(
                      'No suggestions yet',
                      style: TextStyle(
                        color: theme.colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // ShaderMask: 顶部/底部渐隐遮罩
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (rect) => LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black,
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.12, 0.88, 1.0],
                          ).createShader(rect),
                          blendMode: BlendMode.dstIn,
                          child: ListView(
                            physics: BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(vertical: 8),
                            children: [
                              for (var p in combined.take(5))
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        appState.favorites.contains(p)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                      SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          context
                                              .read<MyAppState>()
                                              .setCurrent(p);
                                          final homeState =
                                              context.findAncestorStateOfType<
                                                  _MyHomePageState>();
                                          homeState?.goToHome();
                                        },
                                        child: Text(
                                          p.asPascalCase,
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      IconButton(
                                        iconSize: 18,
                                        icon: Icon(
                                          appState.favorites.contains(p)
                                              ? Icons.delete_outline
                                              : Icons.add_circle_outline,
                                          color: theme.colorScheme.primary,
                                        ),
                                        onPressed: () {
                                          if (appState.favorites.contains(p)) {
                                            appState.removeFavorite(p);
                                          } else {
                                            appState.addFavorite(p);
                                          }
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      if (combined.length > 5)
                        TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (ctx) {
                                return Container(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('All suggestions',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                      SizedBox(height: 8),
                                      Flexible(
                                        child: ListView(
                                          shrinkWrap: true,
                                          children: [
                                            for (var p in combined)
                                              ListTile(
                                                leading: Icon(
                                                  appState.favorites.contains(p)
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                                title: Text(p.asPascalCase),
                                                trailing: IconButton(
                                                  icon: Icon(appState.favorites
                                                          .contains(p)
                                                      ? Icons.delete_outline
                                                      : Icons
                                                          .add_circle_outline),
                                                  onPressed: () {
                                                    if (appState.favorites
                                                        .contains(p)) {
                                                      appState
                                                          .removeFavorite(p);
                                                    } else {
                                                      appState.addFavorite(p);
                                                    }
                                                    (ctx as Element)
                                                        .markNeedsBuild();
                                                  },
                                                ),
                                                onTap: () {
                                                  context
                                                      .read<MyAppState>()
                                                      .setCurrent(p);
                                                  Navigator.of(ctx).pop();
                                                  final homeState = context
                                                      .findAncestorStateOfType<
                                                          _MyHomePageState>();
                                                  homeState?.goToHome();
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Text('More'),
                        ),
                    ],
                  ),
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 350),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: BigCard(key: ValueKey(pair.asPascalCase), pair: pair),
          ),
          SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                  setState(() {});
                },
                icon: Icon(icon, color: theme.colorScheme.primary),
                label: Text('Like',
                    style: TextStyle(color: theme.colorScheme.primary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  elevation: 0,
                  shape: StadiumBorder(),
                  side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.12)),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  _onNext(appState);
                },
                child: Text('Next',
                    style: TextStyle(color: theme.colorScheme.primary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  elevation: 0,
                  shape: StadiumBorder(),
                  side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.12)),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({super.key, required this.pair});

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: 220, minHeight: 80),
          child: Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: pair.first + ' ',
                    style: style.copyWith(fontWeight: FontWeight.w400),
                  ),
                  TextSpan(
                    text: pair.second,
                    style: style.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<WordPair> _localFavorites;
  MyAppState? _appState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.read<MyAppState>();
    if (_appState != appState) {
      _appState?.removeListener(_onFavoritesChanged);
      _appState = appState;
      _localFavorites = List.from(_appState!.favorites);
      _appState!.addListener(_onFavoritesChanged);
    }
  }

  @override
  void dispose() {
    _appState?.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    final newList = _appState!.favorites;
    if (newList.length > _localFavorites.length) {
      final index = newList.indexWhere((e) => !_localFavorites.contains(e));
      if (index >= 0) {
        _localFavorites.insert(index, newList[index]);
        _listKey.currentState
            ?.insertItem(index, duration: Duration(milliseconds: 300));
      }
    } else if (newList.length < _localFavorites.length) {
      final index = _localFavorites.indexWhere((e) => !newList.contains(e));
      if (index >= 0) {
        final removed = _localFavorites.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: ListTile(
              leading: Icon(Icons.favorite),
              title: Text(removed.asPascalCase),
            ),
          ),
          duration: Duration(milliseconds: 300),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty && _localFavorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return AnimatedList(
      key: _listKey,
      initialItemCount: _localFavorites.length,
      padding: EdgeInsets.only(top: 8),
      itemBuilder: (context, index, animation) {
        final pair = _localFavorites[index];
        final offsetAnimation = Tween<Offset>(
                begin: Offset(0.25, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: ListTile(
              leading: Icon(Icons.favorite,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(pair.asPascalCase),
              onTap: () {
                context.read<MyAppState>().setCurrent(pair);
                context.read<MyAppState>().removeFavorite(pair);
                final homeState =
                    context.findAncestorStateOfType<_MyHomePageState>();
                homeState?.goToHome();
              },
              trailing: IconButton(
                icon: Icon(Icons.delete_outline),
                onPressed: () {
                  context.read<MyAppState>().removeFavorite(pair);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
