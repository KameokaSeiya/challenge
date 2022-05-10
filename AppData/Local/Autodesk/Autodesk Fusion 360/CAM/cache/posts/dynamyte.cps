/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Dyna Myte post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {ACB1E01D-849C-464c-B8EF-9DC599A56D0E}
*/

description = "Dyna Myte 2400";
vendor = "Dyna Mechtronics";
vendorUrl = "http://www.autodesk.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic milling post for Dyna Myte 2400.";

extension = "pgd";
programNameIsInteger = true;
setCodePage("ascii");

capabilities = CAPABILITY_MILLING;
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
    value: true,
    scope: "post"
  },
  sequenceNumberStart: {
    title: "Start sequence number",
    description: "The number at which to start the sequence numbers.",
    group: 1,
    type: "integer",
    value: 0,
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
  maximumSequenceNumber: {
    title: "Maximum Sequence number",
    description: "Sets the maximum sequence number.",
    group: 1,
    type: "integer",
    value: 700,
    scope: "post"
  }
};

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,=_-";

var nFormat = createFormat({width:3, zeropad:true, decimals:0});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, trim:false});
var feedFormat = createFormat({decimals:(unit == MM ? 1 : 2), forceDecimal:true, trim:false});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-99999.999
var sweepFormat = createFormat({decimals:3, forceDecimal:true, trim:false, scale:DEG});
var taperFormat = createFormat({decimals:1, scale:DEG});

var xOutput = createVariable({prefix:"X "}, xyzFormat);
var yOutput = createVariable({prefix:"Y "}, xyzFormat);
var zOutput = createVariable({onchange: function() {retracted = false;}, prefix: "Z "}, xyzFormat);
var feedOutput = createVariable({}, feedFormat);
var sOutput = createVariable({force:true}, rpmFormat);

var WARNING_WORK_OFFSET = 0;

// collected state
var sequenceNumber;
var currentCoolantMode = undefined;
var retracted = false; // specifies that the tool has been retracted to the safe plane

function resetSequence() {
  if (sequenceNumber >= getProperty("maximumSequenceNumber")) {
    writeBlock("GRfZ", xyzFormat.format(5));
    writeBlock("DWELL", secFormat.format(1));// TAG: fixme
    writeBlock("SKIP TO", nFormat.format(999));
    writeBlock(nFormat.format(999));
    writeBlock("SKIP TO", nFormat.format(4));
    writeBlock("HALT");
    writeBlock("GRfZ", xyzFormat.format(-5));
    sequenceNumber = 0;
  }
}

/**
  Writes the specified block.
*/
function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }
  writeWords(nFormat.format(sequenceNumber), arguments);
  sequenceNumber += getProperty("sequenceNumberIncrement");
}

function setCoolant(coolant) {
  var enabled = coolant != COOLANT_OFF;
  if (enabled == currentCoolantMode) {
    return; // coolant is already active
  }

  if (enabled) {
    writeBlock("COOLANT ON");
  } else {
    writeBlock("COOLANT OFF");
  }

  currentCoolantMode = enabled;
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeBlock("; " + filterText(String(text).toUpperCase(), permittedCommentChars));
}

function onOpen() {
  sequenceNumber = getProperty("sequenceNumberStart");

  if (programName) {
    var programId;
    try {
      programId = getAsInt(programName);
    } catch (e) {
      error(localize("Program name must be a number."));
    }
    if (!((programId >= 1) && (programId <= 99))) {
      error(localize("Program number is out of range."));
    }
    var oFormat = createFormat({width:2, zeropad:true, decimals:0});
    writeBlock("START MM", oFormat.format(programId));
  } else {
    writeBlock("START MM", oFormat.format(1));
  }
  writeComment(programComment);

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

  writeBlock("TOOL", toolFormat.format(1));
  writeBlock("TD=", xyzFormat.format(10));
  writeBlock("SETUP>ZCXYU");
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
  
  retracted = false;
  var newWorkOffset = isFirstSection() ||
    (getPreviousSection().workOffset != currentSection.workOffset); // work offset changes
  var newWorkPlane = isFirstSection() ||
    !isSameDirection(getPreviousSection().getGlobalFinalToolAxis(), currentSection.getGlobalInitialToolAxis()) ||
    (currentSection.isOptimizedForMachine() && getPreviousSection().isOptimizedForMachine() &&
      Vector.diff(getPreviousSection().getFinalToolAxisABC(), currentSection.getInitialToolAxisABC()).length > 1e-4) ||
    (!machineConfiguration.isMultiAxisConfiguration() && currentSection.isMultiAxis()) ||
    (!getPreviousSection().isMultiAxis() && currentSection.isMultiAxis() ||
      getPreviousSection().isMultiAxis() && !currentSection.isMultiAxis()); // force newWorkPlane between indexing and simultaneous operations
  if (insertToolCall || newWorkOffset || newWorkPlane) {
      
    retracted = true;
    writeBlock("Z>C");
    setCoolant(COOLANT_OFF);
    writeBlock("Z>C");
    zOutput.reset();
  }
  
  if (insertToolCall) {
    onCommand(COMMAND_COOLANT_OFF);

    if (tool.number > 99) {
      warning(localize("Tool number exceeds maximum value."));
    }

    writeBlock("TOOL", toolFormat.format(tool.number));
    writeBlock("TD=", xyzFormat.format(tool.diameter));
    writeBlock("SPINDLE ON");
    writeBlock("CONTROL 3");
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
    writeBlock("SP=", sOutput.format((tool.clockwise ? 1 : -1) * spindleSpeed), "RPM");
  }

  // wcs
  var workOffset = currentSection.workOffset;
  if (workOffset != 0) {
    warningOnce(localize("Work offset is not used."), WARNING_WORK_OFFSET);
  }

  // set coolant after we have positioned at Z
  setCoolant(tool.coolant);

  forceAny();

  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  if (!retracted && !insertToolCall) {
    if (getCurrentPosition().z < initialPosition.z) {
      writeBlock("GO", zOutput.format(initialPosition.z));
    }
  }

  if (insertToolCall) {
    writeBlock("GO", xOutput.format(initialPosition.x));
    writeBlock("  ", yOutput.format(initialPosition.y));
    writeBlock("GO", zOutput.format(initialPosition.z));
  }
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  writeBlock("DWELL", secFormat.format(seconds));
}

