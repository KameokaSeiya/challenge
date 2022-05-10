/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Philips post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {DA9A525E-9C72-4AC3-8558-930DBF28A415}
*/

description = "Maho Philips 432";
vendor = "Philips";
vendorUrl = "http://www.autodesk.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic post for MAHO machines using Philips CNC 432 control. Use property 'vertical' to switch between vertical and horizontal machining.";

extension = "nc";
programNameIsInteger = true;
setCodePage("ascii");
capabilities = CAPABILITY_MILLING;

tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(360);
allowHelicalMoves = false;
allowSpirallMoves = false;
allowedCircularPlanes = 1 << PLANE_XY;

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
  writeTools: {
    title: "Write tool list",
    description: "Output a tool list in the header of the code.",
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
    value: 1,
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
  useRadius: {
    title: "Radius arcs",
    description: "If yes is selected, arcs are outputted using radius values rather than IJK.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  vertical: {
    title: "Vertical",
    description: "Choose between machining in G17/G18.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  useM53M54: {
    title: "Use M53/M54",
    description: "Output M53/M54 for driven machine head.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  writeComments: {
    title: "Output comments",
    description: "Enable to allow the usage of comments.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  useCycles: {
    title: "Use cycles",
    description: "Specifies if canned drilling cycles should be used.",
    type: "boolean",
    value: true,
    scope: "post"
  }
};

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,=_-";

var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"M", decimals:0});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var feedFormat = createFormat({decimals:(unit == MM ? 1 : 2)});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:1}); // seconds - range 0.1-900
var taperFormat = createFormat({decimals:1, scale:DEG});

var xOutput = createVariable({prefix:"X"}, xyzFormat);
var yOutput = createVariable({prefix:"Y"}, xyzFormat);
var zOutput = createVariable({prefix:"Z"}, xyzFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var sOutput = createVariable({prefix:"S", force:true}, rpmFormat);

// circular output
var iOutput = createVariable({prefix:"I", force:true}, xyzFormat);
var jOutput = createVariable({prefix:"J", force:true}, xyzFormat);
var kOutput = createVariable({prefix:"K", force:true}, xyzFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gUnitModal = createModal({}, gFormat); // modal group 6 // G70-71
var gCycleModal = createModal({}, gFormat); // modal group 9 // G81, ...

var WARNING_WORK_OFFSET = 0;
var WARNING_LENGTH_OFFSET = 1;
var WARNING_DIAMETER_OFFSET = 2;

// collected state
var sequenceNumber;
var currentWorkOffset;

/**
  Writes the specified block.
*/

function invertAxis() {
  var yFormat = createFormat({decimals:(unit == MM ? 3 : 4), scale:-1});
  yOutput = createVariable({prefix:"Z"}, yFormat);
  zOutput.setPrefix("Y"); // no scaling
  kOutput = createVariable({prefix:"K", force:true}, yFormat);
}

function writeBlock() {
  if (getProperty("showSequenceNumbers")) {
    writeWords2("N" + sequenceNumber, arguments);
    sequenceNumber += getProperty("sequenceNumberIncrement");
  } else {
    writeWords(arguments);
  }
}

/**
  Output a comment.
*/
function writeComment(text) {
  if (getProperty("writeComments")) {
    writeln(formatComment(text));
  }
}

function formatComment(text) {
  return "(" + filterText(String(text).toUpperCase(), permittedCommentChars).replace(/[()]/g, "") + ")";
}

function onOpen() {
  if (getProperty("vertical")) {
    invertAxis();
  }
  if (getProperty("useRadius")) {
    maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
  }
  sequenceNumber = getProperty("sequenceNumberStart");

  if (programName) {
    var programId;
    try {
      programId = getAsInt(programName);
    } catch (e) {
      error(localize("Program name must be a number."));
    }
    if (!((programId >= 9000) && (programId <= 9999))) {
      error(localize("Program number is out of range. Use program numbers within range 9000 to 9999."));
    }
    writeln("%PM");
    writeln("N" + programId);
    writeComment(programName);
  } else {
    error(localize("Program name has not been specified."));
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
        var comment = "T" + toolFormat.format(tool.number) + "  " +
          "D=" + xyzFormat.format(tool.diameter) + " " +
          localize("CR") + "=" + xyzFormat.format(tool.cornerRadius);
        if ((tool.taperAngle > 0) && (tool.taperAngle < Math.PI)) {
          comment += " " + localize("TAPER") + "=" + taperFormat.format(tool.taperAngle) + localize("deg");
        }
        if (zRanges[tool.number]) {
          comment += " - " + localize("ZMIN") + "=" + xyzFormat.format(zRanges[tool.number].getMinimum());
        }
        comment += " - " + getToolTypeName(tool.type);
        writeComment(comment);
      }
    }
  }

  var workOffset = getSection(0).workOffset;
  if (workOffset == 0) {
    warningOnce(localize("Work offset has not been specified. Using G54 as WCS."), WARNING_WORK_OFFSET);
    workOffset = 1;
  }
  if (workOffset > 0) {
    if (workOffset != currentWorkOffset) {
      writeBlock(gFormat.format(53 + workOffset)); // G54->G59
      currentWorkOffset = workOffset;
    }
  }

  { // stock - workpiece
    var workpiece = getWorkpiece();
    var delta = Vector.diff(workpiece.upper, workpiece.lower);
    if (delta.isNonZero()) {
      writeBlock(gFormat.format(98), "X" + xyzFormat.format(workpiece.lower.x) + " Y" + xyzFormat.format(workpiece.lower.z) + " Z" + xyzFormat.format(-workpiece.upper.y) + " I" + xyzFormat.format(delta.x) + " J" + xyzFormat.format(delta.z) + " K" + xyzFormat.format(delta.y));
      writeBlock(gFormat.format(99), "X" + xyzFormat.format(workpiece.lower.x) + " Y" + xyzFormat.format(workpiece.lower.z) + " Z" + xyzFormat.format(-workpiece.upper.y) + " I" + xyzFormat.format(delta.x) + " J" + xyzFormat.format(delta.z) + " K" + xyzFormat.format(delta.y));
    }
  }
  // absolute coordinates and feed per min
  writeBlock(gAbsIncModal.format(90));
  writeBlock(gPlaneModal.format(getPlane()));
  
  if (getProperty("useM53M54")) {
    if (getProperty("vertical")) {
      writeBlock(mFormat.format(54));
    } else {
      writeBlock(mFormat.format(53));
    }
  }
  switch (unit) {
  case IN:
    writeBlock(gUnitModal.format(70));
    break;
  case MM:
    writeBlock(gUnitModal.format(71));
    break;
  }
}

