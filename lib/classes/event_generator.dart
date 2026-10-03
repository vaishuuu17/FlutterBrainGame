import 'dart:math';

import 'package:brain_game/enums/event.dart';

class EventGenerator {
  // Create ONE Random object and reuse it.
  static final Random _random = Random();

  /// Generates a random swap event.
  static Event generate() {
    int randomValue = _random.nextInt(3);

    if (randomValue == 0) {
      return Event.firstAndSecond;
    } else if (randomValue == 1) {
      return Event.secondAndThird;
    } else {
      return Event.firstAndThird;
    }
  }
}