var modelType = "TMC 250";
description = "Jyoti TMC-250 with Siemens control";
// >>>>> INCLUDED FROM ../common/jyoti tmc-ax turn mill-turn_Siemens.cps
//Save This line for editing purposes, comment out before merge
//var modelType = "AX 300-MSY";

/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Jyoti lathe post processor configuration.

  $Revision: 43262 b8c9137bd3ef7bcc6437110256bba039137f5046 $
  $Date: 2021-05-12 11:28:01 $
  
  FORKID {BFB15D7F-4DB9-4AC8-8040-F21470F319F9}
*/

///////////////////////////////////////////////////////////////////////////////
//                        MANUAL NC COMMANDS
//
// The following ACTION commands are supported by this post.
//
//     useXZCMode                 - Force XZC mode for next operation
//     usePolarMode               - Force Polar mode for next operation
//
///////////////////////////////////////////////////////////////////////////////

if (!description) {
  description = "Jyoti TMC-AX";
}
vendor = "Jyoti";
vendorUrl = "http://jyoti.co.in/";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

if (!longDescription) {
  longDescription = subst("Preconfigured %1 for mill-turn. This post requires careful testing when used.", description);
}

extension = "mpf";
setCodePage("ascii");

capabilities = CAPABILITY_MILLING | CAPABILITY_TURNING;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
var useArcTurn = false;
maximumCircularSweep = toRad(useArcTurn ? 120 : 120); // max revolutions
allowHelicalMoves = !useArcTurn;
allowedCircularPlanes = undefined; // allow any circular motion
allowSpiralMoves = false;
highFeedrate = (unit == IN) ? 470 : 5000;

// user-defined properties
properties = {
  writeMachine: {
    title: "Write machine",
    description: "Output the machine settings in the header of the code.",
    group: 0,
    type: "boolean",
    value: false,
    scope: "post"
  },
  writeTools: {
    title: "Write tool list",
    description: "Output a tool list in the header of the code.",
    group: 0,
    type: "boolean",
    value: false,
    scope: "post"
  },
  showSequenceNumbers: {
    title: "Use sequence numbers",
    description: "Use sequence numbers for each block of outputted code.",
    group: 1,
    type: "boolean",
    value: true,
    scope: "post"
  },
  sequenceNumberStart: {
    title: "Start sequence number",
    description: "The number at which to start the sequence numbers.",
    group: 1,
    type: "integer",
    value: 10,
    scope: "post"
  },
  sequenceNumberIncrement: {
    title: "Sequence number increment",
    description: "The amount by which the sequence number is incremented by in each block.",
    group: 1,
    type: "integer",
    value: 1,
    scope: "post"
  },
  optionalStop: {
    title: "Optional stop",
    description: "Outputs optional stop code during when necessary in the code.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  separateWordsWithSpace: {
    title: "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  useRadius: {
    title: "Radius arcs",
    description: "If yes is selected, arcs are outputted using radius values rather than IJK.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  maximumSpindleSpeed: {
    title: "Max spindle speed",
    description: "Defines the maximum spindle speed allowed by your machines.",
    type: "integer",
    range: [0, 999999999],
    value: 6000,
    scope: "post"
  },
  useParametricFeed: {
    title: "Parametric feed",
    description: "Specifies the feed value that should be output using a Q value.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  showNotes: {
    title: "Show notes",
    description: "Writes operation notes as comments in the outputted code.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  g75HomePositionX: {
    title: "G75 home position X",
    description: "G75 X-axis home position.",
    type: "number",
    value: 0,
    scope: "post"
  },
  g75HomePositionY: {
    title: "G75 home position Y",
    description: "G75 Y-axis home position.",
    type: "number",
    value: 0,
    scope: "post"
  },
  g75HomePositionZ: {
    title: "G75 home position Z",
    description: "G75 Z-axis home position.",
    type: "number",
    value: 0,
    scope: "post"
  },
  g75HomePositionSubZ: {
    title: "G75 home position Z (secondary spindle)",
    description: "G75 Z-axis home position for the secondary spindle.",
    type: "number",
    value: 0,
    scope: "post"
  },
  useTailStock: {
    title: "Use tailstock",
    description: "Specifies whether to use the tailstock or not.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  gotChipConveyor: {
    title: "Got chip conveyor",
    description: "Specifies whether to use a chip conveyor.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  toolAsName: {
    title: "Tool as name",
    description: "If enabled, the tool will be called with the tool description rather than the tool number.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  useYAxisForDrilling: {
    title: "Position in Y for axial drilling",
    description: "Positions in Y for axial drilling options when it can instead of using the C-axis.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  useShortestDirection: {
    title: "Use shortest direction",
    description: "Specifies that the shortest angular direction should be used.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  useSubroutines: {
    title: "Use subroutines",
    description: "Select your desired subroutine option. 'All Operations' creates subroutines per each operation.",
    type: "enum",
    values: [
      {title: "No", id: "none"},
      {title: "All Operations", id: "allOperations"}
      //{title: "Cycles", id: "cycles"},
      //{title: "Patterns", id: "patterns"}
    ],
    value: "none",
    scope: "post"
  },
  useFilesForSubprograms: {
    title: "Use files for subroutines",
    description: "If enabled, subroutines will be saved as individual files.",
    type: "boolean",
    value: false,
    scope: "post"
  }
};

// samples:
// throughTool: {on: 88, off: 89}
// throughTool: {on: [8, 88], off: [9, 89]}
var coolants = {
  flood: {turret1: {on: 8, off: 9}, turret2: {}},
  mist: {},
  throughTool: {turret1: {}, turret2: {}},
  air: {},
  airThroughTool: {turret1: {}, turret2: {}},
  suction: {},
  floodMist: {},
  floodThroughTool: {},
  off: 9
};

var writeDebug = false; // specifies to output debug information

var mainSpindleAxisName = ["SP1", 1]; // axis name, axis number (number is used for eg. SETMS(VALUE));
var subSpindleAxisName = ["SP2", 3]; // axis name, axis number (number is used for eg. SETMS(VALUE));
var liveToolSpindleAxisName = ["SP3", 2]; // axis name, axis number (number is used for eg. SETMS(VALUE));

var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"M", decimals:0});
var dFormat = createFormat({prefix:"D", decimals:0});

var spatialFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var xFormat = createFormat({decimals:(unit == MM ? 3 : 4), scale:2}); // diameter mode & IS SCALING POLAR COORDINATES
var yFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var zFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var abcFormat = createFormat({decimals:3, scale:DEG});
var abcDirectFormat = createFormat({decimals:3, scale:DEG, cyclicLimit:Math.PI * 2, cyclicSign:1, prefix:"=DC(", suffix:")"});
var cFormat = createFormat({decimals:3, forceDecimal:true, scale:DEG, prefix:"="});
var feedFormat = createFormat({decimals:(unit == MM ? 2 : 3)});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3}); // seconds - range 0.001-99999.999
var milliFormat = createFormat({decimals:0}); // milliseconds // range 1-9999
var taperFormat = createFormat({decimals:1, scale:DEG});
var integerFormat = createFormat({decimals:0});

var xOutput = createVariable({onchange:function () {retracted = false;}, prefix:"X"}, xFormat);
var yOutput = createVariable({prefix:"Y"}, yFormat);
var zOutput = createVariable({onchange:function () {retracted = false;}, prefix:"Z"}, zFormat);
var aOutput = createVariable({prefix:"A"}, abcFormat);
var bOutput = createVariable({prefix:"B1="}, abcFormat);
var cOutput = createVariable({prefix:mainSpindleAxisName[0]}, cFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var sOutput = createVariable({force:true}, rpmFormat);
var dOutput = createVariable({}, dFormat);

// circular output
var iOutput = createReferenceVariable({prefix:"I", force:true}, spatialFormat);
var jOutput = createReferenceVariable({prefix:"J", force:true}, spatialFormat);
var kOutput = createReferenceVariable({prefix:"K", force:true}, spatialFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G98-99
var gSpindleModeModal = createModal({}, gFormat); // modal group 5 // G96-97
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-21
var cAxisBrakeModal = createModal({}, mFormat);
var cAxisEngageModal = createModal({}, mFormat);

// fixed settings
var firstFeedParameter = 100;
var maximumLineLength = 80; // the maximum number of charaters allowed in a line

var gotYAxis;
var yAxisMinimum;
var yAxisMaximum;
var xAxisMinimum;
var gotBAxis;
var gotMultiTurret;

var gotPolarInterpolation;
var gotSecondarySpindle;
var gotDoorControl = false;
var gotBarFeeder = false;

var WARNING_WORK_OFFSET = 0;

// collected state
var sequenceNumber;
var currentWorkOffset;
var optionalSection = false;
var forceSpindleSpeed = false;
var activeMovements; // do not use by default
var currentFeedId;
var forcePolarMode = false; // force Polar output, activated by Action:usePolarMode
var forceXZCMode = false; // forces XZC output, activated by Action:useXZCMode
var bestABCIndex = undefined;
var retracted = false; // specifies that the tool has been retracted to the safe plane
var subprograms = [];
var currentPattern = -1;
var firstPattern = false;
var currentSubprogram = 0;
var lastSubprogram = 0;
var saveShowSequenceNumbers;
var subprogramExtension = "spf";

var machineState = {
  liveToolIsActive: undefined,
  cAxisIsEngaged: undefined,
  machiningDirection: undefined,
  mainSpindleIsActive: undefined,
  subSpindleIsActive: undefined,
  mainSpindleBrakeIsActive: undefined,
  subSpindleBrakeIsActive: undefined,
  tailstockIsActive: undefined,
  usePolarMode: undefined,
  useXZCMode: undefined,
  axialCenterDrilling: undefined,
  tapping: undefined,
  feedPerRevolution: undefined,
  currentBAxisOrientationTurning: new Vector(0, 0, 0),
  currentTurret: undefined
};

/** G/M codes setup. */
function getCode(code) {
  switch (code) {
  /*
  case "PART_CATCHER_ON":
    return mFormat.format(36);
  case "PART_CATCHER_OFF":
    return mFormat.format(37);
  case "TAILSTOCK_ON":
    machineState.tailstockIsActive = true;
    return tailStockModal.format(21);
  case "TAILSTOCK_OFF":
    machineState.tailstockIsActive = false;
    return tailStockModal.format(22);
*/
  case "ENGAGE_C_AXIS":
    machineState.cAxisIsEngaged = true;
    cOutput.reset();
    return "";
    // return "SPOS[" + (currentSection.spindle == SPINDLE_PRIMARY ? mainSpindleAxisName[1] : subSpindleAxisName[1])+ "]=" + abcFormat.format(0);
  case "DISENGAGE_C_AXIS":
    machineState.cAxisIsEngaged = false;
    cOutput.reset();
    return "";
    // return "SPOS[" + (currentSection.spindle == SPINDLE_PRIMARY ? mainSpindleAxisName[1] : subSpindleAxisName[1]) + "]=" + abcFormat.format(0);
  case "POLAR_INTERPOLATION_ON":
    return "TRANSMIT";
  case "POLAR_INTERPOLATION_OFF":
    return "TRAFOOF";
  case "STOP_LIVE_TOOL":
    machineState.liveToolIsActive = false;
    return mFormat.format(5);
  case "STOP_MAIN_SPINDLE":
    machineState.mainSpindleIsActive = false;
    return mFormat.format(5);
  case "STOP_SUB_SPINDLE":
    machineState.subSpindleIsActive = false;
    return mFormat.format(5);
  case "START_LIVE_TOOL_CW":
    machineState.liveToolIsActive = true;
    return mFormat.format(3);
  case "START_LIVE_TOOL_CCW":
    machineState.liveToolIsActive = true;
    return mFormat.format(4);
  case "START_MAIN_SPINDLE_CW":
    machineState.mainSpindleIsActive = true;
    return mFormat.format(3);
  case "START_MAIN_SPINDLE_CCW":
    machineState.mainSpindleIsActive = true;
    return mFormat.format(4);
  case "START_SUB_SPINDLE_CW":
    machineState.subSpindleIsActive = true;
    return mFormat.format(3);
  case "START_SUB_SPINDLE_CCW":
    machineState.subSpindleIsActive = true;
    return mFormat.format(4);
  case "MAIN_SPINDLE_BRAKE_ON":
    machineState.mainSpindleBrakeIsActive = true;
    return cAxisBrakeModal.format(71);
  case "MAIN_SPINDLE_BRAKE_OFF":
    machineState.mainSpindleBrakeIsActive = false;
    return cAxisBrakeModal.format(72);
  case "SUB_SPINDLE_BRAKE_ON":
    machineState.subSpindleBrakeIsActive = true;
    return cAxisBrakeModal.format(89);
  case "SUB_SPINDLE_BRAKE_OFF":
    machineState.subSpindleBrakeIsActive = false;
    return cAxisBrakeModal.format(90);
  case "FEED_MODE_UNIT_REV":
    machineState.feedPerRevolution = true;
    return gFeedModeModal.format(95);
  case "FEED_MODE_UNIT_MIN":
    machineState.feedPerRevolution = false;
    return gFeedModeModal.format(94);
  case "CONSTANT_SURFACE_SPEED_ON":
    return gSpindleModeModal.format(96);
  case "CONSTANT_SURFACE_SPEED_OFF":
    return gSpindleModeModal.format(97);
    /*
  case "MAINSPINDLE_AIR_BLAST_ON":
    return mFormat.format();
  case "MAINSPINDLE_AIR_BLAST_OFF":
    return mFormat.format();
  case "SUBSPINDLE_AIR_BLAST_ON":
    return mFormat.format();
  case "SUBSPINDLE_AIR_BLAST_OFF":
    return mFormat.format();
  case "CLAMP_PRIMARY_CHUCK":
    return mFormat.format();
  case "UNCLAMP_PRIMARY_CHUCK":
    return mFormat.format();
  case "CLAMP_SECONDARY_CHUCK":
    return mFormat.format();
  case "UNCLAMP_SECONDARY_CHUCK":
    return mFormat.format();
  case "SPINDLE_SYNCHRONIZATION_ON":
    machineState.spindleSynchronizationIsActive = true;
    return "L726";
  case "SPINDLE_SYNCHRONIZATION_OFF":
    machineState.spindleSynchronizationIsActive = false;
    return "L727";
  case "START_CHIP_TRANSPORT":
    return mFormat.format();
  case "STOP_CHIP_TRANSPORT":
    return mFormat.format();
  case "OPEN_DOOR":
    return mFormat.format();
  case "CLOSE_DOOR":
    return mFormat.format();
*/
  default:
    error(localize("Command " + code + " is not defined."));
    return 0;
  }
}

function getmachinetype() {
  if (modelType == "AX 200-M") {
    gotYAxis = false;
    yAxisMinimum = toPreciseUnit(gotYAxis ? 0 : 0, MM); // specifies the minimum range for the Y-axis
    yAxisMaximum = toPreciseUnit(gotYAxis ? 0 : 0, MM); // specifies the maximum range for the Y-axis
    xAxisMinimum = toPreciseUnit(0, MM); // specifies the maximum range for the X-axis (RADIUS MODE VALUE)
    gotBAxis = false; // B-axis always requires customization to match the machine specific functions for doing rotations
    gotMultiTurret = false; // specifies if the machine has several turrets
    gotPolarInterpolation = true; // specifies if the machine has XY polar interpolation (TRANSMIT) capabilities
    gotSecondarySpindle = false;
  } else if (modelType == "AX 200-MY") {
    gotYAxis = true;
    yAxisMinimum = toPreciseUnit(gotYAxis ? -40.0 : 0, MM); // specifies the minimum range for the Y-axis
    yAxisMaximum = toPreciseUnit(gotYAxis ? 40.0 : 0, MM); // specifies the maximum range for the Y-axis
    xAxisMinimum = toPreciseUnit(0, MM); // specifies the maximum range for the X-axis (RADIUS MODE VALUE)
    gotBAxis = false; // B-axis always requires customization to match the machine specific functions for doing rotations
    gotMultiTurret = false; // specifies if the machine has several turrets
    gotPolarInterpolation = true; // specifies if the machine has XY polar interpolation (TRANSMIT) capabilities
    gotSecondarySpindle = false;
  } else if (modelType == "AX 200-MSY") {
    gotYAxis = true;
    yAxisMinimum = toPreciseUnit(gotYAxis ? -40.0 : 0, MM); // specifies the minimum range for the Y-axis
    yAxisMaximum = toPreciseUnit(gotYAxis ? 40.0 : 0, MM); // specifies the maximum range for the Y-axis
    xAxisMinimum = toPreciseUnit(0, MM); // specifies the maximum range for the X-axis (RADIUS MODE VALUE)
    gotBAxis = false; // B-axis always requires customization to match the machine specific functions for doing rotations
    gotMultiTurret = false; // specifies if the machine has several turrets
    gotPolarInterpolation = true; // specifies if the machine has XY polar interpolation (TRANSMIT) capabilities
    gotSecondarySpindle = true;
  } else if (modelType == "AX 300-M") {
    gotYAxis = false;
    yAxisMinimum = toPreciseUnit(gotYAxis ? 0 : 0, MM); // specifies the minimum range for the Y-axis
    yAxisMaximum = toPreciseUnit(gotYAxis ? 0 : 0, MM); // specifies the maximum range for the Y-axis
    xAxisMinimum = toPreciseUnit(0, MM); // specifies the maximum range for the X-axis (RADIUS MODE VALUE)
    gotBAxis = false; // B-axis always requires customization to match the machine specific functions for doing rotations
    gotMultiTurret = false; // specifies if the machine has several turrets
    gotPolarInterpolation = true; // specifies if the machine has XY polar interpolation (TRANSMIT) capabilities
    gotSecondarySpindle = false;
  } else if (modelType == "AX 300-MY") {
    gotYAxis = true;
    yAxisMinimum = toPreciseUnit(gotYAxis ? -50.8 : 0, MM); // specifies the minimum range for the Y-axis
    yAxisMaximum = toPreciseUnit(gotYAxis ? 50.8 : 0, MM); // specifies the maximum range for the Y-axis
    xAxisMinimum = toPreciseUnit(0, MM); // specifies the maximum range for the X-axis (RADIUS MODE VALUE)
    gotBAxis = false; // B-axis always requires customization to match the machine specific functions for doing rotations
    gotMultiTurret = false; // specifies if the machine has several turrets
    gotPolarInterpolation = true; // specifies if the machine has XY polar interpolation (TRANSMIT) capabilities
    gotSecondarySpindle = false;
  } else if (modelType == "AX 300-MSY") {
    gotYAxis = true;
    yAxisMinimum = toPreciseUnit(gotYAxis ? -50.8 : 0, MM); // specifies the minimum range for the Y-axis
    yAxisMaximum = toPreciseUnit(gotYAxis ? 50.8 : 0, MM); // specifies the maximum range for the Y-axis
    xAxisMinimum = toPreciseUnit(0, MM); // specifies the maximum range for the X-axis (RADIUS MODE VALUE)
    gotBAxis = false; // B-axis always requires customization to match the machine specific functions for doing rotations
    gotMultiTurret = false; // specifies if the machine has several turrets
    gotPolarInterpolation = true; // specifies if the machine has XY polar interpolation (TRANSMIT) capabilities
    gotSecondarySpindle = true;
  } else if (modelType == "TMC 200") {
    gotYAxis = false;
    yAxisMinimum = toPreciseUnit(gotYAxis ? 0 : 0, MM); // specifies the minimum range for the Y-axis
    yAxisMaximum = toPreciseUnit(gotYAxis ? 0 : 0, MM); // specifies the maximum range for the Y-axis
    xAxisMinimum = toPreciseUnit(0, MM); // specifies the maximum range for the X-axis (RADIUS MODE VALUE)
    gotBAxis = false; // B-axis always requires customization to match the machine specific functions for doing rotations
    gotMultiTurret = false; // specifies if the machine has several turrets
    gotPolarInterpolation = true; // specifies if the machine has XY polar interpolation (TRANSMIT) capabilities
    gotSecondarySpindle = false;
  } else if (modelType == "TMC 250") {
    gotYAxis = false;
    yAxisMinimum = toPreciseUnit(gotYAxis ? 0 : 0, MM); // specifies the minimum range for the Y-axis
    yAxisMaximum = toPreciseUnit(gotYAxis ? 0 : 0, MM); // specifies the maximum range for the Y-axis
    xAxisMinimum = toPreciseUnit(0, MM); // specifies the maximum range for the X-axis (RADIUS MODE VALUE)
    gotBAxis = false; // B-axis always requires customization to match the machine specific functions for doing rotations
    gotMultiTurret = false; // specifies if the machine has several turrets
    gotPolarInterpolation = true; // specifies if the machine has XY polar interpolation (TRANSMIT) capabilities
    gotSecondarySpindle = false;
  } else if (modelType == "TMC 350") {
    gotYAxis = false;
    yAxisMinimum = toPreciseUnit(gotYAxis ? 0 : 0, MM); // specifies the minimum range for the Y-axis
    yAxisMaximum = toPreciseUnit(gotYAxis ? 0 : 0, MM); // specifies the maximum range for the Y-axis
    xAxisMinimum = toPreciseUnit(0, MM); // specifies the maximum range for the X-axis (RADIUS MODE VALUE)
    gotBAxis = false; // B-axis always requires customization to match the machine specific functions for doing rotations
    gotMultiTurret = false; // specifies if the machine has several turrets
    gotPolarInterpolation = true; // specifies if the machine has XY polar interpolation (TRANSMIT) capabilities
    gotSecondarySpindle = false;
  }
}

function isSpindleSpeedDifferent() {
  if (isFirstSection()) {
    return true;
  }
  if (getPreviousSection().getTool().clockwise != tool.clockwise) {
    return true;
  }
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    if ((getPreviousSection().getTool().getSpindleMode() != SPINDLE_CONSTANT_SURFACE_SPEED) ||
        rpmFormat.areDifferent(getPreviousSection().getTool().surfaceSpeed, tool.surfaceSpeed)) {
      return true;
    }
  } else {
    if ((getPreviousSection().getTool().getSpindleMode() != SPINDLE_CONSTANT_SPINDLE_SPEED) ||
        rpmFormat.areDifferent(getPreviousSection().getTool().spindleRPM, spindleSpeed)) {
      return true;
    }
  }
  return false;
}

function onSpindleSpeed(spindleSpeed) {
  if ((sOutput.getCurrent() != Number.POSITIVE_INFINITY) && rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) { // avoid redundant output of spindle speed
    writeBlock("S" + sOutput.format(spindleSpeed));
  }
}

function startSpindle(forceRPMMode, initialPosition) {
  var _spindleSpeed = spindleSpeed;
  var useConstantSurfaceSpeed = currentSection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED;
  var maximumSpindleSpeed = (tool.maximumSpindleSpeed > 0) ? Math.min(tool.maximumSpindleSpeed, getProperty("maximumSpindleSpeed")) : getProperty("maximumSpindleSpeed");
  writeBlock("SETMS(" + getSpindleCode(currentSection) + ")");

  gSpindleModeModal.reset();
  var spindleMode;
  if (useConstantSurfaceSpeed && !forceRPMMode) {
    spindleMode = getCode("CONSTANT_SURFACE_SPEED_ON");
  } else {
    spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF");
  }

  if (useConstantSurfaceSpeed) {
    _spindleSpeed = tool.surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0);
  }
  if (useConstantSurfaceSpeed && forceRPMMode) { // RPM mode is forced until move to initial position
    if (xFormat.getResultingValue(initialPosition.x) == 0) {
      _spindleSpeed = maximumSpindleSpeed;
    } else {
      _spindleSpeed = Math.min((_spindleSpeed * ((unit == MM) ? 1000.0 : 12.0) / (Math.PI * Math.abs(initialPosition.x * 2))), maximumSpindleSpeed);
    }
  }
  switch (currentSection.spindle) {
  case SPINDLE_PRIMARY: // main spindle
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) { // turning main spindle
      gSpindleModeModal.reset();
      writeBlock(
        spindleMode,
        "S" + sOutput.format(_spindleSpeed),
        (tool.clockwise ? getCode("START_MAIN_SPINDLE_CW") : getCode("START_MAIN_SPINDLE_CCW"))
      );
    } else { // milling main spindle
      writeBlock(
        spindleMode,
        "S" + sOutput.format(_spindleSpeed),
        tool.clockwise ? getCode("START_LIVE_TOOL_CW") : getCode("START_LIVE_TOOL_CCW")
      );
    }
    break;
  case SPINDLE_SECONDARY: // sub spindle
    if (!gotSecondarySpindle) {
      error(localize("Secondary spindle is not available."));
      return;
    }
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) { // turning sub spindle
      gSpindleModeModal.reset();
      writeBlock(
        spindleMode,
        "S" + sOutput.format(_spindleSpeed),
        (tool.clockwise ? getCode("START_SUB_SPINDLE_CW") : getCode("START_SUB_SPINDLE_CCW"))
      );
    } else { // milling sub spindle
      writeBlock(
        spindleMode,
        "S" + sOutput.format(_spindleSpeed),
        tool.clockwise ? getCode("START_LIVE_TOOL_CW") : getCode("START_LIVE_TOOL_CCW")
      );
    }
    break;
  }
  gFeedModeModal.reset();
  if ((currentSection.feedMode == FEED_PER_REVOLUTION) || machineState.tapping || machineState.axialCenterDrilling || (hasParameter("operation-strategy") && (getParameter("operation-strategy") == "drill"))) {
    if (!useConstantSurfaceSpeed) {
      writeBlock(getCode("FEED_MODE_UNIT_REV")); // unit/rev
    }
  } else {
    writeBlock(getCode("FEED_MODE_UNIT_MIN")); // unit/min
  }
}

