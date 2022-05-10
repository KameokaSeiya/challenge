/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  AMADA post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {529DEECD-52B5-4DC1-81AE-12966900A1E8}
*/

description = "AMADA Laser";
vendor = "AMADA";
vendorUrl = "http://www.amada.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

extension = "nc";
programNameIsInteger = true;
setCodePage("ascii");

capabilities = CAPABILITY_JET;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(90);
allowHelicalMoves = false;
allowedCircularPlanes = undefined; // allow any circular motion

// user-defined properties
properties = {
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
  useRetracts: {
    title: "Use retracts",
    description: "Output retracts, otherwise only output part contours for importing into a third-party jet application.",
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
  materialType: {
    title: "Material type",
    description: "Specifies the material type for the M102 database call.",
    type: "string",
    value: "O-CRS0",
    scope: "post"
  },
  materialThickness: {
    title: "Material thickness",
    description: "Specifies the material thickness for the M102 database call.",
    type: "string",
    value: ".120",
    scope: "post"
  },
  useStockForThickness: {
    title: "Use stock for thickenss",
    description: "Specifies whether the stock thickness should be used for the M102 database call, instead of the 'use stock for thickness' property.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  wcsX: {
    title: "WCS X",
    description: "Sets the X WCS position.",
    type: "number",
    value: 50,
    scope: "post"
  },
  wcsY: {
    title: "WCS Y",
    description: "Sets the Y WCS position.",
    type: "number",
    value: 50,
    scope: "post"
  }
};

var gFormat = createFormat({prefix: "G", decimals: 0});
var mFormat = createFormat({prefix: "M", decimals: 0});

var xyzFormat = createFormat({decimals: (unit == MM ? 3 : 4)});
var feedFormat = createFormat({decimals: (unit == MM ? 1 : 2)});
var secFormat = createFormat({decimals: 3, forceDecimal: true}); // seconds - range 0.001-1000

var xOutput = createVariable({prefix: "X"}, xyzFormat);
var yOutput = createVariable({prefix: "Y"}, xyzFormat);
var feedOutput = createVariable({prefix: "F"}, feedFormat);

// circular output
var rOutput = createVariable({prefix: "R", force: true}, xyzFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-21

var WARNING_WORK_OFFSET = 0;

// collected state
var sequenceNumber;
var currentWorkOffset;
var split = false;
var cutQuality;

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
  writeln("%");

  if (programName) {
    writeBlock(programName, programComment ? "(" + programComment + ")" : "");
  }

  // absolute coordinates and feed per min
  writeBlock(gAbsIncModal.format(90), gFormat.format(92), xOutput.format(getProperty("wcsX")), yOutput.format(getProperty("wcsY")));

  switch (unit) {
  case IN:
    writeBlock(gUnitModal.format(20));
    break;
  case MM:
    writeBlock(gUnitModal.format(21));
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
}

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
  forceXYZ();
  feedOutput.reset();
}

function onSection() {
  var insertToolCall = isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number);

  var retracted = false; // specifies that the tool has been retracted to the safe plane
  var newWorkOffset = isFirstSection() ||
    (getPreviousSection().workOffset != currentSection.workOffset); // work offset changes
  var newWorkPlane = isFirstSection() ||
    !isSameDirection(getPreviousSection().getGlobalFinalToolAxis(), currentSection.getGlobalInitialToolAxis());

  if (hasParameter("operation:machineQualityControl")) {  // check to see if quaility is manaul Feeds or automatic
    var qualityType = getParameter("operation:machineQualityControl");
    if (qualityType == "automatic") {
      auto = true;
    }
  }

  onCommand(COMMAND_COOLANT_OFF);

  switch (tool.type) {
  case TOOL_LASER_CUTTER:
    break;
  default:
    error(localize("The CNC does not support the required tool."));
    return;
  }

  if (insertToolCall) {
    var materialThickness = undefined;
    if (getProperty("useStockForThickness")) {
      if (hasGlobalParameter("stock-lower-z") && hasGlobalParameter("stock-upper-z")) {
        materialThickness = xyzFormat.format(Math.abs(getGlobalParameter("stock-lower-z") - getGlobalParameter("stock-upper-z")));
      } else {
        materialThickness = getProperty("materialThickness");
      }
    } else {
      materialThickness = getProperty("materialThickness");
    }

    writeBlock(mFormat.format(102) + "(" + getProperty("materialType") + materialThickness + ")"); // material designation
    writeBlock(mFormat.format(100)); //Laser mode on
  }

  switch (currentSection.jetMode) {
  case JET_MODE_THROUGH:
    cutQuality = 1;
    break;
  case JET_MODE_ETCHING:
    cutQuality = 10;
    break;
  default:
    error(localize("Unsupported cutting mode."));
    return;
  }
  writeBlock("E" + cutQuality); // cut condition select

  forceXYZ();

  { // pure 3D
    var remaining = currentSection.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported."));
      return;
    }
    setRotation(remaining);
  }

  forceAny();

  split = false;
  if (getProperty("useRetracts")) {

    var initialPosition = getFramePosition(currentSection.getInitialPosition());

    if (insertToolCall || retracted) {
      gMotionModal.reset();

      if (!machineConfiguration.isHeadConfiguration()) {
        writeBlock(
          gAbsIncModal.format(90),
          gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y)
        );
      } else {
        writeBlock(
          gAbsIncModal.format(90),
          gMotionModal.format(0),
          xOutput.format(initialPosition.x),
          yOutput.format(initialPosition.y)
        );
      }
    } else {
      writeBlock(
        gAbsIncModal.format(90),
        gMotionModal.format(0),
        xOutput.format(initialPosition.x),
        yOutput.format(initialPosition.y)
      );
    }
  } else {
    split = true;
  }
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.001, seconds, 99999.999);
  writeBlock(gFormat.format(4), "X" + secFormat.format(seconds));
}

