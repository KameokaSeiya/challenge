/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  IPG Photonics LaserCube post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {BF662981-28CB-4AE5-A0FE-B24CB4F38F84}
*/

description = "IPG Photonics LaserCube";
vendor = "IPG Photonics";
vendorUrl = "https://www.ipgphotonics.com/en";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic post for IPG Photonics LaserCube compact fiber laser cutting machine.  Use tools 1-5 for StartCut1-5 and 11-15 for StartMark1-5. For Inventor CAM the Action Manual NC command 'POWER:1-5' should be used.";

extension = "prg";
setCodePage("ascii");

capabilities = CAPABILITY_JET;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = false;
allowedCircularPlanes = (1 << PLANE_XY); // allow circular in XY-plane

// user-defined properties
properties = {
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
    value: 2,
    scope: "post"
  },
  sequenceNumberIncrement: {
    title: "Sequence number increment",
    description: "The amount by which the sequence number is incremented by in each block.",
    group: 1,
    type: "integer",
    value: 2,
    scope: "post"
  },
  separateWordsWithSpace: {
    title: "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  defaultPower: {
    title: "Default power",
    description: "Select the default power setting from 1 through 5.  Only used with Inventor CAM.",
    type: "enum",
    values: [
      {title: "1", id: "1"},
      {title: "2", id: "2"},
      {title: "3", id: "3"},
      {title: "4", id: "4"},
      {title: "5", id: "5"}
    ],
    value: "1",
    scope: "post"
  }
};

var gFormat = createFormat({prefix:"G", decimals:0, width:2, zeropad:true});
var mFormat = createFormat({prefix:"M", decimals:1, width:2, zeropad:true, forceDecimal:false});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 5)});
var powerFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-1000

var xOutput = createVariable({prefix:"X", force:true}, xyzFormat);
var yOutput = createVariable({prefix:"Y", force:true}, xyzFormat);
var zOutput = createVariable({prefix:"Z"}, xyzFormat);

// circular output
var iOutput = createReferenceVariable({prefix:"I", force:true}, xyzFormat);
var jOutput = createReferenceVariable({prefix:"J", force:true}, xyzFormat);

var gMotionModal = createModal({force:true}, gFormat); // modal group 1 // G0-G3, ...

var WARNING_WORK_OFFSET = 0;

// collected state
var sequenceNumber;
var currentWorkOffset;
var partCounter = 1;
var newPart = false;
var cutPower = 1;

/**
  Writes the specified block.
*/
function writeBlock() {
  if (getProperty("showSequenceNumbers")) {
    writeWords2("N" + sequenceNumber, arguments);
    sequenceNumber += getProperty("sequenceNumberIncrement");
  } else {
    writeWords(arguments);
  }
}