/** Output block to do safe retract and/or move to home position. */
function writeRetract() {
  var words = []; // store all retracted axes in an array
  for (var i = 0; i < arguments.length; ++i) {
    let instances = 0; // checks for duplicate retract calls
    for (var j = 0; j < arguments.length; ++j) {
      if (arguments[i] == arguments[j]) {
        ++instances;
      }
    }
    if (instances > 1) { // error if there are multiple retract calls for the same axis
      error(localize("Cannot retract the same axis twice in one line"));
      return;
    }
    switch (arguments[i]) {
    case X:
      xOutput.reset();
      words.push(xOutput.format((currentSection.spindle == SPINDLE_PRIMARY) ? getProperty("g75HomePositionX") : getProperty("g75HomePositionX")));
      retracted = true; // specifies that the tool has been retracted to the safe plane
      break;
    case Y:
      if (gotYAxis) {
        yOutput.reset();
        words.push(yOutput.format(getProperty("g75HomePositionY")));
      }
      break;
    case Z:
      zOutput.reset();
      words.push(zOutput.format((currentSection.spindle == SPINDLE_SECONDARY) ? getProperty("g75HomePositionSubZ") : getProperty("g75HomePositionZ")));
      retracted = true; // specifies that the tool has been retracted to the safe plane
      break;
    default:
      error(localize("Bad axis specified for writeRetract()."));
      return;
    }
  }
  if (words.length > 0) {
    writeBlock(gFormat.format(75), words); // retract
  }
  dOutput.reset();
  zOutput.reset();
}

/** Write WCS. */
function writeWCS(section) {
  var workOffset = section.workOffset;
  if (workOffset == 0) {
    warningOnce(localize("Work offset has not been specified. Using G54 as WCS."), WARNING_WORK_OFFSET);
    workOffset = 1;
    if (section.spindle == SPINDLE_SECONDARY) {
      error(localize("Work offset cannot be 0 for the secondary spindle."));
      return;
    }
  }
  if (workOffset > 0) {
    var code = (workOffset > 4) ? 500 : 53;
    if (workOffset > 19) {
      error(localize("Work offset out of range."));
      return;
    } else {
      if (workOffset != currentWorkOffset) {
        forceWorkPlane();
        writeBlock(gFormat.format(code + workOffset)); // G54->G57, G505 ->G524
        currentWorkOffset = workOffset;
      }
    }
  }
}

/** Returns the modulus. */
function getModulus(x, y) {
  return Math.sqrt(x * x + y * y);
}

/**
  Returns the C rotation for the given X and Y coordinates.
*/
function getC(x, y) {
  var direction;
  if (Vector.dot(machineConfiguration.getAxisU().getAxis(), new Vector(0, 0, 1)) != 0) {
    direction = (machineConfiguration.getAxisU().getAxis().getCoordinate(2) >= 0) ? 1 : -1; // C-axis is the U-axis
  } else {
    direction = (machineConfiguration.getAxisV().getAxis().getCoordinate(2) >= 0) ? 1 : -1; // C-axis is the V-axis
  }

  return Math.atan2(y, x) * direction;
}

/**
  Returns the C rotation for the given X and Y coordinates in the desired rotary direction.
*/
function getCClosest(x, y, _c, clockwise) {
  if (_c == Number.POSITIVE_INFINITY) {
    _c = 0; // undefined
  }
  if (!xFormat.isSignificant(x) && !yFormat.isSignificant(y)) { // keep C if XY is on center
    return _c;
  }
  var c = getC(x, y);
  if (clockwise != undefined) {
    if (clockwise) {
      while (c < _c) {
        c += Math.PI * 2;
      }
    } else {
      while (c > _c) {
        c -= Math.PI * 2;
      }
    }
  } else {
    min = _c - Math.PI;
    max = _c + Math.PI;
    while (c < min) {
      c += Math.PI * 2;
    }
    while (c > max) {
      c -= Math.PI * 2;
    }
  }
  return c;
}

function getCWithinRange(x, y, _c, clockwise) {
  var c = getCClosest(x, y, _c, clockwise);
  
  var cyclicLimit;
  var cyclic;
  if (Vector.dot(machineConfiguration.getAxisU().getAxis(), new Vector(0, 0, 1)) != 0) {
    // C-axis is the U-axis
    cyclicLimit = machineConfiguration.getAxisU().getRange();
    cyclic = machineConfiguration.getAxisU().isCyclic();
  } else if (Vector.dot(machineConfiguration.getAxisV().getAxis(), new Vector(0, 0, 1)) != 0) {
    // C-axis is the V-axis
    cyclicLimit = machineConfiguration.getAxisV().getRange();
    cyclic = machineConfiguration.getAxisV().isCyclic();
  } else {
    error(localize("Unsupported rotary axis direction."));
    return 0;
  }
  
  // see if rewind is required
  forceRewind = false;
  if ((cFormat.getResultingValue(c) < cFormat.getResultingValue(cyclicLimit[0])) || (cFormat.getResultingValue(c) > cFormat.getResultingValue(cyclicLimit[1]))) {
    if (!cyclic) {
      forceRewind = true;
    }
    c = getCClosest(x, y, 0); // find closest C to 0
    if ((cFormat.getResultingValue(c) < cFormat.getResultingValue(cyclicLimit[0])) || (cFormat.getResultingValue(c) > cFormat.getResultingValue(cyclicLimit[1]))) {
      var midRange = cyclicLimit[0] + (cyclicLimit[1] - cyclicLimit[0]) / 2;
      c = getCClosest(x, y, midRange); // find closest C to midRange
    }
    if ((cFormat.getResultingValue(c) < cFormat.getResultingValue(cyclicLimit[0])) || (cFormat.getResultingValue(c) > cFormat.getResultingValue(cyclicLimit[1]))) {
      error(localize("Unable to find C-axis position within the defined range."));
      return 0;
    }
  }
  return c;
}

/**
  Returns the desired tolerance for the given section.
*/
function getTolerance() {
  var t = tolerance;
  if (hasParameter("operation:tolerance")) {
    if (t > 0) {
      t = Math.min(t, getParameter("operation:tolerance"));
    } else {
      t = getParameter("operation:tolerance");
    }
  }
  return t;
}

/**
  Writes the specified block.
*/
function writeBlock() {
  if (getProperty("showSequenceNumbers")) {
    if (sequenceNumber > 99999) {
      sequenceNumber = getProperty("sequenceNumberStart");
    }
    if (optionalSection) {
      var text = formatWords(arguments);
      if (text) {
        writeWords("/", "N" + sequenceNumber, text);
      }
    } else {
      writeWords2("N" + sequenceNumber, arguments);
    }
    sequenceNumber += getProperty("sequenceNumberIncrement");
  } else {
    if (optionalSection) {
      writeWords2("/", arguments);
    } else {
      writeWords(arguments);
    }
  }
}

/**
  Writes the specified optional block.
*/
function writeOptionalBlock() {
  if (getProperty("showSequenceNumbers")) {
    var words = formatWords(arguments);
    if (words) {
      writeWords("/", "N" + sequenceNumber, words);
      sequenceNumber += getProperty("sequenceNumberIncrement");
    }
  } else {
    writeWords2("/", arguments);
  }
}