function onCycle() {
  onError("Drilling is not supported by CNC.");
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

function onRapid(_x, _y, _z) {

  if (!getProperty("useRetracts") && ((movement == MOVEMENT_RAPID) || (movement == MOVEMENT_HIGH_FEED))) {
    doSplit();
    return;
  }

  if (split) {
    split = false;
    var start = getCurrentPosition();
    onExpandedRapid(start.x, start.y, start.z);
  }

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

  if (!getProperty("useRetracts") && ((movement == MOVEMENT_RAPID) || (movement == MOVEMENT_HIGH_FEED))) {
    doSplit();
    return;
  }

  if (split) {
    resumeFromSplit(feed);
  }

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
        writeBlock(gMotionModal.format(1), gFormat.format(41), x, y, conditional(auto = false, f));
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gMotionModal.format(1), gFormat.format(42), x, y, conditional(auto = false, f));
        break;
      default:
        writeBlock(gMotionModal.format(1), gFormat.format(40), x, y, conditional(auto = false, f));
      }
    } else {
      writeBlock(gMotionModal.format(1), x, y, conditional(auto = false, f));
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      feedOutput.reset(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(1), conditional(auto = false, f));
    }
  }
}

function onRapid5D(_x, _y, _z, _a, _b, _c) {
  error(localize("The CNC does not support 5-axis simultaneous toolpath."));
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed) {
  error(localize("The CNC does not support 5-axis simultaneous toolpath."));
}

function doSplit() {
  if (!split) {
    split = true;
    gMotionModal.reset();
    xOutput.reset();
    yOutput.reset();
    feedOutput.reset();
  }
}

function resumeFromSplit(feed) {
  if (split) {
    split = false;
    var start = getCurrentPosition();
    var _pendingRadiusCompensation = pendingRadiusCompensation;
    pendingRadiusCompensation = -1;
    onExpandedLinear(start.x, start.y, start.z, feed);
    pendingRadiusCompensation = _pendingRadiusCompensation;
  }
}

