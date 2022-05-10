/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Deckel Dialog 12 post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $

  FORKID {4EE83F9D-E7AB-467b-8585-C930FE13FF32}
*/

description = "Deckel Dialog 12";
vendor = "Deckel";
vendorUrl = "http://www.autodesk.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Post for Deckel Dialog 12. Note that there are quite some difference between the Dialog 12 controls so this post would most likely need further customization to work properly for the specific control.";

extension = "nc";
programNameIsInteger = true;
setCodePage("ascii");

capabilities = CAPABILITY_MILLING;
tolerance = spatial(0.002, MM);

highFeedrate = (unit == IN) ? 100 : 1000;
minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(360);
allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular motion

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
  separateWordsWithSpace: {
    title: "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  retractZ: {
    title: "Retract Z value",
    description: "Specifies the amount to retract in Z.",
    type: "number",
    value: 200,
    scope: "post"
  },
  safePositionMethod: {
    title: "Safe Retracts",
    description: "Select your desired retract option. 'Clearance Height' retracts to the operation clearance height.",
    type: "enum",
    values: [
      // {title:"G28", id: "G28"},
      // {title:"G53", id: "G53"},
      {title: "Clearance Height", id: "clearanceHeight"},
      {title: "Specified Z value", id: "specifiedZvalue"}
    ],
    value: "specifiedZvalue",
    scope: "post"
  },
  useToolNumberForCompensation: {
    title: "Use tool number for compensation",
    description: "Use tool numbers for compensation output.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  scale: {
    title: "1000 Scaling for XYZ",
    description: "Enable to scale the XYZ axis by 1000.",
    type: "boolean",
    value: false,
    scope: "post"
  }
};

var singleLineCoolant = false; // specifies to output multiple coolant codes in one line rather than in separate lines
// samples:
// {id: COOLANT_THROUGH_TOOL, on: 88, off: 89}
// {id: COOLANT_THROUGH_TOOL, on: [8, 88], off: [9, 89]}
var coolants = [
  {id: COOLANT_FLOOD, on: 8},
  {id: COOLANT_MIST},
  {id: COOLANT_THROUGH_TOOL},
  {id: COOLANT_AIR},
  {id: COOLANT_AIR_THROUGH_TOOL},
  {id: COOLANT_SUCTION},
  {id: COOLANT_FLOOD_MIST},
  {id: COOLANT_FLOOD_THROUGH_TOOL},
  {id: COOLANT_OFF, off: 9}
];

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,=_-";

var offset = 50;

var oFormat = createFormat({decimals:0});
var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"M", decimals:0});
var uFormat = createFormat({prefix:"N*", decimals:0});
var nFormat = createFormat({prefix:"N", decimals:0});

var listXYZFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceSign:true});
var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var feedFormat = createFormat({decimals:0});
var toolFormat = createFormat({decimals:0});
var listOffsetFormat = createFormat({decimals:0, width:2, zeropad:true});
var offsetFormat = createFormat({decimals:0, width:2, zeropad:true, forceSign:true});
var rpmFormat = createFormat({decimals:0, forceSign:true});
var secFormat = createFormat({decimals:1}); // seconds - range 0.1-99.9
var taperFormat = createFormat({decimals:1, scale:DEG});

var xOutput = createVariable({prefix:"X"}, xyzFormat);
var yOutput = createVariable({prefix:"Y"}, xyzFormat);
var zOutput = createVariable({onchange: function() {retracted = false;}, prefix: "Z"}, xyzFormat);
var feedOutput = createVariable({prefix: "F"}, feedFormat);
var sOutput = createVariable({prefix:"S", force:true}, rpmFormat);

// circular output
var iOutput = createReferenceVariable({prefix:"I", force:true}, xyzFormat);
var jOutput = createReferenceVariable({prefix:"J", force:true}, xyzFormat);
var kOutput = createReferenceVariable({prefix:"K", force:true}, xyzFormat);

var gMotionModal = createModal({}, gFormat); // G0-G3, ...
var gAbsIncModal = createModal({}, gFormat); // G90-91
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // G17-19
var gCycleModal = createModal({force:true}, gFormat); // G81, ...

var WARNING_WORK_OFFSET = 0;