function formatComment(text) {
  return "; " + String(text);
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

function getB(abc, section) {
  if (section.spindle == SPINDLE_PRIMARY) {
    return abc.y;
  } else {
    return Math.PI - abc.y;
  }
}

var machineConfigurationMainSpindle;
var machineConfigurationSubSpindle;

function onOpen() {
  getmachinetype();

  if (getProperty("useRadius")) {
    maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
  }

  if (true) {
    var bAxisMain = createAxis({coordinate:1, table:false, axis:[0, -1, 0], range:[-0.001, 90.001], preference:0});
    var cAxisMain = createAxis({coordinate:2, table:true, axis:[0, 0, 1], range:[0, 359.999], cyclic:true, preference:0});

    var bAxisSub = createAxis({coordinate:1, table:false, axis:[0, -1, 0], range:[-0.001, 180.001], preference:0});
    var cAxisSub = createAxis({coordinate:2, table:true, axis:[0, 0, -1], range:[0, 359.999], cyclic:true, preference:0});

    machineConfigurationMainSpindle = gotBAxis ? new MachineConfiguration(bAxisMain, cAxisMain) : new MachineConfiguration(cAxisMain);
    machineConfigurationSubSpindle =  gotBAxis ? new MachineConfiguration(bAxisSub, cAxisSub) : new MachineConfiguration(cAxisSub);
  }

  machineConfiguration = new MachineConfiguration(); // creates an empty configuration to be able to set eg vendor information

  if (!gotYAxis) {
    yOutput.disable();
  }
  aOutput.disable();
  if (!gotBAxis) {
    bOutput.disable();
  }

  if (highFeedrate <= 0) {
    error(localize("You must set 'highFeedrate' because axes are not synchronized for rapid traversal."));
    return;
  }

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");

  if (programName) {
    // writeln("; %_N_" + translateText(String(programName).toUpperCase(), " ", "_") + "_MPF");

    if (programComment) {
      writeComment(programComment);
    }
  } else {
    error(localize("Program name has not been specified."));
    return;
  }

  // dump machine configuration
  var vendor = machineConfiguration.getVendor();
  var model = machineConfiguration.getModel();
  var description = machineConfiguration.getDescription();

  if (getProperty("writeMachine") && (vendor || model || description)) {
    writeComment(localize("Machine"));
    if (vendor) {
      writeComment("  " + localize("vendor") + ": " + vendor);
    }
    if (model) {
      writeComment("  " + localize("model") + ": " + model);
    }
    if (description) {
      writeComment("  " + localize("description") + ": "  + description);
    }
  }

  // dump tool information
  if (getProperty("writeTools")) {
    var zRanges = {};
    if (is3D()) {
      var numberOfSections = getNumberOfSections();
      for (var i = 0; i < numberOfSections; ++i) {
        var section = getSection(i);
        var zRange = section.getGlobalZRange();
        var tool = section.getTool();
        if (zRanges[tool.number]) {
          zRanges[tool.number].expandToRange(zRange);
        } else {
          zRanges[tool.number] = zRange;
        }
      }
    }

    var tools = getToolTable();
    if (tools.getNumberOfTools() > 0) {
      for (var i = 0; i < tools.getNumberOfTools(); ++i) {
        var tool = tools.getTool(i);
        var comment = "T" + (getProperty("toolAsName") ? "="  + "\"" + (tool.description.toUpperCase()) + "\"" : toolFormat.format(tool.number)) + " " +
          (tool.diameter != 0 ? "D=" + spatialFormat.format(tool.diameter) + " " : "") +
          (tool.isTurningTool() ? localize("NR") + "=" + spatialFormat.format(tool.noseRadius) : localize("CR") + "=" + spatialFormat.format(tool.cornerRadius)) +
          (tool.taperAngle > 0 && (tool.taperAngle < Math.PI) ? " " + localize("TAPER") + "=" + taperFormat.format(tool.taperAngle) + localize("deg") : "") +
          (zRanges[tool.number] ? " - " + localize("ZMIN") + "=" + spatialFormat.format(zRanges[tool.number].getMinimum()) : "") +
          " - " + localize(getToolTypeName(tool.type));
        writeComment(comment);
      }
    }
  }

  if (false) {
    // check for duplicate tool number
    for (var i = 0; i < getNumberOfSections(); ++i) {
      var sectioni = getSection(i);
      var tooli = sectioni.getTool();
      for (var j = i + 1; j < getNumberOfSections(); ++j) {
        var sectionj = getSection(j);
        var toolj = sectionj.getTool();
        if (tooli.number == toolj.number) {
          if (spatialFormat.areDifferent(tooli.diameter, toolj.diameter) ||
              spatialFormat.areDifferent(tooli.cornerRadius, toolj.cornerRadius) ||
              abcFormat.areDifferent(tooli.taperAngle, toolj.taperAngle) ||
              (tooli.numberOfFlutes != toolj.numberOfFlutes)) {
            error(
              subst(
                localize("Using the same tool number for different cutter geometry for operation '%1' and '%2'."),
                sectioni.hasParameter("operation-comment") ? sectioni.getParameter("operation-comment") : ("#" + (i + 1)),
                sectionj.hasParameter("operation-comment") ? sectionj.getParameter("operation-comment") : ("#" + (j + 1))
              )
            );
            return;
          }
        }
      }
    }
  }

  if (true) { // stock - workpiece
    var workpiece = getWorkpiece();
    var delta = Vector.diff(workpiece.upper, workpiece.lower);
    if (delta.isNonZero()) {
      var spindle = getSection(0).getSpindle() == SPINDLE_PRIMARY ? 192 : 4288;
      var XA = workpiece.upper.x; // diameter
      var ZA = workpiece.upper.z; // stock offset Z
      var ZI = workpiece.lower.z; // stock Z
      var ZB = ZI + toPreciseUnit(1, MM); // stock in chuck
      writeBlock(
        "WORKPIECE" + "(" + ",,," + "\"" + "CYLINDER" + "\""  + "," + spindle + "," + zFormat.format(ZA) + "," + zFormat.format(ZI) +
        "," + spatialFormat.format(ZB) + "," + xFormat.format(XA) + ")"
      );
    }
  }

  if ((getNumberOfSections() > 0) && (getSection(0).workOffset == 0)) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      if (getSection(i).workOffset > 0) {
        error(localize("Using multiple work offsets is not possible if the initial work offset is 0."));
        return;
      }
    }
  }

  // absolute coordinates and feed per min
  writeBlock(gAbsIncModal.format(90), getCode("FEED_MODE_UNIT_MIN"), gPlaneModal.format(18), gFormat.format(40));

  switch (unit) {
  case IN:
    writeBlock(gUnitModal.format(70));
    break;
  case MM:
    writeBlock(gUnitModal.format(71));
    break;
  }

  // writeBlock("#" + (firstFeedParameter - 1) + "=" + ((currentSection.spindle == SPINDLE_SECONDARY) ? getProperty("g75HomePositionSubZ") : getProperty("g75HomePositionZ")), formatComment("g75HomePositionZ"));
  
  var usesPrimarySpindle = false;
  var usesSecondarySpindle = false;
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    if (section.getType() == TYPE_TURNING) {
      switch (section.spindle) {
      case SPINDLE_PRIMARY:
        usesPrimarySpindle = true;
        break;
      case SPINDLE_SECONDARY:
        usesSecondarySpindle = true;
        break;
      }
    }
  }
  
  writeBlock("LIMS=" + rpmFormat.format(getProperty("maximumSpindleSpeed")));
  sOutput.reset();

  if (getProperty("gotChipConveyor")) {
    onCommand(COMMAND_START_CHIP_TRANSPORT);
  }

  if (gotSecondarySpindle) {
    // retract Sub Spindle if applicable
  }
}

function onComment(message) {
  writeComment(message);
}

/** Force output of X, Y, and Z. */
function forceXYZ() {
  xOutput.reset();
  yOutput.reset();
  zOutput.reset();
}

/** Force output of A, B, and C. */
function forceABC() {
  aOutput.reset();
  bOutput.reset();
  cOutput.reset();
}

function forceFeed() {
  currentFeedId = undefined;
  feedOutput.reset();
}

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
  forceXYZ();
  forceABC();
  forceFeed();
}

function FeedContext(id, description, feed) {
  this.id = id;
  this.description = description;
  this.feed = feed;
}

function getFeed(f) {
  _f = (currentSection.feedMode != FEED_PER_REVOLUTION && machineState.feedPerRevolution) ? f / spindleSpeed : f;
  if (activeMovements) {
    var feedContext = activeMovements[movement];
    if (feedContext != undefined) {
      if (!feedFormat.areDifferent(feedContext.feed, _f)) {
        if (feedContext.id == currentFeedId) {
          return ""; // nothing has changed
        }
        forceFeed();
        currentFeedId = feedContext.id;
        return "F=R" + (firstFeedParameter + feedContext.id);
      }
    }
    currentFeedId = undefined; // force Q feed next time
  }
  return feedOutput.format(_f); // use feed value
}

function initializeActiveFeeds() {
  activeMovements = new Array();
  var movements = currentSection.getMovements();
  var feedPerRev = currentSection.feedMode == FEED_PER_REVOLUTION;

  var id = 0;
  var activeFeeds = new Array();
  if (hasParameter("operation:tool_feedCutting")) {
    if (movements & ((1 << MOVEMENT_CUTTING) | (1 << MOVEMENT_LINK_TRANSITION) | (1 << MOVEMENT_EXTENDED))) {
      var feedContext = new FeedContext(id, localize("Cutting"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_CUTTING] = feedContext;
      activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
      activeMovements[MOVEMENT_EXTENDED] = feedContext;
    }
    ++id;
    if (movements & (1 << MOVEMENT_PREDRILL)) {
      feedContext = new FeedContext(id, localize("Predrilling"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeMovements[MOVEMENT_PREDRILL] = feedContext;
      activeFeeds.push(feedContext);
    }
    ++id;
  }

  if (hasParameter("operation:finishFeedrate")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var finishFeedrateRel;
      if (hasParameter("operation:finishFeedrateRel")) {
        finishFeedrateRel = getParameter("operation:finishFeedrateRel");
      } else if (hasParameter("operation:finishFeedratePerRevolution")) {
        finishFeedrateRel = getParameter("operation:finishFeedratePerRevolution");
      }
      var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? finishFeedrateRel : getParameter("operation:finishFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedEntry")) {
    if (movements & (1 << MOVEMENT_LEAD_IN)) {
      var feedContext = new FeedContext(id, localize("Entry"), feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_IN] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LEAD_OUT)) {
      var feedContext = new FeedContext(id, localize("Exit"), feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_OUT] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:noEngagementFeedrate")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(id, localize("Direct"), feedPerRev ? getParameter("operation:noEngagementFeedrateRel") : getParameter("operation:noEngagementFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting") &&
             hasParameter("operation:tool_feedEntry") &&
             hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(
        id,
        localize("Direct"),
        Math.max(
          feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"),
          feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"),
          feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit")
        )
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:reducedFeedrate")) {
    if (movements & (1 << MOVEMENT_REDUCED)) {
      var feedContext = new FeedContext(id, localize("Reduced"), feedPerRev ? getParameter("operation:reducedFeedrateRel") : getParameter("operation:reducedFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_REDUCED] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedRamp")) {
    if (movements & ((1 << MOVEMENT_RAMP) | (1 << MOVEMENT_RAMP_HELIX) | (1 << MOVEMENT_RAMP_PROFILE) | (1 << MOVEMENT_RAMP_ZIG_ZAG))) {
      var feedContext = new FeedContext(id, localize("Ramping"), feedPerRev ? getParameter("operation:tool_feedRampRel") : getParameter("operation:tool_feedRamp"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_RAMP] = feedContext;
      activeMovements[MOVEMENT_RAMP_HELIX] = feedContext;
      activeMovements[MOVEMENT_RAMP_PROFILE] = feedContext;
      activeMovements[MOVEMENT_RAMP_ZIG_ZAG] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedPlunge")) {
    if (movements & (1 << MOVEMENT_PLUNGE)) {
      var feedContext = new FeedContext(id, localize("Plunge"), feedPerRev ? getParameter("operation:tool_feedPlungeRel") : getParameter("operation:tool_feedPlunge"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_PLUNGE] = feedContext;
    }
    ++id;
  }
  if (true) { // high feed
    if ((movements & (1 << MOVEMENT_HIGH_FEED)) || (highFeedMapping != HIGH_FEED_NO_MAPPING)) {
      var feed;
      if (hasParameter("operation:highFeedrateMode") && getParameter("operation:highFeedrateMode") != "disabled") {
        feed = getParameter("operation:highFeedrate");
      } else {
        feed = this.highFeedrate;
      }
      var feedContext = new FeedContext(id, localize("High Feed"), feed);
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_HIGH_FEED] = feedContext;
      activeMovements[MOVEMENT_RAPID] = feedContext;
    }
    ++id;
  }

  for (var i = 0; i < activeFeeds.length; ++i) {
    var feedContext = activeFeeds[i];
    writeBlock("R" + (firstFeedParameter + feedContext.id) + "=" + feedFormat.format(feedContext.feed), formatComment(feedContext.description));
  }
}

var currentWorkPlaneABC = undefined;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

function defineWorkPlane(_section, _setWorkPlane) {
  var abc = new Vector(0, 0, 0);
  if (machineConfiguration.isMultiAxisConfiguration()) {
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
      if (gotBAxis) {
        // TAG: handle B-axis support for turning operations here
        if (_setWorkPlane) {
          writeBlock(gMotionModal.format(0), conditional(machineConfiguration.isMachineCoordinate(1), bOutput.format(getB(bAxisOrientationTurning, _section))));
        }
        machineState.currentBAxisOrientationTurning = bAxisOrientationTurning;
        //setSpindleOrientationTurning();
      } else {
        setRotation(_section.workPlane);
      }
    } else {
      if (_section.isMultiAxis()) {
        if (_setWorkPlane) {
          forceWorkPlane();
          onCommand(COMMAND_UNLOCK_MULTI_AXIS);
        }
        cancelTransformation();
        abc = _section.getInitialToolAxisABC();
      } else {
        if (machineState.useXZCMode) {
          setRotation(_section.workPlane); // enables calculation of the C-axis by tool XY-position
          abc = new Vector(0, 0, getCWithinRange(getFramePosition(_section.getInitialPosition()).x, getFramePosition(_section.getInitialPosition()).y, cOutput.getCurrent()));
        } else {
          abc = getWorkPlaneMachineABC(_section, _section.workPlane);
        }
      }
      if (_setWorkPlane) {
        setWorkPlane(abc);
      }
    }
  } else { // pure 3D
    var remaining = _section.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported by the CNC machine."));
      return abc;
    }
    setRotation(remaining);
  }
  if (abc !== undefined) {
    if (_setWorkPlane) {
      if (!_section.isMultiAxis()) {
        cOutput.format(abc.z); // make C current - we do not want to output here
      }
    }
  }
  return abc;
}

function setWorkPlane(abc) {
  // milling only

  if (!machineConfiguration.isMultiAxisConfiguration()) {
    return; // ignore
  }

  if (!((currentWorkPlaneABC == undefined) ||
        abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
        abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
        abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z))) {
    return; // no change
  }

  currentWorkPlaneABC = abc;

  onCommand(COMMAND_UNLOCK_MULTI_AXIS);
  gMotionModal.reset();

  writeBlock(
    gMotionModal.format(0),
    conditional(machineConfiguration.isMachineCoordinate(0), aOutput.format(abc.x)),
    conditional(machineConfiguration.isMachineCoordinate(1), bOutput.format(getB(abc, currentSection))),
    conditional(machineConfiguration.isMachineCoordinate(2) && machineState.cAxisIsEngaged, cOutput.format(abc.z))
  );
  
  if (gotBAxis) {
    writeBlock("ROT");
    writeBlock("AROT Y" + abcFormat.format(abc.y));
  }

  if (!currentSection.isMultiAxis() && !machineState.usePolarMode && !machineState.useXZCMode) {
    if (machineState.cAxisIsEngaged) {
      onCommand(COMMAND_LOCK_MULTI_AXIS);
    }
  }

  currentWorkPlaneABC = abc;
}

function getBestABCIndex(section) {
  var fitFlag = false;
  var index = undefined;
  for (var i = 0; i < 6; ++i) {
    fitFlag = doesToolpathFitInXYRange(getBestABC(section, section.workPlane, i));
    if (fitFlag) {
      index = i;
      break;
    }
  }
  return index;
}

function getBestABC(section, workPlane, which) {
  var W = workPlane;
  var abc = machineConfiguration.getABC(W);
  if (which == undefined) { // turning, XZC, Polar modes
    return abc;
  }
  if (Vector.dot(machineConfiguration.getAxisU().getAxis(), new Vector(0, 0, 1)) != 0) {
    var axis = machineConfiguration.getAxisU(); // C-axis is the U-axis
  } else {
    var axis = machineConfiguration.getAxisV(); // C-axis is the V-axis
  }
  if (axis.isEnabled() && axis.isTable()) {
    var ix = axis.getCoordinate();
    var rotAxis = axis.getAxis();
    if (isSameDirection(machineConfiguration.getDirection(abc), rotAxis) ||
        isSameDirection(machineConfiguration.getDirection(abc), Vector.product(rotAxis, -1))) {
      var direction = isSameDirection(machineConfiguration.getDirection(abc), rotAxis) ? 1 : -1;
      var box = section.getGlobalBoundingBox();
      switch (which) {
      case 1:
        x = box.lower.x + ((box.upper.x - box.lower.x) / 2);
        y = box.lower.y + ((box.upper.y - box.lower.y) / 2);
        break;
      case 2:
        x = box.lower.x;
        y = box.lower.y;
        break;
      case 3:
        x = box.upper.x;
        y = box.lower.y;
        break;
      case 4:
        x = box.upper.x;
        y = box.upper.y;
        break;
      case 5:
        x = box.lower.x;
        y = box.upper.y;
        break;
      default:
        var R = machineConfiguration.getRemainingOrientation(abc, W);
        x = R.right.x;
        y = R.right.y;
        break;
      }
      abc.setCoordinate(ix, getCClosest(x, y, cOutput.getCurrent()));
    }
  }
  // writeComment("Which = " + which + "  Angle = " + abc.z)
  return abc;
}

var closestABC = false; // choose closest machine angles
var currentMachineABC;

function getWorkPlaneMachineABC(section, workPlane) {
  var W = workPlane; // map to global frame

  var abc;
  if (machineState.isTurningOperation && gotBAxis) {
    var both = machineConfiguration.getABCByDirectionBoth(workPlane.forward);
    abc = both[0];
    if (both[0].z != 0) {
      abc = both[1];
    }
  } else {
    abc = getBestABC(section, workPlane, bestABCIndex);
    if (closestABC) {
      if (currentMachineABC) {
        abc = machineConfiguration.remapToABC(abc, currentMachineABC);
      } else {
        abc = machineConfiguration.getPreferredABC(abc);
      }
    } else {
      abc = machineConfiguration.getPreferredABC(abc);
    }
  }

  try {
    abc = machineConfiguration.remapABC(abc);
    currentMachineABC = abc;
  } catch (e) {
    error(
      localize("Machine angles not supported") + ":"
      + conditional(machineConfiguration.isMachineCoordinate(0), " A" + abcFormat.format(abc.x))
      + conditional(machineConfiguration.isMachineCoordinate(1), " B" + abcFormat.format(abc.y))
      + conditional(machineConfiguration.isMachineCoordinate(2), " C" + abcFormat.format(abc.z))
    );
  }

  var direction = machineConfiguration.getDirection(abc);
  if (!isSameDirection(direction, W.forward)) {
    error(localize("Orientation not supported."));
  }

  if (machineState.isTurningOperation && gotBAxis) { // remapABC can change the B-axis orientation
    if (abc.z != 0) {
      error(localize("Could not calculate a B-axis turning angle within the range of the machine."));
      return abc;
    }
  }

  if (!machineConfiguration.isABCSupported(abc)) {
    error(
      localize("Work plane is not supported") + ":"
      + conditional(machineConfiguration.isMachineCoordinate(0), " A" + abcFormat.format(abc.x))
      + conditional(machineConfiguration.isMachineCoordinate(1), " B" + abcFormat.format(abc.y))
      + conditional(machineConfiguration.isMachineCoordinate(2), " C" + abcFormat.format(abc.z))
    );
  }

  if (!machineState.isTurningOperation) {
    var tcp = false;
    if (tcp) {
      setRotation(W); // TCP mode
    } else {
      var O = machineConfiguration.getOrientation(abc);
      var R = machineConfiguration.getRemainingOrientation(abc, W);
      setRotation(R);
    }
  }

  return abc;
}

function getBAxisOrientationTurning(section) {
  var toolAngle = hasParameter("operation:tool_angle") ? getParameter("operation:tool_angle") : 0;
  var toolOrientation = section.toolOrientation;
  if (toolAngle && (toolOrientation != 0)) {
    error(localize("You cannot use tool angle and tool orientation together in operation " + "\"" + (getParameter("operation-comment")) + "\""));
  }

  var angle = toRad(toolAngle) + toolOrientation;

  var axis = new Vector(0, 1, 0);
  var mappedAngle = (currentSection.spindle == SPINDLE_PRIMARY ? (Math.PI / 2 - angle) : (Math.PI / 2 - angle));
  var mappedWorkplane = new Matrix(axis, mappedAngle);
  var abc = getWorkPlaneMachineABC(section, mappedWorkplane);

  return abc;
}

function setSpindleOrientationTurning(section) {
  var J; // cutter orientation
  var R; // cutting quadrant
  var leftHandTool = (hasParameter("operation:tool_hand") && (getParameter("operation:tool_hand") == "L" || getParameter("operation:tool_holderType") == 0));
  if (hasParameter("operation:machineInside")) {
    if (getParameter("operation:machineInside") == 0) {
      R = currentSection.spindle == SPINDLE_PRIMARY ? 3 : 4;
    } else {
      R = currentSection.spindle == SPINDLE_PRIMARY ? 2 : 1;
    }
  } else {
    if ((hasParameter("operation-strategy") && getParameter("operation-strategy") == "turningFace") ||
      (hasParameter("operation-strategy") && getParameter("operation-strategy") == "turningPart")) {
      R = currentSection.spindle == SPINDLE_PRIMARY ? 3 : 4;
    } else {
      error(subst(localize("Failed to identify spindle orientation for operation \"%1\"."), getOperationComment()));
      return;
    }
  }
  if (leftHandTool) {
    J = currentSection.spindle == SPINDLE_PRIMARY ? 2 : 1;
  } else {
    J = currentSection.spindle == SPINDLE_PRIMARY ? 1 : 2;
  }
  writeComment("Post processor is not customized, add code for cutter orientation and cutting quadrant here if needed.");
}

var bAxisOrientationTurning = new Vector(0, 0, 0);

function getSpindle() {
  if (getNumberOfSections() == 0) {
    return SPINDLE_PRIMARY;
  }
  if (getCurrentSectionId() < 0) {
    return getSection(getNumberOfSections() - 1).spindle == 0;
  }
  if (currentSection.getType() == TYPE_TURNING) {
    return currentSection.spindle;
  } else {
    if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))) {
      return SPINDLE_PRIMARY;
    } else if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, -1))) {
      if (!gotSecondarySpindle) {
        error(localize("Secondary spindle is not available."));
      }
      return SPINDLE_SECONDARY;
    } else {
      return SPINDLE_PRIMARY;
    }
  }
}

