/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  MicroKinetices MillMaster Pro 2014 post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {16E7F1DF-8745-4CD2-AEB0-16239DB2C385}
*/

description = "MicroKinetics MillMaster Pro";
vendor = "MicroKinetics";
vendorUrl = "http://www.microkinetics.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic MicroKinetics MillMaster Pro 2014. You can set the property 'retractZlevel' to a non-zero value to make the machine retract to the given Z-level between operations.";

extension = "cnc";
setCodePage("ascii");

capabilities = CAPABILITY_MILLING;
tolerance = spatial(0.002, MM);
minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular motion

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
  showSequenceNumbersAtToolChange: {
    title: "Sequence number only on tool change",
    description: "If enabled, sequence numbers are only outputted when a toolchange is called.",
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
  retractZlevel: {
    title: "Retract Z level",
    description: "Sets the safe retracts Z level. 0 = disabled.",
    type: "number",
    value: 0,
    scope: "post"
  },
  useM29: {
    title: "Use M29",
    description: "If enabled, an M29 z block is used to retract the Z.",
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
  },
  toolChangePosX: {
    title: "Tool change position X",
    description: "Sets the tool change position in X.",
    type: "number",
    value: -3,
    scope: "post"
  },
  toolChangePosY: {
    title: "Tool change position Y",
    description: "Sets the tool change position in Y.",
    type: "number",
    value: 0,
    scope: "post"
  },
  useRadius: {
    title: "Radius arcs",
    description: "If yes is selected, arcs are outputted using radius values rather than IJK.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  materialShape: {
    title: "Material shape",
    description: "Specify the shape of the material.",
    type: "string",
    value: "Rectangle",
    scope: "post"
  }
};

var numberOfToolSlots = 9999;

var WARNING_WORK_OFFSET = 0;
var WARNING_COOLANT = 1;

var gFormat = createFormat({prefix:"G", width:2, zeropad:true, decimals:0});
var mFormat = createFormat({prefix:"M", width:2, zeropad:true, decimals:0});
var hFormat = createFormat({prefix:"H", decimals:0});
var dFormat = createFormat({prefix:"D", decimals:0});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var rFormat = xyzFormat; // radius
var feedFormat = createFormat({decimals:0, scale:(unit == MM ? 1 : 10)});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-1000
var taperFormat = createFormat({decimals:1, scale:DEG});