// collected state
var sequenceNumber;
var currentWorkOffset;
var nextCycleCall = 1;
var cycleCalls = "";
var retracted = false; // specifies that the tool has been retracted to the safe plane

/**
  Writes the specified block.
*/
function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }
  if (getProperty("showSequenceNumbers")) {
    writeWords2(nFormat.format(sequenceNumber), arguments);
    sequenceNumber += getProperty("sequenceNumberIncrement");
    if (sequenceNumber >= 10000) {
      sequenceNumber = getProperty("sequenceNumberStart");
    }
  } else {
    writeWords(arguments);
  }
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln("(" + filterText(String(text).toUpperCase(), permittedCommentChars) + ")");
}

function onOpen() {

  if (getProperty("scale")) {
    listXYZFormat = createFormat({decimals:0, width:6, zeropad:true, forceSign:true, scale:1000});
    xyzFormat = createFormat({decimals:0, scale:1000});

    xOutput = createVariable({prefix:"X"}, xyzFormat);
    yOutput = createVariable({prefix:"Y"}, xyzFormat);
    zOutput = createVariable({prefix:"Z"}, xyzFormat);

    iOutput = createReferenceVariable({prefix:"I", force:true}, xyzFormat);
    jOutput = createReferenceVariable({prefix:"J", force:true}, xyzFormat);
    kOutput = createReferenceVariable({prefix:"K", force:true}, xyzFormat);
  }

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");
  var programId;
  if (programName) {
    try {
      programId = getAsInt(programName);
    } catch (e) {
      error(localize("Program name must be a number."));
      return;
    }
    if (!((programId >= 1) && (programId <= 99999))) {
      error(localize("Program number is out of range. Use program numbers within range 1 to 99999."));
      return;
    }
    writeln("&P" + oFormat.format(programId));
  } else {
    error(localize("Program name has not been specified."));
    return;
  }

  writeln("");

  {
    var tools = getToolTable();
    if (tools.getNumberOfTools() > 0) {
      for (var i = 0; i < tools.getNumberOfTools(); ++i) {
        var tool = tools.getTool(i);
        var l = getProperty("useToolNumberForCompensation") ? tool.number : tool.lengthOffset;
        if ((l <= 0) || (l > offset)) {
          warning(localize("The length offset is invalid."));
        }
        writeWords("D" + listOffsetFormat.format(l), listXYZFormat.format(0) /*, "( " + getToolTypeName(tool.type) + " )"*/);
      }

      for (var i = 0; i < tools.getNumberOfTools(); ++i) {
        var tool = tools.getTool(i);
        var d = getProperty("useToolNumberForCompensation") ? tool.number : tool.diameterOffset;
        if ((d <= 0) || (d > offset)) {
          warning(localize("The diameter offset is invalid."));
        }
        writeWords("D" + listOffsetFormat.format(d + offset), listXYZFormat.format(tool.diameter / 2) /*, "( " + getToolTypeName(tool.type) + " )"*/);
      }
    }
  }

  writeln("");
  writeln("%");
  writeln("(&P" + oFormat.format(programId) + "/0000)");

  if (programComment) {
    writeComment(programComment);
  }

  // dump tool information
  if (false) {
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

  if ((getNumberOfSections() > 0) && (getSection(0).workOffset == 0)) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      if (getSection(i).workOffset > 0) {
        error(localize("Using multiple work offsets is not possible if the initial work offset is 0."));
        return;
      }
    }
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

function isProbeOperation() {
  return hasParameter("operation-strategy") && (getParameter("operation-strategy") == "probe");
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
      
    zOutput.reset();
  }

  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment(comment);
    }
  }
  
  if (insertToolCall) {
    setCoolant(COOLANT_OFF);
  
    if (tool.number > 999999) {
      warning(localize("Tool number exceeds maximum value."));
    }

    writeBlock(gMotionModal.format(0), zOutput.format(getProperty("retractZ")), "T" + toolFormat.format(tool.number), mFormat.format(6));
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
      forceSpindleSpeed ||
      isFirstSection() ||
      (rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) ||
      (tool.clockwise != getPreviousSection().getTool().clockwise)) {
    forceSpindleSpeed = false;
    
    if (spindleSpeed < 1) {
      error(localize("Spindle speed out of range."));
      return;
    }
    if (spindleSpeed > 99999) {
      warning(localize("Spindle speed exceeds maximum value."));
    }
    writeBlock(
      sOutput.format((tool.clockwise ? 1 : -1) * spindleSpeed)
    );
  }

  // wcs
  if (insertToolCall) { // force work offset when changing tool
    currentWorkOffset = undefined;
  }
  var workOffset = currentSection.workOffset;
  if (workOffset == 0) {
    warningOnce(localize("Work offset has not been specified."), WARNING_WORK_OFFSET);
  }
  if (workOffset > 0) {
    if (workOffset > 999) {
      error(localize("Work offset out of range."));
      return;
    } else {
      if (workOffset != currentWorkOffset) {
        writeBlock(gFormat.format(51) + "*" + workOffset);
        currentWorkOffset = workOffset;
      }
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

  // set coolant after we have positioned at Z
  setCoolant(tool.coolant);

  forceAny();
  gMotionModal.reset();

  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  if (!retracted && !insertToolCall) {
    if (getCurrentPosition().z < initialPosition.z) {
      writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z), "D" + offsetFormat.format(getProperty("useToolNumberForCompensation") ? tool.number : tool.lengthOffset));
    }
  }

  if (insertToolCall) {
    gMotionModal.reset();
    
    writeBlock(
      gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y)
    );
    writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z), "D" + offsetFormat.format(getProperty("useToolNumberForCompensation") ? tool.number : tool.lengthOffset));
  } else {
    writeBlock(
      gAbsIncModal.format(90),
      gMotionModal.format(0),
      xOutput.format(initialPosition.x),
      yOutput.format(initialPosition.y)
    );
  }

  if (insertToolCall) {
    gPlaneModal.reset();
  }
}