/** Adjust final point to lie exactly on circle. */
function CircularData(_plane, _center, _end) {
  // use Output variables, since last point could have been adjusted if previous move was circular
  var start = new Vector(xOutput.getCurrent(), yOutput.getCurrent(), 0 /*zOutput.getCurrent()*/);
  var saveStart = new Vector(start.x, start.y, start.z);
  var center = new Vector(
    xyzFormat.getResultingValue(_center.x),
    xyzFormat.getResultingValue(_center.y),
    xyzFormat.getResultingValue(_center.z)
  );
  var end = new Vector(_end.x, _end.y, _end.z);
  switch (_plane) {
  case PLANE_XY:
    start.setZ(center.z);
    end.setZ(center.z);
    break;
  case PLANE_ZX:
    start.setY(center.y);
    end.setY(center.y);
    break;
  case PLANE_YZ:
    start.setX(center.x);
    end.setX(center.x);
    break;
  default:
    this.center = new Vector(_center.x, _center.y, _center.z);
    this.start = new Vector(start.x, start.y, start.z);
    this.end = new Vector(_end.x, _end.y, _end.z);
    this.offset = Vector.diff(center, start);
    this.radius = this.offset.length;
    break;
  }
  this.start = new Vector(
    xyzFormat.getResultingValue(start.x),
    xyzFormat.getResultingValue(start.y),
    xyzFormat.getResultingValue(start.z)
  );
  var temp = Vector.diff(center, start);
  this.offset = new Vector(
    xyzFormat.getResultingValue(temp.x),
    xyzFormat.getResultingValue(temp.y),
    xyzFormat.getResultingValue(temp.z)
  );
  this.center = Vector.sum(this.start, this.offset);
  this.radius = this.offset.length;

  temp = Vector.diff(end, center).normalized;
  this.end = new Vector(
    xyzFormat.getResultingValue(this.center.x + temp.x * this.radius),
    xyzFormat.getResultingValue(this.center.y + temp.y * this.radius),
    xyzFormat.getResultingValue(this.center.z + temp.z * this.radius)
  );

  switch (_plane) {
  case PLANE_XY:
    this.start.setZ(saveStart.z);
    this.end.setZ(_end.z);
    this.offset.setZ(0);
    break;
  case PLANE_ZX:
    this.start.setY(saveStart.y);
    this.end.setY(_end.y);
    this.offset.setY(0);
    break;
  case PLANE_YZ:
    this.start.setX(saveStart.x);
    this.end.setX(_end.x);
    this.offset.setX(0);
    break;
  }
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  
  if (!getProperty("useRetracts") && ((movement == MOVEMENT_RAPID) || (movement == MOVEMENT_HIGH_FEED))) {
    doSplit();
    return;
  }
  
  var circle = new CircularData(getCircularPlane(), new Vector(cx, cy, cz), new Vector(x, y, z));

  var r = circle.radius;
  if (toDeg(getCircularSweep()) > (180 + 1e-9)) {
    r = -r; // allow up to <360 deg arcs
  }

  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }

  if (split) {
    resumeFromSplit(feed);
  }

  var start = circle.start;
  if (isFullCircle()) {
    if (isHelical()) {
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(circle.end.x), rOutput.format(r), conditional(auto = false, feedOutput.format(feed)));
      break;
    default:
      linearize(tolerance);
    }
  } else {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(circle.end.x), yOutput.format(circle.end.y), rOutput.format(r), conditional(auto = false, feedOutput.format(feed)));
      break;
    default:
      linearize(tolerance);
    }
  }
}

var mapCommand = {
  COMMAND_STOP: 0,
  COMMAND_OPTIONAL_STOP: 1,
  COMMAND_END: 2
};

function onCommand(command) {
  switch (command) {
  case COMMAND_POWER_ON:
    writeBlock(mFormat.format(103) + (cutQuality == 10 ? " A0" : ""));
    return;
  case COMMAND_POWER_OFF:
    writeBlock(mFormat.format(104));
    return;
  case COMMAND_COOLANT_ON:
    return;
  case COMMAND_COOLANT_OFF:
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
  writeBlock(mFormat.format(101)); // laser mode off
  writeBlock(gFormat.format(50)); // return home
  writeBlock(gFormat.format(30)); // program end
  writeln("%");
}

function setProperty(property, value) {
  properties[property].current = value;
}
