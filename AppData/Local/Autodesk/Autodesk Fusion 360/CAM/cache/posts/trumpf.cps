/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  TRUMPF post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {995D7871-9574-4283-9522-CBD604EBFEB9}
*/

description = "TRUMPF Laser";
vendor = "TRUMPF";
vendorUrl = "http://www.trumpf.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic post for TRUMPF laser cutting.";

extension = "lst";
programNameIsInteger = true;
setCodePage("ascii");

capabilities = CAPABILITY_JET;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = false;
allowedCircularPlanes = undefined; // allow any circular motion

// user-defined properties
properties = {
  separateWordsWithSpace: {
    title: "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  useFeed: {
    title: "Use feed",
    description: "Specifies whether feed codes should be output.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  etchOn: {
    title: "Etch start",
    description: "The outputted string for starting etch toolpaths.",
    type: "string",
    value: "AL012IA0-N2S0-30-2",
    scope: "post"
  },
  vaporizeOn: {
    title: "Vaporize start",
    description: "The outputted string for starting vaporize toolpaths.",
    type: "string",
    value: "AL012IA0-N2S0-30-2",
    scope: "post"
  },
  throughOn: {
    title: "Through start",
    description: "The outputted string for starting through toolpaths.",
    type: "string",
    value: "AL012IA0-N2S0-30-2",
    scope: "post"
  }
};

var gFormat = createFormat({prefix: "G", width: 2, zeropad: true, decimals: 0});
var mFormat = createFormat({prefix: "M", width: 2, zeropad: true, decimals: 0});

var xyzFormat = createFormat({decimals: (unit == MM ? 3 : 4)});
var feedFormat = createFormat({decimals: (unit == MM ? 1 : 2)});
var toolFormat = createFormat({decimals: 0});
var powerFormat = createFormat({decimals: 0});
var secFormat = createFormat({decimals: 3, forceDecimal: true}); // seconds - range 0.001-1000

var xOutput = createVariable({prefix: "X"}, xyzFormat);
var yOutput = createVariable({prefix: "Y"}, xyzFormat);
var zOutput = createVariable({prefix: "Z"}, xyzFormat);
var feedOutput = createVariable({prefix: "F"}, feedFormat);
var sOutput = createVariable({prefix: "S", force: true}, powerFormat);