function formatComment(text) {
  return "! " + String(text).replace(/[()]/g, "");
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

function getPowerMode(section) {
  var mode;
  var tnum = tool.number;
  if (tnum == 0) {
    tnum = cutPower;
    if (section.jetMode == JET_MODE_ETCHING) {
      tnum += 10;
    }
  }
  switch (tnum) {
  case 1:
    mode = "StartCut1";
    break;
  case 2:
    mode = "StartCut2";
    break;
  case 3:
    mode = "StartCut3";
    break;
  case 4:
    mode = "StartCut4";
    break;
  case 5:
    mode = "StartCut5";
    break;
  case 11:
    mode = "StartMark1";
    break;
  case 12:
    mode = "StartMark2";
    break;
  case 13:
    mode = "StartMark3";
    break;
  case 14:
    mode = "StartMark4";
    break;
  case 15:
    mode = "StartMark5";
    break;
  default:
    error(localize("Invalid tool number. Use tools 1-5 for cutting and 11-15 for etching."));
    return 0;
  }
  return mode;
}

function onOpen() {
  
  cutPower = parseInt(getProperty("defaultPower"), 10);
  if (isNaN(cutPower) || (cutPower < 1) || (cutPower > 5)) {
    error(localize("The default power setting must be between 1 and 5."));
    return;
  }

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");

  // write header
  var comment = "";
  writeComment("IPG Photonics Laser Cube");
  if (hasGlobalParameter("generated-by")) {
    comment += getGlobalParameter("generated-by") + " ";
  }
  if (programName) {
    comment += programName + " ";
  }
  var d = new Date();
  comment += " | " + d.toLocaleDateString() + ", " + d.toLocaleTimeString();
  writeComment(comment);

  var eos = longDescription.indexOf(".");
  comment = (eos == -1) ? longDescription : longDescription.substr(0, eos + 1);
  if ((typeof getHeaderVersion == "function") && getHeaderVersion()) {
    comment += ", " + getHeaderVersion();
  }
  writeComment(comment);

  writeComment("Length unit: " + (unit == IN ? "in" : "mm"));
  writeln("");
  writeln("");

  // write workpiece size
  var workpiece = getWorkpiece();
  var delta = Vector.diff(workpiece.upper, workpiece.lower);
  writeln("N00 M20001" + " X" + xyzFormat.format(delta.x) + " Y" + xyzFormat.format(delta.y));
  writeln("N00 M20002" + " X" + xyzFormat.format(-workpiece.lower.x) + " Y" + xyzFormat.format(-workpiece.lower.y));

  if ((getNumberOfSections() > 0)) {
    var workOffset = getSection(0).workOffset;
    for (var i = 0; i < getNumberOfSections(); ++i) {
      if (getSection(i).workOffset != workOffset || getSection(i).workOffset > 6) {
        error(localize("Using multiple work offsets is not possible."));
        return;
      }
    }
    if (workOffset != 0) {
      writeln("");
      writeln("CALL ZtoSafe;");
      writeBlock(mFormat.format(212));
      writeBlock(gFormat.format(53 + workOffset));
      writeBlock(gFormat.format(90), "X" + xyzFormat.format(0), "Y" + xyzFormat.format(0));
      writeBlock(gFormat.format(52));
    }
  }

  writeln("");
  writeln("CALL Initialize;");
  writeln("GOTO Part1");
}

function onParameter(name, value) {
  var invalid = false;
  switch (name) {
  case "action":
    if (value == "pierce") {
      break;
    }
    var sText1 = String(value);
    var sText2 = new Array();
    sText2 = sText1.split(":");
    if (sText2.length != 2) {
      error(localize("Invalid action command: ") + value);
      return;
    }
    if (sText2[0].toUpperCase() == "POWER") {
      cutPower = parseInt(sText2[1], 10);
      if ((cutPower == isNaN()) || (cutPower < 1) || (cutPower > 5)) {
        error(localize("Tool number must be a value in the range of 1-5"));
        return;
      }
    } else {
      invalid = true;
    }
    if (invalid) {
      error(localize("Invalid action parameter: ") + sText2[0] + ":" + sText2[1]);
      return;
    }
    break;
  case "job-description":
    newPart = true;
    break;
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

/** Force output of X, Y, Z, and F on next output. */
function forceAny() {
  forceXYZ();
}

function onSection() {
  if (newPart) {
    writeln("");
    writeln("Part" + partCounter + ":");
    writeln(subst("Part_Count = %1 ; ! Part Counter", partCounter++));
    writeln("");
  }
  
  /*if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment(comment);
    }
  }*/
  
  if (currentSection.getType() == TYPE_JET) {
    switch (tool.type) {
    case TOOL_LASER_CUTTER:
      break;
    default:
      error(localize("The CNC does not support the required tool/process. Only laser cutting is supported."));
      return;
    }
  } else {
    error(localize("The CNC does not support the required tool/process. Only laser cutting is supported."));
    return;
  }

  if (currentSection.jetMode == JET_MODE_ETCHING) {
    if (((tool.number < 11) || (tool.number > 15)) && (tool.number != 0)) {
      error(localize("You must use tools 11-15 for etching."));
    }
  }

  { // pure 3D
    var remaining = currentSection.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported."));
      return;
    }
    setRotation(remaining);
  }

  if (newPart) {
    var initialPosition = getFramePosition(currentSection.getInitialPosition());
    writeBlock(formatWords(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y)));
    writeln("");
  }
  newPart = false;
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
  if (power) {
    writeln("CALL " + getPowerMode(currentSection) + ";");
  } else {
    writeln("CALL StopCut;");
  }
}

function onRapid(_x, _y, _z) {
  if (xyzFormat.areDifferent(_x, xOutput.getCurrent()) || xyzFormat.areDifferent(_y, yOutput.getCurrent())) {
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    if (pendingRadiusCompensation >= 0) {
      error(localize("Radius compensation mode cannot be changed at rapid traversal."));
      return;
    }
    writeBlock(gMotionModal.format(0), x, y);
  } else if (xyzFormat.areDifferent(_z, zOutput.getCurrent())) {
    if (_z > getCurrentPosition().z) {
      writeln("CALL ZtoSafe;");
    }
  }
  zOutput.format(_z);
}

function onLinear(_x, _y, _z, feed) {
  // at least one axis is required
  if (pendingRadiusCompensation >= 0) {
    // ensure that we end at desired position when compensation is turned off
    xOutput.reset();
    yOutput.reset();
  } else if (movement == MOVEMENT_LINK_DIRECT) {
    onRapid(_x, _y, _z);
    return;
  }
  if (xyzFormat.areDifferent(_x, xOutput.getCurrent()) || xyzFormat.areDifferent(_y, yOutput.getCurrent())) {
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gFormat.format(41) + "D[CRC]");
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gFormat.format(42) + "D[CRC]");
        break;
      default:
        writeBlock(gFormat.format(40));
      }
    }
    writeBlock(gMotionModal.format(1), x, y);
  }
  zOutput.format(_z);
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
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0));
      break;
    default:
      linearize(tolerance);
    }
  } else {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0));
      break;
    default:
      linearize(tolerance);
    }
  }
}

