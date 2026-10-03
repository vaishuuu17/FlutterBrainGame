import 'dart:math';

import 'package:flutter/material.dart';

import 'package:brain_game/classes/swap_action.dart';
import 'package:brain_game/enums/event.dart';
import 'package:brain_game/constants/game_constants.dart';
import 'package:brain_game/enums/swap_item_name.dart';
import 'package:brain_game/classes/event_generator.dart';
import 'package:brain_game/classes/item_selector.dart';
import 'package:brain_game/enums/widget_name.dart';
import 'package:brain_game/classes/swap_items_box.dart';

import 'package:brain_game/ui/widgets/alram_clock.dart';
import 'package:brain_game/ui/widgets/book.dart';
import 'package:brain_game/ui/widgets/score.dart';
import 'package:brain_game/ui/widgets/score_dialog.dart';

import 'package:brain_game/utils/game_assets.dart';
import '../controllers/game_score_controller.dart';


// ============================================================
// DRIVER
// ============================================================

class Driver {
  // ----------------------------------------------------------
  // Singleton
  // ----------------------------------------------------------

  static final Driver _instance = Driver._internal();

  factory Driver() {
    return _instance;
  }

  Driver._internal() {
    _numberOfPlayedLevels = 0;
    _numberOfPlayedRoundsBerLevel = 0;
    _timeInMilliseconds = GameCosntants.startTimeInMilliseconds;
  }

  // ----------------------------------------------------------
  // Variables
  // ----------------------------------------------------------

  late final Map<Enum, GlobalKey<State<StatefulWidget>>> _stateKeysMap;

  late BuildContext _context;

  late int _numberOfPlayedLevels;

  late int _numberOfPlayedRoundsBerLevel;

  late int _timeInMilliseconds;

  int _streamId = 0;

  // IMPORTANT:
  // Prevent multiple selections while the animation/question
  // transition is happening.
  bool _isProcessingSelection = false;

  // ----------------------------------------------------------
  // START / DRIVE GAME
  // ----------------------------------------------------------

  Future<void> drive(bool isFirstSelect) async {
    // If game is already finished, don't generate anything.
    if (_numberOfPlayedLevels >= GameCosntants.numberOfLevels) {
      return;
    }

    // --------------------------------------------------------
    // New level
    // --------------------------------------------------------

    if (_numberOfPlayedRoundsBerLevel ==
        GameCosntants.numberOfRoundsBerLevel) {
      _numberOfPlayedLevels++;

      _numberOfPlayedRoundsBerLevel = 0;

      _decrementDurationOfSwapAnimation();
    }

    // --------------------------------------------------------
    // Generate random swaps
    // --------------------------------------------------------

    int numberOfSwaps = randomNumberOfSwaps;

    for (int i = 0; i < numberOfSwaps; i++) {
      // Generate event
      Event event = EventGenerator.generate();

      // Generate action for event
      SwapAction action =
          SwapAction.createSwapActionByEvent(event, _context);

      // Update items and run animation
      await _sendActionValuesToBoxAndRunTheAnimation(
        event,
        action,
      );
    }

    // --------------------------------------------------------
    // Count round
    // --------------------------------------------------------

    if (!isFirstSelect) {
      _numberOfPlayedRoundsBerLevel++;
    }
  }

  // ==========================================================
  // PLAYER SELECT
  // ==========================================================

  Future<void> select(
    SwapItemName label,
    bool isFirstSelect,
  ) async {
    // --------------------------------------------------------
    // Ignore clicks while animation is running
    // --------------------------------------------------------

    if (_isProcessingSelection) {
      return;
    }

    // --------------------------------------------------------
    // Check whether animation is still running
    // --------------------------------------------------------

    if (!checkSelectEnable()) {
      return;
    }

    _isProcessingSelection = true;

    try {
      // ------------------------------------------------------
      // Get correct answer
      // ------------------------------------------------------

      SwapItemName correctAnswer =
          SwapItemsBox().getSelectedSwapItem;

      // ------------------------------------------------------
      // CORRECT ANSWER
      // ------------------------------------------------------

      if (correctAnswer == label) {
        // First selection is only used to initialize the game.
        if (!isFirstSelect) {
          // -----------------------------------------------
          // Increase score
          // -----------------------------------------------

          GameScoreController.to.incrementScore();

          // -----------------------------------------------
          // Flip score coin
          // -----------------------------------------------

          final scoreState =
              _stateKeysMap[WidgetName.score]?.currentState;

          if (scoreState is ScoreState) {
            scoreState.flipCoin();
          }

          // -----------------------------------------------
          // Correct-answer sound
          // -----------------------------------------------

          try {
            await GameAssets.pool.play(
              GameAssets.earnCoinsSoundId,
            );
          } catch (_) {
            // Sound is optional on unsupported platforms.
          }
        }

        // ----------------------------------------------------
        // Generate NEXT question
        // ----------------------------------------------------

        await drive(isFirstSelect);

        return;
      }

      // ======================================================
      // WRONG ANSWER
      // ======================================================

      // Stop background music
      try {
        await GameAssets.backgroundPlayer.stop();
      } catch (_) {}

      // Stop alarm clock
      final alarmState =
          _stateKeysMap[WidgetName.alarmClock]?.currentState;

      if (alarmState is AlarmClockState) {
        alarmState.cancelClock();
      }

      // ------------------------------------------------------
      // Check current score
      // ------------------------------------------------------

      int score = GameScoreController.to.score;

      bool isVictory = score >= 15;

      // ------------------------------------------------------
      // Play game-over / victory sound
      // ------------------------------------------------------

      try {
        if (isVictory) {
          _streamId = await GameAssets.pool.play(
            GameAssets.victorySoundId,
          );
        } else {
          _streamId = await GameAssets.pool.play(
            GameAssets.gameOverSoundId,
          );
        }
      } catch (_) {
        // Sound is optional on unsupported platforms.
      }

      // ------------------------------------------------------
      // Show result dialog
      // ------------------------------------------------------

      await showDialog(
        context: _context,
        barrierDismissible: false,
        builder: (context) {
          return ScoreDialog(
            isVictory: isVictory,
          );
        },
      );
    } finally {
      _isProcessingSelection = false;
    }
  }

