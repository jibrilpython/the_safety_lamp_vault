import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:the_safety_lamp_vault/models/project_model.dart';
import 'package:the_safety_lamp_vault/providers/image_provider.dart';
import 'package:the_safety_lamp_vault/providers/input_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ProjectNotifier extends ChangeNotifier {
  ProjectNotifier() {
    loadEntries();
  }

  List<SafetyLampModel> entries = [];
  bool isLoading = true;
  int stateVersion = 0;
  static const String _storageKey = 'tslv_entries_v1';
  final _uuid = const Uuid();

  void _sortEntries() {
    entries.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
  }

  Future<void> loadEntries() async {
    isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> decodedList = jsonDecode(jsonString);
        entries =
            decodedList
                .map((item) => SafetyLampModel.fromJson(item))
                .toList();
        _sortEntries();
      }
    } catch (e) {
      debugPrint('Error loading entries: $e');
      entries = [];
    } finally {
      isLoading = false;
      stateVersion++;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(
      entries.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encodedList);
  }

  void addEntry(WidgetRef ref) {
    final p = ref.read(inputProvider);
    final imgProv = ref.read(imageProvider);

    final newEntry = SafetyLampModel(
      id: _uuid.v4(),
      vaultControlNumber: p.vaultControlNumber,
      apparatusClassification: p.apparatusClassification,
      foundryOrManufacturer: p.foundryOrManufacturer,
      eraOfProduction: p.eraOfProduction,
      gasDetectionClass: p.gasDetectionClass,
      bodyMetal: p.bodyMetal,
      gauzeConfiguration: p.gauzeConfiguration,
      lockingMechanismType: p.lockingMechanismType,
      fuelAndIlluminant: p.fuelAndIlluminant,
      airInflowDesign: p.airInflowDesign,
      physicalProportions: p.physicalProportions,
      preservationStatus: p.preservationStatus,
      accompanyingGear: p.accompanyingGear,
      inspectorAndCollieryStamps: p.inspectorAndCollieryStamps,
      historicalContext: p.historicalContext,
      archivalNotes: p.archivalNotes,
      photoPath:
          imgProv.resultImage.isNotEmpty ? imgProv.resultImage : p.photoPath,
      tags: List<String>.from(p.tags),
      dateAdded: DateTime.now(),
    );

    entries = [newEntry, ...entries];
    _sortEntries();
    _save();
    stateVersion++;
    notifyListeners();
  }

  void editEntry(WidgetRef ref, int index) {
    final p = ref.read(inputProvider);
    final imgProv = ref.read(imageProvider);
    final existing = entries[index];

    final updatedEntry = SafetyLampModel(
      id: existing.id,
      vaultControlNumber: p.vaultControlNumber,
      apparatusClassification: p.apparatusClassification,
      foundryOrManufacturer: p.foundryOrManufacturer,
      eraOfProduction: p.eraOfProduction,
      gasDetectionClass: p.gasDetectionClass,
      bodyMetal: p.bodyMetal,
      gauzeConfiguration: p.gauzeConfiguration,
      lockingMechanismType: p.lockingMechanismType,
      fuelAndIlluminant: p.fuelAndIlluminant,
      airInflowDesign: p.airInflowDesign,
      physicalProportions: p.physicalProportions,
      preservationStatus: p.preservationStatus,
      accompanyingGear: p.accompanyingGear,
      inspectorAndCollieryStamps: p.inspectorAndCollieryStamps,
      historicalContext: p.historicalContext,
      archivalNotes: p.archivalNotes,
      photoPath:
          imgProv.resultImage.isNotEmpty
              ? imgProv.resultImage
              : existing.photoPath,
      tags: List<String>.from(p.tags),
      dateAdded: existing.dateAdded,
    );

    final newList = List<SafetyLampModel>.from(entries);
    newList[index] = updatedEntry;
    entries = newList;

    _sortEntries();
    _save();
    stateVersion++;
    notifyListeners();
  }

  void deleteEntry(int index) {
    final newList = List<SafetyLampModel>.from(entries);
    newList.removeAt(index);
    entries = newList;

    _save();
    stateVersion++;
    notifyListeners();
  }

  void fillInput(WidgetRef ref, int index) {
    final p = ref.read(inputProvider);
    final imgProv = ref.read(imageProvider);
    final entry = entries[index];

    p.vaultControlNumber = entry.vaultControlNumber;
    p.apparatusClassification = entry.apparatusClassification;
    p.foundryOrManufacturer = entry.foundryOrManufacturer;
    p.eraOfProduction = entry.eraOfProduction;
    p.gasDetectionClass = entry.gasDetectionClass;
    p.bodyMetal = entry.bodyMetal;
    p.gauzeConfiguration = entry.gauzeConfiguration;
    p.lockingMechanismType = entry.lockingMechanismType;
    p.fuelAndIlluminant = entry.fuelAndIlluminant;
    p.airInflowDesign = entry.airInflowDesign;
    p.physicalProportions = entry.physicalProportions;
    p.preservationStatus = entry.preservationStatus;
    p.accompanyingGear = entry.accompanyingGear;
    p.inspectorAndCollieryStamps = entry.inspectorAndCollieryStamps;
    p.historicalContext = entry.historicalContext;
    p.archivalNotes = entry.archivalNotes;
    p.photoPath = entry.photoPath;
    p.tags = List<String>.from(entry.tags);
    p.dateAdded = entry.dateAdded;

    imgProv.resultImage = entry.photoPath;

    notifyListeners();
  }
}

final projectProvider = ChangeNotifierProvider<ProjectNotifier>(
  (ref) => ProjectNotifier(),
);