function subprogramDefine(_initialPosition, _abc, _retracted, _zIsOutput) {
  // convert patterns into subprograms
  var usePattern = false;
  patternIsActive = false;
  if (currentSection.isPatterned && currentSection.isPatterned() && false /*(getProperty("useSubroutines") == "patterns")*/) {
    currentPattern = currentSection.getPatternId();
    firstPattern = true;
    for (var i = 0; i < definedPatterns.length; ++i) {
      if ((definedPatterns[i].patternType == SUB_PATTERN) && (currentPattern == definedPatterns[i].patternId)) {
        currentSubprogram = definedPatterns[i].subProgram;
        usePattern = definedPatterns[i].validPattern;
        firstPattern = false;
        break;
      }
    }

    if (firstPattern) {
      // determine if this is a valid pattern for creating a subprogram
      usePattern = subprogramIsValid(currentSection, currentPattern, SUB_PATTERN);
      if (usePattern) {
        currentSubprogram = ++lastSubprogram;
      }
      definedPatterns.push({
        patternType: SUB_PATTERN,
        patternId: currentPattern,
        subProgram: currentSubprogram,
        validPattern: usePattern,
        initialPosition: _initialPosition,
        finalPosition: _initialPosition
      });
    }

    if (usePattern) {
      // make sure Z-position is output prior to subprogram call
      if (!_retracted && !_zIsOutput) {
        writeBlock(gMotionModal.format(0), zOutput.format(_initialPosition.z));
      }

      // call subprogram
      subprogramCall();
      patternIsActive = true;

      if (firstPattern) {
        subprogramStart(_initialPosition, _abc, true);
      } else {
        skipRemainingSection();
        setCurrentPosition(getFramePosition(currentSection.getFinalPosition()));
      }
    }
  }

  // Output cycle operation as subprogram
  if (!usePattern && false /*(getProperty("useSubroutines") == "cycles")*/ && currentSection.doesStrictCycle &&
    (currentSection.getNumberOfCycles() == 1) && currentSection.getNumberOfCyclePoints() >= minimumCyclePoints) {
    var finalPosition = getFramePosition(currentSection.getFinalPosition());
    currentPattern = currentSection.getNumberOfCyclePoints();
    firstPattern = true;
    for (var i = 0; i < definedPatterns.length; ++i) {
      if ((definedPatterns[i].patternType == SUB_CYCLE) && (currentPattern == definedPatterns[i].patternId) &&
          !areSpatialVectorsDifferent(_initialPosition, definedPatterns[i].initialPosition) &&
          !areSpatialVectorsDifferent(finalPosition, definedPatterns[i].finalPosition)) {
        currentSubprogram = definedPatterns[i].subProgram;
        usePattern = definedPatterns[i].validPattern;
        firstPattern = false;
        break;
      }
    }

    if (firstPattern) {
      // determine if this is a valid pattern for creating a subprogram
      usePattern = subprogramIsValid(currentSection, currentPattern, SUB_CYCLE);
      if (usePattern) {
        currentSubprogram = ++lastSubprogram;
      }
      definedPatterns.push({
        patternType: SUB_CYCLE,
        patternId: currentPattern,
        subProgram: currentSubprogram,
        validPattern: usePattern,
        initialPosition: _initialPosition,
        finalPosition: finalPosition
      });
    }
    cycleSubprogramIsActive = usePattern;
  }

  // Output each operation as a subprogram
  if (!usePattern && (getProperty("useSubroutines") == "allOperations")) {
    currentSubprogram = ++lastSubprogram;
    // writeBlock("REPEAT LABEL" + currentSubprogram + " LABEL0");
    subprogramCall();
    firstPattern = true;
    subprogramStart(_initialPosition, _abc, false);
  }
}

function subprogramStart(_initialPosition, _abc, _incremental) {
  var comment = "";
  if (hasParameter("operation-comment")) {
    comment = getParameter("operation-comment");
  }
  
  if (getProperty("useFilesForSubprograms")) {
    // used if external files are used for subprograms
    var subprogram = "sub" + String(programName).substr(0, Math.min(programName.length, 20)) + currentSubprogram; // set the subprogram name
    var path = FileSystem.getCombinedPath(FileSystem.getFolderPath(getOutputPath()), subprogram + "." + subprogramExtension); // set the output path for the subprogram(s)
    redirectToFile(path); // redirect output to the new file (defined above)
    writeln("; %_N_" + translateText(String(subprogram).toUpperCase(), " ", "_") + "_SPF"); // add the program name to the first line of the newly created file
  } else {
    // used if subroutines are contained within the same file
    redirectToBuffer();
    writeln(
      "LABEL" + currentSubprogram + ":" +
      conditional(comment, formatComment(comment.substr(0, maximumLineLength - 2 - 6 - 1)))
    ); // output the subroutine name as the first line of the new file
  }
  
  saveShowSequenceNumbers = getProperty("showSequenceNumbers");
  setProperty("showSequenceNumbers", false); // disable sequence numbers for subprograms
  if (_incremental) {
    setIncrementalMode(_initialPosition, _abc);
  }
  gPlaneModal.reset();
  gMotionModal.reset();
}

function subprogramCall() {
  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeln("");
      writeBlock("MSG (" + "\"" + formatComment(comment) + "\"" + ")");
    }
  }
  if (getProperty("useFilesForSubprograms")) {
    var subprogram = "sub" + String(programName).substr(0, Math.min(programName.length, 20)) + currentSubprogram; // set the subprogram name
    var callType = "SPF CALL";
    writeBlock(subprogram + " ;", callType); // call subprogram
  } else {
    writeBlock("CALL BLOCK LABEL" + currentSubprogram + " TO LABEL0");
  }
}

function subprogramEnd() {
  if (firstPattern) {
    if (!getProperty("useFilesForSubprograms")) {
      writeBlock("LABEL0:"); // sets the end block of the subroutine
      writeln("");
      subprograms += getRedirectionBuffer();
    } else {
      writeBlock(mFormat.format(17)); // close the external subprogram with M17
    }
  }
  forceAny();
  firstPattern = false;
  setProperty("showSequenceNumbers", saveShowSequenceNumbers);
  closeRedirection();
}

function onSection() {
  if (currentSection.spindle == SPINDLE_PRIMARY) {
    yFormat = createFormat({decimals: (unit == MM ? 3 : 4), scale: 1});
    yOutput = createVariable({prefix: "Y"}, yFormat);
    jOutput = createReferenceVariable({prefix: "J", force: true}, yFormat);
    cOutput = createVariable({prefix: mainSpindleAxisName[0]}, (getProperty("useShortestDirection") /*&& section.isMultiAxis()*/) ? abcDirectFormat : cFormat);
  } else { // secondary
    yFormat = createFormat({decimals: (unit == MM ? 3 : 4), scale: -1});
    yOutput = createVariable({prefix: "Y"}, yFormat);
    jOutput = createReferenceVariable({prefix: "J", force: true}, yFormat);
    cOutput = createVariable({prefix: subSpindleAxisName[0]}, (getProperty("useShortestDirection") /*&& section.isMultiAxis()*/) ? abcDirectFormat : cFormat);
  }

  if (!gotYAxis) {
    yOutput.disable();
  }

  // Detect machine configuration
  machineConfiguration = (currentSection.spindle == SPINDLE_PRIMARY) ? machineConfigurationMainSpindle : machineConfigurationSubSpindle;
  if (!gotBAxis) {
    if (getMachiningDirection(currentSection) == MACHINING_DIRECTION_AXIAL && !currentSection.isMultiAxis()) {
      machineConfiguration.setSpindleAxis(new Vector(0, 0, 1));
    } else {
      machineConfiguration.setSpindleAxis(new Vector(1, 0, 0));
    }
  } else {
    machineConfiguration.setSpindleAxis(new Vector(0, 0, 1)); // set the spindle axis depending on B0 orientation
  }

  setMachineConfiguration(machineConfiguration);
  currentSection.optimizeMachineAnglesByMachine(machineConfiguration, 1); // map tip mode
  
  if (getProperty("toolAsName") && !tool.description) {
    if (hasParameter("operation-comment")) {
      error(localize("Tool description is empty in operation " + "\"" + (getParameter("operation-comment").toUpperCase()) + "\""));
    } else {
      error(localize("Tool description is empty."));
    }
    return;
  }

  machineState.tapping = hasParameter("operation:cycleType") &&
    ((getParameter("operation:cycleType") == "tapping") ||
     (getParameter("operation:cycleType") == "right-tapping") ||
     (getParameter("operation:cycleType") == "left-tapping") ||
     (getParameter("operation:cycleType") == "tapping-with-chip-breaking"));

  var forceToolAndRetract = optionalSection && !currentSection.isOptional();
  optionalSection = currentSection.isOptional();
  bestABCIndex = undefined;

  machineState.isTurningOperation = (currentSection.getType() == TYPE_TURNING);
  if (machineState.isTurningOperation && gotBAxis) {
    bAxisOrientationTurning = getBAxisOrientationTurning(currentSection);
  }
  var insertToolCall = forceToolAndRetract || isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number) ||
    (tool.compensationOffset != getPreviousSection().getTool().compensationOffset) ||
    (tool.diameterOffset != getPreviousSection().getTool().diameterOffset) ||
    (tool.lengthOffset != getPreviousSection().getTool().lengthOffset) ||
    conditional(getProperty("toolAsName"), tool.description != getPreviousSection().getTool().description);
  retracted = false; // specifies that the tool has been retracted to the safe plane
  var newSpindle = isFirstSection() ||
    (getPreviousSection().spindle != currentSection.spindle);
  var newWorkOffset = isFirstSection() ||
    (getPreviousSection().workOffset != currentSection.workOffset); // work offset changes
  var newWorkPlane = isFirstSection() ||
    !isSameDirection(getPreviousSection().getGlobalFinalToolAxis(), currentSection.getGlobalInitialToolAxis()) ||
    (machineState.isTurningOperation &&
      abcFormat.areDifferent(bAxisOrientationTurning.x, machineState.currentBAxisOrientationTurning.x) ||
      abcFormat.areDifferent(bAxisOrientationTurning.y, machineState.currentBAxisOrientationTurning.y) ||
      abcFormat.areDifferent(bAxisOrientationTurning.z, machineState.currentBAxisOrientationTurning.z));
  var stockTransfer = hasParameter("operation-strategy") &&
    (getParameter("operation-strategy") == "turningStockTransfer");
  var zIsOutput = true; // true if the Z-position has been output, used for patterns

  // define subprogram
  subprogramDefine(initialPosition, abc, retracted, zIsOutput);
  
  if (insertToolCall || newSpindle || newWorkOffset || newWorkPlane && !currentSection.isPatterned()) {
    if (insertToolCall) {
      onCommand(COMMAND_COOLANT_OFF);
    }
    // retract to safe plane
    writeRetract(X);
    writeRetract(Y);
    writeRetract(Z);
  }

  updateMachiningMode(currentSection); // sets the needed machining mode to machineState (usePolarMode, useXZCMode, axialCenterDrilling)

  if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
    if (machineState.liveToolIsActive) {
      writeBlock(getCode("STOP_LIVE_TOOL"));
    }
  } else {
    if (machineState.mainSpindleIsActive) {
      writeBlock(getCode("STOP_MAIN_SPINDLE"));
    }
    if (machineState.subSpindleIsActive) {
      writeBlock(getCode("STOP_SUB_SPINDLE"));
    }
  }

  writeln("");

  if (!(getProperty("useSubroutines") == "allOperations")) {
    if (hasParameter("operation-comment")) {
      var comment = getParameter("operation-comment");
      if (comment) {
        writeBlock("MSG (" + "\"" + formatComment(comment) + "\"" + ")");
      }
    }
  }

  if (getProperty("showNotes") && hasParameter("notes")) {
    var notes = getParameter("notes");
    if (notes) {
      var lines = String(notes).split("\n");
      var r1 = new RegExp("^[\\s]+", "g");
      var r2 = new RegExp("[\\s]+$", "g");
      for (line in lines) {
        var comment = lines[line].replace(r1, "").replace(r2, "");
        if (comment) {
          writeComment(comment);
        }
      }
    }
  }

  if (stockTransfer) {
    return; // skip onSection(), continue in onCycle()
  }

  gPlaneModal.reset();

  writeBlock(gPlaneModal.format(getPlane()));

  if (machineState.isTurningOperation) {
    writeBlock("DIAMON");
    if (gotBAxis) {
      writeBlock("ROT");
    }
    xFormat.setScale(2); // diameter mode
    xOutput = createVariable({prefix:"X"}, xFormat);
  } else {
    writeBlock("DIAMOF");
    xFormat.setScale(1); // radius mode
    xOutput = createVariable({prefix:"X"}, xFormat);
  }

  if (insertToolCall) {
    forceWorkPlane();
    cAxisEngageModal.reset();
    onCommand(COMMAND_COOLANT_OFF);
    if (!isFirstSection() && getProperty("optionalStop")) {
      onCommand(COMMAND_OPTIONAL_STOP);
    }

    /** Handle multiple turrets. */
    if (gotMultiTurret) {
      var turret = tool.turret;
      if (turret == 0) {
        warning(localize("Turret has not been specified. Using Turret 1 as default."));
        turret = 1; // upper turret as default
      }
      if (turret != machineState.currentTurret) {
      // change of turret
        setCoolant(COOLANT_OFF, machineState.currentTurret);
      }
      switch (turret) {
      case 1:
        // add specific handling for turret 1
        break;
      case 2:
        // add specific handling for turret 2
        break;
      default:
        error(localize("Turret is not supported."));
        return;
      }
      machineState.currentTurret = turret;
    }

    if (tool.number > 99) {
      warning(localize("Tool number exceeds maximum value."));
    }

    var compensationOffset = tool.isTurningTool() ? tool.compensationOffset : tool.lengthOffset;
    if (compensationOffset > 99) {
      error(localize("Compensation offset is out of range."));
      return;
    }

    var lengthOffset = 1; // optional, use tool.lengthOffset instead
    if (lengthOffset > 99) {
      error(localize("Length offset out of range."));
      return;
    }

    writeBlock("T" + (getProperty("toolAsName") ? "="  + "\"" + (tool.description.toUpperCase()) + "\"" : toolFormat.format(tool.number)));
    writeBlock(mFormat.format(6));
    writeBlock(dFormat.format(lengthOffset));
    if (tool.comment) {
      writeComment(tool.comment);
    }

    var showToolZMin = false;
    if (showToolZMin && (currentSection.getType() == TYPE_MILLING)) {
      if (is3D()) {
        var numberOfSections = getNumberOfSections();
        var zRange = currentSection.getGlobalZRange();
        var number = tool.number;
        for (var i = currentSection.getId() + 1; i < numberOfSections; ++i) {
          var section = getSection(i);
          if (section.getTool().number != number) {
            break;
          }
          zRange.expandToRange(section.getGlobalZRange());
        }
        writeComment(localize("ZMIN") + "=" + zRange.getMinimum());
      }
    }

    /*
    if (getProperty("preloadTool")) {
      var nextTool = getNextTool(tool.number);
      if (nextTool) {
        var compensationOffset = nextTool.isTurningTool() ? nextTool.compensationOffset : nextTool.lengthOffset;
        if (compensationOffset > 99) {
          error(localize("Compensation offset is out of range."));
          return;
        }
        writeBlock("T" + toolFormat.format(nextTool.number * 100 + compensationOffset));
      } else {
        // preload first tool
        var section = getSection(0);
        var firstTool = section.getTool().number;
        if (tool.number != firstTool.number) {
          var compensationOffset = firstTool.isTurningTool() ? firstTool.compensationOffset : firstTool.lengthOffset;
          if (compensationOffset > 99) {
            error(localize("Compensation offset is out of range."));
            return;
          }
          writeBlock("T" + toolFormat.format(firstTool.number * 100 + compensationOffset));
        }
      }
    }
*/
  }

  // command stop for manual tool change, useful for quick change live tools
  if (insertToolCall && tool.manualToolChange) {
    onCommand(COMMAND_STOP);
    writeComment("MANUAL TOOL CHANGE TO T" + (getProperty("toolAsName") ? "="  + "\"" + (tool.description.toUpperCase()) + "\"" : toolFormat.format(tool.number * 100 + compensationOffset)) + ")");
  }

  if (newSpindle) {
    // select spindle if required
  }

  sOutput.reset(); // force spindle speeds

  // Engage tailstock
  if (getProperty("useTailStock")) {
    if (machineState.axialCenterDrilling || (currentSection.spindle == SPINDLE_SECONDARY) ||
      (machineState.liveToolIsActive && (getMachiningDirection(currentSection) == MACHINING_DIRECTION_AXIAL))) {
      if (currentSection.tailstock) {
        warning(localize("Tail stock is not supported for secondary spindle or Z-axis milling."));
      }
      if (machineState.tailstockIsActive) {
        writeBlock(getCode("TAILSTOCK_OFF"));
      }
    } else {
      writeBlock(currentSection.tailstock ? getCode("TAILSTOCK_ON") : getCode("TAILSTOCK_OFF"));
    }
  }

  if (insertToolCall ||
      newSpindle ||
      isFirstSection() ||
      isSpindleSpeedDifferent()) {
    if (machineState.isTurningOperation) {
      if (spindleSpeed > 99999) {
        warning(subst(localize("Spindle speed exceeds maximum value for operation \"%1\"."), getOperationComment()));
      }
    } else {
      if (spindleSpeed > 6000) {
        warning(subst(localize("Spindle speed exceeds maximum value for operation \"%1\"."), getOperationComment()));
      }
    }
    startSpindle(true, getFramePosition(currentSection.getInitialPosition()));
  }

  // wcs
  if (insertToolCall) { // force work offset when changing tool
    currentWorkOffset = undefined;
  }
  var workOffset = currentSection.workOffset;
  writeWCS(currentSection);

  if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
    writeBlock(conditional(machineState.cAxisIsEngaged || machineState.cAxisIsEngaged == undefined), getCode("DISENGAGE_C_AXIS"));
  } else { // milling
    writeBlock(conditional(!machineState.cAxisIsEngaged || machineState.cAxisIsEngaged == undefined), getCode("ENGAGE_C_AXIS"));
  }

  var useConstantSurfaceSpeed = currentSection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED;
  if ((tool.maximumSpindleSpeed > 0) && useConstantSurfaceSpeed) {
    var maximumSpindleSpeed = (tool.maximumSpindleSpeed > 0) ? Math.min(tool.maximumSpindleSpeed, getProperty("maximumSpindleSpeed")) : getProperty("maximumSpindleSpeed");
    writeBlock("LIMS=" + rpmFormat.format(maximumSpindleSpeed));
  }

  if (getProperty("useParametricFeed") &&
      hasParameter("operation-strategy") &&
      (getParameter("operation-strategy") != "drill") && // legacy
      !(currentSection.hasAnyCycle && currentSection.hasAnyCycle())) {
    if (!insertToolCall &&
        activeMovements &&
        (getCurrentSectionId() > 0) &&
        ((getPreviousSection().getPatternId() == currentSection.getPatternId()) && (currentSection.getPatternId() != 0))) {
      // use the current feeds
    } else {
      initializeActiveFeeds();
    }
  } else {
    activeMovements = undefined;
  }

  if (currentSection.partCatcher) {
    engagePartCatcher(true);
  }

  gMotionModal.reset();

  var abc = defineWorkPlane(currentSection, true);
  
  forceAny();

  // writeRetract(X);
  // writeRetract(Y);
  // writeRetract(Z);

  if (true /*|| retracted && !insertToolCall*/) {
    var lengthOffset = tool.isTurningTool() ? tool.compensationOffset : 1; // optional, use tool.lengthOffset instead
    if (lengthOffset > 99) {
      error(localize("Length offset out of range."));
      return;
    }
    writeBlock(dOutput.format(lengthOffset));
  }

  gMotionModal.reset();

  if (machineState.cAxisIsEngaged) { // make sure C-axis in engaged
    if (!machineState.usePolarMode && !machineState.useXZCMode && !currentSection.isMultiAxis()) {
      onCommand(COMMAND_LOCK_MULTI_AXIS);
    } else {
      onCommand(COMMAND_UNLOCK_MULTI_AXIS);
    }
  }

  if (machineState.usePolarMode) {
    setPolarMode(true); // enable polar interpolation mode
  }

  // set coolant after we have positioned at Z
  setCoolant(tool.coolant, machineState.currentTurret);
  
  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  if (currentSection.isMultiAxis()) {
    forceABC();
    forceWorkPlane();
    cancelTransformation();
    // turn machine
    // writeBlock("TRANS_5A(" + (currentSection.spindle == SPINDLE_PRIMARY ? mainSpindleAxisName[1] :  subSpindleAxisName[1]) + "," + "\"" + "BC" + "\"" + ")");
    writeBlock(gAbsIncModal.format(90), gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), zOutput.format(initialPosition.z), aOutput.format(abc.x), bOutput.format(getB(abc, currentSection)), cOutput.format(abc.z));
  } else {
    if (insertToolCall || retracted) {
      gMotionModal.reset();
      if (machineState.useXZCMode) {
        writeBlock(gPlaneModal.format(getPlane()));
        writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
        writeBlock(
          gMotionModal.format(0),
          xOutput.format(getModulus(initialPosition.x, initialPosition.y)),
          conditional(gotYAxis, yOutput.format(0)),
          cOutput.format(getCWithinRange(initialPosition.x, initialPosition.y, cOutput.getCurrent())));
      } else {
        if (machineState.isTurningOperation) {
          writeBlock(gMotionModal.format(0), yOutput.format(initialPosition.y));
          writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z), xOutput.format(initialPosition.x));
        } else {
          writeBlock(gAbsIncModal.format(90), gMotionModal.format(0), zOutput.format(initialPosition.z));
          writeBlock(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y));
        }
      }
    }
  }
  // enable SFM spindle speed
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    startSpindle(false);
  }

  if (writeDebug) { // DEBUG
    for (var key in machineState) {
      writeComment(key + " : " + machineState[key]);
    }
    writeComment((getMachineConfigurationAsText(machineConfiguration)));
  }
}