function onDwell(seconds) {
  if (seconds > 99.9) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.1, seconds, 99.9);
  writeBlock(gFormat.format(4), "V" + secFormat.format(seconds));
}

function onSpindleSpeed(spindleSpeed) {
  writeBlock(sOutput.format((tool.clockwise ? 1 : -1) * spindleSpeed));
}

function onCycle() {
  writeBlock(gPlaneModal.format(17));
}

function onCyclePoint(x, y, z) {
  if (!isSameDirection(getRotation().forward, new Vector(0, 0, 1))) {
    expandCyclePoint(x, y, z);
    return;
  }
  if (isFirstCyclePoint()) {
    repositionToCycleClearance(cycle, x, y, z);
    
    if (cycleCalls == "") {
      cycleCalls = EOL;
    }
    
    var F = cycle.feedrate;
    var S = (tool.clockwise ? 1 : -1) * spindleSpeed;
    var P = !cycle.dwell ? 0 : clamp(0.1, cycle.dwell, 99.9); // in seconds

    switch (cycleType) {
    case "drilling":
      cycleCalls +=
        formatWords(
          uFormat.format(nextCycleCall),
          gCycleModal.format(81),
          feedOutput.format(F),
          sOutput.format(S),
          "Z" + xyzFormat.format(-(cycle.retract - cycle.bottom)),
          "Z" + xyzFormat.format(cycle.clearance - cycle.retract)
        ) + EOL;
      break;
    case "counter-boring":
      cycleCalls +=
        formatWords(
          uFormat.format(nextCycleCall),
          gCycleModal.format(81),
          feedOutput.format(F),
          sOutput.format(S),
          "Z" + xyzFormat.format(-(cycle.retract - cycle.bottom)),
          conditional(P > 0, gFormat.format(4)),
          conditional(P > 0, "V" + secFormat.format(P)),
          "Z" + xyzFormat.format(cycle.clearance - cycle.retract)
        ) + EOL;
      break;
    case "chip-breaking":
      if (cycle.accumulatedDepth < cycle.depth) {
        expandCyclePoint(x, y, z);
      } else {
        cycleCalls +=
          formatWords(
            uFormat.format(nextCycleCall),
            gCycleModal.format(82),
            feedOutput.format(F),
            sOutput.format(S),
            "Z" + xyzFormat.format(-(cycle.retract - cycle.bottom)),
            "Z" + xyzFormat.format(-cycle.incrementalDepth),
            "Z" + xyzFormat.format(machineParameters.chipBreakingDistance),
            conditional(P > 0, gFormat.format(4)),
            conditional(P > 0, "V" + secFormat.format(P)),
            "Z" + xyzFormat.format(cycle.clearance - cycle.retract)
          ) + EOL;
      }
      break;
    case "deep-drilling":
      cycleCalls +=
        formatWords(
          uFormat.format(nextCycleCall),
          gCycleModal.format(83),
          feedOutput.format(F),
          sOutput.format(S),
          "Z" + xyzFormat.format(-(cycle.retract - cycle.bottom)),
          "Z" + xyzFormat.format(-cycle.incrementalDepth),
          "Z" + xyzFormat.format(-machineParameters.drillingSafeDistance),
          conditional(cycle.incrementalDepthReduction != 0, "Z" + xyzFormat.format(-cycle.incrementalDepthReduction)),
          conditional(P > 0, gFormat.format(4)),
          conditional(P > 0, "V" + secFormat.format(P)),
          "Z" + xyzFormat.format(cycle.clearance - cycle.retract)
        ) + EOL;
      break;
    case "tapping":
      cycleCalls +=
        formatWords(
          uFormat.format(nextCycleCall),
          gCycleModal.format(84),
          feedFormat.format(tool.getTappingFeedrate()),
          sOutput.format(S),
          "Z" + xyzFormat.format(-(cycle.retract - cycle.bottom)),
          "Z" + xyzFormat.format(cycle.clearance - cycle.retract)
        ) + EOL;
      break;
    case "left-tapping":
      cycleCalls +=
        formatWords(
          uFormat.format(nextCycleCall),
          gCycleModal.format(84),
          feedFormat.format(tool.getTappingFeedrate()),
          sOutput.format(S),
          "Z" + xyzFormat.format(-(cycle.retract - cycle.bottom)),
          "Z" + xyzFormat.format(cycle.clearance - cycle.retract)
        ) + EOL;
      break;
    case "right-tapping":
      cycleCalls +=
        formatWords(
          uFormat.format(nextCycleCall),
          gCycleModal.format(84),
          feedFormat.format(tool.getTappingFeedrate()),
          sOutput.format(S),
          "Z" + xyzFormat.format(-(cycle.retract - cycle.bottom)),
          "Z" + xyzFormat.format(cycle.clearance - cycle.retract)
        ) + EOL;
      break;
    case "reaming":
      cycleCalls +=
        formatWords(
          uFormat.format(nextCycleCall),
          gCycleModal.format(85),
          feedOutput.format(F),
          sOutput.format(S),
          "Z" + xyzFormat.format(-(cycle.retract - cycle.bottom)),
          conditional(P > 0, gFormat.format(4)),
          conditional(P > 0, "V" + secFormat.format(P)),
          "Z" + xyzFormat.format(cycle.clearance - cycle.retract)
        ) + EOL;
      break;
    case "boring":
      cycleCalls +=
        formatWords(
          uFormat.format(nextCycleCall),
          gCycleModal.format(86),
          feedOutput.format(F),
          sOutput.format(S),
          "Z" + xyzFormat.format(-(cycle.retract - cycle.bottom)),
          conditional(P > 0, gFormat.format(4)),
          conditional(P > 0, "V" + secFormat.format(P)),
          "Z" + xyzFormat.format(cycle.clearance - cycle.retract)
        ) + EOL;
      break;
    default:
      expandCyclePoint(x, y, z);
    }
  }
  
  if (cycleExpanded) {
    expandCyclePoint(x, y, z);
  } else {
    writeBlock(uFormat.format(nextCycleCall), gMotionModal.format(0), xOutput.format(x), yOutput.format(y));
    nextCycleCall += 1;
  }
}

