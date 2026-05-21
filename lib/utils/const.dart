import 'package:flutter/material.dart';
import 'package:the_safety_lamp_vault/enum/my_enums.dart';

// ─── COLOR PALETTE — "Pit Bottom Clarity" ─────────────────────────────────────
const Color kBackground      = Color(0xFF0E0C09); // Pit black — warm, brown-black
const Color kPrimaryText     = Color(0xFFF2EDE4); // Lamp glow white — warm cream
const Color kPanelBg         = Color(0xFF181410); // Secondary panels / card surfaces
const Color kSecondaryText   = Color(0xFF6B6258); // Coalfield grey
const Color kAccent          = Color(0xFFD4920A); // Carbide gold
const Color kSecondaryAccent = Color(0xFFC0392B); // Danger red / firedamp
const Color kOutline         = Color(0xFF1E1A14); // Dark pit rule lines
const Color kError           = Color(0xFF8B2000); // Deep firedamp red

// ─── DERIVED COLORS ──────────────────────────────────────────────────────────
const Color kAccentSurface   = Color(0x1AD4920A); // 10% carbide gold tint
const Color kDangerSurface   = Color(0x1AC0392B); // 10% danger red tint
const Color kGlassBackground = Color(0x26F2EDE4); // 15% warm cream glass

// ─── GAS DETECTION CLASS COLORS ──────────────────────────────────────────────
Color getGasDetectionColor(GasDetectionClass gdc) {
  switch (gdc) {
    case GasDetectionClass.firedampDetection:
      return kSecondaryAccent;                       // danger red
    case GasDetectionClass.blackdampIndicator:
      return const Color(0xFF607D8B);                // blue-grey
    case GasDetectionClass.generalIllumination:
      return kAccent;                                // carbide gold
    case GasDetectionClass.inspectionLamp:
      return const Color(0xFFB8860B);                // darker gold
    case GasDetectionClass.rescueService:
      return const Color(0xFFE57373);                // soft rescue red
  }
}

// ─── BODY METAL COLORS ───────────────────────────────────────────────────────
Color getBodyMetalColor(BodyMetal bm) {
  switch (bm) {
    case BodyMetal.polishedBrass:
      return kAccent;
    case BodyMetal.stampedSteel:
      return const Color(0xFF8A8A8A);
    case BodyMetal.castAluminium:
      return const Color(0xFFA8B0B8);
    case BodyMetal.copperTrim:
      return const Color(0xFFB87333);
    case BodyMetal.brassAndGlass:
      return const Color(0xFFCDAD5F);
    case BodyMetal.mixedUnknown:
      return kSecondaryText;
  }
}

// ─── PRESERVATION STATUS COLORS ──────────────────────────────────────────────
Color getConditionColor(PreservationStatus status) {
  switch (status) {
    case PreservationStatus.museumGrade:
      return kAccent;
    case PreservationStatus.fullyOperational:
      return const Color(0xFF22C55E);
    case PreservationStatus.serviceable:
      return const Color(0xFF0891B2);
    case PreservationStatus.displayOnly:
      return kSecondaryText;
    case PreservationStatus.requiresRestoration:
      return kSecondaryAccent;
    case PreservationStatus.fragmentary:
      return kError;
    case PreservationStatus.unknown:
      return kSecondaryText;
  }
}

// ─── LAMP HAZARD CHECK ───────────────────────────────────────────────────────
/// Returns true if the lamp has disaster provenance or significant damage.
/// Used to render red-tinted flame instead of gold on list cards.
bool isHazardLamp(PreservationStatus status, GasDetectionClass gdc) {
  return status == PreservationStatus.fragmentary ||
      status == PreservationStatus.requiresRestoration ||
      gdc == GasDetectionClass.firedampDetection;
}

// ─── GAS DETECTION INTENSITY (0.0–1.0) ───────────────────────────────────────
double getGasIntensity(GasDetectionClass gdc) {
  switch (gdc) {
    case GasDetectionClass.firedampDetection: return 1.0;
    case GasDetectionClass.blackdampIndicator: return 0.7;
    case GasDetectionClass.rescueService: return 0.55;
    case GasDetectionClass.inspectionLamp: return 0.35;
    case GasDetectionClass.generalIllumination: return 0.15;
  }
}

// ─── SPACING ─────────────────────────────────────────────────────────────────
const double kSpacingXXS  = 4.0;
const double kSpacingXS   = 8.0;
const double kSpacingS    = 12.0;
const double kSpacingM    = 16.0;
const double kSpacingL    = 20.0;
const double kSpacingXL   = 24.0;
const double kSpacingXXL  = 32.0;
const double kSpacingXXXL = 48.0;

// ─── BORDER RADIUS ───────────────────────────────────────────────────────────
const double kRadiusZero     = 0.0;
const double kRadiusSubtle   = 10.0;
const double kRadiusStandard = 16.0;
const double kRadiusMedium   = 24.0;
const double kRadiusLarge    = 32.0;
const double kRadiusPill     = 999.0;

// ─── SHADOWS ─────────────────────────────────────────────────────────────────
const BoxShadow kShadowSubtle = BoxShadow(
  offset: Offset(0, 4),
  blurRadius: 16,
  spreadRadius: -2,
  color: Color(0x1A000000),
);

const BoxShadow kShadowFloat = BoxShadow(
  offset: Offset(0, 8),
  blurRadius: 28,
  spreadRadius: -4,
  color: Color(0x40D4920A),
);

const BoxShadow kShadowBlue = BoxShadow(
  offset: Offset(0, 8),
  blurRadius: 24,
  spreadRadius: -2,
  color: Color(0x50D4920A),
);

const BoxShadow kShadowDanger = BoxShadow(
  offset: Offset(0, 4),
  blurRadius: 16,
  spreadRadius: -2,
  color: Color(0x40C0392B),
);

// Stroke weights
const double kStrokeWeight       = 1.0;
const double kStrokeWeightMedium = 2.0;
const double kStrokeWeightThick  = 3.0;
