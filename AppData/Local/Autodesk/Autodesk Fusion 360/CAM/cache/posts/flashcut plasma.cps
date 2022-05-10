/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  FlashCut plasma post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {71AE40B8-DE02-4B80-ABFE-B342213EB035}
*/

description = "FlashCut plasma";
vendor = "FlashCut";
vendorUrl = "http://www.flashcutcnc.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic plasma post for FlashCut control.";

extension = "cnc";
setCodePage("ascii");

capabilities = CAPABILITY_JET;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = false;
allowedCircularPlanes = 1 << PLANE_XY; // arcs in xy plane only

// user-defined properties
properties = {
  writeMachine: {
    title: "Write machine",
    description: "Output the machine settings in the header of the code.",
    group: 1,
    type: "boolean",
    value: false,
    scope: "post"
  },
  showSequenceNumbers: {
    title: "Use sequence numbers",
    description: "Use sequence numbers for each block of outputted code.",
    group: 1,
    type: "boolean",
    value: false,
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
    value: 5,
    scope: "post"
  },
  separateWordsWithSpace: {
    title: "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    group: 1,
    type: "boolean",
    value: true,
    scope: "post"
  },
  useFabricationHeadId: {
    title: "Use M106 H",
    description: "Output M106 fabrication head id in NC code",
    group: 0,
    type: "boolean",
    value: false,
    scope: "post"
  },
  fabricationHeadId: {
    title: "Fabrication head id",
    description: "Used when \" Use M106 H \" fabrication head specification is enabled",
    group: 0,
    type: "string",
    value: "plasma1",
    scope: "post"
  },
  OutputTorchOnOff: {
    title: "Output torch on/off comannds",
    description: "Output M50/M51 torch on off commands in NC code",
    group: 0,
    type: "boolean",
    value: false,
    scope: "post"
  },
  suppressComments: {
    title: "Omit comments",
    description: "Yes - Omit all comments. No - Print comments",
    group: 1,
    type: "boolean",
    value: true,
    scope: "post"
  }
};

var gFormat = createFormat({prefix:"G", decimals:0, zeropad: true, width: 2});
var mFormat = createFormat({prefix:"M", decimals:0});

var xyzFormat = createFormat({decimals:(unit == MM ? 5 : 6), forceDecimal: true, trim: false});
var feedFormat = createFormat({decimals:(unit == MM ? 1 : 2), forceDecimal: true});
var secFormat = createFormat({decimals:3}); // seconds - range 0.001-1000

var xOutput = createVariable({prefix:"X"}, xyzFormat);
var yOutput = createVariable({prefix:"Y"}, xyzFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);

// circular output
var iOutput = createReferenceVariable({prefix:"I", force: true}, xyzFormat);
var jOutput = createReferenceVariable({prefix:"J", force: true}, xyzFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-21

// collected state
var sequenceNumber;

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
  if (!getProperty("suppressComments")) {
    writeln(formatComment(text));
  }
}

function onOpen() {
  
  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");

  if (programName) {
    writeComment(programName);
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

  if (hasGlobalParameter("material")) {
    writeComment("MATERIAL = " + getGlobalParameter("material"));
  }

  if (hasGlobalParameter("material-hardness")) {
    writeComment("MATERIAL HARDNESS = " + getGlobalParameter("material-hardness"));
  }

  { // stock - workpiece
    var workpiece = getWorkpiece();
    var delta = Vector.diff(workpiece.upper, workpiece.lower);
    if (delta.isNonZero()) {
      writeComment("THICKNESS = " + xyzFormat.format(workpiece.upper.z - workpiece.lower.z));
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

  if (getProperty("useFabricationHeadId")) {
    writeBlock(mFormat.format(106), "H" + getProperty("fabricationHeadId"));
  }
}

function onComment(message) {
  writeComment(message);
}

/**
  Force output of X, Y.
*/
function forceXYZ() {
  xOutput.reset();
  yOutput.reset();
}

/**
  Force output of X, Y, and F on next output.
*/
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
  case TOOL_PLASMA_CUTTER:
    // pass through. checking tool type only
    break;
  default:
    error(localize("The CNC does not support the required tool."));
    return;
  }

  switch (currentSection.jetMode) {
  case JET_MODE_THROUGH:
    // pass through. checking quality type only
    break;
  default:
    error(localize("Unsupported cutting mode."));
    return;
  }

  if (tool.comment) {
    writeComment(tool.comment);
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
  if (isFirstSection()) {
    writeBlock(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y));
  }
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.001, seconds, 99999.999);
  writeBlock(gFormat.format(4), "P" + secFormat.format(seconds));
}

