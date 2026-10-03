import 'dart:math';

import 'package:brain_game/enums/event.dart';
import 'package:brain_game/enums/swap_item_name.dart';

class ItemSelector {
  // Use one Random object instead of creating a new one
  // every time the function is called.
  static final Random _random = Random();

  // ==========================================================
  // SELECT INITIAL CORRECT ITEM
  // ==========================================================

  /// Randomly selects which book initially contains the message.
  static SwapItemName select() {
    int randomValue = _random.nextInt(3);

    if (randomValue == 0) {
      return SwapItemName.firstSwapItem;
    }

    if (randomValue == 1) {
      return SwapItemName.secondSwapItem;
    }

    return SwapItemName.thirdSwapItem;
  }

  // ==========================================================
  // UPDATE CORRECT ITEM AFTER A SWAP
  // ==========================================================

  /// Returns the new location of the message after a swap.
  ///
  /// Example:
  ///
  /// Message is in first book.
  /// Event = firstAndSecond.
  ///
  /// After the swap:
  /// Message is in second book.
  ///
  /// If the message is in the third book and the event is
  /// firstAndSecond, it remains in the third book.
  static SwapItemName swapSelectedItem(
    Event event,
    SwapItemName selectedItem,
  ) {
    // --------------------------------------------------------
    // FIRST <-> SECOND
    // --------------------------------------------------------

    if (event == Event.firstAndSecond) {
      if (selectedItem == SwapItemName.firstSwapItem) {
        return SwapItemName.secondSwapItem;
      }

      if (selectedItem == SwapItemName.secondSwapItem) {
        return SwapItemName.firstSwapItem;
      }

      // Message is in third book.
      return SwapItemName.thirdSwapItem;
    }

    // --------------------------------------------------------
    // SECOND <-> THIRD
    // --------------------------------------------------------

    if (event == Event.secondAndThird) {
      if (selectedItem == SwapItemName.secondSwapItem) {
        return SwapItemName.thirdSwapItem;
      }

      if (selectedItem == SwapItemName.thirdSwapItem) {
        return SwapItemName.secondSwapItem;
      }

      // Message is in first book.
      return SwapItemName.firstSwapItem;
    }

    // --------------------------------------------------------
    // FIRST <-> THIRD
    // --------------------------------------------------------

    if (event == Event.firstAndThird) {
      if (selectedItem == SwapItemName.firstSwapItem) {
        return SwapItemName.thirdSwapItem;
      }

      if (selectedItem == SwapItemName.thirdSwapItem) {
        return SwapItemName.firstSwapItem;
      }

      // Message is in second book.
      return SwapItemName.secondSwapItem;
    }

    // Safety fallback
    return selectedItem;
  }
}
