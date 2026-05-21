// ─── APPARATUS CLASSIFICATION ─────────────────────────────────────────────────
enum ApparatusClassification {
  flameSafetyLamp('Flame Safety Lamp'),
  carbideCapLamp('Carbide Cap Lamp'),
  oilWickCapLamp('Oil Wick Cap Lamp'),
  pocketDial('Pocket Dial Compass'),
  surveyorCompass('Surveyor\'s Transit Compass'),
  other('Unclassified Artifact');

  const ApparatusClassification(this.label);
  final String label;
}

// ─── GAS DETECTION CLASS ─────────────────────────────────────────────────────
enum GasDetectionClass {
  firedampDetection('Firedamp Detection'),
  blackdampIndicator('Blackdamp Indicator'),
  generalIllumination('General Illumination'),
  inspectionLamp('Inspection Lamp'),
  rescueService('Rescue Service');

  const GasDetectionClass(this.label);
  final String label;
}

// ─── BODY METAL ──────────────────────────────────────────────────────────────
enum BodyMetal {
  polishedBrass('Polished Brass'),
  stampedSteel('Stamped Steel'),
  castAluminium('Cast Aluminium'),
  copperTrim('Copper Trim'),
  brassAndGlass('Brass & Glass'),
  mixedUnknown('Composite / Unknown');

  const BodyMetal(this.label);
  final String label;
}

// ─── LOCKING MECHANISM ───────────────────────────────────────────────────────
enum LockingMechanism {
  magneticLock('Magnetic Lock'),
  leadSealLock('Lead Seal Lock'),
  rivetLock('Rivet Lock'),
  screwLock('Screw Lock'),
  noLock('No Lock / Open');

  const LockingMechanism(this.label);
  final String label;
}

// ─── PRESERVATION STATUS ─────────────────────────────────────────────────────
enum PreservationStatus {
  museumGrade('Museum Grade — Exhibition Ready'),
  fullyOperational('Operational — Flame Functional'),
  serviceable('Serviceable — All Parts Present'),
  displayOnly('Display Only — Non-Functional'),
  requiresRestoration('Restoration Required'),
  fragmentary('Fragmentary — Parts Missing'),
  unknown('Indeterminate');

  const PreservationStatus(this.label);
  final String label;
}