  // ==========================================================
  // RESTART GAME
  // ==========================================================

  Future<void> restart() async {
    // --------------------------------------------------------
    // Reset game variables
    // --------------------------------------------------------

    _cleanGameVariables();

    _isProcessingSelection = false;

    // --------------------------------------------------------
    // Select random initial item
    // --------------------------------------------------------

    SwapItemsBox().setSelectedSwapItem =
        ItemSelector.select();

    // --------------------------------------------------------
    // Reset all books
    // --------------------------------------------------------

    _stateKeysMap.forEach(
      (key, value) {
        if (key.name.length > 8 &&
            key.name.substring(
                  key.name.length - 8,
                ) ==
                'SwapItem') {
          final state = value.currentState;

          if (state is BookState) {
            state.runFirstCheckAnimation();

            state.setDurationOfSwapAnimation(
              Duration(
                milliseconds: _timeInMilliseconds,
              ),
            );
          }
        }
      },
    );

    // --------------------------------------------------------
    // Restart alarm clock
    // --------------------------------------------------------

    final alarmState =
        _stateKeysMap[WidgetName.alarmClock]?.currentState;

    if (alarmState is AlarmClockState) {
      alarmState.startClock();
    }

    // --------------------------------------------------------
    // Stop previous result sound
    // --------------------------------------------------------

    try {
      await GameAssets.pool.stop(_streamId);
    } catch (_) {}

    // --------------------------------------------------------
    // Restart background music
    // --------------------------------------------------------

    try {
      await GameAssets.backgroundPlayer.seekToNext();

      await GameAssets.backgroundPlayer.play();
    } catch (_) {}
  }

  // ==========================================================
  // SETTERS
  // ==========================================================

  set setContext(BuildContext context) {
    _context = context;
  }

  set setStateKeysMap(
    Map<Enum, GlobalKey<State<StatefulWidget>>> map,
  ) {
    _stateKeysMap = map;
  }

  // ==========================================================
  // RESET GAME VARIABLES
  // ==========================================================

  void _cleanGameVariables() {
    GameScoreController.to.cleanScore();

    _numberOfPlayedLevels = 0;

    _numberOfPlayedRoundsBerLevel = 0;

    _timeInMilliseconds =
        GameCosntants.startTimeInMilliseconds;
  }

  // ==========================================================
  // DECREASE ANIMATION TIME
  // ==========================================================

  void _decrementDurationOfSwapAnimation() {
    _timeInMilliseconds -=
        GameCosntants.timeToDecrementInMilliseconds;

    // Prevent negative animation duration
    if (_timeInMilliseconds < 100) {
      _timeInMilliseconds = 100;
    }

    _stateKeysMap.forEach(
      (key, value) {
        if (key.name.length > 8 &&
            key.name.substring(
                  key.name.length - 8,
                ) ==
                'SwapItem') {
          final state = value.currentState;

          if (state is BookState) {
            state.setDurationOfSwapAnimation(
              Duration(
                milliseconds: _timeInMilliseconds,
              ),
            );
          }
        }
      },
    );
  }

  // ==========================================================
  // RANK
  // ==========================================================

  String get getRank {
    int score = GameScoreController.to.score;

    if (score < 5) {
      return GameCosntants.ranks[0];
    } else if (score < 10) {
      return GameCosntants.ranks[1];
    } else if (score < 15) {
      return GameCosntants.ranks[2];
    } else if (score < 20) {
      return GameCosntants.ranks[3];
    } else if (score < 25) {
      return GameCosntants.ranks[4];
    } else {
      return GameCosntants.ranks[5];
    }
  }