function getPlane() {
  if (getProperty("vertical")) {
    return 18;
  } else {
    return 17;
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

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
  forceXYZ();
  feedOutput.reset();
}

function onParameter(name, value) {
}

function onSection() {

  var insertToolCall = isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number);
  
  var retracted = false; // specifies that the tool has been retracted to the safe plane
  var newWorkOffset = isFirstSection() ||
    (getPreviousSection().workOffset != currentSection.workOffset); // work offset changes

  if (insertToolCall || newWorkOffset) {
    // retract to safe plane
    // retracted = true;
    // writeBlock(gFormat.format(74), "Y" + xyzFormat.format(machineConfiguration.getRetractPlane()), "L1"); // retract
  }
  
  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment(comment);
    }
  }

  if (insertToolCall) {
    gMotionModal.reset();
    if (!isFirstSection()) {
      onCommand(COMMAND_COOLANT_OFF);
    }
    if (tool.number > 9999) {
      warning(localize("Tool number exceeds maximum value."));
    }

    writeBlock("T" + toolFormat.format(tool.number), mFormat.format(6));
    if (tool.comment) {
      writeComment(tool.comment);
    }

    /*
    if (getProperty("preloadTool")) {
      var nextTool = getNextTool(tool.number);
      if (nextTool) {
        writeBlock("T" + toolFormat.format(nextTool.number));
      } else {
        // preload first tool
        var section = getSection(0);
        var firstToolNumber = section.getTool().number;
        if (tool.number != firstToolNumber) {
          writeBlock("T" + toolFormat.format(firstToolNumber));
        }
      }
    }
*/
  }
  
  if (insertToolCall ||
      isFirstSection() ||
      (rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) ||
      (tool.clockwise != getPreviousSection().getTool().clockwise)) {
    if (spindleSpeed < 1) {
      error(localize("Spindle speed out of range."));
    }
    if (spindleSpeed > 99999) { // machine specific
      warning(localize("Spindle speed exceeds maximum value."));
    }
    writeBlock(
      sOutput.format(spindleSpeed), mFormat.format(tool.clockwise ? 3 : 4)
    );
  }

  // wcs
  if (insertToolCall) { // force work offset when changing tool
    currentWorkOffset = undefined;
  }
  var workOffset = currentSection.workOffset;
  if (workOffset == 0) {
    warningOnce(localize("Work offset has not been specified. Using G54 as WCS."), WARNING_WORK_OFFSET);
    workOffset = 1;
  }
  if (workOffset > 0) {
    if (workOffset != currentWorkOffset) {
      writeBlock(gFormat.format(53 + workOffset)); // G54->G59
      currentWorkOffset = workOffset;
    }
  }

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
  
  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  if (!retracted && !insertToolCall) {
    if (getCurrentPosition().z < initialPosition.z) {
      writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
    }
  }
  
  if (!machineConfiguration.isHeadConfiguration()) {
    writeBlock(gAbsIncModal.format(90));
    writeBlock(
      gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y)
    );
    var z = zOutput.format(initialPosition.z);
    if (z) {
      writeBlock(gMotionModal.format(0), z);
    }
  } else {
    writeBlock(gAbsIncModal.format(90));
    writeBlock(
      gMotionModal.format(0),
      xOutput.format(initialPosition.x),
      yOutput.format(initialPosition.y),
      zOutput.format(initialPosition.z)
    );
  }
  
  // set coolant after we have positioned at Z
  setCoolant(tool.coolant);
}