/** Returns true if the toolpath fits within the machine XY limits for the given C orientation. */
function doesToolpathFitInXYRange(abc) {
  var xMin = xAxisMinimum * Math.abs(xFormat.getScale());
  var yMin = yAxisMinimum * Math.abs(yFormat.getScale());
  var yMax = yAxisMaximum * Math.abs(yFormat.getScale());
  var c = 0;
  if (abc) {
    c = abc.z;
  }
  if (Vector.dot(machineConfiguration.getAxisU().getAxis(), new Vector(0, 0, 1)) != 0) {
    c *= (machineConfiguration.getAxisU().getAxis().getCoordinate(2) >= 0) ? 1 : -1; // C-axis is the U-axis
  } else {
    c *= (machineConfiguration.getAxisV().getAxis().getCoordinate(2) >= 0) ? 1 : -1; // C-axis is the V-axis
  }

  var dx = new Vector(Math.cos(c), Math.sin(c), 0);
  var dy = new Vector(Math.cos(c + Math.PI / 2), Math.sin(c + Math.PI / 2), 0);

  if (currentSection.getGlobalRange) {
    var xRange = currentSection.getGlobalRange(dx);
    var yRange = currentSection.getGlobalRange(dy);

    if (writeDebug) { // DEBUG
      writeComment(
        "toolpath X minimum= " + xFormat.format(xRange[0]) + ", " + "Limit= " + xMin + ", " +
        "within range= " + (xFormat.getResultingValue(xRange[0]) >= xMin)
      );
      writeComment(
        "toolpath Y minimum= " + yFormat.getResultingValue(yRange[0]) + ", " + "Limit= " + yMin + ", " +
        "within range= " + (yFormat.getResultingValue(yRange[0]) >= yMin)
      );
      writeComment(
        "toolpath Y maximum= " + (yFormat.getResultingValue(yRange[1]) + ", " + "Limit= " + yMax) + ", " +
        "within range= " + (yFormat.getResultingValue(yRange[1]) <= yMax)
      );
      writeln("");
    }

    if (getMachiningDirection(currentSection) == MACHINING_DIRECTION_RADIAL) { // G19 plane
      if ((yFormat.getResultingValue(yRange[0]) >= yMin) &&
          (yFormat.getResultingValue(yRange[1]) <= yMax)) {
        return true; // toolpath does fit in XY range
      } else {
        return false; // toolpath does not fit in XY range
      }
    } else { // G17 plane
      if ((xFormat.getResultingValue(xRange[0]) >= xMin) &&
          (yFormat.getResultingValue(yRange[0]) >= yMin) &&
          (yFormat.getResultingValue(yRange[1]) <= yMax)) {
        return true; // toolpath does fit in XY range
      } else {
        return false; // toolpath does not fit in XY range
      }
    }
  } else {
    if (revision < 40000) {
      warning(localize("Please update to the latest release to allow XY linear interpolation instead of polar interpolation."));
    }
    return false; // for older versions without the getGlobalRange() function
  }
}

var MACHINING_DIRECTION_AXIAL = 0;
var MACHINING_DIRECTION_RADIAL = 1;
var MACHINING_DIRECTION_INDEXING = 2;

function getMachiningDirection(section) {
  var forward = section.isMultiAxis() ? section.getGlobalInitialToolAxis() : section.workPlane.forward;
  if (isSameDirection(forward, new Vector(0, 0, 1))) {
    machineState.machiningDirection = MACHINING_DIRECTION_AXIAL;
    return MACHINING_DIRECTION_AXIAL;
  } else if (Vector.dot(forward, new Vector(0, 0, 1)) < 1e-7) {
    machineState.machiningDirection = MACHINING_DIRECTION_RADIAL;
    return MACHINING_DIRECTION_RADIAL;
  } else {
    machineState.machiningDirection = MACHINING_DIRECTION_INDEXING;
    return MACHINING_DIRECTION_INDEXING;
  }
}

function updateMachiningMode(section) {
  machineState.axialCenterDrilling = false; // reset
  machineState.usePolarMode = false; // reset
  machineState.useXZCMode = false; // reset

  if ((section.getType() == TYPE_MILLING) && !section.isMultiAxis()) {
    if (getMachiningDirection(section) == MACHINING_DIRECTION_AXIAL) {
      if (section.hasParameter("operation-strategy") && (section.getParameter("operation-strategy") == "drill")) {
        // drilling axial
        if ((section.getNumberOfCyclePoints() == 1) &&
            !xFormat.isSignificant(getGlobalPosition(section.getInitialPosition()).x) &&
            !yFormat.isSignificant(getGlobalPosition(section.getInitialPosition()).y) &&
            (spatialFormat.format(section.getFinalPosition().x) == 0) &&
            !doesCannedCycleIncludeYAxisMotion(section)) { // catch drill issue for old versions
          // single hole on XY center
          if (section.getTool().isLiveTool && section.getTool().isLiveTool()) {
            // use live tool
          } else {
            // use main spindle for axialCenterDrilling
            machineState.axialCenterDrilling = true;
          }
        } else {
          // several holes not on XY center
          bestABCIndex = getBestABCIndex(section);
          if (getProperty("useYAxisForDrilling") && (bestABCIndex != undefined) && !doesCannedCycleIncludeYAxisMotion(section)) {
            // use XYZ-mode
          } else { // use XZC mode
            machineState.useXZCMode = true;
            bestABCIndex = undefined;
          }
        }
      } else { // milling
        if (forcePolarMode) {
          machineState.usePolarMode = true;
        } else if (forceXZCMode) {
          machineState.useXZCMode = true;
        } else {
          fitFlag = false;
          bestABCIndex = undefined;
          for (var i = 0; i < 6; ++i) {
            fitFlag = doesToolpathFitInXYRange(getBestABC(section, section.workPlane, i));
            if (fitFlag) {
              bestABCIndex = i;
              break;
            }
          }
          if (!fitFlag) { // does not fit, set polar/XZC mode
            if (gotPolarInterpolation) {
              machineState.usePolarMode = true;
            } else {
              machineState.useXZCMode = true;
            }
          }
        }
      }
    } else if (getMachiningDirection(section) == MACHINING_DIRECTION_RADIAL) { // G19 plane
      if (!gotYAxis) {
        if (!section.isMultiAxis() && (!doesToolpathFitInXYRange(machineConfiguration.getABC(section.workPlane)) || doesCannedCycleIncludeYAxisMotion(section))) {
          error(subst(localize("Y-axis motion is not possible without a Y-axis for operation \"%1\"."), getOperationComment()));
          return;
        }
      } else {
        if (!doesToolpathFitInXYRange(machineConfiguration.getABC(section.workPlane)) || forceXZCMode) {
          error(subst(localize("Toolpath exceeds the maximum ranges for operation \"%1\"."), getOperationComment()));
          return;
        }
      }
      // C-coordinates come from setWorkPlane or is within a multi axis operation, we cannot use the C-axis for non wrapped toolpathes (only multiaxis works, all others have to be into XY range)
    } else {
      // useXZCMode & usePolarMode is only supported for axial machining, keep false
    }
  } else {
    // turning or multi axis, keep false
  }

  if (machineState.axialCenterDrilling) {
    cOutput.disable();
  } else {
    cOutput.enable();
  }

  var checksum = 0;
  checksum += machineState.usePolarMode ? 1 : 0;
  checksum += machineState.useXZCMode ? 1 : 0;
  checksum += machineState.axialCenterDrilling ? 1 : 0;
  validate(checksum <= 1, localize("Internal post processor error."));
}

function getPlane() {
  if (getMachiningDirection(currentSection) == MACHINING_DIRECTION_AXIAL) { // axial
    if (machineState.isTurningOperation) {
      return 18; // turning
    } else {
      return 17; // milling
    }
  } else if (getMachiningDirection(currentSection) == MACHINING_DIRECTION_RADIAL) { // radial
    return 19; // YZ plane
  } else if (getMachiningDirection(currentSection) == MACHINING_DIRECTION_INDEXING) { // radial
    return 17;
  } else {
    error(subst(localize("Unsupported machining direction for operation " +  "\"" + "%1" + "\"" + "."), getOperationComment()));
    return undefined;
  }
}

function doesCannedCycleIncludeYAxisMotion(section) {
  // these cycles have Y axis motions which are not detected by getGlobalRange()
  var hasYMotion = false;
  if (section.hasParameter("operation:strategy") && (section.getParameter("operation:strategy") == "drill")) {
    switch (section.getParameter("operation:cycleType")) {
    case "thread-milling":
    case "bore-milling":
    case "circular-pocket-milling":
      hasYMotion = true; // toolpath includes Y-axis motion
      break;
    case "back-boring":
    case "fine-boring":
      var shift = getParameter("operation:boringShift");
      if (shift != spatialFormat.format(0)) {
        hasYMotion = true; // toolpath includes Y-axis motion
      }
      break;
    default:
      hasYMotion = false; // all other cycles don't have Y-axis motion
    }
  }
  return hasYMotion;
}

function getOperationComment() {
  var operationComment = hasParameter("operation-comment") && getParameter("operation-comment");
  return operationComment;
}

