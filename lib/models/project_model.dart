import 'package:the_safety_lamp_vault/enum/my_enums.dart';

class SafetyLampModel {
  String id;
  String vaultControlNumber;
  ApparatusClassification apparatusClassification;
  String foundryOrManufacturer;
  String eraOfProduction;
  GasDetectionClass gasDetectionClass;
  BodyMetal bodyMetal;
  String gauzeConfiguration;
  LockingMechanism lockingMechanismType;
  String fuelAndIlluminant;
  String airInflowDesign;
  String physicalProportions;
  PreservationStatus preservationStatus;
  String accompanyingGear;
  String inspectorAndCollieryStamps;
  String historicalContext;
  String archivalNotes;
  String photoPath;
  List<String> tags;
  DateTime dateAdded;

  SafetyLampModel({
    required this.id,
    required this.vaultControlNumber,
    required this.apparatusClassification,
    required this.foundryOrManufacturer,
    required this.eraOfProduction,
    required this.gasDetectionClass,
    required this.bodyMetal,
    required this.gauzeConfiguration,
    required this.lockingMechanismType,
    required this.fuelAndIlluminant,
    required this.airInflowDesign,
    required this.physicalProportions,
    required this.preservationStatus,
    required this.accompanyingGear,
    required this.inspectorAndCollieryStamps,
    required this.historicalContext,
    required this.archivalNotes,
    required this.photoPath,
    required this.tags,
    required this.dateAdded,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vaultControlNumber': vaultControlNumber,
        'apparatusClassification': apparatusClassification.name,
        'foundryOrManufacturer': foundryOrManufacturer,
        'eraOfProduction': eraOfProduction,
        'gasDetectionClass': gasDetectionClass.name,
        'bodyMetal': bodyMetal.name,
        'gauzeConfiguration': gauzeConfiguration,
        'lockingMechanismType': lockingMechanismType.name,
        'fuelAndIlluminant': fuelAndIlluminant,
        'airInflowDesign': airInflowDesign,
        'physicalProportions': physicalProportions,
        'preservationStatus': preservationStatus.name,
        'accompanyingGear': accompanyingGear,
        'inspectorAndCollieryStamps': inspectorAndCollieryStamps,
        'historicalContext': historicalContext,
        'archivalNotes': archivalNotes,
        'photoPath': photoPath,
        'tags': tags,
        'dateAdded': dateAdded.toIso8601String(),
      };

  factory SafetyLampModel.fromJson(Map<String, dynamic> json) =>
      SafetyLampModel(
        id: json['id'] ?? '',
        vaultControlNumber: json['vaultControlNumber'] ?? '',
        apparatusClassification:
            ApparatusClassification.values
                .asNameMap()[json['apparatusClassification']] ??
            ApparatusClassification.other,
        foundryOrManufacturer: json['foundryOrManufacturer'] ?? '',
        eraOfProduction: json['eraOfProduction'] ?? '',
        gasDetectionClass:
            GasDetectionClass.values
                .asNameMap()[json['gasDetectionClass']] ??
            GasDetectionClass.generalIllumination,
        bodyMetal:
            BodyMetal.values.asNameMap()[json['bodyMetal']] ??
            BodyMetal.mixedUnknown,
        gauzeConfiguration: json['gauzeConfiguration'] ?? '',
        lockingMechanismType:
            LockingMechanism.values
                .asNameMap()[json['lockingMechanismType']] ??
            LockingMechanism.noLock,
        fuelAndIlluminant: json['fuelAndIlluminant'] ?? '',
        airInflowDesign: json['airInflowDesign'] ?? '',
        physicalProportions: json['physicalProportions'] ?? '',
        preservationStatus:
            PreservationStatus.values
                .asNameMap()[json['preservationStatus']] ??
            PreservationStatus.unknown,
        accompanyingGear: json['accompanyingGear'] ?? '',
        inspectorAndCollieryStamps:
            json['inspectorAndCollieryStamps'] ?? '',
        historicalContext: json['historicalContext'] ?? '',
        archivalNotes: json['archivalNotes'] ?? '',
        photoPath: json['photoPath'] ?? '',
        tags: List<String>.from(json['tags'] ?? []),
        dateAdded:
            DateTime.tryParse(json['dateAdded'] ?? '') ?? DateTime.now(),
      );
}
