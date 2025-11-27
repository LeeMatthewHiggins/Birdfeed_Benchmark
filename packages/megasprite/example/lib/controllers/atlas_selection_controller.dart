import 'package:flutter/foundation.dart';

class AtlasSelectionController extends ChangeNotifier {
  String? _selectedSpriteId;

  String? get selectedSpriteId => _selectedSpriteId;

  void select(String? spriteId) {
    if (_selectedSpriteId == spriteId) return;

    _selectedSpriteId = spriteId;
    notifyListeners();
  }

  void toggle(String spriteId) {
    if (_selectedSpriteId == spriteId) {
      select(null);
    } else {
      select(spriteId);
    }
  }

  void clear() {
    select(null);
  }
}