var mapCommand = {
  COMMAND_STOP:0,
  COMMAND_END:2
};

function onCommand(command) {
  switch (command) {
  case COMMAND_POWER_ON:
    return;
  case COMMAND_POWER_OFF:
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
}

function onClose() {
  writeln("");
  writeComment("MAIN PROGRAM END");
  writeln("");
  writeln("CALL Terminate;");
  writeln("STOP");
  writeln("");
  writeln("!==================================================");
  writeln("!=============== IPG SUBROUTINES ==================");
  writeln("Initialize:");
  writeln("N00 M404");
  writeln("RET");
  writeln("Terminate:");
  writeln("N00 M405");
  writeln("RET");
  writeln("SetZeroXY:");
  writeln("N00 M200");
  writeln("RET");
  writeln("ResetZeroXY:");
  writeln("N00 M201");
  writeln("RET");
  writeln("SetFastVelocity:");
  writeln("N00 M302");
  writeln("RET");
  writeln("SetCuttingVelocity:");
  writeln("N00 M203");
  writeln("RET");
  writeln("SetLaser:");
  writeln("N00 M304 ; ! Init Laser");
  writeln("RET");
  writeln("ResetLaser:");
  writeln("N00 M205");
  writeln("RET");
  writeln("SetGas:");
  writeln("N00 M206");
  writeln("RET");
  writeln("ResetGas:");
  writeln("N00 M207");
  writeln("RET");
  writeln("AutofocusON:");
  writeln("N00 M208");
  writeln("RET");
  writeln("AutofocusOFF:");
  writeln("N00 M209");
  writeln("RET");
  writeln("LaserON:");
  writeln("N00 M210");
  writeln("RET");
  writeln("LaserOFF:");
  writeln("N00 M211");
  writeln("RET");
  writeln("StartCut:");
  writeln("N00 M203 ; ! Set Cutting Velocity");
  writeln("N10 M210 ; ! Laser ON");
  writeln("N00 G200 ,F[SEGMENT_V*60] ,J[CORNER_V*60] ,A[JUNCTION_ANGLE]");
  writeln("RET");
  writeln("StopCut:");
  writeln("N00 M211 ; ! Laser OFF");
  writeln("N00 M302 ; ! SetFastVelocity");
  writeln("RET");
  writeln("SetSystemVelocity:");
  writeln("N00 M212");
  writeln("RET");
  writeln("ZtoSafe:");
  writeln("N00 M209 ; ! Autofocus OFF");
  writeln("ptp/ev (Z),Z_SAFE_POSITION,Z_MAX_VEL");
  writeln("RET");
  writeln("ZtoStart:");
  writeln("N00 M209 ; ! Autofocus OFF");
  writeln("ptp/ev (Z),Z_START_CUT,Z_MAX_VEL");
  writeln("N00 M208 ; ! Autofocus ON");
  writeln("RET");
  writeln("!===============================");
  writeln("!=== Cutting Conditions ====");
  writeln("StartCut1:");
  writeln("N00 M401.1 ; ! Set/Execute Cutting Condition 1");
  writeln("N00 G200 ,F[SEGMENT_V*60] ,J[CORNER_V*60] ,A[JUNCTION_ANGLE]");
  writeln("RET");
  writeln("StartCut2:");
  writeln("N00 M401.2 ; ! Set/Execute Cutting Condition 2");
  writeln("N00 G200 ,F[SEGMENT_V*60] ,J[CORNER_V*60] ,A[JUNCTION_ANGLE]");
  writeln("RET");
  writeln("StartCut3:");
  writeln("N00 M401.3 ; ! Set/Execute Cutting Condition 3");
  writeln("N00 G200 ,F[SEGMENT_V*60] ,J[CORNER_V*60] ,A[JUNCTION_ANGLE]");
  writeln("RET");
  writeln("StartCut4:");
  writeln("N00 M401.4 ; ! Set/Execute Cutting Condition 4");
  writeln("N00 G200 ,F[SEGMENT_V*60] ,J[CORNER_V*60] ,A[JUNCTION_ANGLE]");
  writeln("RET");
  writeln("StartCut5:");
  writeln("N00 M401.5 ; ! Set/Execute Cutting Condition 5");
  writeln("N00 G200 ,F[SEGMENT_V*60] ,J[CORNER_V*60] ,A[JUNCTION_ANGLE]");
  writeln("RET");
  writeln("");
  writeln("!=== Marking Conditions ===");
  writeln("");
  writeln("StartMark1:");
  writeln("N00 M402.1 ; ! Set/Execute Marking Condition 1");
  writeln("N00 G200 ,F[SEGMENT_V*60] ,J[CORNER_V*60] ,A[JUNCTION_ANGLE]");
  writeln("RET");
  writeln("StartMark2:");
  writeln("N00 M402.2 ; ! Set/Execute Marking Condition 2");
  writeln("N00 G200 ,F[SEGMENT_V*60] ,J[CORNER_V*60] ,A[JUNCTION_ANGLE]");
  writeln("RET");
  writeln("StartMark3:");
  writeln("N00 M402.3 ; ! Set/Execute Marking Condition 3");
  writeln("N00 G200 ,F[SEGMENT_V*60] ,J[CORNER_V*60] ,A[JUNCTION_ANGLE]");
  writeln("RET");
  writeln("StartMark4: ; ! Set/Execute Marking Condition 4");
  writeln("N00 G200 ,F[SEGMENT_V*60] ,J[CORNER_V*60] ,A[JUNCTION_ANGLE]");
  writeln("N00 M402.4 ;");
  writeln("RET");
  writeln("StartMark5:");
  writeln("N00 M402.5 ; ! Set/Execute Marking Condition 5");
  writeln("N00 G200 ,F[SEGMENT_V*60] ,J[CORNER_V*60] ,A[JUNCTION_ANGLE]");
  writeln("RET");
}

function setProperty(property, value) {
  properties[property].current = value;
}