  // ==========================================================
  // STARS
  // ==========================================================

  int get getNumberOfStars {
    int score = GameScoreController.to.score;

    if (score < 10) {
      return 0;
    } else if (score < 15) {
      return 1;
    } else if (score < 20) {
      return 2;
    } else if (score < 25) {
      return 3;
    } else {
      return 4;
    }
  }

  // ==========================================================
  // RANDOM NUMBER OF SWAPS
  // ==========================================================

  int get randomNumberOfSwaps {
    int index =
        _numberOfPlayedRoundsBerLevel - 1;

    if (index < 0) {
      index = 0;
    }

    int minimum =
        GameCosntants.minNumberOfSwapsBerLevel[index];

    int maximum =
        GameCosntants.maxNumberOfSwapsBerLevelArray[index];

    // nextInt(maximum - minimum) excludes maximum.
    // +1 makes maximum inclusive.
    if (maximum <= minimum) {
      return minimum;
    }

    return minimum +
        Random().nextInt(
          maximum - minimum + 1,
        );
  }

  // ==========================================================
  // UPDATE ITEMS + ANIMATION
  // ==========================================================

  Future<void> _sendActionValuesToBoxAndRunTheAnimation(
    Event event,
    SwapAction action,
  ) async {
    // --------------------------------------------------------
    // FIRST + SECOND
    // --------------------------------------------------------

    if (event == Event.firstAndSecond) {
      SwapItemsBox().setSwapItem(
        swapItemLabel:
            SwapItemName.firstSwapItem,
        swapItem: action.prefixItem,
      );

      SwapItemsBox().setSwapItem(
        swapItemLabel:
            SwapItemName.secondSwapItem,
        swapItem: action.suffixItem,
      );

      // Update correct answer
      SwapItemsBox().setSelectedSwapItem =
          ItemSelector.swapSelectedItem(
        event,
        SwapItemsBox().getSelectedSwapItem,
      );

      // Animate
      await _runTheSwapAnimation(
        SwapItemName.firstSwapItem,
        SwapItemName.secondSwapItem,
      );

      return;
    }

    // --------------------------------------------------------
    // SECOND + THIRD
    // --------------------------------------------------------

    if (event == Event.secondAndThird) {
      SwapItemsBox().setSwapItem(
        swapItemLabel:
            SwapItemName.secondSwapItem,
        swapItem: action.prefixItem,
      );

      SwapItemsBox().setSwapItem(
        swapItemLabel:
            SwapItemName.thirdSwapItem,
        swapItem: action.suffixItem,
      );

      // Update correct answer
      SwapItemsBox().setSelectedSwapItem =
          ItemSelector.swapSelectedItem(
        event,
        SwapItemsBox().getSelectedSwapItem,
      );

      // Animate
      await _runTheSwapAnimation(
        SwapItemName.secondSwapItem,
        SwapItemName.thirdSwapItem,
      );

      return;
    }

    // --------------------------------------------------------
    // FIRST + THIRD
    // --------------------------------------------------------

    SwapItemsBox().setSwapItem(
      swapItemLabel:
          SwapItemName.firstSwapItem,
      swapItem: action.prefixItem,
    );

    SwapItemsBox().setSwapItem(
      swapItemLabel:
          SwapItemName.thirdSwapItem,
      swapItem: action.suffixItem,
    );

    // Update correct answer
    SwapItemsBox().setSelectedSwapItem =
        ItemSelector.swapSelectedItem(
      event,
      SwapItemsBox().getSelectedSwapItem,
    );

    // Animate
    await _runTheSwapAnimation(
      SwapItemName.firstSwapItem,
      SwapItemName.thirdSwapItem,
    );
  }

  // ==========================================================
  // CHECK WHETHER PLAYER CAN SELECT
  // ==========================================================

  bool checkSelectEnable() {
    final firstState =
        _stateKeysMap[SwapItemName.firstSwapItem]
            ?.currentState;

    final secondState =
        _stateKeysMap[SwapItemName.secondSwapItem]
            ?.currentState;

    final thirdState =
        _stateKeysMap[SwapItemName.thirdSwapItem]
            ?.currentState;

    if (firstState is! BookState ||
        secondState is! BookState ||
        thirdState is! BookState) {
      return false;
    }

    return !firstState.isAnimating &&
        !secondState.isAnimating &&
        !thirdState.isAnimating;
  }

  // ==========================================================
  // RUN SWAP ANIMATION
  // ==========================================================

  Future<void> _runTheSwapAnimation(
    SwapItemName firstItem,
    SwapItemName secondItem,
  ) async {
    final firstState =
        _stateKeysMap[firstItem]?.currentState;

    final secondState =
        _stateKeysMap[secondItem]?.currentState;

    if (firstState is! BookState ||
        secondState is! BookState) {
      return;
    }

    // Start first animation
    firstState.runForwardAnimation();

    // Wait for second animation.
    await secondState.runForwardAnimation();
  }
}