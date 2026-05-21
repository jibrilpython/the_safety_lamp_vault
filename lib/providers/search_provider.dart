import 'package:the_safety_lamp_vault/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchNotifier extends ChangeNotifier {
  String searchQuery = '';

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void clearSearchQuery() {
    searchQuery = '';
    notifyListeners();
  }

  List<SafetyLampModel> filteredList(List<SafetyLampModel> list) {
    if (searchQuery.isEmpty) {
      return list;
    } else {
      final query = searchQuery.toLowerCase();
      return list
          .where((item) =>
              item.vaultControlNumber.toLowerCase().contains(query) ||
              item.foundryOrManufacturer.toLowerCase().contains(query) ||
              item.historicalContext.toLowerCase().contains(query) ||
              item.eraOfProduction.toLowerCase().contains(query) ||
              item.apparatusClassification.label.toLowerCase().contains(query) ||
              item.tags.any((tag) => tag.toLowerCase().contains(query)))
          .toList();
    }
  }
}

final searchProvider = ChangeNotifierProvider((ref) => SearchNotifier());