function setPolarMode(activate) {
  if (activate) {
    writeBlock("DIAMOF");
    if (!machineState.cAxisIsEngaged) {
      writeBlock(getCode("ENGAGE_C_AXIS"));
    }
    if (gotYAxis) {
      writeBlock(gMotionModal.format(0), yOutput.format(0));
    }
    yOutput.reset();
    writeBlock(getCode("POLAR_INTERPOLATION_ON")); // command for polar interpolation
    writeBlock(gPlaneModal.format(getPlane()));
    xFormat.setScale(1); // radius mode
    xOutput = createVariable({prefix:"X"}, xFormat);
    yOutput.enable();
  } else {
    writeBlock(getCode("POLAR_INTERPOLATION_OFF"));
    writeBlock("DIAMON");
    xFormat.setScale(2); // diameter mode
    xOutput = createVariable({prefix:"X"}, xFormat);
    if (!gotYAxis) {
      yOutput.disable();
    }
    cOutput.reset();
  }
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  milliseconds = clamp(1, seconds * 1000, 99999999);
  writeBlock(gFormat.format(4), "P" + milliFormat.format(milliseconds));
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

var resetFeed = false;

function getHighfeedrate(radius) {
  if (currentSection.feedMode == FEED_PER_REVOLUTION) {
    if (toDeg(radius) <= 0) {
      radius = toPreciseUnit(0.1, MM);
    }
    var rpm = spindleSpeed; // rev/min
    if (currentSection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
      var O = 2 * Math.PI * radius; // in/rev
      rpm = tool.surfaceSpeed / O; // in/min div in/rev => rev/min
    }
    return highFeedrate / rpm; // in/min div rev/min => in/rev
  }
  return highFeedrate;
}

function onRapid(_x, _y, _z) {
  if (machineState.useXZCMode) {
    var start = getCurrentPosition();
    var dxy = getModulus(_x - start.x, _y - start.y);
    if (true || (dxy < getTolerance())) {
      var x = xOutput.format(getModulus(_x, _y));
      var c = cOutput.format(getCWithinRange(_x, _y, cOutput.getCurrent()));
      var z = zOutput.format(_z);
      if (pendingRadiusCompensation >= 0) {
        error(localize("Radius compensation mode cannot be changed at rapid traversal."));
        return;
      }
      if (forceRewind) {
        rewindTable(start, _z, cOutput.getCurrent(), highFeedrate, false);
      }
      writeBlock(gMotionModal.format(0), x, c, z);
      forceFeed();
      return;
    }

    onExpandedLinear(_x, _y, _z, highFeedrate);
    return;
  }

  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var primarySpindle = currentSection.spindle == SPINDLE_PRIMARY;
  if (x || y || z) {
    var useG1 = ((x ? 1 : 0) + (y ? 1 : 0) + (z ? 1 : 0)) > 1;
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      if (useG1) {
        switch (radiusCompensation) {
        case RADIUS_COMPENSATION_LEFT:
          writeBlock(gMotionModal.format(1), gFormat.format(primarySpindle ? 41 : 42), x, y, z, getFeed(getHighfeedrate(_x)));
          break;
        case RADIUS_COMPENSATION_RIGHT:
          writeBlock(gMotionModal.format(1), gFormat.format(primarySpindle ? 42 : 41), x, y, z, getFeed(getHighfeedrate(_x)));
          break;
        default:
          writeBlock(gMotionModal.format(1), gFormat.format(40), x, y, z, getFeed(getHighfeedrate(_x)));
        }
      } else {
        switch (radiusCompensation) {
        case RADIUS_COMPENSATION_LEFT:
          writeBlock(gMotionModal.format(0), gFormat.format(primarySpindle ? 41 : 42), x, y, z);
          break;
        case RADIUS_COMPENSATION_RIGHT:
          writeBlock(gMotionModal.format(0), gFormat.format(primarySpindle ? 42 : 41), x, y, z);
          break;
        default:
          writeBlock(gMotionModal.format(0), gFormat.format(40), x, y, z);
        }
      }
    }
    if (false) {
      // axes are not synchronized
      writeBlock(gMotionModal.format(1), x, y, z, getFeed(getHighfeedrate(_x)));
      resetFeed = false;
    } else {
      writeBlock(gMotionModal.format(0), x, y, z);
      // forceFeed();
    }
  }
}

/** Calculate the distance of a point to a line segment. */
function pointLineDistance(startPt, endPt, testPt) {
  var delta = Vector.diff(endPt, startPt);
  distance = Math.abs(delta.y * testPt.x - delta.x * testPt.y + endPt.x * startPt.y - endPt.y * startPt.x) /
    Math.sqrt(delta.y * delta.y + delta.x * delta.x); // distance from line to point
  if (distance < 1e-4) { // make sure point is in line segment
    var moveLength = Vector.diff(endPt, startPt).length;
    var startLength = Vector.diff(startPt, testPt).length;
    var endLength = Vector.diff(endPt, testPt).length;
    if ((startLength > moveLength) || (endLength > moveLength)) {
      distance = Math.min(startLength, endLength);
    }
  }
  return distance;
}

/** Refine segment for XC mapping. */
function refineSegmentXC(startX, startC, endX, endC, maximumDistance) {
  var rotary = machineConfiguration.getAxisU(); // C-axis
  var startPt = rotary.getAxisRotation(startC).multiply(new Vector(startX, 0, 0));
  var endPt = rotary.getAxisRotation(endC).multiply(new Vector(endX, 0, 0));

  var testX = startX + (endX - startX) / 2; // interpolate as the machine
  var testC = startC + (endC - startC) / 2;
  var testPt = rotary.getAxisRotation(testC).multiply(new Vector(testX, 0, 0));

  var delta = Vector.diff(endPt, startPt);
  var distf = pointLineDistance(startPt, endPt, testPt);

  if (distf > maximumDistance) {
    return false; // out of tolerance
  } else {
    return true;
  }
}

function rewindTable(startXYZ, currentZ, rewindC, feed, retract) {
  if (!cFormat.areDifferent(rewindC, cOutput.getCurrent())) {
    error(localize("Rewind position not found."));
    return;
  }
  writeComment("Rewind of C-axis, make sure retracting is possible.");
  onCommand(COMMAND_STOP);
  if (retract) {
    writeBlock(gMotionModal.format(1), zOutput.format(currentSection.getInitialPosition().z), getFeed(feed));
  }
  writeBlock(getCode("DISENGAGE_C_AXIS"));
  writeBlock(getCode("ENGAGE_C_AXIS"));
  gMotionModal.reset();
  xOutput.reset();
  startSpindle(false);
  if (retract) {
    var x = getModulus(startXYZ.x, startXYZ.y);
    if (getProperty("rapidRewinds")) {
      writeBlock(gMotionModal.format(1), xOutput.format(x), getFeed(highFeedrate));
      writeBlock(gMotionModal.format(0), cOutput.format(rewindC));
    } else {
      writeBlock(gMotionModal.format(1), xOutput.format(x), cOutput.format(rewindC), getFeed(highFeedrate));
    }
    writeBlock(gMotionModal.format(1), zOutput.format(startXYZ.z), getFeed(feed));
  }
  setCoolant(tool.coolant, machineState.currentTurret);
  forceRewind = false;
  writeComment("End of rewind");
}

function onLinear(_x, _y, _z, feed) {
  if (machineState.useXZCMode) {
    if (pendingRadiusCompensation >= 0) {
      error(subst(localize("Radius compensation is not supported by using XZC mode for operation \"%1\"."), getOperationComment()));
      return;
    }
    if (maximumCircularSweep > toRad(179)) {
      error(localize("Maximum circular sweep must be below 179 degrees."));
      return;
    }

    var localTolerance = getTolerance() / 4;

    var startXYZ = getCurrentPosition();
    var startX = getModulus(startXYZ.x, startXYZ.y);
    var startZ = startXYZ.z;
    var startC = cOutput.getCurrent();

    var endXYZ = new Vector(_x, _y, _z);
    var endX = getModulus(endXYZ.x, endXYZ.y);
    var endZ = endXYZ.z;
    var endC = getCWithinRange(endXYZ.x, endXYZ.y, startC);

    var currentXYZ = endXYZ; var currentX = endX; var currentZ = endZ; var currentC = endC;
    var centerXYZ = machineConfiguration.getAxisU().getOffset();

    var refined = true;
    var crossingRotary = false;
    forceOptimized = false; // tool tip is provided to DPM calculations
    while (refined) { // stop if we dont refine
      // check if we cross center of rotary axis
      var _start = new Vector(startXYZ.x, startXYZ.y, 0);
      var _current = new Vector(currentXYZ.x, currentXYZ.y, 0);
      var _center = new Vector(centerXYZ.x, centerXYZ.y, 0);
      if ((xFormat.getResultingValue(pointLineDistance(_start, _current, _center)) == 0) &&
          (xFormat.getResultingValue(Vector.diff(_start, _center).length) != 0) &&
          (xFormat.getResultingValue(Vector.diff(_current, _center).length) != 0)) {
        var ratio = Vector.diff(_center, _start).length / Vector.diff(_current, _start).length;
        currentXYZ = centerXYZ;
        currentXYZ.z = startZ + (endZ - startZ) * ratio;
        currentX = getModulus(currentXYZ.x, currentXYZ.y);
        currentZ = currentXYZ.z;
        currentC = startC;
        crossingRotary = true;
      } else { // check if move is out of tolerance
        refined = false;
        while (!refineSegmentXC(startX, startC, currentX, currentC, localTolerance)) { // move is out of tolerance
          refined = true;
          currentXYZ = Vector.lerp(startXYZ, currentXYZ, 0.75);
          currentX = getModulus(currentXYZ.x, currentXYZ.y);
          currentZ = currentXYZ.z;
          currentC = getCWithinRange(currentXYZ.x, currentXYZ.y, startC);
          if (Vector.diff(startXYZ, currentXYZ).length < 1e-5) { // back to start point, output error
            if (forceRewind) {
              break;
            } else {
              warning(localize("Linear move cannot be mapped to rotary XZC motion."));
              break;
            }
          }
        }
      }

      currentC = getCWithinRange(currentXYZ.x, currentXYZ.y, startC);
      if (forceRewind) {
        var rewindC = getCClosest(startXYZ.x, startXYZ.y, currentC);
        xOutput.reset(); // force X for repositioning
        rewindTable(startXYZ, currentZ, rewindC, feed, true);
      }
      var x = xOutput.format(currentX);
      var c = cOutput.format(currentC);
      var z = zOutput.format(currentZ);
      if (x || c || z) {
        writeBlock(gMotionModal.format(1), x, c, z, getFeed(feed));
      }
      setCurrentPosition(currentXYZ);
      if (crossingRotary) {
        writeBlock(gMotionModal.format(1), cOutput.format(endC), getFeed(feed)); // rotate at X0 with endC
        forceFeed();
      }
      startX = currentX; startZ = currentZ; startC = crossingRotary ? endC : currentC; startXYZ = currentXYZ; // loop start point
      currentX = endX; currentZ = endZ; currentC = endC; currentXYZ = endXYZ; // loop end point
      crossingRotary = false;
    }
    forceOptimized = undefined;
    return;
  }

  if (isSpeedFeedSynchronizationActive()) {
    resetFeed = true;
    var threadPitch = getParameter("operation:threadPitch");
    var threadsPerInch = 1.0 / threadPitch; // per mm for metric
    var pitchLetter;
    var xLength = Math.abs(xFormat.format(_x) - xFormat.format(xOutput.getCurrent()));
    var zLength = Math.abs(zFormat.format(_z) - zFormat.format(zOutput.getCurrent()));
    if (xLength > zLength) {
      pitchLetter = "I";
    } else {
      pitchLetter = "K";
    }
    gMotionModal.reset();
    writeBlock(gMotionModal.format(33), xOutput.format(_x), zOutput.format(_z),  pitchLetter + spatialFormat.format(1 / threadsPerInch));
    return;
  }
  if (resetFeed) {
    resetFeed = false;
    forceFeed();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = getFeed(feed);
  var primarySpindle = currentSection.spindle == SPINDLE_PRIMARY;

  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      writeBlock(gPlaneModal.format(getPlane()));
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(primarySpindle ? 41 : 42), x, y, z, f);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(primarySpindle ? 42 : 41), x, y, z, f);
        break;
      default:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(40), x, y, z, f);
      }
    } else {
      writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), x, y, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), f);
    }
  }
}

function onRapid5D(_x, _y, _z, _a, _b, _c) {
  if (!currentSection.isOptimizedForMachine()) {
    error(localize("Multi-axis motion is not supported for XZC mode."));
    return;
  }
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode cannot be changed at rapid traversal."));
    return;
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(_a);
  var b = bOutput.format(getB(new Vector(_a, _b, _c), currentSection));
  var c = cOutput.format(_c);
  if (true) {
    // axes are not synchronized
    writeBlock(gMotionModal.format(1), x, y, z, a, b, c, getFeed(highFeedrate));
  } else {
    writeBlock(gMotionModal.format(0), x, y, z, a, b, c);
    forceFeed();
  }
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed) {
  if (!currentSection.isOptimizedForMachine()) {
    error(localize("Multi-axis motion is not supported for XZC mode."));
    return;
  }
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for 5-axis move."));
    return;
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(_a);
  var b = bOutput.format(getB(new Vector(_a, _b, _c), currentSection));
  var c = cOutput.format(_c);
  var f = getFeed(feed);

  if (x || y || z || a || b || c) {
    writeBlock(gMotionModal.format(1), x, y, z, a, b, c, f);
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(1), f);
    }
  }
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  if (machineState.useXZCMode) {
    switch (getCircularPlane()) {
    case PLANE_ZX:
      if (!isSpiral()) {
        var c = getCClosest(x, y, cOutput.getCurrent());
        if (!cFormat.areDifferent(c, cOutput.getCurrent())) {
          validate(getCircularSweep() < Math.PI, localize("Circular sweep exceeds limit."));
          var start = getCurrentPosition();
          writeBlock(gPlaneModal.format(18), gMotionModal.format(directionCode), xOutput.format(getModulus(x, y)), cOutput.format(c), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
          return;
        }
      }
      break;
    case PLANE_XY:
      var d2 = center.x * center.x + center.y * center.y;
      if (d2 < 1e-6) { // center is on rotary axis
        var c = getCWithinRange(x, y, cOutput.getCurrent(), !clockwise);
        writeBlock(gMotionModal.format(1), xOutput.format(getModulus(x, y)), cOutput.format(c), zOutput.format(z), getFeed(feed));
        return;
      }
      break;
    }
    
    linearize(getTolerance() / 2);
    return;
  }

  if (isSpeedFeedSynchronizationActive()) {
    error(localize("Speed-feed synchronization is not supported for circular moves."));
    return;
  }

  var start = getCurrentPosition();
  var turns = useArcTurn ? Math.floor(Math.abs(getCircularSweep()) / (2 * Math.PI)) : 0; // full turns
  var directionCode = (currentSection.spindle == SPINDLE_PRIMARY) ? (clockwise ? 2 : 3) : (clockwise ? 3 : 2);

  if (isFullCircle()) {
    if (isHelical()) {
      linearize(tolerance);
      return;
    }
    if (turns > 1) {
      error(localize("Multiple turns are not supported."));
      return;
    }
    // G90/G91 are dont care when we do not used XYZ
    switch (getCircularPlane()) {
    case PLANE_XY:
      if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
        if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 17)) {
          error(localize("Plane cannot be changed when radius compensation is active."));
          return;
        }
      }
      writeBlock(gMotionModal.format(directionCode), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      break;
    case PLANE_ZX:
      if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
        if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 18)) {
          error(localize("Plane cannot be changed when radius compensation is active."));
          return;
        }
      }
      writeBlock(gMotionModal.format(directionCode), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    case PLANE_YZ:
      if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
        if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 19)) {
          error(localize("Plane cannot be changed when radius compensation is active."));
          return;
        }
      }
      writeBlock(gMotionModal.format(directionCode), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else if (!getProperty("useRadius")) { // IJK mode
    switch (getCircularPlane()) {
    case PLANE_XY:
      if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
        if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 17)) {
          error(localize("Plane cannot be changed when radius compensation is active."));
          return;
        }
      }
      if (turns > 0) {
        writeBlock(gAbsIncModal.format(90), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed), "TURN=" + turns);
      } else {
        writeBlock(gAbsIncModal.format(90), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      }
      break;
    case PLANE_ZX:
      if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
        if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 18)) {
          error(localize("Plane cannot be changed when radius compensation is active."));
          return;
        }
      }
      if (turns > 0) {
        writeBlock(gAbsIncModal.format(90), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed), "TURN=" + turns);
      } else {
        writeBlock(gAbsIncModal.format(90), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      }
      break;
    case PLANE_YZ:
      if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
        if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 19)) {
          error(localize("Plane cannot be changed when radius compensation is active."));
          return;
        }
      }
      if (turns > 0) {
        writeBlock(gAbsIncModal.format(90), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed), "TURN=" + turns);
      } else {
        writeBlock(gAbsIncModal.format(90), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      }
      break;
    default:
      linearize(tolerance);
    }
  } else { // use radius mode
    var r = getCircularRadius();
    if (toDeg(getCircularSweep()) > (180 + 1e-9)) {
      r = -r; // allow up to <360 deg arcs
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      forceXYZ();
      writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "CR=" + spatialFormat.format(r), getFeed(feed));
      break;
    case PLANE_ZX:
      forceXYZ();
      writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "CR=" + spatialFormat.format(r), getFeed(feed));
      break;
    case PLANE_YZ:
      forceXYZ();
      writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "CR=" + spatialFormat.format(r), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

function writeCycleClearance() {
  if (gotBAxis) {
    return;
  } else {
    switch (gPlaneModal.getCurrent()) {
    case 17:
      writeBlock(gMotionModal.format(0), zOutput.format(cycle.clearance));
      break;
    case 18:
      writeBlock(gMotionModal.format(0), yOutput.format(cycle.clearance));
      break;
    case 19:
      writeBlock(gMotionModal.format(0), xOutput.format(cycle.clearance));
      break;
    default:
      error(localize("Unsupported drilling orientation."));
      return;
    }
  }
}

