import 'package:brain_game/classes/item_selector.dart';
import 'package:brain_game/models/swap_item.dart';
import 'package:brain_game/enums/swap_item_name.dart';

/// Singleton class that contains the current state of the books.
class SwapItemsBox {
  static final SwapItemsBox _instance = SwapItemsBox._internal();

  factory SwapItemsBox() => _instance;

  SwapItemsBox._internal() {
    _swapItemsMap = {
      SwapItemName.firstSwapItem: SwapItem(
        horizontalSpace: 0.0,
        verticalSpace: 0.0,
      ),
      SwapItemName.secondSwapItem: SwapItem(
        horizontalSpace: 0.0,
        verticalSpace: 0.0,
      ),
      SwapItemName.thirdSwapItem: SwapItem(
        horizontalSpace: 0.0,
        verticalSpace: 0.0,
      ),
    };

    // Randomly choose the initial correct book.
    _selectedSwapItem = ItemSelector.select();
  }

  late final Map<SwapItemName, SwapItem?> _swapItemsMap;

  late SwapItemName _selectedSwapItem;

  // ---------------------------------------------------------
  // Swap item position
  // ---------------------------------------------------------

  void setSwapItemHorizontalSpace({
    required SwapItemName swapItemLabel,
    required double horizontalSpace,
  }) {
    _swapItemsMap[swapItemLabel] =
        _swapItemsMap[swapItemLabel]?.copyWith(
      horizontalSpace: horizontalSpace,
    );
  }

  void setSwapItemVerticalSpace({
    required SwapItemName swapItemLabel,
    required double verticalSpace,
  }) {
    _swapItemsMap[swapItemLabel] =
        _swapItemsMap[swapItemLabel]?.copyWith(
      verticalSpace: verticalSpace,
    );
  }

  double getSwapItemHorizontalSpace({
    required SwapItemName? swapItemLabel,
  }) {
    return _swapItemsMap[swapItemLabel]?.horizontalSpace ?? 0.0;
  }

  double getSwapItemVerticalSpace({
    required SwapItemName? swapItemLabel,
  }) {
    return _swapItemsMap[swapItemLabel]?.verticalSpace ?? 0.0;
  }

  // ---------------------------------------------------------
  // Set/Get complete SwapItem
  // ---------------------------------------------------------

  void setSwapItem({
    required SwapItemName swapItemLabel,
    required SwapItem swapItem,
  }) {
    _swapItemsMap[swapItemLabel] = swapItem;
  }

  // ---------------------------------------------------------
  // Correct item
  // ---------------------------------------------------------

  set setSelectedSwapItem(SwapItemName selectedSwapItem) {
    _selectedSwapItem = selectedSwapItem;
  }

  SwapItemName get getSelectedSwapItem => _selectedSwapItem;
}