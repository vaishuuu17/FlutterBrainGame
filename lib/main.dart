import 'package:flutter/material.dart';

import 'package:brain_game/ui/screens/home.dart';
import 'package:brain_game/utils/game_assets.dart';
import 'package:brain_game/utils/game_colors.dart';

Future<void> main() async {
  // Initialize Flutter before loading game assets.
  WidgetsFlutterBinding.ensureInitialized();

  // Preload images and audio before starting the game.
  await GameAssets.preloadAssets();
  runApp(
    MaterialApp(
      theme: ThemeData(
        primaryColor: GameColors.green,
      ),
      title: 'BrainGame',
      home: const Home(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