function onCycleEnd() {
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

function onRapid(_x, _y, _z) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode cannot be changed at rapid traversal."));
    return;
  }
  
  var movingAxes = 0;
  movingAxes |= xyzFormat.areDifferent(_x, xOutput.getCurrent()) ? 1 : 0;
  movingAxes |= xyzFormat.areDifferent(_y, yOutput.getCurrent()) ? 2 : 0;
  movingAxes |= xyzFormat.areDifferent(_z, zOutput.getCurrent()) ? 4 : 0;
  
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);

  if (x || y || z) {
    if ((movingAxes == 1) || (movingAxes == 2) || (movingAxes == 4)) {
      writeBlock(gMotionModal.format(0), x, y, z); // axes are not synchronized
      feedOutput.reset();
    } else {
      gMotionModal.reset();
      writeBlock(gMotionModal.format(0) + "*2", x, y, z);
      feedOutput.reset();
    }
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
      writeBlock(gPlaneModal.format(17));
      var d = getProperty("useToolNumberForCompensation") ? tool.number : tool.diameterOffset;
      if ((d <= 0) || (d > offset)) {
        warning(localize("The diameter offset is invalid."));
      }
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gMotionModal.format(1), gFormat.format(41), x, y, offsetFormat.format(d + offset), f, gFormat.format(64), mFormat.format(62));
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gMotionModal.format(1), gFormat.format(42), x, y, offsetFormat.format(d + offset), f, gFormat.format(64), mFormat.format(62));
        break;
      default:
        writeBlock(gMotionModal.format(1), gFormat.format(40), x, y, f);
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

  if (false && isHelical()) {
    var t = tolerance;
    if (hasParameter("operation:tolerance")) {
      t = getParameter("operation:tolerance");
    }
    linearize(t);
    return;
  }

  var start = getCurrentPosition();

  if (isFullCircle()) {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    case PLANE_ZX:
      writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), yOutput.format(y), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
      break;
    case PLANE_YZ:
      writeBlock(gPlaneModal.format(19), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
      break;
    default:
      var t = tolerance;
      if (hasParameter("operation:tolerance")) {
        t = getParameter("operation:tolerance");
      }
      linearize(t);
    }
  } else {
    switch (getCircularPlane()) {
    case PLANE_XY:
      xOutput.reset();
      yOutput.reset();
      writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    case PLANE_ZX:
      zOutput.reset();
      xOutput.reset();
      writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
      break;
    case PLANE_YZ:
      yOutput.reset();
      zOutput.reset();
      writeBlock(gPlaneModal.format(19), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
      break;
    default:
      var t = tolerance;
      if (hasParameter("operation:tolerance")) {
        t = getParameter("operation:tolerance");
      }
      linearize(t);
    }
  }
}