var currentCoolantMode = COOLANT_OFF;

function setCoolant(coolant) {
  if (coolant == currentCoolantMode) {
    return; // coolant is already active
  }
  
  var m;
  switch (coolant) {
  case COOLANT_OFF:
    m = 9;
    break;
  case COOLANT_FLOOD:
    m = 8;
    break;
  default:
    onUnsupportedCoolant(coolant);
    m = 9;
  }
  
  if (m) {
    writeBlock(mFormat.format(m));
    currentCoolantMode = coolant;
  }
}

function onDwell(seconds) {
  if (seconds > 900) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.1, seconds, 900);
  writeBlock(gFormat.format(4), "X" + secFormat.format(seconds));
}

function onSpindleSpeed(spindleSpeed) {
  writeBlock(sOutput.format(spindleSpeed));
}

var expandCurrentCycle = false;

function onCycle() {
  if (!isSameDirection(getRotation().forward, new Vector(0, 0, 1))) {
    expandCurrentCycle = true;
    return;
  }
  writeBlock(gPlaneModal.format(getPlane()));
  expandCurrentCycle = false;

  if (!getProperty("useCycles")) {
    expandCurrentCycle = true;
    return;
  }

  writeBlock(gMotionModal.format(0), zOutput.format(cycle.clearance));
  setCurrentPositionZ(cycle.clearance);
  
  switch (cycleType) {
  case "drilling":
  case "counter-boring":
    writeBlock(
      gCycleModal.format(81),
      conditional(cycle.dwell > 0, "X" + secFormat.format(cycle.dwell)),
      "Y" + xyzFormat.format(cycle.retract - cycle.stock),
      "Z" + xyzFormat.format(-cycle.depth),
      feedOutput.format(cycle.feedrate)
    );
    break;
  case "chip-breaking":
    if (cycle.accumulatedDepth < cycle.depth) {
      expandCurrentCycle = true;
    } else {
      writeBlock(
        gCycleModal.format(83),
        conditional(cycle.dwell > 0, "X" + secFormat.format(cycle.dwell)),
        "Y" + xyzFormat.format(cycle.retract - cycle.stock),
        "Z" + xyzFormat.format(-cycle.depth),
        "I" + xyzFormat.format(cycle.incrementalDepthReduction),
        conditional(cycle.chipBreakDistance > 0, "J" + xyzFormat.format(cycle.chipBreakDistance)),
        "K" + xyzFormat.format(cycle.incrementalDepth),
        feedOutput.format(cycle.feedrate)
      );
    }
    break;
  case "deep-drilling":
    writeBlock(
      gCycleModal.format(83),
      conditional(cycle.dwell > 0, "X" + secFormat.format(cycle.dwell)),
      "Y" + xyzFormat.format(cycle.retract - cycle.stock),
      "Z" + xyzFormat.format(-cycle.depth),
      "I" + xyzFormat.format(cycle.incrementalDepthReduction),
      "K" + xyzFormat.format(cycle.incrementalDepth),
      feedOutput.format(cycle.feedrate)
    );
    break;
  case "tapping":
  case "right-tapping":
    if (tool.type == TOOL_TAP_LEFT_HAND) {
      error(localize("Left tapping is not supported."));
      return;
    } else {
      var usePitch = false;// use pitch for tapping, if false use feed for tapping
      writeBlock(
        gCycleModal.format(84),
        conditional(cycle.dwell > 0, "X" + secFormat.format(cycle.dwell)),
        "Y" + xyzFormat.format(cycle.retract - cycle.stock),
        "Z" + xyzFormat.format(-cycle.depth),
        "I" + xyzFormat.format(spindleSpeed * 0.01),
        usePitch ? "J" + xyzFormat.format(tool.threadPitch) : feedOutput.format(tool.threadPitch * spindleSpeed),
        sOutput.format(spindleSpeed),
        mFormat.format(tool.clockwise ? 3 : 4)
      );
    }
    break;
  case "left-tapping":
    error(localize("Left tapping is not supported."));
    return;
  case "reaming":
    writeBlock(
      gCycleModal.format(85),
      conditional(cycle.dwell > 0, "X" + secFormat.format(cycle.dwell)),
      "Y" + xyzFormat.format(cycle.retract - cycle.stock),
      "Z" + xyzFormat.format(-cycle.depth),
      feedOutput.format(cycle.feedrate)
    );
    break;
  case "stop-boring":
    writeBlock(
      gCycleModal.format(86),
      conditional(cycle.dwell > 0, "X" + secFormat.format(cycle.dwell)),
      "Y" + xyzFormat.format(cycle.retract - cycle.stock),
      "Z" + xyzFormat.format(-cycle.depth),
      feedOutput.format(cycle.feedrate)
    );
    break;
  default:
    expandCurrentCycle = true;
  }
  if (!expandCurrentCycle) {
    forceXYZ();
  }
}

