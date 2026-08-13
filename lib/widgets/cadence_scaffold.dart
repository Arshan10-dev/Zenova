import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../screens/now_playing/now_playing_screen.dart';
import 'mini_player.dart';

class ZenovaScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavBar;
  final bool showMiniPlayer;
  final Color? backgroundColor;

  const ZenovaScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavBar,
    this.showMiniPlayer = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasQueue = context.select<PlayerProvider, bool>((p) => p.hasQueue);
    final showPlayer = showMiniPlayer && hasQueue;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: body,
      bottomNavigationBar: (!showPlayer && bottomNavBar == null)
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showPlayer) MiniPlayer(onExpand: () => pushNowPlaying(context)),
                if (bottomNavBar != null) bottomNavBar!,
              ],
            ),
    );
  }
}