var currentCoolantMode = COOLANT_OFF;
var coolantOff = undefined;

function setCoolant(coolant) {
  var coolantCodes = getCoolantCodes(coolant);
  if (Array.isArray(coolantCodes)) {
    if (singleLineCoolant) {
      writeBlock(coolantCodes.join(getWordSeparator()));
    } else {
      for (var c in coolantCodes) {
        writeBlock(coolantCodes[c]);
      }
    }
    return undefined;
  }
  return coolantCodes;
}

function getCoolantCodes(coolant) {
  var multipleCoolantBlocks = new Array(); // create a formatted array to be passed into the outputted line
  if (!coolants) {
    error(localize("Coolants have not been defined."));
  }
  if (isProbeOperation()) { // avoid coolant output for probing
    coolant = COOLANT_OFF;
  }
  if (coolant == currentCoolantMode) {
    return undefined; // coolant is already active
  }
  if ((coolant != COOLANT_OFF) && (currentCoolantMode != COOLANT_OFF) && (coolantOff != undefined)) {
    if (Array.isArray(coolantOff)) {
      for (var i in coolantOff) {
        multipleCoolantBlocks.push(mFormat.format(coolantOff[i]));
      }
    } else {
      multipleCoolantBlocks.push(mFormat.format(coolantOff));
    }
  }

  var m;
  var coolantCodes = {};
  for (var c in coolants) { // find required coolant codes into the coolants array
    if (coolants[c].id == coolant) {
      coolantCodes.on = coolants[c].on;
      if (coolants[c].off != undefined) {
        coolantCodes.off = coolants[c].off;
        break;
      } else {
        for (var i in coolants) {
          if (coolants[i].id == COOLANT_OFF) {
            coolantCodes.off = coolants[i].off;
            break;
          }
        }
      }
    }
  }
  if (coolant == COOLANT_OFF) {
    m = !coolantOff ? coolantCodes.off : coolantOff; // use the default coolant off command when an 'off' value is not specified
  } else {
    coolantOff = coolantCodes.off;
    m = coolantCodes.on;
  }

  if (!m) {
    onUnsupportedCoolant(coolant);
    m = 9;
  } else {
    if (Array.isArray(m)) {
      for (var i in m) {
        multipleCoolantBlocks.push(mFormat.format(m[i]));
      }
    } else {
      multipleCoolantBlocks.push(mFormat.format(m));
    }
    currentCoolantMode = coolant;
    return multipleCoolantBlocks; // return the single formatted coolant value
  }
  return undefined;
}