var xOutput = createVariable({prefix:"X"}, xyzFormat);
var yOutput = createVariable({prefix:"Y"}, xyzFormat);
var zOutput = createVariable({prefix:"Z"}, xyzFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var sOutput = createVariable({prefix:"S", force:true}, rpmFormat);
var dOutput = createVariable({}, dFormat);

// circular output
var iOutput = createReferenceVariable({prefix:"I"}, xyzFormat);
var jOutput = createReferenceVariable({prefix:"J"}, xyzFormat);
var kOutput = createReferenceVariable({prefix:"K"}, xyzFormat);

var gMotionModal = createModal({force:true}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gUnitModal = createModal({}, gFormat); // modal group 6 // G70-71
var gCycleModal = createModal({force:true}, gFormat); // modal group 9 // G81, ...

// collected state
var sequenceNumber;

/**
  Writes the specified block.
*/
function writeBlock() {
  if (getProperty("showSequenceNumbers") && !getProperty("showSequenceNumbersAtToolChange")) {
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
  writeln("/" + String(text).replace(/[()]/g, ""));
}

/**
  Output a /* comment.
*/
function writeStarComment(text) {
  writeln("/*" + String(text).replace(/[()]/g, ""));
}

function onOpen() {
  if (getProperty("useRadius")) {
    maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
  }
  
  if (getProperty("retractZlevel") != 0) {
    machineConfiguration.setRetractPlane(getProperty("retractZlevel"));
  }

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

  writeStarComment(" {DEFVAR}: TCPX, " + xyzFormat.format(getProperty("toolChangePosX")) + " ");
  writeStarComment(" {DEFVAR}: TCPY, " + xyzFormat.format(getProperty("toolChangePosY")) + " ");
  
  var material = getProperty("materialShape");
  var stock = getWorkpiece();
  var materialLength = stock.upper.x - stock.lower.x;
  var materialWidth = stock.upper.y - stock.lower.y;
  var materialHeight = stock.upper.z - stock.lower.z;
  if ((material.length < 5) || (materialLength != materialWidth)) {
    material = "rectangle";
  }
  
  writeStarComment("  {SLENGTH}:  " + xyzFormat.format(materialLength));
  writeStarComment("  {SWIDTH}:  " + xyzFormat.format(materialWidth));
  writeStarComment("  {SHEIGHT}:  " + xyzFormat.format(materialHeight));
  writeStarComment("  {Material Shape}:  " + material.toUpperCase());
  
  // dump tool information
  if (getProperty("writeTools")) {
    var tools = getToolTable();
    if (tools.getNumberOfTools() > 0) {
      for (var i = 0; i < tools.getNumberOfTools(); ++i) {
        var tool = tools.getTool(i);
        var comment = "  {TOOL}:  #" + toolFormat.format(tool.number) + ", " + getToolTypeName(tool.type) +
          ", DIAMETER = " + xyzFormat.format(tool.diameter);
        writeStarComment(comment);
      }
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

  writeBlock(gAbsIncModal.format(90)); // absolute coordinates
  writeBlock(gFormat.format(75)); // incremental arc mode
  writeBlock(gPlaneModal.format(17));
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

function onParameter(name, value) {
}

function onSection() {
  var insertToolCall = isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number);
  
  var retracted = false; // specifies that the tool has been retracted to the safe plane
  if (isFirstSection() || insertToolCall) {
    if (!getProperty("useM29") && machineConfiguration.getRetractPlane() != 0) {
      // retract to safe plane
      retracted = true;
      writeBlock(gMotionModal.format(0), "Z" + xyzFormat.format(machineConfiguration.getRetractPlane())); // retract
      zOutput.reset();
    } else if (getProperty("useM29")) {
      writeBlock(mFormat.format(29), "z", "(varname)");
      retracted = true;
    }
  }

  writeln("");
  
  if (insertToolCall) {
    
    retracted = true;
    onCommand(COMMAND_COOLANT_OFF);
  
    if (!isFirstSection() && getProperty("optionalStop")) {
      onCommand(COMMAND_OPTIONAL_STOP);
    }

    if (tool.number > numberOfToolSlots) {
      warning(localize("Tool number exceeds maximum value."));
    }

    gMotionModal.reset();
    writeBlock(gMotionModal.format(0), "X(TCPX) Y(TCPY)");
    if (getProperty("showSequenceNumbers") && getProperty("showSequenceNumbersAtToolChange")) {
      writeBlock("N" + sequenceNumber, mFormat.format(6), "T" + toolFormat.format(tool.number));
      sequenceNumber += getProperty("sequenceNumberIncrement");
    } else {
      writeBlock(mFormat.format(6), "T" + toolFormat.format(tool.number));
    }
    if (tool.comment) {
      writeComment(tool.comment);
    }
    var showToolZMin = false;
    if (showToolZMin) {
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
  }
  
  if (insertToolCall ||
      isFirstSection() ||
      (rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) ||
      (tool.clockwise != getPreviousSection().getTool().clockwise)) {
    if (spindleSpeed < 1) {
      error(localize("Spindle speed out of range."));
    }
    if (spindleSpeed > 99999) {
      warning(localize("Spindle speed exceeds maximum value."));
    }
    writeBlock(
      mFormat.format(tool.clockwise ? 3 : 4), sOutput.format(spindleSpeed)
    );
  }

  // wcs
  if (currentSection.workOffset != 0) {
    warningOnce(localize("Work offset is not supported."), WARNING_WORK_OFFSET);
  }

  setCoolant(tool.coolant);

  forceAny();

  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  if (!retracted && !insertToolCall) {
    if (getCurrentPosition().z < initialPosition.z) {
      writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
    }
  }

  if (insertToolCall) {
    gMotionModal.reset();
    writeBlock(gPlaneModal.format(17));
    
    writeBlock(
      gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y)
    );
    writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
  } else {
    writeBlock(
      gAbsIncModal.format(90),
      gMotionModal.format(0),
      xOutput.format(initialPosition.x),
      yOutput.format(initialPosition.y)
    );
  }
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.001, seconds, 99999.999);
  writeBlock(gFormat.format(4), "D" + secFormat.format(seconds));
}

function onSpindleSpeed(spindleSpeed) {
  writeBlock(sOutput.format(spindleSpeed));
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
      error(localize("Radius compensation mode is not supported by machine."));
      return;
    }
    writeBlock(gMotionModal.format(0), x, y, z);
    feedOutput.reset();
  }
}

function onLinear(_x, _y, _z, feed) {
  // at least one axis is required
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode is not supported by machine."));
    return;
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = feedOutput.format(feed);
  if (x || y || z) {
    writeBlock(gMotionModal.format(1), x, y, z, f);
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      feedOutput.reset(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(1), f);
    }
  }
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  if (isHelical()) {
    var t = tolerance;
    if (hasParameter("operation:tolerance")) {
      t = getParameter("operation:tolerance");
    }
    linearize(t);
    return;
  }

  // one of X/Y and I/J are required and likewise
  
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode is not supported by machine."));
    return;
  }

  var start = getCurrentPosition();

  if (!getProperty("useRadius") || isFullCircle()) {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gPlaneModal.format(17));
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    case PLANE_ZX:
      writeBlock(gPlaneModal.format(18));
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
      break;
    case PLANE_YZ:
      writeBlock(gPlaneModal.format(19));
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
      break;
    default:
      var t = tolerance;
      if (hasParameter("operation:tolerance")) {
        t = getParameter("operation:tolerance");
      }
      linearize(t);
    }
  } else {
    var r = getCircularRadius();
    if (toDeg(getCircularSweep()) > (180 + 1e-9)) {
      r = -r; // allow up to <360 deg arcs
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), feedOutput.format(feed));
      break;
    case PLANE_ZX:
      writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), feedOutput.format(feed));
      break;
    case PLANE_YZ:
      writeBlock(gPlaneModal.format(19), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

function onCycle() {
  if (getProperty("useCycles")) {
    writeBlock(gPlaneModal.format(17));
  }
}

function getCommonCycle(x, y, z, r) {
  forceXYZ(); // force xyz on first drill hole of any cycle
  return [xOutput.format(x), yOutput.format(y),
    "Z" + xyzFormat.format(z)];
}

function onCyclePoint(x, y, z) {
  if (!isSameDirection(getRotation().forward, new Vector(0, 0, 1))) {
    expandCyclePoint(x, y, z);
    return;
  }
  if (!getProperty("useCycles")) {
    expandCyclePoint(x, y, z);
    return;
  }
  
  var retractZ = toPreciseUnit(0.05, IN);
  if (isFirstCyclePoint()) {
    repositionToCycleClearance(cycle, x, y, z);
    writeBlock(
      gAbsIncModal.format(90), gMotionModal.format(0),
      xOutput.format(x), yOutput.format(y), zOutput.format(cycle.bottom + cycle.depth + retractZ)
    );

    // return to initial Z which is clearance plane and set absolute mode

    var F = cycle.feedrate;
    var P = !cycle.dwell ? 0 : clamp(1, cycle.dwell, 9999); // in seconds
  
    switch (cycleType) {
    case "drilling":
      writeBlock(
        gAbsIncModal.format(90), gCycleModal.format(81),
        getCommonCycle(x, y, cycle.depth, cycle.retract),
        feedOutput.format(F)
      );
      break;
    case "counter-boring":
      if (P > 0) {
        writeBlock(
          gAbsIncModal.format(90), gCycleModal.format(82),
          getCommonCycle(x, y, cycle.depth, cycle.retract),
          "D" + secFormat.format(P), feedOutput.format(F)
        );
      } else {
        writeBlock(
          gAbsIncModal.format(90), gCycleModal.format(81),
          getCommonCycle(x, y, cycle.depth, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    case "deep-drilling":
      writeBlock(
        gAbsIncModal.format(90), gCycleModal.format(83),
        getCommonCycle(x, y, cycle.depth, cycle.retract),
        "K" + xyzFormat.format(cycle.incrementalDepth),
        feedOutput.format(F)
      );
      break;
    case "boring":
      writeBlock(
        gAbsIncModal.format(90), gCycleModal.format(85),
        getCommonCycle(x, y, cycle.depth, cycle.retract),
        feedOutput.format(F)
      );
      break;
    case "chip-breaking":
      if ((cycle.accumulatedDepth < cycle.depth) || (P > 0)) {
        cycleExpanded = true;
      } else {
        writeBlock(
          gAbsIncModal.format(90), gCycleModal.format(87),
          getCommonCycle(x, y, cycle.depth, cycle.retract),
          "K" + xyzFormat.format(cycle.incrementalDepth),
          feedOutput.format(F)
        );
      }
      break;
    case "reaming":
      if (P > 0) {
        writeBlock(
          gAbsIncModal.format(90), gCycleModal.format(89),
          getCommonCycle(x, y, cycle.depth, cycle.retract),
          "D" + secFormat.format(P), feedOutput.format(F)
        );
      } else {
        writeBlock(
          gAbsIncModal.format(90), gCycleModal.format(85),
          getCommonCycle(x, y, cycle.depth, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    
    default:
      expandCyclePoint(x, y, z);
    }
  } else if (cycleExpanded) {
    expandCyclePoint(x, y, z);
  } else {
    writeBlock(xOutput.format(x), yOutput.format(y));
  }
}

function onCycleEnd() {
  writeBlock(gCycleModal.format(80));
}

var currentCoolantMode = COOLANT_OFF;

function setCoolant(coolant) {
  if (coolant == currentCoolantMode) {
    return; // coolant is already active
  }
  
  if (coolant == COOLANT_OFF) {
    writeBlock(mFormat.format(9));
    currentCoolantMode = COOLANT_OFF;
    return;
  }

  var m;
  switch (coolant) {
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

var mapCommand = {
  COMMAND_STOP:0,
  COMMAND_OPTIONAL_STOP:1,
  COMMAND_END:2,
  COMMAND_SPINDLE_CLOCKWISE:3,
  COMMAND_SPINDLE_COUNTERCLOCKWISE:4,
  COMMAND_STOP_SPINDLE:5
};

function onCommand(command) {
  switch (command) {
  case COMMAND_COOLANT_OFF:
    setCoolant(COOLANT_OFF);
    return;
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
  writeln("");
  onCommand(COMMAND_COOLANT_OFF);

  if (machineConfiguration.getRetractPlane() != 0) {
    writeBlock(gMotionModal.format(0), "Z" + xyzFormat.format(machineConfiguration.getRetractPlane())); // retract
    zOutput.reset();
  }

  if (machineConfiguration.hasHomePositionX() || machineConfiguration.hasHomePositionY()) {
    var homeX;
    if (machineConfiguration.hasHomePositionX()) {
      homeX = "X" + xyzFormat.format(machineConfiguration.getHomePositionX());
    }
    var homeY;
    if (machineConfiguration.hasHomePositionY()) {
      homeY = "Y" + xyzFormat.format(machineConfiguration.getHomePositionY());
    }
    writeBlock(gMotionModal.format(0), homeX, homeY);
  }
  writeBlock(mFormat.format(29));

  onImpliedCommand(COMMAND_END);
  onImpliedCommand(COMMAND_STOP_SPINDLE);
  writeBlock(mFormat.format(2)); // stop program, spindle stop, coolant off
}

function setProperty(property, value) {
  properties[property].current = value;
}