// circular output
var iOutput = createReferenceVariable({prefix: "I", force: true}, xyzFormat);
var jOutput = createReferenceVariable({prefix: "J", force: true}, xyzFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange: function() {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G93-94
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-21

var WARNING_WORK_OFFSET = 0;

// collected state
var sequenceNumber = 10;
var currentWorkOffset;
var pierceMode;

/**
  Writes the specified block.
*/
function writeBlock() {
  writeWords("N" + sequenceNumber, arguments);
  sequenceNumber += 10;
}

function writeStartBlock() {
  writeWords(arguments);
}

function formatComment(text) {
  return ";" + String(text).replace(/[()]/g, "");
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeBlock(formatComment(text));
}

function getPowerMode(section) {
  var mode;
  switch (section.quality) {
  case 0: // auto
    break;
  case 1: // high
    break;
  case 2: // medium
    break;
  case 3: // low
    break;
  default:
    error(localize("Only Cutting Mode Through-auto and Through-high are supported."));
    return 0;
  }
  return mode;
}

function onOpen() {
  if (!getProperty("useFeed")) {
    feedOutput.disable();
  }
  zOutput.disable();
  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  writeStartBlock("BD");
  if (unit == MM) {
    writeStartBlock("SET_METRIC");
  } else {
    writeStartBlock("SET_INCH");
  }
  writeC();
  writeStartBlock("BEGIN_EINRICHTEPLAN_INFO");
  writeC();
  var unitOutput = "MM";
  writeStartBlock("ZA," + unitOutput + ",22");
  writeStartBlock(unitOutput + ",AT,1,10,1,1,,'DeviceName',,'',T");
  writeStartBlock(unitOutput + ",AT,1,50,1,1,,'Company',,'',T");
  writeStartBlock(unitOutput + ",AT,1,60,1,1,,'ProgName',,'',T");
  writeStartBlock(unitOutput + ",AT,1,70,1,1,,'UserName',,'',T");
  writeStartBlock(unitOutput + ",AT,1,80,1,1,,'Date',,'',T");
  writeStartBlock(unitOutput + ",AT,1,90,1,1,,'OrderName',,'',T");
  writeStartBlock(unitOutput + ",AT,1,100,1,1,,'ProgramRuns',,'',Z");
  writeStartBlock(unitOutput + ",AT,1,120,1,1,,'MemoryRequirement',,'',Z");
  writeStartBlock(unitOutput + ",AT,1,130,1,1,,'MaterialId',,'',T");
  writeStartBlock(unitOutput + ",AT,1,180,1,1,,'FlagTopsProgram',,'Bool',Z");
  writeStartBlock(unitOutput + ",AT,1,190,1,1,,'SetupPlan',,'',T");
  writeStartBlock(unitOutput + ",AT,1,200,1,1,,'StockDesignation',,'',T");
  writeStartBlock(unitOutput + ",AT,1,220,1,1,,'PalletizationMode',,'',Z");
  writeStartBlock(unitOutput + ",AT,1,230,1,1,,'CleanPallet',,'Bool',Z");
  writeStartBlock(unitOutput + ",AT,1,240,1,1,,'CleanSuctionCup',,'bool',Z");
  writeStartBlock(unitOutput + ",AT,1,250,1,1,,'SystemPalletType',,'',T");
  writeStartBlock(unitOutput + ",AT,1,260,1,1,,'PCSMachineTime',,'min',Z");
  writeStartBlock(unitOutput + ",AT,1,270,1,1,,'CuttingLength',,'mm',Z");
  writeStartBlock(unitOutput + ",AT,1,280,1,1,,'MachineViewerName',,'',T");
  writeStartBlock(unitOutput + ",AT,1,300,1,1,,'CheckLevel',,'',Z");
  writeStartBlock(unitOutput + ",AT,1,310,1,1,,'SetupSuppression',,'',Z");
  writeStartBlock(unitOutput + ",AT,1,320,1,1,,'SortMasterBoxSetupConfiguration',,'',Z");
  writeC();
  writeStartBlock("ZA,DA,1");
  var now = new Date();
  var nowDay = now.getDate();
  var nowMonth = now.getMonth() + 1;
  var nowYear = now.getFullYear();
  writeStartBlock("DA,'L20','Trumpf','" + programName + "','','" + nowDay + "/" + nowMonth + "/" + nowYear + "','" + programComment + "',1,2000,'AL',1,'','',1,1,1,'',0,0,'FUSION 360',-1,0,-1");
  writeC();
  writeStartBlock("ENDE_EINRICHTEPLAN_INFO");
  writeC();
  writeStartBlock("BEGIN_GLOBAL_DATASET");
  writeC();
  writeStartBlock("ZA," + unitOutput + ",2");
  writeStartBlock(unitOutput + ",AT,1,10,1,1,,'DataSetType',,'',T");
  writeStartBlock(unitOutput + ",AT,1,20,1,1,,'DataSetName',,'',T");
  writeC();
  writeStartBlock("ZA,DA,1");
  writeStartBlock("DA,'LTT_STAMM','AL012IA0-N2S0-30-2'");
  writeC();
  writeStartBlock("ENDE_GLOBAL_DATASET");
  writeC();
  writeStartBlock("BEGIN_LTT_CALLS");
  writeC();
  writeStartBlock("ZA," + unitOutput + ",1");
  writeStartBlock(unitOutput + ",AT,1,10,1,1,,'DataSetName',,'',T");
  writeC();
  writeStartBlock("ZA,DA,1");
  writeStartBlock("DA,'AL012IA0-N2S0-30-2'");
  writeC();
  writeStartBlock("ENDE_LTT_CALLS");
  writeC();
  writeStartBlock("BEGIN_PROGRAM_PROPERTIES");
  writeC();
  writeStartBlock("ZA," + unitOutput + ",8");
  writeStartBlock(unitOutput + ",AT,1,10,1,1,,'SyncDataChangePierceToCut',,'',Z");
  writeStartBlock(unitOutput + ",AT,1,20,1,1,,'ProgramType',,'',Z");
  writeStartBlock(unitOutput + ",AT,1,30,1,1,,'ProgramedClampPositionsObligatory',,'Bool',Z");
  writeStartBlock(unitOutput + ",AT,1,40,1,1,,'ReentryRestriction',,'',Z");
  writeStartBlock(unitOutput + ",AT,1,50,1,1,,'ContourLineAdjustmentActive',,'Bool',Z");
  writeStartBlock(unitOutput + ",AT,1,60,1,1,,'FinishedPartSupportNumber',,'',Z");
  writeStartBlock(unitOutput + ",AT,1,70,1,1,,'BevelCuttingVersion',,'',Z");
  writeStartBlock(unitOutput + ",AT,1,80,1,1,,'FluidSprayMode',,'',Z");
  writeC();
  writeStartBlock("ZA,DA,1");
  writeStartBlock("DA,0,3,0,0,0,0,0,0");
  writeC();
  writeStartBlock("ENDE_PROGRAM_PROPERTIES");
  writeC();
  writeStartBlock("BEGIN_PROGRAMM");
  writeC();
  writeStartBlock("ZA," + unitOutput + ",5");
  writeStartBlock(unitOutput + ",AT,1,10,1,1,,'ProgTitle',,'',T");
  writeStartBlock(unitOutput + ",AT,1,20,1,1,,'ProgType',,'',T");
  writeStartBlock(unitOutput + ",AT,1,30,1,1,,'Comment',,'',T");
  writeStartBlock(unitOutput + ",AT,1,60,1,1,,'IncreasingRecordNumberFlag',,'Bool',Z");
  writeStartBlock(unitOutput + ",AT,1,80,1,1,,'IsSubProgMacro',,'Bool',Z");
  writeC();
  writeStartBlock("ZA,DA,1");
  writeStartBlock("DA,'" + programName + "','HP','Fusion',1,0");
  writeStartBlock("START_TEXT");
  writeBlock("MSG(\"MAIN PROGRAM NO.:," + programName + "\")");
  writeBlock("MSG(\"FUSION360 LASER - TRUMPF\")");
  writeBlock(gAbsIncModal.format(90));
  writeBlock(gFormat.format(unit == MM ? 71 : 70));
  writeBlock("TC_SHEET_TECH(\"SHT-1\")");
  writeBlock("TC_SHEET_LOAD(\"SHL-1\")");
  writeBlock("TC_POS_LEVEL(" + Math.abs(getGlobalParameter("stock-upper-z") - getGlobalParameter("stock-lower-z")) + ")");
  writeBlock(";GOTOF ENTRY_LASER");
  writeBlock(";ENTRY_LASER:");
  writeBlock(";(CUT1)");
}

function writeC() {
  writeln("C");
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

/** Force output of X, Y, Z, and F on next output. */
function forceAny() {
  forceXYZ();
  feedOutput.reset();
}

function onSection() {

  if (currentSection.getType() == TYPE_JET) {
    switch (tool.type) {
    case TOOL_LASER_CUTTER:
      break;
    default:
      error(localize("The CNC does not support the required tool/process. Only laser cutting is supported."));
      return;
    }

    switch (currentSection.jetMode) {
    case JET_MODE_THROUGH:
      pierceMode = getProperty("throughOn");
      break;
    case JET_MODE_ETCHING:
      pierceMode = getProperty("etchOn");
      break;
    case JET_MODE_VAPORIZE:
      pierceMode = getProperty("vaporizeOn");
      break;
    default:
      error(localize("Unsupported cutting mode."));
      return;
    }
  } else {
    error(localize("The CNC does not support the required tool/process. Only laser cutting is supported."));
    return;
  }

  { // pure 3D
    var remaining = currentSection.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported."));
      return;
    }
    setRotation(remaining);
  }
  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  writeBlock(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y));
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.001, seconds, 99999.999);
  writeBlock(gFormat.format(4), "P" + secFormat.format(seconds));
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

function onPower(power) {
}

function onRapid(_x, _y, _z) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  if (x || y) {
    if (pendingRadiusCompensation >= 0) {
      error(localize("Radius compensation mode cannot be changed at rapid traversal."));
      return;
    }
    writeBlock(gMotionModal.format(0), x, y);
    feedOutput.reset();
  }
}