var mapCommand = {
  COMMAND_STOP:0,
  COMMAND_OPTIONAL_STOP:1,
  COMMAND_END:2,
  //COMMAND_SPINDLE_CLOCKWISE:3,
  //COMMAND_SPINDLE_COUNTERCLOCKWISE:4,
  COMMAND_STOP_SPINDLE:5,
  COMMAND_ORIENTATE_SPINDLE:19,
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
  writeBlock(gPlaneModal.format(17));
  if (!isLastSection() && (getNextSection().getTool().coolant != tool.coolant)) {
    setCoolant(COOLANT_OFF);
  }
  forceAny();
}

/** Output block to do safe retract and/or move to home position. */
function writeRetract() {
  var words = []; // store all retracted axes in an array
  var retractAxes = new Array(false, false, false);
  var method = getProperty("safePositionMethod");
  if (method == "clearanceHeight") {
    if (!is3D()) {
      error(localize("Retract option 'Clearance Height' is not supported for multi-axis machining."));
    } else {
      return;
    }
  }
  validate(arguments.length != 0, "No axis specified for writeRetract().");

  for (i in arguments) {
    retractAxes[arguments[i]] = true;
  }
  if ((retractAxes[0] || retractAxes[1]) && !retracted) { // retract Z first before moving to X/Y home
    error(localize("Retracting in X/Y is not possible without being retracted in Z."));
    return;
  }
  // special conditions
  /*
  if (retractAxes[2]) { // Z doesn't use G53
    method = "G28";
  }
  */

  // define home positions
  var _xHome;
  var _yHome;
  var _zHome;
  if (false && method == "G28") {
    _xHome = toPreciseUnit(0, MM);
    _yHome = toPreciseUnit(0, MM);
    _zHome = toPreciseUnit(0, MM);
  } else {
    _xHome = machineConfiguration.hasHomePositionX() ? machineConfiguration.getHomePositionX() : toPreciseUnit(0, MM);
    _yHome = machineConfiguration.hasHomePositionY() ? machineConfiguration.getHomePositionY() : toPreciseUnit(0, MM);
    // _zHome = machineConfiguration.getRetractPlane() != 0 ? machineConfiguration.getRetractPlane() : toPreciseUnit(0, MM);
    _zHome = getProperty("retractZ");
  }
  for (var i = 0; i < arguments.length; ++i) {
    switch (arguments[i]) {
    case X:
      words.push("X" + xyzFormat.format(_xHome));
      xOutput.reset();
      break;
    case Y:
      words.push("Y" + xyzFormat.format(_yHome));
      yOutput.reset();
      break;
    case Z:
      words.push("Z" + xyzFormat.format(_zHome), "D" + offsetFormat.format(getProperty("useToolNumberForCompensation") ? tool.number : tool.lengthOffset));
      zOutput.reset();
      retracted = true;
      break;
    default:
      error(localize("Unsupported axis specified for writeRetract()."));
      return;
    }
  }
  if (words.length > 0) {
    switch (method) {
    case "G28":
      gMotionModal.reset();
      gAbsIncModal.reset();
      writeBlock(gFormat.format(28), gAbsIncModal.format(91), words);
      writeBlock(gAbsIncModal.format(90));
      break;
    case "G53":
      gMotionModal.reset();
      writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), words);
      break;
    case "specifiedZvalue":
      writeBlock(gMotionModal.format(0), words); // retract
      break;
    default:
      error(localize("Unsupported safe position method."));
      return;
    }
  }
}

function onClose() {
  setCoolant(COOLANT_OFF);
  // writeln("T" + toolFormat.format(0)); // cancel length offset
  writeRetract(Z);

  writeBlock(mFormat.format(30));

  write(cycleCalls);

  writeln("");
  writeln("?");
  writeln("0000");
}

function setProperty(property, value) {
  properties[property].current = value;
}