function onSpindleSpeed(spindleSpeed) {
  writeBlock("SP=", sOutput.format((tool.clockwise ? 1 : -1) * spindleSpeed), "RPM");
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

function onRapid(_x, _y, _z) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode cannot be changed at rapid traversal."));
  }

  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    if (x || y) {
      // force output of both X and Y
      writeBlock("GO", "X " + xyzFormat.format(_x));
      writeBlock("  ", "Y " + xyzFormat.format(_y));
      if (z) {
        writeBlock("  ", z);
      }
    } else if (z) {
      writeBlock("GO", z);
    }
    feedOutput.reset();
    resetSequence();
  }
}

function onLinear(_x, _y, _z, feed) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode is not supported."));
  }

  var f = feedOutput.format(feed);
  if (f) {
    writeBlock("F XYZ =", f);
  }

  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    if (x || y) {
      // force output of both X and Y
      writeBlock("GO", "X " + xyzFormat.format(_x));
      writeBlock("  ", "Y " + xyzFormat.format(_y));
      if (z) {
        writeBlock("  ", z);
      }
    } else if (z) {
      writeBlock("GO", z);
    }
  }

  resetSequence();
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  var f = feedOutput.format(feed);
  if (f) {
    writeBlock("F XYZ =", f);
  }

  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }

  switch (getCircularPlane()) {
  case PLANE_XY:
    writeBlock("ZERO AT");
    writeBlock("  X", xyzFormat.format(cx));
    writeBlock("  Y", xyzFormat.format(cy));
    writeBlock("GR A", sweepFormat.format((isClockwise() ? -1 : 1) * getCircularSweep()));
    writeBlock(">REF COORD");
    resetSequence();
    break;
  default:
    linearize(tolerance);
  }
}

function onCycle() {
}

function onCyclePoint(x, y, z) {
  if (!isSameDirection(getRotation().forward, new Vector(0, 0, 1))) {
    expandCyclePoint(x, y, z);
    return;
  }
  xOutput.reset();
  yOutput.reset();
  
  if (isFirstCyclePoint()) {
    repositionToCycleClearance(cycle, x, y, z);
    
    switch (cycleType) {
    case "drilling":
      writeBlock("DRIL PECK=", xyzFormat.format(0));
      writeBlock("ZH=", xyzFormat.format(cycle.stock));
      writeBlock("ZD=", xyzFormat.format(cycle.bottom));
      writeBlock(xOutput.format(x));
      writeBlock(yOutput.format(y));
      writeBlock("DWELL", secFormat.format(cycle.dwell));
      break;
    case "counter-boring":
      writeBlock("DRIL PECK=", xyzFormat.format(0));
      writeBlock("ZH=", xyzFormat.format(cycle.stock));
      writeBlock("ZD=", xyzFormat.format(cycle.bottom));
      writeBlock(xOutput.format(x));
      writeBlock(yOutput.format(y));
      writeBlock("DWELL", secFormat.format(cycle.dwell));
      break;
    case "chip-breaking":
      if ((cycle.accumulatedDepth < cycle.depth) || (P > 0)) {
        expandCyclePoint(x, y, z);
      } else {
        writeBlock("DRIL PECK=", xyzFormat.format(cycle.incrementalDepth));
        writeBlock("ZH=", xyzFormat.format(cycle.stock));
        writeBlock("ZD=", xyzFormat.format(cycle.bottom));
        writeBlock(xOutput.format(x));
        writeBlock(yOutput.format(y));
        writeBlock("DWELL", secFormat.format(cycle.dwell));
      }
      break;
    default:
      expandCyclePoint(x, y, z);
    }
  } else {
    if (cycleExpanded) {
      expandCyclePoint(x, y, z);
    } else {
      writeBlock(xOutput.format(x));
      writeBlock(yOutput.format(y));
      writeBlock("DWELL", secFormat.format(cycle.dwell));
    }
  }
}

function onCycleEnd() {
  zOutput.reset();
}

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
  }

  if (command == COMMAND_COOLANT_OFF) {
    setCoolant(COOLANT_OFF);
  } else if (command == COMMAND_COOLANT_ON) {
    setCoolant(COOLANT_FLOOD);
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
  writeBlock("Z>C");
  zOutput.reset();
  writeBlock("SPINDLE OFF");
  writeBlock("CONTROL 3");
  setCoolant(COOLANT_OFF);
  writeBlock("HALT");
  writeBlock("END");
}

function setProperty(property, value) {
  properties[property].current = value;
}
