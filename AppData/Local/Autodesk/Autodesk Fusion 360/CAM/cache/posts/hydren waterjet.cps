/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Hydren Waterjet post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {EC494622-287B-4F2D-87B1-9C703F77891A}
*/

description = "Hydren Systems waterjet";
vendor = "Hydren Systems";
vendorUrl = "http://www.hydrensystems.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic post for the Hydren Systems waterjet cutting tables.";

extension = "cnc";
programNameIsInteger = true;
setCodePage("ascii");

capabilities = CAPABILITY_JET;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(4000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(360);
allowHelicalMoves = false;
allowedCircularPlanes = 1 << PLANE_XY; // only XY
highFeedrate = (unit == IN) ? 200 : 5000;

// user-defined properties
properties = {
  writeMachine: {
    title: "Write machine",
    description: "Output the machine settings in the header of the code.",
    group: 0,
    type: "boolean",
    value: true,
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
  separateWordsWithSpace: {
    title: "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  pierceTime: {
    title: "Pierce time",
    description: "Amount of time in seconds to dwell after turning on the jet.",
    type: "number",
    value: 15,
    scope: "post"
  },
  abrasiveFlow: {
    title: "Abrasive flow rate",
    description: "The flow rate of the abrasive",
    type: "number",
    value: 0.1,
    scope: "post"
  },
  writeCuttingModes: {
    title: "Write cutting modes",
    description: "Enable to document the colors used for the laser cutting modes",
    type: "boolean",
    value: false,
    scope: "post"
  }
};

var gFormat = createFormat({prefix:"G", decimals:0, width:2, zeropad:true});
var mFormat = createFormat({prefix:"M", decimals:0, width:2, zeropad:true});
var oFormat = createFormat({zeropad:false, decimals:0});
var dFormat = createFormat({prefix:"D", decimals:0});
var eFormat = createFormat({prefix:"E", zeropad:false, decimals:0});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var feedFormat = createFormat({decimals:(unit == MM ? 0 : 1)});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-1000
var millisecFormat = createFormat({decimals:0, forceDecimal:false, scale:1000});

var xOutput = createVariable({prefix:"X"}, xyzFormat);
var yOutput = createVariable({prefix:"Y"}, xyzFormat);
var zOutput = createVariable({prefix:"Z"}, xyzFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var dOutput = createVariable({force:true}, dFormat);

// circular output
var iOutput = createReferenceVariable({prefix:"I", force:true}, xyzFormat);
var jOutput = createReferenceVariable({prefix:"J", force:true}, xyzFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G2-G3 - linear moves do not use G-word
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gUnitModal = createModal({}, gFormat); // modal group 6 // G70-71

var WARNING_WORK_OFFSET = 0;

// collected state
var sequenceNumber;
var currentWorkOffset;
var userPressure = 0;
var dwellFlag = false;

var AUTO = 0;
var HIGH = 1;
var MEDIUM = 2;
var LOW = 3;

var jetModes = new Array(
  {mode:JET_MODE_THROUGH, quality:AUTO, pressure:15000},
  {mode:JET_MODE_THROUGH, quality:HIGH, pressure:20000},
  {mode:JET_MODE_THROUGH, quality:MEDIUM, pressure:16000},
  {mode:JET_MODE_THROUGH, quality:LOW, pressure:12000}
  // {mode:JET_MODE_ETCHING, quality:AUTO, pressure:0},
  // {mode:JET_MODE_VAPORIZE, quality:AUTO, pressure:0}
);

function getJetModeString(mode) {
  switch (mode) {
  case JET_MODE_THROUGH:
    return "THROUGH";
  case JET_MODE_ETCHING:
    return "ETCHING";
  case JET_MODE_VAPORIZE:
    return "VAPORIZE";
  default:
    return "UNKNOWN";
  }
}

function getJetQualityString(mode) {
  switch (mode) {
  case AUTO:
    return "AUTO";
  case HIGH:
    return "HIGH";
  case MEDIUM:
    return "MEDIUM";
  case LOW:
    return "LOW";
  default:
    return "UNKNOWN";
  }
}

function getJetPressure(_mode, _quality) {
  if (userPressure != 0) {
    return userPressure;
  }
  for (var i = 0; i < jetModes.length; ++i) {
    if ((_mode == jetModes[i].mode) && (_quality == jetModes[i].quality)) {
      return jetModes[i].pressure;
    }
  }
  error(localize("Unsupported Cutting Mode: ") + _mode + ", " + _quality);
  return 0;
}

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
  return "(" + String(text).replace(/[()]/g, "") + ")";
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

function onOpen() {

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");
  writeln("%"); // required

  if (programName) {
    var programNumber;
    try {
      programNumber = getAsInt(programName);
    } catch (e) {
      error(localize("Program name must be a number."));
      return;
    }
    if (!((programNumber >= 1) && (programNumber <= 9999))) {
      error(localize("Program number is out of range."));
    }

    writeln("O" + oFormat.format(programNumber));
  }

  if (programComment) {
    writeComment(programComment);
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
  if (getProperty("writeCuttingModes")) {
    for (var i = 0; i < jetModes.length; ++i) {
      var qualityText = "";
      if (jetModes[i].mode == JET_MODE_THROUGH) {
        qualityText = localize(", Quality") + ": " + getJetQualityString(jetModes[i].quality) + ", ";
      }
      writeComment(
        localize("Cutting Mode") + ": " + getJetModeString(jetModes[i].mode) +
        qualityText +
        localize("Pressure") + ": " + jetModes[i].pressure
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

  switch (unit) {
  case IN:
    writeBlock(gUnitModal.format(20));
    break;
  case MM:
    writeBlock(gUnitModal.format(21));
    break;
  }

  // startup block
  writeBlock(
    gFormat.format(0),
    gFormat.format(17),
    gFormat.format(40),
    gFormat.format(49),
    gFormat.format(80),
    gFormat.format(90)
  );
}

function onComment(message) {
  writeComment(message);
}

/** Force output of X, Y, and Z. */
function forceXYZ() {
  xOutput.reset();
  yOutput.reset();
}

/** Force output of X, Y, Z, and F on next output. */
function forceAny() {
  forceXYZ();
  feedOutput.reset();
}

function onSection() {

  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment(comment);
    }
  }
  
  switch (tool.type) {
  case TOOL_WATER_JET:
    writeComment("T" + tool.number + " = " + xyzFormat.format(tool.jetDiameter) + " WATER JET");
    break;
  default:
    error(localize("The CNC does not support the required tool/process. Only water jet cutting is supported."));
    return;
  }
  
  var newWorkOffset = isFirstSection() ||
    (getPreviousSection().workOffset != currentSection.workOffset); // work offset changes

  { // pure 3D
    var remaining = currentSection.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported."));
      return;
    }
    setRotation(remaining);
  }

  forceAny();

  var workOffset = currentSection.workOffset;
  if (workOffset == 0) {
    warningOnce(localize("Work offset has not been specified. Using G54 as WCS."), WARNING_WORK_OFFSET);
    workOffset = 1;
  }

  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  gAbsIncModal.reset();
  gMotionModal.reset();
  writeBlock(
    gMotionModal.format(0),
    gAbsIncModal.format(90),
    gFormat.format(53 + workOffset),
    xOutput.format(initialPosition.x), yOutput.format(initialPosition.y)
  );

  switch (currentSection.jetMode) {
  case JET_MODE_THROUGH:
    writeBlock(mFormat.format(300), eFormat.format(getJetPressure(currentSection.jetMode, currentSection.quality)));
    break;
  case JET_MODE_ETCHING:
    error(localize("Etch cutting mode is not supported."));
    break;
  case JET_MODE_VAPORIZE:
    error(localize("Vaporize cutting mode is not supported."));
    break;
  default:
    error(localize("Unsupported cutting mode."));
    return;
  }
}

function formatDwell(seconds) {
  return [gFormat.format(4), "P" + millisecFormat.format(seconds)];
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.001, seconds, 99999.999);
  writeBlock(formatDwell(seconds));
}

function onCycle() {
  error(localize("Canned cycles are not supported by CNC."));
}

function onCyclePoint(x, y, z) {
}

function onCycleEnd() {
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

var shapeArea = 0;
var shapePerimeter = 0;
var shapeSide = "inner";
var cuttingSequence = "";

function onParameter(name, value) {
  if (name == "action") {
    if (value == "pierce") {
      // add delay if desired
    } else {
      var sText1 = String(value);
      var sText2 = sText1.split(":");
      if (sText2.length != 2) {
        error(localize("Invalid action command: ") + value);
        return;
      }
      if ((String(sText2[0]).toUpperCase() == "PRESSURE")) {
        userPressure = Number(sText2[1]);
        if ((isNaN(userPressure)) || (userPressure <= 0)) {
          error(localize("Invalid pressure value: ") + sText2[1]);
        }
      } else {
        error(localize("Invalid action command: ") + value);
        return;
      }
    }
  } else if (name == "shapeArea") {
    shapeArea = value;
  } else if (name == "shapePerimeter") {
    shapePerimeter = value;
  } else if (name == "shapeSide") {
    shapeSide = value;
  } else if (name == "beginSequence") {
    if (value == "piercing") {
      if (cuttingSequence != "piercing") {
        if (getProperty("allowHeadSwitches")) {
          // Allow head to be switched here
          // onCommand(COMMAND_STOP);
        }
      }
    } else if (value == "cutting") {
      if (cuttingSequence == "piercing") {
        if (getProperty("allowHeadSwitches")) {
          // Allow head to be switched here
          // onCommand(COMMAND_STOP);
        }
      }
    }
    cuttingSequence = value;
  }
}

function onPower(power) {
  if (power) {
    gMotionModal.reset();
    writeBlock(
      mFormat.format(3),
      formatDwell(4.0),
      gMotionModal.format(0),
      "A" + getProperty("abrasiveFlow"), formatDwell(2.5),
      formatDwell(getProperty("pierceTime"))
    );
  } else {
    dwellFlag = true;
    gMotionModal.reset();
    writeBlock(gMotionModal.format(0), "A0", formatDwell(2.5));
    writeBlock(mFormat.format(5));
  }
}

function onRapid(_x, _y, _z) {
  // at least one axis is required
  if (pendingRadiusCompensation >= 0) {
    // ensure that we end at desired position when compensation is turned off
    xOutput.reset();
    yOutput.reset();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var dwell = "";
  if (dwellFlag) {
    dwell = formatDwell(1.5);
    dwellFlag = false;
  }
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      var d = tool.diameterOffset;
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        dOutput.reset();
        writeBlock(gMotionModal.format(0), gFormat.format(41), dOutput.format(d), x, y, z, dwell);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        dOutput.reset();
        writeBlock(gMotionModal.format(0), gFormat.format(42), dOutput.format(d), x, y, z, dwell);
        break;
      default:
        writeBlock(gMotionModal.format(0), gFormat.format(40), x, y, z, dwell);
      }
    } else {
      writeBlock(gMotionModal.format(0), x, y, z, dwell);
    }
    
    // feedOutput.reset();
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
  var z = zOutput.format(_z);
  var f = feedOutput.format(feed);
  var dwell = "";
  if (dwellFlag) {
    dwell = formatDwell(1.5);
    dwellFlag = false;
  }
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      var d = tool.diameterOffset;
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        dOutput.reset();
        writeBlock(gMotionModal.format(1), gFormat.format(41), dOutput.format(d), x, y, z, f, dwell);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        dOutput.reset();
        writeBlock(gMotionModal.format(1), gFormat.format(42), dOutput.format(d), x, y, z, f, dwell);
        break;
      default:
        writeBlock(gMotionModal.format(1), gFormat.format(40), x, y, z, f, dwell);
      }
    } else {
      writeBlock(gMotionModal.format(1), x, y, z, f, dwell);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      feedOutput.reset(); // force feed on next line
    } else {
      writeBlock(f);
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
    pendingRadiusCompensation = -1;
    switch (radiusCompensation) {
    case RADIUS_COMPENSATION_LEFT:
      writeBlock(gFormat.format(41));
      break;
    case RADIUS_COMPENSATION_RIGHT:
      writeBlock(gFormat.format(42));
      break;
    default:
      writeBlock(gFormat.format(40));
    }
  }

  var start = getCurrentPosition();

  if (isFullCircle()) {
    switch (getCircularPlane()) {
    case PLANE_XY:
      forceXYZ();
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

var mapCommand = {
  COMMAND_STOP:0,
  COMMAND_OPTIONAL_STOP:1
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
  forceAny();
  userPressure = 0;
}

function onClose() {
  writeBlock(mFormat.format(5)); // turn off plasma
  writeBlock(mFormat.format(30)); // stop program - rewind
}

function setProperty(property, value) {
  properties[property].current = value;
}