function onCycle() {
  if (isSubSpindleCycle && isSubSpindleCycle(cycleType)) {
    error(localize("Stock transfer is not customized for your machine"));
    return;
    /*
    writeln("");
    if (hasParameter("operation-comment")) {
      var comment = getParameter("operation-comment");
      if (comment) {
        writeComment(comment);
      }
    }
    setCoolant(COOLANT_OFF);
    writeRetract(currentSection, true); // retract in X, Y, Z

    // wcs required here
    currentWorkOffset = undefined;
    writeWCS(currentSection);

    writeBlock(gMotionModal.format(0), "B1=" + spatialFormat.format(180), "Y" + yFormat.format(-99));
    bOutput.reset();
    yOutput.reset();
    switch (cycleType) {
    case "secondary-spindle-grab":
      if (cycle.usePartCatcher) {
        engagePartCatcher(true);
      }
      writeBlock(mFormat.format(currentSection.spindle == SPINDLE_PRIMARY ? 326 : 426)); // check if the opposite spindle is empty
      writeBlock(
        getCode(currentSection.spindle == SPINDLE_PRIMARY ? "UNCLAMP_SECONDARY_CHUCK" : "UNCLAMP_PRIMARY_CHUCK"),
        formatComment(currentSection.spindle == SPINDLE_PRIMARY ? "UNCLAMP SECONDARY CHUCK" : "UNCLAMP PRIMARY CHUCK")
      );
      writeBlock(getCode("FEED_MODE_UNIT_REV")); // mm/rev
      if (cycle.stopSpindle) { // no spindle rotation
        writeBlock(conditional(machineState.mainSpindleIsActive, getCode("STOP_MAIN_SPINDLE")));
        writeBlock(conditional(machineState.subSpindleIsActive, getCode("STOP_SUB_SPINDLE")));
        writeBlock("L705(0)   ;ENGAGE C3-AXIS");
        writeBlock("L707(0)   ;ENGAGE C4-AXIS");
      } else { // spindle rotation
        writeBlock(getCode("MAIN_SPINDLE_BRAKE_OFF"));
        writeBlock(getCode("SUB_SPINDLE_BRAKE_OFF"));
        writeBlock("L706         ;DISENGAGE C3-AXIS");
        writeBlock("L708         ;DISENGAGE C4-AXIS");
        writeBlock("S" + mainSpindleAxisName[1] + "=" + rpmFormat.format(cycle.spindleSpeed), tool.clockwise ? getCode("START_MAIN_SPINDLE_CW") : getCode("START_MAIN_SPINDLE_CCW"));
        writeBlock("S" + subSpindleAxisName[1] + "=" +rpmFormat.format(cycle.spindleSpeed), tool.clockwise ? getCode("START_SUB_SPINDLE_CCW") : getCode("START_SUB_SPINDLE_CW")); // inverted
        writeBlock(getCode("SPINDLE_SYNCHRONIZATION_ON") + "(" + abcFormat.format(cycle.spindleOrientation) + ")", formatComment("SPINDLE SYNCHRONIZATION ON")); // Sync spindles
      }
      // writeBlock(getCode("MAINSPINDLE_AIR_BLAST_ON"), formatComment("MAINSPINDLE AIR BLAST ON"));
      // writeBlock(getCode("SUBSPINDLE_AIR_BLAST_ON"), formatComment("SUBSPINDLE AIR BLAST ON"));
      writeBlock(mFormat.format(currentSection.spindle == SPINDLE_PRIMARY ? 307 : 407), formatComment("CLEANING COOLANT ON"));
      onDwell(cycle.dwell);
      gMotionModal.reset();
      writeBlock(conditional(cycle.useMachineFrame, gFormat.format(53)), gMotionModal.format(0), "Z3=" + spatialFormat.format(cycle.feedPosition));

      onDwell(cycle.dwell);
      writeBlock(conditional(cycle.useMachineFrame, gFormat.format(53)), gMotionModal.format(1), "Z3=" + spatialFormat.format(cycle.chuckPosition), getFeed(cycle.feedrate));
      writeBlock(
        getCode(currentSection.spindle == SPINDLE_PRIMARY ? "CLAMP_SECONDARY_CHUCK" : "CLAMP_PRIMARY_CHUCK"),
        formatComment(currentSection.spindle == SPINDLE_PRIMARY ? "CLAMP SECONDARY CHUCK" : "CLAMP PRIMARY CHUCK")
      );
      writeBlock(mFormat.format(currentSection.spindle == SPINDLE_PRIMARY ? 309 : 409), formatComment("CLEANING COOLANT OFF"));
      onDwell(cycle.dwell);
      break;
    case "secondary-spindle-return":
      writeBlock(getCode("FEED_MODE_UNIT_REV")); // mm/rev
      if (cycle.stopSpindle) { // no spindle rotation
        writeBlock(conditional(machineState.mainSpindleIsActive, getCode("STOP_MAIN_SPINDLE")));
        writeBlock(conditional(machineState.subSpindleIsActive, getCode("STOP_SUB_SPINDLE")));
      } else { // spindle rotation
        writeBlock("S" + mainSpindleAxisName[1] + "=" + rpmFormat.format(cycle.spindleSpeed), tool.clockwise ? getCode("START_MAIN_SPINDLE_CW") : getCode("START_MAIN_SPINDLE_CCW"));
        writeBlock("S" + subSpindleAxisName[1] + "=" +rpmFormat.format(cycle.spindleSpeed), tool.clockwise ? getCode("START_SUB_SPINDLE_CCW") : getCode("START_SUB_SPINDLE_CW")); // inverted
      }
      if (!machineState.spindleSynchronizationIsActive) {
        writeBlock(getCode("SPINDLE_SYNCHRONIZATION_ON"), formatComment("SPINDLE SYNCHRONIZATION ON")); // Sync spindles
      }
      switch (cycle.unclampMode) {
      case "unclamp-primary":
        writeBlock(getCode("UNCLAMP_PRIMARY_CHUCK"), formatComment("UNCLAMP PRIMARY CHUCK"));
        break;
      case "unclamp-secondary":
        writeBlock(getCode("UNCLAMP_SECONDARY_CHUCK"), formatComment("UNCLAMP SECONDARY CHUCK"));
        break;
      case "keep-clamped":
        break;
      }
      onDwell(cycle.dwell);
      writeBlock(conditional(cycle.useMachineFrame, gFormat.format(53)), gMotionModal.format(1), "Z3=" + spatialFormat.format(cycle.feedPosition), getFeed(cycle.feedrate));
      writeBlock(gMotionModal.format(0), "Z3=" + spatialFormat.format(1020));
      if (machineState.spindleSynchronizationIsActive) { // spindles are synchronized
        writeBlock(getCode("SPINDLE_SYNCHRONIZATION_OFF"), formatComment("SPINDLE SYNCHRONIZATION OFF")); // disable spindle sync
      }
      break;
    case "secondary-spindle-pull":
      if (cycle.stopSpindle) { // no spindle rotation
        if (machineState.spindleSynchronizationIsActive) { // spindles are synchronized
          writeBlock(getCode("SPINDLE_SYNCHRONIZATION_OFF")); // disable spindle sync
        }
        writeBlock(conditional(machineState.mainSpindleIsActive, getCode("STOP_MAIN_SPINDLE")));
        writeBlock(conditional(machineState.subSpindleIsActive, getCode("STOP_SUB_SPINDLE")));
      } else { // spindle rotation
        writeBlock(sOutput.format(cycle.spindleSpeed), getCode("START_MAIN_SPINDLE_CW"));
        // writeBlock(pOutput.format(cycle.spindleSpeed), mFormat.format(getCode("START_SUB_SPINDLE_CW")));
      }
      writeBlock(getCode("FEED_MODE_UNIT_REV")); // mm/rev
      writeBlock(getCode(currentSection.spindle == SPINDLE_PRIMARY ? "UNCLAMP_PRIMARY_CHUCK" : "UNCLAMP_SECONDARY_CHUCK"));

      onDwell(cycle.dwell);
      writeBlock(gMotionModal.format(1), "Z3=" + spatialFormat.format(cycle.pullingDistance), getFeed(cycle.feedrate));
      writeBlock(getCode(currentSection.spindle == SPINDLE_PRIMARY ? "CLAMP_PRIMARY_CHUCK" : "CLAMP_SECONDARY_CHUCK"));
      onDwell(cycle.dwell);
      if (machineState.spindleSynchronizationIsActive) { // spindles are synchronized
        writeBlock(getCode("SPINDLE_SYNCHRONIZATION_OFF")); // disable spindle sync
      }
      break;
    }
*/
  }

  writeBlock(gPlaneModal.format(getPlane()));
  
  expandCurrentCycle = false;

  if ((cycleType != "tapping") &&
        (cycleType != "right-tapping") &&
        (cycleType != "left-tapping") &&
        (cycleType != "tapping-with-chip-breaking") &&
        (cycleType != "turning-canned-rough")) {
    writeBlock(getFeed(cycle.feedrate));
  }

  var RTP = cycle.clearance; // return plane (absolute)
  var RFP = cycle.stock; // reference plane (absolute)
  var SDIS = cycle.retract - cycle.stock; // safety distance
  var DP = cycle.bottom; // depth (absolute)
  // var DPR = RFP - cycle.bottom; // depth (relative to reference plane)
  var DTB = cycle.dwell;
  var SDIR = tool.clockwise ? 3 : 4; // direction of rotation: M3:3 and M4:4

  switch (cycleType) {
  case "drilling":
    writeCycleClearance();
    writeBlock(
      "MCALL CYCLE81(" + spatialFormat.format(RTP) +
        "," + spatialFormat.format(RFP) +
        "," + spatialFormat.format(SDIS) +
        "," + spatialFormat.format(DP) +
        "," /*+ spatialFormat.format(DPR)*/ + ")"
    );
    break;
  case "counter-boring":
    writeCycleClearance();
    writeBlock(
      "MCALL CYCLE82(" + spatialFormat.format(RTP) +
        "," + spatialFormat.format(RFP) +
        "," + spatialFormat.format(SDIS) +
        "," + spatialFormat.format(DP) +
        "," /*+ spatialFormat.format(DPR)*/ +
        "," + conditional(DTB > 0, secFormat.format(DTB)) + ")"
    );
    break;
  case "chip-breaking":
    
    if (cycle.accumulatedDepth < cycle.depth) {
      expandCurrentCycle = true;
    } else {
      writeCycleClearance();
      var FDEP = cycle.stock - cycle.incrementalDepth;
      var FDPR = cycle.incrementalDepth; // relative to reference plane (unsigned)
      var DAM = 0; // degression (unsigned)
      var DTS = 0; // dwell time at start
      var FRF = 1; // feedrate factor (unsigned)
      var VARI = 0; // chip breaking
      var _AXN = 3; // tool axis
      var _MDEP = cycle.incrementalDepth; // minimum drilling depth
      var _VRT = 0; // retraction distance
      var _DTD = (cycle.dwell != undefined) ? cycle.dwell : 0;
      var _DIS1 = 0; // limit distance

      writeBlock(
        "MCALL CYCLE83(" + spatialFormat.format(RTP) +
          ", " + spatialFormat.format(RFP) +
          ", " + spatialFormat.format(SDIS) +
          ", " + spatialFormat.format(DP) +
          ", " /*+ spatialFormat.format(DPR)*/ +
          ", " + spatialFormat.format(FDEP) +
          ", " /*+ spatialFormat.format(FDPR)*/ +
          ", " + spatialFormat.format(DAM) +
          ", " + /*conditional(DTB > 0, secFormat.format(DTB))*/ // only dwell at bottom
          ", " + conditional(DTS > 0, secFormat.format(DTS)) +
          ", " + spatialFormat.format(FRF) +
          ", " + spatialFormat.format(VARI) +
          ", " + /*_AXN +*/
          ", " + spatialFormat.format(_MDEP) +
          ", " + spatialFormat.format(_VRT) +
          ", " + secFormat.format(_DTD) +
          ", 0" + /*spatialFormat.format(_DIS1) +*/
          ")"
      );
    }
    break;
  case "deep-drilling":
    writeCycleClearance();
    var FDEP = cycle.stock - cycle.incrementalDepth;
    var FDPR = cycle.incrementalDepth; // relative to reference plane (unsigned)
    var DAM = 0; // degression (unsigned)
    var DTS = 0; // dwell time at start
    var FRF = 1; // feedrate factor (unsigned)
    var VARI = 1; // full retract
    var _MDEP = cycle.incrementalDepth; // minimum drilling depth
    var _VRT = 0; // retraction distance
    var _DTD = (cycle.dwell != undefined) ? cycle.dwell : 0;
    var _DIS1 = 0; // limit distance

    writeBlock(
      "MCALL CYCLE83(" + spatialFormat.format(RTP) +
        ", " + spatialFormat.format(RFP) +
        ", " + spatialFormat.format(SDIS) +
        ", " + spatialFormat.format(DP) +
        ", " /*+ spatialFormat.format(DPR)*/ +
        ", " + spatialFormat.format(FDEP) +
        ", " /*+ spatialFormat.format(FDPR)*/ +
        ", " + spatialFormat.format(DAM) +
        ", " + /*conditional(DTB > 0, secFormat.format(DTB)) +*/ // only dwell at bottom
        ", " + conditional(DTS > 0, secFormat.format(DTS)) +
        ", " + spatialFormat.format(FRF) +
        ", " + spatialFormat.format(VARI) +
        ", " + /*_AXN +*/
        ", " + spatialFormat.format(_MDEP) +
        ", " + spatialFormat.format(_VRT) +
        ", " + secFormat.format(_DTD) +
        ", 0" + /*spatialFormat.format(_DIS1) +*/
        ")"
    );
    break;
  case "tapping":
  case "left-tapping":
  case "right-tapping":
    writeCycleClearance();
    var SDAC = SDIR; // direction of rotation after end of cycle
    var MPIT = 0; // thread pitch as thread size
    var PIT = ((tool.type == TOOL_TAP_LEFT_HAND) ? -1 : 1) * tool.threadPitch; // thread pitch
    var POSS = 0; // spindle position for oriented spindle stop in cycle (in degrees)
    var SST = spindleSpeed; // speed for tapping
    var SST1 = spindleSpeed; // speed for return
    writeBlock(
      "MCALL CYCLE84(" + spatialFormat.format(RTP) +
        ", " + spatialFormat.format(RFP) +
        ", " + spatialFormat.format(SDIS) +
        ", " + spatialFormat.format(DP) +
        ", " /*+ spatialFormat.format(DPR)*/ +
        ", " + conditional(DTB > 0, secFormat.format(DTB)) +
        ", " + spatialFormat.format(SDAC) +
        ", " /*+ spatialFormat.format(MPIT)*/ +
        ", " + spatialFormat.format(PIT) +
        ", " + spatialFormat.format(POSS) +
        ", " + spatialFormat.format(SST) +
        ", " + spatialFormat.format(SST1) + ")"
    );
    break;
  case "tapping-with-chip-breaking":
    writeCycleClearance();
    var SDAC = SDIR; // direction of rotation after end of cycle
    var MPIT = 0; // thread pitch as thread size
    var PIT = ((tool.type == TOOL_TAP_LEFT_HAND) ? -1 : 1) * tool.threadPitch; // thread pitch
    var POSS = 0; // spindle position for oriented spindle stop in cycle (in degrees)
    var SST = spindleSpeed; // speed for tapping
    var SST1 = spindleSpeed; // speed for return
    var _AXN = 0; // tool axis
    var _PTAB = 0; // must be 0
    var _TECHNO = 0; // technology settings
    var _VARI = 1; // machining type: 0 = tapping full depth, 1 = tapping partial retract, 2 = tapping full retract
    var _DAM = cycle.incrementalDepth; // incremental depth
    var _VRT = cycle.chipBreakDistance; // retract distance for chip breaking
  
    writeBlock(
      "MCALL CYCLE84(" + spatialFormat.format(RTP) +
        ", " + spatialFormat.format(RFP) +
        ", " + spatialFormat.format(SDIS) +
        ", " + spatialFormat.format(DP) +
        ", " /*+ spatialFormat.format(DPR)*/ +
        ", " + conditional(DTB > 0, secFormat.format(DTB)) +
        ", " + spatialFormat.format(SDAC) +
        ", " + spatialFormat.format(MPIT) +
        ", " + spatialFormat.format(PIT) +
        ", " + spatialFormat.format(POSS) +
        ", " + spatialFormat.format(SST) +
        ", " + spatialFormat.format(SST1) +
        ", " + spatialFormat.format(_AXN) +
        ", " + spatialFormat.format(_PTAB) +
        ", " + spatialFormat.format(_TECHNO) +
        ", " + spatialFormat.format(_VARI) +
        ", " + spatialFormat.format(_DAM) +
        ", " + spatialFormat.format(_VRT) + ")"
    );
    break;
  case "reaming":
    writeCycleClearance();
    var FFR = cycle.feedrate;
    var RFF = cycle.retractFeedrate;
    writeBlock(
      "MCALL CYCLE85(" + spatialFormat.format(RTP) +
        ", " + spatialFormat.format(RFP) +
        ", " + spatialFormat.format(SDIS) +
        ", " + spatialFormat.format(DP) +
        ", " /*+ spatialFormat.format(DPR)*/ +
        ", " + conditional(DTB > 0, secFormat.format(DTB)) +
        ", " + spatialFormat.format(FFR) +
        ", " + spatialFormat.format(RFF) + ")"
    );
    break;
  case "stop-boring":
    if (cycle.dwell > 0) {
      expandCurrentCycle = true;
    } else {
      writeCycleClearance();
      writeBlock(
        "MCALL CYCLE87(" + spatialFormat.format(RTP) +
          ", " + spatialFormat.format(RFP) +
          ", " + spatialFormat.format(SDIS) +
          ", " + spatialFormat.format(DP) +
          ", " /*+ spatialFormat.format(DPR)*/ +
          ", " + SDIR + ")"
      );
    }
    break;
  case "fine-boring":
    writeCycleClearance();
    var RPA = 0; // return path in abscissa of the active plane (enter incrementally with)
    var RPO = 0; // return path in the ordinate of the active plane (enter incrementally sign)
    var RPAP = 0; // return plane in the applicate (enter incrementally with sign)
    var POSS = 0; // spindle position for oriented spindle stop in cycle (in degrees)
    writeBlock(
      "MCALL CYCLE86(" + spatialFormat.format(RTP) +
        ", " + spatialFormat.format(RFP) +
        ", " + spatialFormat.format(SDIS) +
        ", " + spatialFormat.format(DP) +
        ", " /*+ spatialFormat.format(DPR)*/ +
        ", " + conditional(DTB > 0, secFormat.format(DTB)) +
        ", " + SDIR +
        ", " + spatialFormat.format(RPA) +
        ", " + spatialFormat.format(RPO) +
        ", " + spatialFormat.format(RPAP) +
        ", " + spatialFormat.format(POSS) + ")"
    );
    break;
  case "back-boring":
    expandCurrentCycle = true;
    break;
  case "manual-boring":
    writeCycleClearance();
    writeBlock(
      "MCALL CYCLE88(" + spatialFormat.format(RTP) +
        ", " + spatialFormat.format(RFP) +
        ", " + spatialFormat.format(SDIS) +
        ", " + spatialFormat.format(DP) +
        ", " /*+ spatialFormat.format(DPR)*/ +
        ", " + conditional(DTB > 0, secFormat.format(DTB)) +
        ", " + SDIR + ")"
    );
    break;
  case "boring":
    writeCycleClearance();
    // retract feed is ignored
    writeBlock(
      "MCALL CYCLE89(" + spatialFormat.format(RTP) +
        ", " + spatialFormat.format(RFP) +
        ", " + spatialFormat.format(SDIS) +
        ", " + spatialFormat.format(DP) +
        ", " /*+ spatialFormat.format(DPR)*/ +
        ", " + conditional(DTB > 0, secFormat.format(DTB)) + ")"
    );
    break;
  default:
    expandCurrentCycle = true;
  }
    
  if (cycleType == "stock-transfer") {
    error(localize("Stock transfer is not supported. Requires machine specific customization."));
    return;
  }
}