function onCycle() {
  onError("Drilling is not supported by CNC.");
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

var deviceOn = false;
function onPower(power) {
  
  if (power) {
    deviceOn = true;
    if (getProperty("OutputTorchOnOff")) {
      writeBlock(mFormat.format(50));
    }
  } else {
    deviceOn = false;
    if (getProperty("OutputTorchOnOff")) {
      writeBlock(mFormat.format(51));
      onDwell(1000);
    }
  }
}

function checkPowerMode(moveType) {
  if (deviceOn != moveType) {
    if ((currentSection.getMovements() & (1 << MOVEMENT_HIGH_FEED) || (highFeedMapping != HIGH_FEED_NO_MAPPING)))  {
      error(localize("The post property \"High feedrate mapping\" has been set and is in conflict with cutting tool on/off control." + EOL +
                     "Set High feedrate mapping to \"Preserve rapid movement\" to eliminate this error."));
    } else {
      if (deviceOn) {
        error(localize("The cutting tool is ON during a rapid move."));
      } else {
        error(localize("The cutting tool is OFF during a feed move."));
      }
    }
  }
}

function onRapid(_x, _y, _z) {
  checkPowerMode(false);

  if (xyzFormat.areDifferent(_x, getCurrentPosition().x) ||
    xyzFormat.areDifferent(_y, getCurrentPosition().y)) {
    gMotionModal.reset();
    forceXYZ();
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    if (pendingRadiusCompensation >= 0) {
      error(localize("Radius compensation mode cannot be changed at rapid traversal."));
      return;
    }
    writeBlock(gMotionModal.format(0), x, y);
  }
}

function onLinear(_x, _y, _z, feed) {
  checkPowerMode(true);
  // at least one axis is required
  if (pendingRadiusCompensation >= 0) {
    // ensure that we end at desired position when compensation is turned off
    forceXYZ();
  }
  if (xyzFormat.areDifferent(_x, getCurrentPosition().x) ||
    xyzFormat.areDifferent(_y, getCurrentPosition().y)) {
    gMotionModal.reset();
    forceXYZ();
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var f = feedOutput.format(feed);
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gFormat.format(41));
        writeBlock(gMotionModal.format(1), x, y, f);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gFormat.format(42));
        writeBlock(gMotionModal.format(1), x, y, f);
        break;
      default:
        writeBlock(gFormat.format(40));
        writeBlock(gMotionModal.format(1), x, y, f);
      }
    } else {
      writeBlock(gMotionModal.format(1), x, y, f);
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
  checkPowerMode(true);
  
  //show xyij for each line
  gMotionModal.reset();
  forceXYZ();
  // one of X/Y and I/J are required and likewise
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }
  var start = getCurrentPosition();
  switch (getCircularPlane()) {
  case PLANE_XY:
    writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
    break;
  default:
    linearize(tolerance);
  }
}

var mapCommand = {
  COMMAND_STOP:0,
  COMMAND_OPTIONAL_STOP:1,
  COMMAND_END:2
};

function onCommand(command) {
  switch (command) {
  case COMMAND_POWER_ON:
    return;
  case COMMAND_POWER_OFF:
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
  writeBlock(gFormat.format(0), xOutput.format(0), yOutput.format(0));
  onImpliedCommand(COMMAND_END);
}

function setProperty(property, value) {
  properties[property].current = value;
}