function onCyclePoint(x, y, z) {
  if (!expandCurrentCycle) {
    forceXYZ();
    writeBlock(
      gFormat.format(79), xOutput.format(x),
      (getPlane() == 17 ? yOutput.format(y) : zOutput.format(cycle.stock)),
      (getPlane() == 17 ? zOutput.format(cycle.stock) : yOutput.format(y))
    );
  } else {
    expandCyclePoint(x, y, z);
  }
}

function onCycleEnd() {
  zOutput.reset();
  gCycleModal.reset();
  gMotionModal.reset();
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

function onRapid(_x, _y, _z) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      error(localize("Radius compensation mode cannot be changed at rapid traversal."));
    }
    writeBlock(gMotionModal.format(0), x, z, y);
    feedOutput.reset();
  }
}

function onLinear(_x, _y, _z, feed) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = feedOutput.format(feed);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      if (tool.diameterOffset) {
        warningOnce(localize("Diameter offset is not supported."), WARNING_DIAMETER_OFFSET);
      }
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gMotionModal.format(1), f);
        writeBlock(gFormat.format(43), x, y, z);
        writeBlock(gFormat.format(41));
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gMotionModal.format(1), f);
        writeBlock(gFormat.format(43), x, y, z);
        writeBlock(gFormat.format(42));
        break;
      default:
        writeBlock(gMotionModal.format(1), f);
        writeBlock(gFormat.format(40), x, y, z, f);
      }
    } else {
      writeBlock(gMotionModal.format(1), x, y, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      feedOutput.reset(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(1), f);
    }
  }
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }
  writeBlock(gAbsIncModal.format(90));
  if (isHelical()) {
    linearize(tolerance);
    return;
  }

  if (!getProperty("useRadius")) {
    switch (getCircularPlane()) {
    case PLANE_XY:
      xOutput.reset();
      yOutput.reset();
      writeBlock(
        gMotionModal.format(clockwise ? 2 : 3),
        xOutput.format(x),
        yOutput.format(y),
        conditional(isHelical(), zOutput.format(z)),
        iOutput.format(cx),
        (getProperty("vertical") ? kOutput.format(cy) : jOutput.format(cy)),
        feedOutput.format(feed)
      );
      break;
    default:
      linearize(tolerance);
    }
  } else {
    var r = getCircularRadius();
    xOutput.reset();
    yOutput.reset();
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), "R" + xyzFormat.format(r), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

var mapCommand = {
  COMMAND_STOP:0,
  COMMAND_END:30,
  COMMAND_SPINDLE_CLOCKWISE:3,
  COMMAND_SPINDLE_COUNTERCLOCKWISE:4,
  COMMAND_STOP_SPINDLE:5,
  COMMAND_LOAD_TOOL:6
};

function onCommand(command) {
  switch (command) {
  case COMMAND_START_SPINDLE:
    onCommand(tool.clockwise ? COMMAND_SPINDLE_CLOCKWISE : COMMAND_SPINDLE_COUNTERCLOCKWISE);
    return;
  case COMMAND_LOCK_MULTI_AXIS:
    return;
  case COMMAND_UNLOCK_MULTI_AXIS:
    return;
  case COMMAND_BREAK_CONTROL:
    return;
  case COMMAND_TOOL_MEASURE:
    return;
  case COMMAND_COOLANT_OFF:
    setCoolant(COOLANT_OFF);
    return;
  case COMMAND_COOLANT_ON:
    setCoolant(COOLANT_FLOOD);
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
  onCommand(COMMAND_COOLANT_OFF);

  onImpliedCommand(COMMAND_END);
  onImpliedCommand(COMMAND_STOP_SPINDLE);
  writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off
  writeln(EOT);
}

function setProperty(property, value) {
  properties[property].current = value;
}