var expandCurrentCycle = false;

function onCyclePoint(x, y, z) {
  if (expandCurrentCycle) {
    expandCyclePoint(x, y, z);
  } else if (machineState.useXZCMode) {
    forceXYZ();
    onCommand(COMMAND_UNLOCK_MULTI_AXIS);
    cOutput.reset();
    var _x = xOutput.format(getModulus(x, y));
    var _c = cOutput.format(getCWithinRange(x, y, cOutput.getCurrent()));
    // writeBlock(_x, _c, getCode(currentSection.spindle == SPINDLE_PRIMARY ? "MAIN_SPINDLE_BRAKE_ON" : "SUB_SPINDLE_BRAKE_ON"));
    writeBlock(_x, _c);
  } else {
    forceXYZ();
    var _x = xOutput.format(x);
    var _y = yOutput.format(y);
    var _z = zOutput.format(z);
    switch (gPlaneModal.getCurrent()) {
    case 17: // XY
      writeBlock(_x, _y);
      break;
    case 18: // ZX
      writeBlock(_z, _x);
      break;
    case 19: // YZ
      writeBlock(_y, _z);
      break;
    }
  }
}

function onCycleEnd() {
  if (!expandCurrentCycle) {
    writeBlock("MCALL"); // end modal cycle
  }
  zOutput.reset();
  onCommand(COMMAND_UNLOCK_MULTI_AXIS);
}

var saveShowSequenceNumbers = true;

function onCyclePath() {
  saveShowSequenceNumbers = getProperty("showSequenceNumbers");

  // buffer all paths and stop feeds being output
  feedOutput.disable();
  setProperty("showSequenceNumbers", false);
  redirectToBuffer();
  //Adding indice in cases of multiple canned cycles calls
  writeBlock("START" + integerFormat.format(currentSection.getId()) + ":");
  gMotionModal.reset();
  xOutput.reset();
  zOutput.reset();
}

function onCyclePathEnd() {
  writeBlock("END" + integerFormat.format(currentSection.getId()) + ":");
  setProperty("showSequenceNumbers", saveShowSequenceNumbers); // reset property to initial state
  feedOutput.enable();
  var cyclePath = String(getRedirectionBuffer()).split(EOL); // get cycle path from buffer
  closeRedirection();
  for (line in cyclePath) { // remove empty elements
    if (cyclePath[line] == "") {
      cyclePath.splice(line);
    }
  }

  var outsideProfiling = cycle.turningMode == 0;
  var verticalPasses;
  if (cycle.profileRoughingCycle == 0) {
    verticalPasses = false;
  } else if (cycle.profileRoughingCycle == 1) {
    verticalPasses = true;
  } else {
    error(localize("Unsupported passes type."));
    return;
  }

  // output cycle data
  switch (cycleType) {
  case "turning-canned-rough":
    var NPP = "\"" + "START" + integerFormat.format(currentSection.getId()) + ":END" + integerFormat.format(currentSection.getId()) + "\""; // Name of contour subroutine
    var MID = spatialFormat.format(cycle.depthOfCut); // Infeed depth (enter without sign)
    //Siemens doesn't use sign for allowance
    var FALZ = Math.abs(spatialFormat.format(cycle.zStockToLeave)); // Finishing allowance in the longitudinal axis (enter without sign)
    var FALX = Math.abs(xFormat.format(cycle.xStockToLeave)); // Finishing allowance in the transverse axis (enter without sign)
    var FAL = 0; // Finishing allowance suitable for contour (enter without sign)
    var FF1 = feedFormat.format(cycle.cutfeedrate); // Feedrate for roughing without relief cut
    var FF2 = feedFormat.format(cycle.cutfeedrate); //Feedrate for plunging into relief cut element
    var FF3 = feedFormat.format(cycle.cutfeedrate); // Feedrate for finishing cut
    var VARI = outsideProfiling ? (verticalPasses ? 2 : 1) : (verticalPasses ? 4 : 3); // Machining typeRange of values: 1 ... 12
    var DT = 0; // Dwell time fore chip breaking when roughing
    var DAM = 0; // Path length after which each roughing step is interrupted for chip breaking
    var _VRT = spatialFormat.format(cycle.retractLength); // Lift-off distance from contour when roughing, incremental (to be entered without sign)

    writeBlock(
      "CYCLE95(" + NPP + ", " + MID + ", " + FALZ + ", " + FALX + ", " + FAL + ", " + FF1 + ", " + FF2 +
        ", " + FF3 + ", " + VARI + ", " + DT + ", " + DAM + ", " + _VRT + ")"
    );
    break;
  default:
    error(localize("Unsupported turning canned cycle."));
  }
  
  for (var i = 0; i < cyclePath.length; ++i) {
    writeBlock(cyclePath[i]); // output cycle path
    setProperty("showSequenceNumbers", saveShowSequenceNumbers); // reset property to initial state
  }
}

function onPassThrough(text) {
  writeBlock(text);
}

function onParameter(name, value) {
  var invalid = false;
  switch (name) {
  case "action":
    if (String(value).toUpperCase() == "USEXZCMODE") {
      forceXZCMode = true;
      forcePolarMode = false;
    } else if (String(value).toUpperCase() == "USEPOLARMODE") {
      forcePolarMode = true;
      forceXZCMode = false;
    } else {
      invalid = true;
    }
  }
  if (invalid) {
    error(localize("Invalid action parameter: ") + value);
    return;
  }
}

var currentCoolantMode = COOLANT_OFF;
var coolantOff = undefined;

function setCoolant(coolant, turret) {
  var coolantCodes = getCoolantCodes(coolant, gotMultiTurret ? turret : 1);
  if (Array.isArray(coolantCodes)) {
    for (var c in coolantCodes) {
      writeBlock(coolantCodes[c]);
    }
    return undefined;
  }
  return coolantCodes;
}

function getCoolantCodes(coolant, turret) {
  if (!coolants) {
    error(localize("Coolants have not been defined."));
  }
  if (!coolantOff) { // use the default coolant off command when an 'off' value is not specified for the previous coolant mode
    coolantOff = coolants.off;
  }

  if (coolant == currentCoolantMode) {
    return undefined; // coolant is already active
  }

  var m;
  if (coolant == COOLANT_OFF) {
    m = coolantOff;
    coolantOff = coolants.off;
  }

  switch (coolant) {
  case COOLANT_FLOOD:
    if (!coolants.flood) {
      break;
    }
    m = (turret == 1) ? coolants.flood.turret1.on : coolants.flood.turret2.on;
    coolantOff = (turret == 1) ? coolants.flood.turret1.off : coolants.flood.turret2.off;
    break;
  case COOLANT_THROUGH_TOOL:
    if (!coolants.throughTool) {
      break;
    }
    m = (turret == 1) ? coolants.throughTool.turret1.on : coolants.throughTool.turret2.on;
    coolantOff = (turret == 1) ? coolants.throughTool.turret1.off : coolants.throughTool.turret2.off;
    break;
  case COOLANT_AIR:
    if (!coolants.air) {
      break;
    }
    m = (turret == 1) ? coolants.air.turret1.on : coolants.air.turret2.on;
    coolantOff = (turret == 1) ? coolants.air.turret1.off : coolants.air.turret2.off;
    break;
  case COOLANT_AIR_THROUGH_TOOL:
    if (!coolants.airThroughTool) {
      break;
    }
    m = (turret == 1) ? coolants.airThroughTool.turret1.on : coolants.airThroughTool.turret2.on;
    coolantOff = (turret == 1) ? coolants.airThroughTool.turret1.off : coolants.airThroughTool.turret2.off;
    break;
  case COOLANT_FLOOD_MIST:
    if (!coolants.floodMist) {
      break;
    }
    m = (turret == 1) ? coolants.floodMist.turret1.on : coolants.floodMist.turret2.on;
    coolantOff = (turret == 1) ? coolants.floodMist.turret1.off : coolants.floodMist.turret2.off;
    break;
  case COOLANT_MIST:
    if (!coolants.mist) {
      break;
    }
    m = (turret == 1) ? coolants.mist.turret1.on : coolants.mist.turret2.on;
    coolantOff = (turret == 1) ? coolants.mist.turret1.off : coolants.mist.turret2.off;
    break;
  case COOLANT_SUCTION:
    if (!coolants.suction) {
      break;
    }
    m = (turret == 1) ? coolants.suction.turret1.on : coolants.suction.turret2.on;
    coolantOff = (turret == 1) ? coolants.suction.turret1.off : coolants.suction.turret2.off;
    break;
  case COOLANT_FLOOD_THROUGH_TOOL:
    if (!coolants.floodThroughTool) {
      break;
    }
    m = (turret == 1) ? coolants.floodThroughTool.turret1.on : coolants.floodThroughTool.turret2.on;
    coolantOff = (turret == 1) ? coolants.floodThroughTool.turret1.off : coolants.floodThroughTool.turret2.off;
    break;
  }
  
  if (!m) {
    onUnsupportedCoolant(coolant);
    m = 9;
  }

  if (m) {
    currentCoolantMode = coolant;
    var multipleCoolantBlocks = new Array(); // create a formatted array to be passed into the outputted line
    if (Array.isArray(m)) {
      for (var i in m) {
        multipleCoolantBlocks.push(mFormat.format(m[i]));
      }
    } else {
      multipleCoolantBlocks.push(mFormat.format(m));
    }
    return multipleCoolantBlocks; // return the single formatted coolant value
  }
  return undefined;
}

function onCommand(command) {
  switch (command) {
  case COMMAND_COOLANT_OFF:
    setCoolant(COOLANT_OFF, machineState.currentTurret);
    break;
  case COMMAND_COOLANT_ON:
    setCoolant(COOLANT_FLOOD, machineState.currentTurret);
    break;
  case COMMAND_START_SPINDLE:
    break;
  case COMMAND_STOP_SPINDLE:
    break;
  case COMMAND_SPINDLE_CLOCKWISE:
    if (currentSection.getType() == TYPE_TURNING || machineState.axialCenterDrilling) {
      writeBlock(getCode("START_MAIN_SPINDLE_CW"));
    } else {
      writeBlock(getCode("START_LIVE_TOOL_CW"));
    }
    break;
  case COMMAND_SPINDLE_COUNTERCLOCKWISE:
    if (currentSection.getType() == TYPE_TURNING || machineState.axialCenterDrilling) {
      writeBlock(getCode("START_MAIN_SPINDLE_CCW"));
    } else {
      writeBlock(getCode("START_LIVE_TOOL_CCW"));
    }
    break;
  case COMMAND_LOCK_MULTI_AXIS:
    if (currentSection.spindle == SPINDLE_PRIMARY) {
      writeBlock(getCode("MAIN_SPINDLE_BRAKE_ON"));
    } else {
      writeBlock(getCode("SUB_SPINDLE_BRAKE_ON"));
    }
    break;
  case COMMAND_UNLOCK_MULTI_AXIS:
    if (currentSection.spindle == SPINDLE_PRIMARY) {
      writeBlock(getCode("MAIN_SPINDLE_BRAKE_OFF"));
    } else {
      writeBlock(getCode("SUB_SPINDLE_BRAKE_OFF"));
    }
    break;
  case COMMAND_START_CHIP_TRANSPORT:
    writeBlock(mFormat.format(31));
    break;
  case COMMAND_STOP_CHIP_TRANSPORT:
    writeBlock(mFormat.format(33));
    break;
  case COMMAND_OPEN_DOOR:
    break;
  case COMMAND_CLOSE_DOOR:
    break;
  case COMMAND_BREAK_CONTROL:
    break;
  case COMMAND_TOOL_MEASURE:
    break;
  case COMMAND_ACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    break;
  case COMMAND_DEACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    break;
  case COMMAND_STOP:
    writeBlock(mFormat.format(0));
    forceSpindleSpeed = true;
    break;
  case COMMAND_OPTIONAL_STOP:
    writeBlock(mFormat.format(1));
    break;
  case COMMAND_END:
    writeBlock(mFormat.format(2));
    break;
  case COMMAND_ORIENTATE_SPINDLE:
    /*
    if (currentSection.getType() == TYPE_TURNING) {
      if (currentSection.spindle == SPINDLE_PRIMARY) {
        writeBlock(mFormat.format(19)); // use P or R to set angle (optional)
      } else {
        writeBlock(mFormat.format(119));
      }
    } else {
      if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))) {
        writeBlock(mFormat.format(19)); // use P or R to set angle (optional)
      } else if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, -1))) {
        writeBlock(mFormat.format(119));
      } else {
        error(localize("Spindle orientation is not supported for live tooling."));
        return;
      }
    }
*/
    break;
  default:
    onUnsupportedCommand(command);
  }
}

function engagePartCatcher(engage) {
  if (engage) {
    // catch part here
    writeBlock(getCode("PART_CATCHER_ON"), formatComment(localize("PART CATCHER ON")));
  } else {
    onCommand(COMMAND_COOLANT_OFF);
    writeRetract(X);
    writeRetract(Y);
    writeRetract(Z);
    writeBlock(getCode("PART_CATCHER_OFF"), formatComment(localize("PART CATCHER OFF")));
    forceXYZ();
  }
}

function onSectionEnd() {

  if (currentSection.partCatcher) {
    engagePartCatcher(false);
  }

  if (machineState.usePolarMode) {
    setPolarMode(false); // disable polar interpolation mode
  }

  // cancel SFM mode to preserve spindle speed
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    startSpindle(true, getFramePosition(currentSection.getFinalPosition()));
  }

  if (((getCurrentSectionId() + 1) >= getNumberOfSections()) ||
      (tool.number != getNextSection().getTool().number)) {
    onCommand(COMMAND_BREAK_CONTROL);
  }

  if (hasNextSection()) {
    if (getNextSection().getTool().coolant != currentSection.getTool().coolant) {
      setCoolant(COOLANT_OFF, machineState.currentTurret);
    }
  }

  if (true) {
    if (isRedirecting()) {
      if (firstPattern) {
        var finalPosition = getFramePosition(currentSection.getFinalPosition());
        var abc;
        if (currentSection.isMultiAxis() && machineConfiguration.isMultiAxisConfiguration()) {
          abc = currentSection.getFinalToolAxisABC();
        } else {
          abc = currentWorkPlaneABC;
        }
        if (abc == undefined) {
          abc = new Vector(0, 0, 0);
        }
        // setAbsoluteMode(finalPosition, abc);
        subprogramEnd();
      }
    }
  }

  forceAny();
  forceXZCMode = false;
  forcePolarMode = false;
}

function onClose() {
  writeln("");

  optionalSection = false;

  onCommand(COMMAND_COOLANT_OFF);

  if (getProperty("gotChipConveyor")) {
    onCommand(COMMAND_STOP_CHIP_TRANSPORT);
  }

  forceWorkPlane();

  writeRetract(X);
  writeRetract(Y);
  writeRetract(Z);

  if (machineState.liveToolIsActive) {
    writeBlock(getCode("STOP_LIVE_TOOL"));
  } else if (machineState.mainSpindleIsActive) {
    writeBlock(getCode("STOP_MAIN_SPINDLE"));
  } else if (machineState.subSpindleIsActive) {
    writeBlock(getCode("STOP_SUB_SPINDLE"));
  } else {
    error(localize("Unknown machineState."));
    return;
  }

  if (machineState.tailstockIsActive) {
    writeBlock(getCode("TAILSTOCK_OFF"));
  }
  forceWorkPlane();

  writeBlock(getCode("DISENGAGE_C_AXIS"));

  if (gotBarFeeder) {
    writeln("");
    writeComment(localize("Bar feed"));
    // specify your code here for bar feeder
  }

  if (gotBAxis) {
    writeBlock("TRANS_OFF");
    writeBlock("ROT");
  }
  
  writeln("");
  onImpliedCommand(COMMAND_END);
  onImpliedCommand(COMMAND_STOP_SPINDLE);
  writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off

  if (subprograms.length > 0) {
    writeln("");
    write(subprograms);
  }
  writeln("%");
}

function getSpindleCode(section) {
  if (section.spindle == SPINDLE_PRIMARY) { // mainspindle
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
      return mainSpindleAxisName[1];
    } else {
      return liveToolSpindleAxisName[1]; // milling live tool
    }
  } else { // subspindle
    if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
      return subSpindleAxisName[1];
    } else {
      return liveToolSpindleAxisName[1]; // milling live tool
    }
  }
}

function getNextToolDescription(description) {
  var currentSectionId = getCurrentSectionId();
  if (currentSectionId < 0) {
    return null;
  }
  for (var i = currentSectionId + 1; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    var sectionTool = section.getTool();
    if (description != sectionTool.description) {
      return sectionTool; // found next tool
    }
  }
  return null; // not found
}

function setProperty(property, value) {
  properties[property].current = value;
}
// <<<<< INCLUDED FROM ../common/jyoti tmc-ax turn mill-turn_Siemens.cps
properties.maximumSpindleSpeed.value = 2500;