function onLinear(_x, _y, _z, feed) {
  // at least one axis is required
  if (pendingRadiusCompensation >= 0) {
    // ensure that we end at desired position when compensation is turned off
    xOutput.reset();
    yOutput.reset();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var f = feedOutput.format(feed);
  if (x || y) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock("TC_LASERCORR_ON(T_LEFT)");
        writeBlock(gMotionModal.format(1), x, y, f);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock("TC_LASERCORR_ON(T_RIGHT)");
        writeBlock(gMotionModal.format(1), x, y, f);
        break;
      default:
        writeBlock(gMotionModal.format(1), x, y, f);
      }
    } else {
      writeBlock(gMotionModal.format(1), x, y, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      feedOutput.reset(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(1), f);
    }
  }
}

function onRapid5D(_x, _y, _z, _a, _b, _c) {
  error(localize("The CNC does not support 5-axis simultaneous toolpath."));
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed) {
  error(localize("The CNC does not support 5-axis simultaneous toolpath."));
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }

  var start = getCurrentPosition();

  if (isFullCircle()) {
    if (isHelical()) {
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

var mapCommand = {
  COMMAND_STOP: 0,
  COMMAND_END: 2
};

function onCommand(command) {
  switch (command) {
  case COMMAND_POWER_ON:
    writeBlock("TC_LASER_ON(11,\"" + pierceMode.trim() + "\",10,100)");
    return;
  case COMMAND_POWER_OFF:
    writeBlock("TC_LASER_OFF(2)");
    return;
  case COMMAND_LOCK_MULTI_AXIS:
    return;
  case COMMAND_UNLOCK_MULTI_AXIS:
    return;
  case COMMAND_BREAK_CONTROL:
    return;
  case COMMAND_TOOL_MEASURE:
    return;
  }

  var stringId = getCommandStringId(command);
  var mcode = mapCommand[stringId];
  if (mcode != undefined) {
    writeBlock(mFormat.format(mcode));
  } else {
    onUnsupportedCommand(command);
  }
}

function onSectionEnd() {
  forceAny();
}

function onClose() {
  writeBlock(mFormat.format(30));
  writeln("STOP_TEXT");
  writeC();
  writeln("ENDE_PROGRAMM");
  writeC();
  writeln("BEGIN_SHEET_LOAD");
  writeC();
  writeln("ZA,MM,14");
  writeln("MM,AT,1,10,1,1,,'LoadName',,'',T");
  writeln("MM,AT,1,20,1,1,,'LoadingPositionX',,'mm',Z");
  writeln("MM,AT,1,30,1,1,,'LoadingPositionY',,'mm',Z");
  writeln("MM,AT,1,40,1,1,,'Feed',,'m/min',Z");
  writeln("MM,AT,1,500,1,1,,'LoadingType',,'',Z");
  writeln("MM,AT,1,620,1,1,,'SheetStop',,'',Z");
  writeln("MM,AT,1,630,1,1,,'MeasureSheetPosition',,'',Z");
  writeln("MM,AT,1,640,1,1,,'MeasuringRangeX',,'mm',Z");
  writeln("MM,AT,1,650,1,1,,'MeasuringRangeY',,'mm',Z");
  writeln("MM,AT,1,660,1,1,,'CalibrationActive',,'Bool',Z");
  writeln("MM,AT,1,690,1,1,,'PalletChangerType',,'',Z");
  writeln("MM,AT,1,700,1,1,,'MeasuringCorner',,'',Z");
  writeln("MM,AT,1,710,1,1,,'StopPin',,'',Z");
  writeln("MM,AT,1,780,1,1,,'InsertionAid',,'Bool',Z");
  writeC();
  writeln("ZA,DA,1");
  writeln("DA,'SHL-1',0,0,0,1,1,0,50.8,50.8,1,1,1,1,1");
  writeC();
  writeln("ENDE_SHEET_LOAD");
  writeC();
  writeln("BEGIN_SHEET_TECH");
  writeC();
  writeln("ZA,MM,33");
  writeln("MM,AT,1,10,1,1,,'DatasetName',,'',T");
  writeln("MM,AT,1,20,1,1,,'SheetDimensionX',,'mm',Z");
  writeln("MM,AT,1,30,1,1,,'SheetDimensionY',,'mm',Z");
  writeln("MM,AT,1,40,1,1,,'Thickness',,'mm',Z");
  writeln("MM,AT,1,50,1,1,,'Type',,'',Z");
  writeln("MM,AT,1,70,1,1,,'ScratchFree',,'Bool',Z");
  writeln("MM,AT,1,100,1,1,,'MagazinePositionClamp1',,'',Z");
  writeln("MM,AT,1,110,1,1,,'MagazinePositionClamp2',,'',Z");
  writeln("MM,AT,1,120,1,1,,'MagazinePositionClamp3',,'',Z");
  writeln("MM,AT,1,130,1,1,,'MagazinePositionClamp4',,'',Z");
  writeln("MM,AT,1,160,1,1,,'MagazinePositionClamp5',,'',Z");
  writeln("MM,AT,1,170,1,1,,'MagazinePositionClamp6',,'',Z");
  writeln("MM,AT,1,180,1,1,,'MagazinePositionCoveredMinimum',,'',Z");
  writeln("MM,AT,1,190,1,1,,'MagazinePositionCoveredMaximum',,'',Z");
  writeln("MM,AT,1,210,1,1,,'ProcessingBetweenClamps',,'',Z");
  writeln("MM,AT,1,220,1,1,,'XLength',,'mm',Z");
  writeln("MM,AT,1,230,1,1,,'YLength',,'mm',Z");
  writeln("MM,AT,1,240,1,1,,'Grade',,'',T");
  writeln("MM,AT,1,250,1,1,,'AccelerationAdaption',,'Bool',Z");
  writeln("MM,AT,1,260,1,1,,'Density',,'kg/dm3',Z");
  writeln("MM,AT,1,270,1,1,,'GripFormatType',,'',Z");
  writeln("MM,AT,1,280,1,1,,'DynamicLevel',,'',Z");
  writeln("MM,AT,1,290,1,1,,'MaterialGroup',,'',T");
  writeln("MM,AT,1,300,1,1,,'ScratchFreeDieOn',,'Bool',Z");
  writeln("MM,AT,1,310,1,1,,'SafeDistance',,'mm',Z");
  writeln("MM,AT,1,320,1,1,,'PrepareSafeDistance',,'mm',Z");
  writeln("MM,AT,1,330,1,1,,'LaserBeamProtection',,'mm',Z");
  writeln("MM,AT,1,340,1,1,,'ThicknessTolerancePlus',,'mm',Z");
  writeln("MM,AT,1,350,1,1,,'ThicknessToleranceMinus',,'mm',Z");
  writeln("MM,AT,1,360,1,1,,'PrepareSafeDistanceNibbling',,'mm',Z");
  writeln("MM,AT,1,370,1,1,,'AdvancedEvaporateSwitch',,'',Z");
  writeln("MM,AT,1,380,1,1,,'AdvancedEvaporateCircleRadius',,'mm',Z");
  writeln("MM,AT,1,390,1,1,,'SurfaceOpticalReflectionProperty',,'',Z");
  writeC();
  writeln("ZA,DA,1");
  writeln("DA,'SHT-1',82.55,51.435,3.175,0,0,0,0,0,0,0,0,0,0,-1,82.55,51.435,'AL',0,7.86109293764,0,0,'1.0038',1,0,0,0.4,0,0,0,0,0,2");
  writeC();
  writeln("ENDE_SHEET_TECH");
  writeC();
  writeln("BEGIN_LTT_STAMM");
  writeC();
  writeln("ZA,MM,230");
  writeln("MM,AT,1,10,1,1,,'LT_ALL_TAB_NAME',,'',T");
  writeln("MM,AT,1,80,1,1,,'LT_ALL_MASCH_TYP',,'',T");
  writeln("MM,AT,1,90,1,1,,'LT_ALL_LASER_LSTG',,'W',Z");
  writeln("MM,AT,1,100,1,1,,'LT_ALL_MATERIAL',,'',T");
  writeln("MM,AT,1,110,1,1,,'LT_ALL_MAT_DICKE',,'mm',Z");
  writeln("MM,AT,1,120,1,1,,'LT_ALL_LINSENBRENNW',,'in',Z");
  writeln("MM,AT,1,130,1,1,,'LT_ALL_DUESENTYP',,'mm',Z");
  writeln("MM,AT,1,140,1,1,,'LT_ALL_SCHNEIDKOPFNR',,'',Z");
  writeln("MM,AT,1,150,1,1,,'LT_ALL_GASSP_SCH_EIN',,'s',Z");
  writeln("MM,AT,1,160,1,1,,'LT_ALL_GASSP_EIN_SCH',,'s',Z");
  writeln("MM,AT,1,170,1,1,,'LT_SCH_FOKUSLAGE',,'mm',Z");
  writeln("MM,AT,1,180,1,1,,'LT_SCH_BESCHL_RED',,'m/s2',Z");
  writeln("MM,AT,1,190,1,1,,'LT_SCH_BESCHL',,'m/s2',Z");
  writeln("MM,AT,1,200,1,1,,'LT_SCH_ECKENK_ZEIT',,'s',Z");
  writeln("MM,AT,1,210,1,1,,'LT_SCH_GESCHW_RED',,'%',Z");
  writeln("MM,AT,1,220,1,1,,'LT_SCH_GASART',,'',Z");
  writeln("MM,AT,1,230,1,1,,'LT_SCH_GASART_RED',,'',Z");
  writeln("MM,AT,1,240,1,1,,'LT_SCH_GR_SPALT',,'mm',Z");
  writeln("MM,AT,1,250,1,1,,'LT_SCH_GR_NOR_LSTG',,'W',Z");
  writeln("MM,AT,1,260,1,1,,'LT_SCH_GR_NOR_TASTFR',,'Hz',Z");
  writeln("MM,AT,1,270,1,1,,'LT_SCH_GR_NOR_GESCHW',,'m/min',Z");
  writeln("MM,AT,1,280,1,1,,'LT_SCH_GR_NOR_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,290,1,1,,'LT_SCH_GR_NOR_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,300,1,1,,'LT_SCH_GR_RED_LSTG',,'W',Z");
  writeln("MM,AT,1,310,1,1,,'LT_SCH_GR_RED_TASTFR',,'Hz',Z");
  writeln("MM,AT,1,320,1,1,,'LT_SCH_GR_RED_GESCHW',,'m/min',Z");
  writeln("MM,AT,1,330,1,1,,'LT_SCH_GR_RED_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,340,1,1,,'LT_SCH_GR_RED_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,350,1,1,,'LT_SCH_MI_SPALT',,'mm',Z");
  writeln("MM,AT,1,360,1,1,,'LT_SCH_MI_NOR_LSTG',,'W',Z");
  writeln("MM,AT,1,370,1,1,,'LT_SCH_MI_NOR_TASTFR',,'Hz',Z");
  writeln("MM,AT,1,380,1,1,,'LT_SCH_MI_NOR_GESCHW',,'m/min',Z");
  writeln("MM,AT,1,390,1,1,,'LT_SCH_MI_NOR_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,400,1,1,,'LT_SCH_MI_NOR_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,410,1,1,,'LT_SCH_MI_RED_LSTG',,'W',Z");
  writeln("MM,AT,1,420,1,1,,'LT_SCH_MI_RED_TASTFR',,'Hz',Z");
  writeln("MM,AT,1,430,1,1,,'LT_SCH_MI_RED_GESCHW',,'m/min',Z");
  writeln("MM,AT,1,440,1,1,,'LT_SCH_MI_RED_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,450,1,1,,'LT_SCH_MI_RED_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,460,1,1,,'LT_SCH_KL_SPALT',,'mm',Z");
  writeln("MM,AT,1,470,1,1,,'LT_SCH_KL_NOR_LSTG',,'W',Z");
  writeln("MM,AT,1,480,1,1,,'LT_SCH_KL_NOR_TASTFR',,'Hz',Z");
  writeln("MM,AT,1,490,1,1,,'LT_SCH_KL_NOR_GESCHW',,'m/min',Z");
  writeln("MM,AT,1,500,1,1,,'LT_SCH_KL_NOR_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,510,1,1,,'LT_SCH_KL_NOR_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,520,1,1,,'LT_SCH_KL_RED_LSTG',,'W',Z");
  writeln("MM,AT,1,530,1,1,,'LT_SCH_KL_RED_TASTFR',,'Hz',Z");
  writeln("MM,AT,1,540,1,1,,'LT_SCH_KL_RED_GESCHW',,'m/min',Z");
  writeln("MM,AT,1,550,1,1,,'LT_SCH_KL_RED_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,560,1,1,,'LT_SCH_KL_RED_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,570,1,1,,'LT_EINST_FOKUSLAGE',,'mm',Z");
  writeln("MM,AT,1,580,1,1,,'LT_EINST_NOR_ZEIT',,'s',Z");
  writeln("MM,AT,1,590,1,1,,'LT_EINST_NOR_RAMPNR',,'',Z");
  writeln("MM,AT,1,600,1,1,,'LT_EINST_NOR_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,610,1,1,,'LT_EINST_NOR_AUSBLASZEIT',,'s',Z");
  writeln("MM,AT,1,620,1,1,,'LT_EINST_NOR_GASART',,'',Z");
  writeln("MM,AT,1,630,1,1,,'LT_EINST_NOR_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,640,1,1,,'LT_EINST_NOR_OEL_SPRUEH',,'Bool',Z");
  writeln("MM,AT,1,650,1,1,,'LT_EINST_SAN_ZEIT',,'s',Z");
  writeln("MM,AT,1,660,1,1,,'LT_EINST_SAN_RAMPNR',,'',Z");
  writeln("MM,AT,1,670,1,1,,'LT_EINST_SAN_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,680,1,1,,'LT_EINST_SAN_AUSBLASZEIT',,'s',Z");
  writeln("MM,AT,1,690,1,1,,'LT_EINST_SAN_GASART',,'',Z");
  writeln("MM,AT,1,700,1,1,,'LT_EINST_SAN_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,710,1,1,,'LT_EINST_SAN_OEL_SPRUEH',,'Bool',Z");
  writeln("MM,AT,1,720,1,1,,'LT_ABD_FOKUSLAGE',,'mm',Z");
  writeln("MM,AT,1,730,1,1,,'LT_ABD_ZEIT',,'s',Z");
  writeln("MM,AT,1,740,1,1,,'LT_ABD_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,750,1,1,,'LT_ABD_LSTG',,'W',Z");
  writeln("MM,AT,1,760,1,1,,'LT_ABD_TASTFR',,'Hz',Z");
  writeln("MM,AT,1,770,1,1,,'LT_ABD_GESCHW',,'m/min',Z");
  writeln("MM,AT,1,780,1,1,,'LT_ABD_GASART',,'',Z");
  writeln("MM,AT,1,790,1,1,,'LT_ABD_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,800,1,1,,'LT_KEN_FOKUSLAGE',,'mm',Z");
  writeln("MM,AT,1,810,1,1,,'LT_KEN_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,820,1,1,,'LT_KEN_LSTG',,'W',Z");
  writeln("MM,AT,1,830,1,1,,'LT_KEN_TASTFR',,'Hz',Z");
  writeln("MM,AT,1,840,1,1,,'LT_KEN_GESCHW',,'m/min',Z");
  writeln("MM,AT,1,850,1,1,,'LT_KEN_GASART',,'',Z");
  writeln("MM,AT,1,860,1,1,,'LT_KEN_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,870,1,1,,'LT_KOE_FOKUSLAGE',,'mm',Z");
  writeln("MM,AT,1,880,1,1,,'LT_KOE_GEO_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,890,1,1,,'LT_KOE_GEO_LSTG',,'W',Z");
  writeln("MM,AT,1,900,1,1,,'LT_KOE_GEO_TASTFR',,'Hz',Z");
  writeln("MM,AT,1,910,1,1,,'LT_KOE_GEO_GESCHW',,'m/min',Z");
  writeln("MM,AT,1,920,1,1,,'LT_KOE_GEO_GASART',,'',Z");
  writeln("MM,AT,1,930,1,1,,'LT_KOE_GEO_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,940,1,1,,'LT_KOE_PUN_EINST_ZEIT',,'s',Z");
  writeln("MM,AT,1,950,1,1,,'LT_KOE_PUN_RAMPNR',,'',Z");
  writeln("MM,AT,1,960,1,1,,'LT_KOE_PUN_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,970,1,1,,'LT_KOE_PUN_GASART',,'',Z");
  writeln("MM,AT,1,980,1,1,,'LT_KOE_PUN_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,990,1,1,,'LT_PUN_FOKUSLAGE',,'mm',Z");
  writeln("MM,AT,1,1000,1,1,,'LT_PUN_SAN_ZEIT',,'s',Z");
  writeln("MM,AT,1,1010,1,1,,'LT_PUN_SAN_RAMPNR',,'',Z");
  writeln("MM,AT,1,1020,1,1,,'LT_PUN_SAN_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,1030,1,1,,'LT_PUN_SAN_GASART',,'',Z");
  writeln("MM,AT,1,1040,1,1,,'LT_PUN_SAN_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,1050,1,1,,'LT_PUN_FEST_ZEIT',,'s',Z");
  writeln("MM,AT,1,1060,1,1,,'LT_PUN_FEST_RAMPNR',,'',Z");
  writeln("MM,AT,1,1070,1,1,,'LT_PUN_FEST_DUESENABST',,'mm',Z");
  writeln("MM,AT,1,1080,1,1,,'LT_PUN_FEST_GASART',,'',Z");
  writeln("MM,AT,1,1090,1,1,,'LT_PUN_FEST_GASDRUCK',,'bar',Z");
  writeln("MM,AT,1,1110,1,1,,'LT_SCH_GESCHW_RED_STANZLOCH',,'%',Z");
  writeln("MM,AT,1,1120,1,1,,'LT_SCH_GR_FOKUSLAGE',,'mm',Z");
  writeln("MM,AT,1,1130,1,1,,'LT_SCH_MI_FOKUSLAGE',,'mm',Z");
  writeln("MM,AT,1,1140,1,1,,'LT_SCH_KL_FOKUSLAGE',,'mm',Z");
  writeln("MM,AT,1,1160,1,1,,'LT_SCH_BESCHL_HOCH',,'m/s2',Z");
  writeln("MM,AT,1,1730,1,1,,'LT_SCH_PMS_EIN',,'Bool',Z");
  writeln("MM,AT,1,1740,1,1,,'LT_SCH_PMS_SCHWELLE1',,'%',Z");
  writeln("MM,AT,1,1750,1,1,,'LT_SCH_PMS_SCHWELLE2',,'%',Z");
  writeln("MM,AT,1,1760,1,1,,'LT_ANALOG_STEUERG',,'',Z");
  writeln("MM,AT,1,1770,1,1,,'LT_LLS_V_OG',,'%',Z");
  writeln("MM,AT,1,1780,1,1,,'LT_LLS_V_OG_LSTG',,'%',Z");
  writeln("MM,AT,1,1790,1,1,,'LT_LLS_V_UG',,'%',Z");
  writeln("MM,AT,1,1800,1,1,,'LT_LLS_V_UG_LSTG',,'%',Z");
  writeln("MM,AT,1,1810,1,1,,'LT_LFS_V_OG',,'%',Z");
  writeln("MM,AT,1,1820,1,1,,'LT_LFS_V_OG_FREQ',,'%',Z");
  writeln("MM,AT,1,1830,1,1,,'LT_LFS_V_UG',,'%',Z");
  writeln("MM,AT,1,1840,1,1,,'LT_LFS_V_UG_FREQ',,'%',Z");
  writeln("MM,AT,1,1850,1,1,,'LT_EINST_NOR_SENSORIK',,'',Z");
  writeln("MM,AT,1,1860,1,1,,'LT_EINST_SAN_SENSORIK',,'',Z");
  writeln("MM,AT,1,1870,1,1,,'LT_SCH_GR_STRAHL_DM',,'mm',Z");
  writeln("MM,AT,1,1880,1,1,,'LT_SCH_MI_STRAHL_DM',,'mm',Z");
  writeln("MM,AT,1,1890,1,1,,'LT_SCH_KL_STRAHL_DM',,'mm',Z");
  writeln("MM,AT,1,1900,1,1,,'LT_EINST_STRAHL_DM',,'mm',Z");
  writeln("MM,AT,1,1910,1,1,,'LT_ABD_STRAHL_DM',,'mm',Z");
  writeln("MM,AT,1,1920,1,1,,'LT_KEN_STRAHL_DM',,'mm',Z");
  writeln("MM,AT,1,1930,1,1,,'LT_KOE_STRAHL_DM',,'mm',Z");
  writeln("MM,AT,1,1940,1,1,,'LT_PUN_STRAHL_DM',,'mm',Z");
  writeln("MM,AT,1,1950,1,1,,'LT_LLS_V_OG_2',,'m/min',Z");
  writeln("MM,AT,1,1960,1,1,,'LT_LLS_V_OG_LSTG_2',,'W',Z");
  writeln("MM,AT,1,1970,1,1,,'LT_LLS_V_UG_2',,'m/min',Z");
  writeln("MM,AT,1,1980,1,1,,'LT_LLS_V_UG_LSTG_2',,'W',Z");
  writeln("MM,AT,1,1990,1,1,,'LT_LFS_V_OG_2',,'m/min',Z");
  writeln("MM,AT,1,2000,1,1,,'LT_LFS_V_OG_FREQ_2',,'Hz',Z");
  writeln("MM,AT,1,2010,1,1,,'LT_LFS_V_UG_2',,'m/min',Z");
  writeln("MM,AT,1,2020,1,1,,'LT_LFS_V_UG_FREQ_2',,'Hz',Z");
  writeln("MM,AT,1,2030,1,1,,'LT_EINST_SAN_FOKUSLAGE',,'mm',Z");
  writeln("MM,AT,1,2040,1,1,,'LT_SCH_MI_PMS_EIN',,'Bool',Z");
  writeln("MM,AT,1,2050,1,1,,'LT_SCH_KL_PMS_EIN',,'Bool',Z");
  writeln("MM,AT,1,2060,1,1,,'LT_SON_BESCHL',,'m/s2',Z");
  writeln("MM,AT,1,2070,1,1,,'LT_EINST_STRAHL_DM_PCS',,'mm',Z");
  writeln("MM,AT,1,2080,1,1,,'LT_EINST_NOR_FOKUSLAGE_PCS',,'mm',Z");
  writeln("MM,AT,1,2090,1,1,,'LT_EINST_NOR_ZEIT_PCS',,'s',Z");
  writeln("MM,AT,1,2100,1,1,,'LT_EINST_NOR_RAMPNR_PCS',,'',Z");
  writeln("MM,AT,1,2110,1,1,,'LT_EINST_NOR_DUESENABST_PCS',,'mm',Z");
  writeln("MM,AT,1,2120,1,1,,'LT_EINST_NOR_AUSBLASZEIT_PCS',,'s',Z");
  writeln("MM,AT,1,2130,1,1,,'LT_EINST_NOR_GASART_PCS',,'',Z");
  writeln("MM,AT,1,2140,1,1,,'LT_EINST_NOR_GASDRUCK_PCS',,'bar',Z");
  writeln("MM,AT,1,2150,1,1,,'LT_EINST_NOR_OEL_SPRUEH_PCS',,'Bool',Z");
  writeln("MM,AT,1,2160,1,1,,'LT_EINST_NOR_SENSORIK_PCS',,'',Z");
  writeln("MM,AT,1,2170,1,1,,'LT_EINST_NOR_QUERBLASEN_PCS',,'Bool',Z");
  writeln("MM,AT,1,2180,1,1,,'LT_EINST_SAN_FOKUSLAGE_PCS',,'mm',Z");
  writeln("MM,AT,1,2190,1,1,,'LT_EINST_SAN_ZEIT_PCS',,'s',Z");
  writeln("MM,AT,1,2200,1,1,,'LT_EINST_SAN_RAMPNR_PCS',,'',Z");
  writeln("MM,AT,1,2210,1,1,,'LT_EINST_SAN_DUESENABST_PCS',,'mm',Z");
  writeln("MM,AT,1,2220,1,1,,'LT_EINST_SAN_AUSBLASZEIT_PCS',,'s',Z");
  writeln("MM,AT,1,2230,1,1,,'LT_EINST_SAN_GASART_PCS',,'',Z");
  writeln("MM,AT,1,2240,1,1,,'LT_EINST_SAN_GASDRUCK_PCS',,'bar',Z");
  writeln("MM,AT,1,2250,1,1,,'LT_EINST_SAN_OEL_SPRUEH_PCS',,'Bool',Z");
  writeln("MM,AT,1,2260,1,1,,'LT_EINST_SAN_SENSORIK_PCS',,'',Z");
  writeln("MM,AT,1,2270,1,1,,'LT_EINST_SAN_QUERBLASEN_PCS',,'Bool',Z");
  writeln("MM,AT,1,2280,1,1,,'LT_SCH_BESCHL_HOCH_AUX',,'m/s2',Z");
  writeln("MM,AT,1,2290,1,1,,'LT_MATERIAL_STANDARD',,'',Z");
  writeln("MM,AT,1,2310,1,1,,'LT_OffsetEinstellmass',,'mm',Z");
  writeln("MM,AT,1,2320,1,1,,'LT_SCH_BESCHL_HOCH_AUX_X',,'m/s2',Z");
  writeln("MM,AT,1,2330,1,1,,'LaserHeadType',,'',Z");
  writeln("MM,AT,1,2340,1,1,,'LaserHeadGeneration',,'',Z");
  writeln("MM,AT,1,2350,1,1,,'LaserHeadComponentId',,'',Z");
  writeln("MM,AT,1,2360,1,1,,'LtMarkLPCLowerLimitSpeed',,'m/min',Z");
  writeln("MM,AT,1,2370,1,1,,'LtMarkLPCPowerLowLimitSpeed',,'W',Z");
  writeln("MM,AT,1,2380,1,1,,'LtVapLPCLowerLimitSpeed',,'m/min',Z");
  writeln("MM,AT,1,2390,1,1,,'LtVapLPCPowerLowLimitSpeed',,'W',Z");
  writeln("MM,AT,1,2400,1,1,,'LtMarkLPCFreqLowLimitSpeed',,'Hz',Z");
  writeln("MM,AT,1,2410,1,1,,'LtVapLPCFreqLowLimitSpeed',,'Hz',Z");
  writeln("MM,AT,1,2440,1,1,,'LensFocalLengthMetric',,'mm',Z");
  writeln("MM,AT,1,2510,1,1,,'ApproachModeLarge',,'',Z");
  writeln("MM,AT,1,2520,1,1,,'ApproachModeMedium',,'',Z");
  writeln("MM,AT,1,2530,1,1,,'ApproachModeSmall',,'',Z");
  writeln("MM,AT,1,2600,1,1,,'LT2_VIEWER_NAME',,'',T");
  writeln("MM,AT,1,2610,1,1,,'LT2_DIMENSION_MACHINE_MIN',,'mm',Z");
  writeln("MM,AT,1,2620,1,1,,'LT2_DIMENSION_MACHINE_MAX',,'mm',Z");
  writeln("MM,AT,1,2630,1,1,,'LT2_WERKSTOFF',,'',T");
  writeln("MM,AT,1,2640,1,1,,'LT2_LASERTYP',,'',T");
  writeln("MM,AT,1,2650,1,1,,'LT2_FOIL_TYPE',,'',Z");
  writeln("MM,AT,1,2660,1,1,,'LT2_SUITABLE_FOR_COATING',,'',Z");
  writeln("MM,AT,1,2670,1,1,,'LT2_PROCESSING_TECHNOLOGY_1',,'',Z");
  writeln("MM,AT,1,2680,1,1,,'LT2_PROCESSING_TECHNOLOGY_2',,'',Z");
  writeln("MM,AT,1,2700,1,1,,'LT2_CutChangeModeLarge',,'',Z");
  writeln("MM,AT,1,2710,1,1,,'LT2_CutChangeModeMedium',,'',Z");
  writeln("MM,AT,1,2720,1,1,,'LT2_CutChangeModeSmall',,'',Z");
  writeln("MM,AT,1,2730,1,1,,'LT2_CutChangePathLengthLarge',,'mm',Z");
  writeln("MM,AT,1,2740,1,1,,'LT2_CutChangePathLengthMedium',,'mm',Z");
  writeln("MM,AT,1,2750,1,1,,'LT2_CutChangePathLengthSmall',,'mm',Z");
  writeln("MM,AT,1,2760,1,1,,'LT2_CutChangeStartSettingValueLarge',,'mm',Z");
  writeln("MM,AT,1,2770,1,1,,'LT2_CutChangeStartSettingValueMedium',,'mm',Z");
  writeln("MM,AT,1,2780,1,1,,'LT2_CutChangeStartSettingValueSmall',,'mm',Z");
  writeln("MM,AT,1,2790,1,1,,'LT2_EINST_NOR_QUERBLASEN',,'Bool',Z");
  writeln("MM,AT,1,2800,1,1,,'LT2_EINST_SAN_QUERBLASEN',,'Bool',Z");
  writeln("MM,AT,1,2810,1,1,,'LT2_SALES_STATUS',,'',Z");
  writeln("MM,AT,1,2850,1,1,,'LT2_SCH_GR_RED_FOKUSLAGE_LI',,'mm',Z");
  writeln("MM,AT,1,2860,1,1,,'LT2_SCH_GR_RED_GESCHW_LI',,'m/min',Z");
  writeln("MM,AT,1,2870,1,1,,'LT2_SCH_GR_RED_DUESENABST_LI',,'mm',Z");
  writeln("MM,AT,1,2880,1,1,,'LT2_SCH_GR_RED_GASDRUCK_LI',,'bar',Z");
  writeln("MM,AT,1,2890,1,1,,'LT2_SCH_MI_RED_FOKUSLAGE_LI',,'mm',Z");
  writeln("MM,AT,1,2900,1,1,,'LT2_SCH_MI_RED_GESCHW_LI',,'m/min',Z");
  writeln("MM,AT,1,2910,1,1,,'LT2_SCH_MI_RED_DUESENABST_LI',,'mm',Z");
  writeln("MM,AT,1,2920,1,1,,'LT2_SCH_MI_RED_GASDRUCK_LI',,'bar',Z");
  writeln("MM,AT,1,2930,1,1,,'LT2_SCH_KL_RED_FOKUSLAGE_LI',,'mm',Z");
  writeln("MM,AT,1,2940,1,1,,'LT2_SCH_KL_RED_GESCHW_LI',,'m/min',Z");
  writeln("MM,AT,1,2950,1,1,,'LT2_SCH_KL_RED_DUESENABST_LI',,'mm',Z");
  writeln("MM,AT,1,2960,1,1,,'LT2_SCH_KL_RED_GASDRUCK_LI',,'bar',Z");
  writeln("MM,AT,1,2970,1,1,,'LT2_SCH_GR_FOKUS_DM',,'um',Z");
  writeln("MM,AT,1,2980,1,1,,'LT2_SCH_MI_FOKUS_DM',,'um',Z");
  writeln("MM,AT,1,2990,1,1,,'LT2_SCH_KL_FOKUS_DM',,'um',Z");
  writeln("MM,AT,1,3000,1,1,,'LT2_EINST_NOR_FOKUS_DM_PCS',,'um',Z");
  writeln("MM,AT,1,3010,1,1,,'LT2_EINST_SAN_FOKUS_DM_PCS',,'um',Z");
  writeln("MM,AT,1,3020,1,1,,'LT2_ABD_FOKUS_DM',,'um',Z");
  writeln("MM,AT,1,3030,1,1,,'LT2_KEN_FOKUS_DM',,'um',Z");
  writeln("MM,AT,1,3040,1,1,,'LT2_KOE_FOKUS_DM',,'um',Z");
  writeln("MM,AT,1,3050,1,1,,'LT2_PUN_FOKUS_DM',,'um',Z");
  writeln("MM,AT,1,3060,1,1,,'LT2_EINST_SAN_QUERBLASDRUCK',,'bar',Z");
  writeln("MM,AT,1,3070,1,1,,'LT2_EINST_NOR_QUERBLASDRUCK',,'bar',Z");
  writeln("MM,AT,1,3080,1,1,,'LT2_EINST_SAN_QUERBLASDRUCK_PCS',,'bar',Z");
  writeln("MM,AT,1,3090,1,1,,'LT2_EINST_NOR_QUERBLASDRUCK_PCS',,'bar',Z");
  writeln("MM,AT,1,3130,1,1,,'LT2_PulsePowerSmallNor',,'W',Z");
  writeln("MM,AT,1,3140,1,1,,'LT2_PulsePowerMediumNor',,'W',Z");
  writeln("MM,AT,1,3150,1,1,,'LT2_PulsePowerLargeNor',,'W',Z");
  writeln("MM,AT,1,3160,1,1,,'LT2_PulsePowerMarking',,'W',Z");
  writeC();
  writeln("ZA,DA,1");
  writeC();
  writeln("ENDE_LTT_STAMM");
  writeC();
  writeln("ED");
}

function setProperty(property, value) {
  properties[property].current = value;
}
