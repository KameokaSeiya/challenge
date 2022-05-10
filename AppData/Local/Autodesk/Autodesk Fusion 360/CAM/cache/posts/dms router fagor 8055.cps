/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  FAGOR post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {AFBF02F9-62E3-4ec8-9FE8-4B1705B25A49}
*/

///////////////////////////////////////////////////////////////////////////////
//                        MANUAL NC COMMANDS
//
// The following ACTION commands are supported by this post.
//
//     useVTable                  - Use the V-table for this operation
//     useYTable                  - Use the Y-table for this operation
//
///////////////////////////////////////////////////////////////////////////////

description = "DMS Router with FAGOR 8055 Control";
vendor = "Diversified Machine Systems DMS";
vendorUrl = "http://dmscncrouters.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic 5-axis milling post for DMS routers with a FAGOR 8055 control.";

extension = "pim";
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
  preloadTool: {
    title: "Preload tool",
    description: "Preloads the next tool at a tool change (if any).",
    group: 1,
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
  useVTable: {
    title: "Use V table",
    description: "Defaults to the Y-table.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  useG16: {
    title: "Use G16",
    description: "If enables, G16 is used instead of G17/G18/G19.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  fiveAxis: {
    title: "Five axis",
    description: "Defines whether the machine is a 5-axis router.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  gotContinuousCAxis: {
    title: "Continuous C-axis",
    description: "If enabled, the C-axis is continuous with no limits.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  safeRetractDistance: {
    title: "Safe retract distance",
    description: "A set distance to add to the tool length for rewind C-axis tool retract.",
    type: "number",
    value: (unit == MM ? 12.0 : 0.5),
    scope: "post"
  },
  safeZHeight: {
    title: "Safe Z height",
    description: "Safe retract height for operations.",
    type: "number",
    value: 0,
    scope: "post"
  },
  parkXY: {
    title: "Park XY position",
    description: "XY park position in G53 mode.",
    type: "string",
    value: "0,0",
    scope: "post"
  },
  contouringAcceleration: {
    title: "Contouring acceleration",
    description: "Acceleration percentage used for G51 look-ahead smoothing.",
    type: "number",
    value: 60,
    scope: "post"
  },
  contouringError: {
    title: "Contouring error",
    description: "Error allowed during G52 look-ahead smoothing.",
    type: "number",
    value: 0.001,
    scope: "post"
  },
  forceHomeOnIndexing: {
    title: "Force home position on indexing",
    description: "Force home position on multi-axis indexing.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  cAxisLinearScale: {
    title: "C-axis moves on a linear scale",
    description: "Set to false to output continuous C-axis between 0-360 degrees.",
    type: "boolean",
    value: false,
    scope: "post"
  }
};

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,=_-";

var singleLineCoolant = false; // specifies to output multiple coolant codes in one line rather than in separate lines
// samples:
// {id: COOLANT_THROUGH_TOOL, on: 88, off: 89}
// {id: COOLANT_THROUGH_TOOL, on: [8, 88], off: [9, 89]}
var coolants = [
  {id: COOLANT_FLOOD, on:65, off:66},
  {id: COOLANT_MIST},
  {id: COOLANT_THROUGH_TOOL},
  {id: COOLANT_AIR},
  {id: COOLANT_AIR_THROUGH_TOOL},
  {id: COOLANT_SUCTION},
  {id: COOLANT_FLOOD_MIST},
  {id: COOLANT_FLOOD_THROUGH_TOOL},
  {id: COOLANT_OFF, off: 66}
];

var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"M", decimals:0});
var dFormat = createFormat({prefix:"D", decimals:0});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var abcFormat = createFormat({decimals:3, forceDecimal:true, scale:DEG});
var feedFormat = createFormat({decimals:(unit == MM ? 5 : 5)});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var kFormat = createFormat({decimals:0}); // centiseconds - range 0-99999
var taperFormat = createFormat({decimals:1, scale:DEG});
var eFormat = createFormat({decimals:5});
var accelFormat = createFormat({decimals:0});

var xOutput = createVariable({prefix:"X"}, xyzFormat);
var yOutput = createVariable({prefix:"Y"}, xyzFormat);
var zOutput = createVariable({onchange: function() {retracted = false;}, prefix: "Z"}, xyzFormat);
var aOutput = createVariable({prefix: "A"}, abcFormat);
var bOutput = createVariable({prefix:"B"}, abcFormat);
var cOutput = createVariable({prefix:"C"}, abcFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var sOutput = createVariable({prefix:"S", force:true}, rpmFormat);
var dOutput = createVariable({}, dFormat);

// circular output
var iOutput = createReferenceVariable({prefix:"I", force:true}, xyzFormat);
var jOutput = createReferenceVariable({prefix:"J", force:true}, xyzFormat);
var kOutput = createReferenceVariable({prefix:"K", force:true}, xyzFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G16-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G94-95
var gUnitModal = createModal({}, gFormat); // modal group 6 // G70-71
var gCycleModal = createModal({}, gFormat); // modal group 9 // G81, ...
var gRetractModal = createModal({}, gFormat); // modal group 10 // G98-99
var gTableModal = createModal({}, gFormat); // modal group 11 // G28-29

// fixed settings
var maxFeedRate = 99999.99999;
var pivotDistance = toPreciseUnit(8.2202, IN); // distance to pivot point along B-axis
var headOffset = pivotDistance; // can have the tool length added to it
var safeRetractFeed = (unit == IN) ? 40 : 1000;
var safePlungeFeed = (unit == IN) ? 25 : 625;

var WARNING_WORK_OFFSET = 0;

// collected state
var sequenceNumber;
var currentWorkOffset;
var currentPlane;
var previousABC = new Vector(0, 0, 0);
var parkPosition = new Vector(0, 0, 0);
var vTableActive = false;
var retracted = false; // specifies that the tool has been retracted to the safe plane
var rotaryScale;
var retractPlane;

function getG16(plane) {
  if (currentPlane != plane) {
    currentPlane = plane;
    return formatWords(gFormat.format(16), plane);
  }
  return [];
}

/**
  Writes the specified block.
*/
function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }
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
  writeBlock("; " + filterText(String(text).toUpperCase(), permittedCommentChars));
}

/**
  Parses a string containing two values (0,0).
*/
function parseXY(_text) {
  var limits = {min:0, max:0};
  var tmpArray = parseNumbers(_text, 2);
  if (tmpArray[0] != 2) {
    writeFatal(localize("Property table limits are in the wrong format."));
    return new Vector(0, 0, 0);
  } else {
    return new Vector(tmpArray[1], tmpArray[2], 0);
  }
}

function parseNumbers(_text, _max) {
  // extract values between commas
  var sText1 = _text;
  var sText2 = new Array();
  var retCoord = new Array();
  sText2 = sText1.split(",");
  retCoord[0] = sText2.length;

  // too many values, return 0
  if (retCoord[0] > _max) {
    retCoord[0] = 0;
    return retCoord;
  }

  // parse numbers,  if a string is not a valid number, then return 0
  for (i = 0; i < retCoord[0]; i++) {
    retCoord[i + 1] = parseFloat(sText2[i]);
    // if a string is not a valid number, then return 0
    if (isNaN(retCoord[i])) {
      retCoord[0] = 0;
      return retCoord;
    }
  }
  return retCoord;
}

function onOpen() {

  rotaryScale = getProperty("gotContinuousCAxis") && !getProperty("cAxisLinearScale");
  // define XYZ home position
  parkPosition = parseXY(getProperty("parkXY"));

  if (getProperty("fiveAxis")) {
    var bAxis = createAxis({coordinate:1, table:false, axis:[0, -1, 0], range:[-125.000, 125.000]});
    var cAxis;
    if (getProperty("gotContinuousCAxis")) {
      if (getProperty("cAxisLinearScale")) {
        cAxis = createAxis({coordinate:2, table:false, axis:[0, 0, -1], cyclic:true, preference:0});
      } else {
        cAxis = createAxis({coordinate:2, table:false, axis:[0, 0, -1], cyclic:true, range:[0.0, 360.0], preference:0});
      }
    } else {
      cAxis = createAxis({coordinate:2, table:false, axis:[0, 0, -1], cyclic:false, range:[-365.0, 365.0], preference:0});
    }
    machineConfiguration = new MachineConfiguration(bAxis, cAxis);

    setMachineConfiguration(machineConfiguration);
    optimizeMachineAngles2(0); // TCP mode
  }
  machineConfiguration.setRetractPlane(toPreciseUnit(getProperty("safeZHeight"), IN));
  retractPlane = getProperty("safeZHeight");

  if (!machineConfiguration.isMachineCoordinate(0)) {
    aOutput.disable();
  }
  if (!machineConfiguration.isMachineCoordinate(1)) {
    bOutput.disable();
  }
  if (!machineConfiguration.isMachineCoordinate(2)) {
    cOutput.disable();
  }
  
  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");

  var fileName = FileSystem.getFilename(FileSystem.replaceExtension(getOutputPath(), "xxx").split(".xxx", 1));
  if (!fileName) {
    if (programComment) {
      fileName = programComment;
    } else if (programName) {
      fileName = programName;
    } else {
      error(localize("Program name has not been specified."));
      return;
    }
  }
  writeln("%" + fileName.slice(0, 20).replace(/[,]/g, " ") + ",MX--,"); // max 20 chars

  /*
  if (programName) {
    var programId;
    try {
      programId = getAsInt(programName);
    } catch(e) {
      error(localize("Program name must be a number."));
      return;
    }
    if ((programId < 1) || (programId > 999999)) {
      error(localize("Program number is out of range."));
      return;
    }
    writeln(oFormat.format(programId));
  } else {
    error(localize("Program name has not been specified."));
    return;
  }
*/

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

  if ((getNumberOfSections() > 0) && (getSection(0).workOffset == 0)) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      if (getSection(i).workOffset > 0) {
        error(localize("Using multiple work offsets is not possible if the initial work offset is 0."));
        return;
      }
    }
  }

  // absolute coordinates and feed per min
  writeBlock(gAbsIncModal.format(90), gFeedModeModal.format(94), conditional(!getProperty("useG16"), gPlaneModal.format(17)));
  if (getProperty("useG16")) {
    writeBlock(getG16("XY"));
  }

  switch (unit) {
  case IN:
    writeBlock(gUnitModal.format(70));
    break;
  case MM:
    writeBlock(gUnitModal.format(71));
    break;
  }
  writeBlock(gFormat.format(48), "S0");

  if (getProperty("useVTable")) {
    swapVTable(true, false);
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

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
  forceXYZ();
  forceABC();
  feedOutput.reset();
}

var currentSmoothing = undefined;

function setSmoothing(mode) {
  if (mode == currentSmoothing) {
    return false;
  }

  currentSmoothing = mode;
  if (mode) {
    writeBlock(
      gFormat.format(51),
      "A" + accelFormat.format(getProperty("contouringAcceleration")),
      "E" + eFormat.format(getProperty("contouringError"))
    ); // enable look ahead
  } else {
    writeBlock(gFormat.format(7));
  }
  return true;
}

var currentWorkPlaneABC = undefined;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

function setWorkPlane(abc) {
  if (!machineConfiguration.isMultiAxisConfiguration()) {
    return; // ignore
  }

  if (!((currentWorkPlaneABC == undefined) ||
        abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
        abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
        abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z))) {
    return; // no change
  }

  onCommand(COMMAND_UNLOCK_MULTI_AXIS);

  var plane = calculateRetractPlane(abc);
  if (plane < retractPlane) {
    retractPlane = plane;
    writeRetract(Z);
  }

  writeBlock(
    gMotionModal.format(0),
    conditional(machineConfiguration.isMachineCoordinate(0), aOutput.format(abc.x)),
    conditional(machineConfiguration.isMachineCoordinate(1), bOutput.format(abc.y)),
    conditional(machineConfiguration.isMachineCoordinate(2),
      cOutput.format(getDirectionalABC(previousABC.z, abc.z, cOutput, rotaryScale)))
  );
  
  onCommand(COMMAND_LOCK_MULTI_AXIS);

  currentWorkPlaneABC = abc;
  previousABC = abc;
}

var closestABC = false; // choose closest machine angles
var currentMachineABC;

function getWorkPlaneMachineABC(workPlane) {
  var W = workPlane; // map to global frame

  var abc = machineConfiguration.getABC(W);
  if (closestABC) {
    if (currentMachineABC) {
      abc = machineConfiguration.remapToABC(abc, currentMachineABC);
    } else {
      abc = machineConfiguration.getPreferredABC(abc);
    }
  } else {
    abc = machineConfiguration.getPreferredABC(abc);
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
  
  if (!machineConfiguration.isABCSupported(abc)) {
    error(
      localize("Work plane is not supported") + ":"
      + conditional(machineConfiguration.isMachineCoordinate(0), " A" + abcFormat.format(abc.x))
      + conditional(machineConfiguration.isMachineCoordinate(1), " B" + abcFormat.format(abc.y))
      + conditional(machineConfiguration.isMachineCoordinate(2), " C" + abcFormat.format(abc.z))
    );
  }

  var tcp = true;
  if (tcp) {
    setRotation(W); // TCP mode
  } else {
    var O = machineConfiguration.getOrientation(abc);
    var R = machineConfiguration.getRemainingOrientation(abc, W);
    setRotation(R);
  }
  
  return abc;
}

function swapVTable(_vTable, _swap) {
  if (_vTable) {
    writeBlock(gTableModal.format(28), "YV");
    if (_swap) {
      writeComment("add table swap codes here");
    }
    vTableActive = true;
  } else {
    writeBlock(gTableModal.format(29), "Y");
    if (_swap) {
      writeComment("add table swap codes here");
    }
    vTableActive = false;
  }
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
  var forceSmoothing =
    (hasParameter("operation-strategy") && (getParameter("operation-strategy") == "drill") ||
    !isFirstSection() && getPreviousSection().hasParameter("operation-strategy") && (getPreviousSection().getParameter("operation-strategy") == "drill")); // force smoothing in case !insertToolCall (2d chamfer)
  if (insertToolCall || newWorkOffset || newWorkPlane || forceSmoothing) {
    
    // stop spindle before retract during tool change
    if (insertToolCall && !isFirstSection()) {
      onCommand(COMMAND_STOP_SPINDLE);
      setCoolant(COOLANT_OFF);
    }
    if (!isFirstSection()) {
      writeBlock(gFormat.format(48), "S0");
    }

    // retract tool
    zOutput.reset();
    retractPlane = calculateRetractPlane(previousABC);
    writeRetract(Z);
    if (getProperty("forceHomeOnIndexing")) {
      writeRetract(X, Y);
    }
    forceABC();
    var abc = new Vector(0, 0, 0);
    if (currentSection.isMultiAxis() && !rotaryScale) {
      abc = currentSection.getInitialToolAxisABC();
    }
    abc = machineConfiguration.remapToABC(new Vector(0, 0, 0), abc);
    writeBlock(gFormat.format(53), aOutput.format(0), bOutput.format(0), cOutput.format(abc.z));
    previousABC = new Vector(0, 0, 0);
    if ((insertToolCall && !isFirstSection()) || forceSmoothing) {
      setSmoothing(false);
    }
  }
  
  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment(comment);
    }
  }

  if (insertToolCall) {
    forceWorkPlane();
    
    if (!isFirstSection() && getProperty("optionalStop")) {
      onCommand(COMMAND_OPTIONAL_STOP);
    }

    if (tool.number > 99) {
      warning(localize("Tool number exceeds maximum value."));
    }

    writeBlock("T" + toolFormat.format(tool.number));
    writeBlock(mFormat.format(6));
    if (tool.comment) {
      writeComment(tool.comment);
    }
    if (getProperty("fiveAxis")) { // tool change causes position change, move it back to its home position
      writeRetract(Z);
      if (getProperty("forceHomeOnIndexing")) {
        writeRetract(X, Y);
      }
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
  }
  
  if (insertToolCall ||
      isFirstSection() ||
      (rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) ||
      (tool.clockwise != getPreviousSection().getTool().clockwise)) {
    if (spindleSpeed < 1) {
      error(localize("Spindle speed out of range."));
      return;
    }
    if (spindleSpeed > 99999) {
      warning(localize("Spindle speed exceeds maximum value."));
    }
    writeBlock(
      sOutput.format(spindleSpeed), mFormat.format(tool.clockwise ? 3 : 4)
    );
    onDwell(3.0);
    setSmoothing(!(hasParameter("operation-strategy") && (getParameter("operation-strategy") == "drill")));
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
    if (workOffset > 4) {
      var code = workOffset;
      if (code > 20) {
        error(localize("Work offset out of range."));
        return;
      }
      if (workOffset != currentWorkOffset) {
        writeBlock(gFormat.format(159), "N" + code);
        currentWorkOffset = workOffset;
        // writeln(";(ORGX58=0,ORGY58=0,ORGZ58=0)");
        // writeBlock(gFormat.format(58));
      }
    } else {
      if (workOffset != currentWorkOffset) {
        writeBlock(gFormat.format((53 + workOffset))); // G54->G59
        currentWorkOffset = workOffset;
        writeln(";(ORGX58=0,ORGY58=0,ORGZ58=0)");
        writeBlock(gFormat.format(58));
      }
    }
  }

  forceXYZ();
  gMotionModal.reset();
  headOffset = tool.bodyLength + pivotDistance;
  // retractPlane = calculateRetractPlane(previousABC);
  // writeRetract(Z);

  if (machineConfiguration.isMultiAxisConfiguration()) { // use 5-axis indexing for multi-axis mode
    // set working plane after datum shift

    var abc;
    if (currentSection.isMultiAxis()) {
      abc = currentSection.getInitialToolAxisABC();
      forceWorkPlane();
      cancelTransformation();
    } else {
      abc = getWorkPlaneMachineABC(currentSection.workPlane);
    }
    setWorkPlane(abc);
  } else { // pure 3D
    var remaining = currentSection.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported."));
      return;
    }
    setRotation(remaining);
  }

  // control uses D-word for length offset also
  var lengthOffset = tool.lengthOffset;
  if (lengthOffset > 99) {
    error(localize("Length offset out of range."));
    return;
  }

  if (retracted) {
    if (getProperty("fiveAxis")) {
      writeBlock(dOutput.format(lengthOffset));
      writeBlock(gFormat.format(48), "S1"); // Enable TCP mode after Work Plane if G53 is used for retract
    }
  }

  forceXYZ();
  gMotionModal.reset();

  // set coolant after we have positioned at Z
  setCoolant(tool.coolant);

  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  if (!retracted && !insertToolCall) {
    if (getCurrentPosition().z < initialPosition.z) {
      writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
    }
  }

  if (insertToolCall || retracted) {
    gMotionModal.reset();
    currentPlane = undefined;
    if (getProperty("useG16")) {
      writeBlock(getG16("XY"));
    } else {
      writeBlock(gPlaneModal.format(17));
    }
    
    if (!machineConfiguration.isHeadConfiguration()) {
      writeBlock(
        gAbsIncModal.format(90),
        gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y)
      );
      writeBlock(
        gMotionModal.format(0),
        conditional(!getProperty("fiveAxis"), gFormat.format(43)),
        zOutput.format(initialPosition.z), conditional(!getProperty("fiveAxis"), dOutput.format(lengthOffset))
      );
    } else {
      writeBlock(
        gAbsIncModal.format(90),
        gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y)
      );
      writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
    }

    gMotionModal.reset();
  } else {
    writeBlock(
      gAbsIncModal.format(90),
      gMotionModal.format(0),
      xOutput.format(initialPosition.x),
      yOutput.format(initialPosition.y)
    );
    writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
  }
}

function onDwell(seconds) {
  if (seconds > 999.99) {
    warning(localize("Dwelling time is out of range."));
  }
  time = clamp(1, seconds * 100, 99999);
  writeBlock(gFormat.format(4), "K" + kFormat.format(time));
}

function onSpindleSpeed(spindleSpeed) {
  writeBlock(sOutput.format(spindleSpeed));
  onDwell(3.0);
}

function onCycle() {
  if (getProperty("useG16")) {
    writeBlock(getG16("XY"));
  } else {
    writeBlock(gPlaneModal.format(17));
  }
}

function getCommonCycle(x, y, reference, bottom) {
  forceXYZ();
  return [xOutput.format(x), yOutput.format(y),
    "Z" + xyzFormat.format(reference),
    "I" + xyzFormat.format(bottom)];
}

function onCyclePoint(x, y, z) {
  if (!isSameDirection(getRotation().forward, new Vector(0, 0, 1))) {
    expandCyclePoint(x, y, z);
    return;
  }

  if (isFirstCyclePoint()) {
    repositionToCycleClearance(cycle, x, y, z);
    
    // return to initial Z which is clearance plane and set absolute mode

    var F = cycle.feedrate;
    var K = (cycle.dwell == 0) ? 0 : clamp(1, cycle.dwell * 100, 99999);

    switch (cycleType) {
    case "drilling":
      writeBlock(
        gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(81),
        getCommonCycle(x, y, cycle.retract, cycle.bottom),
        ((K > 0) ? "K" + kFormat.format(K) : ""),
        feedOutput.format(F)
      );
      break;
    case "counter-boring":
      writeBlock(
        gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(82),
        getCommonCycle(x, y, cycle.retract, cycle.bottom),
        "K" + kFormat.format(K),
        feedOutput.format(F)
      );
      break;
    case "chip-breaking":
      if ((cycle.accumulatedDepth < cycle.depth) || (P > 0)) {
        expandCyclePoint(x, y, z);
      } else {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(69),
          getCommonCycle(x, y, cycle.retract, cycle.bottom),
          "B" + xyzFormat.format(cycle.incrementalDepth),
          // "C" + xyzFormat.format(machineParameters.drillingSafeDistance),
          "D" + xyzFormat.format(cycle.retract - cycle.stock),
          "H" + xyzFormat.format((cycle.chipBreakDistance != undefined) ? cycle.chipBreakDistance : machineParameters.chipBreakingDistance),
          "J" + cycle.plungesPerRetract,
          ((K > 0) ? "K" + kFormat.format(K) : ""),
          ((cycle.minimumIncrementalDepth > 0) ? "L" + xyzFormat.format(cycle.minimumIncrementalDepth) : ""),
          ((cycle.incrementalDepthReduction > 0) ? "R" +
            xyzFormat.format(1 - (cycle.incrementalDepthReduction / cycle.incrementalDepth)) : ""),
          feedOutput.format(F)
        );
      }
      break;
    case "deep-drilling":
      if ((cycle.incrementalDepthReduction > 0) || (K > 0)) {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(69),
          getCommonCycle(x, y, cycle.retract, cycle.bottom),
          "B" + xyzFormat.format(cycle.incrementalDepth),
          // "C" + xyzFormat.format(machineParameters.drillingSafeDistance),
          "D" + xyzFormat.format(cycle.retract - cycle.stock),
          "J1",
          ((K > 0) ? "K" + kFormat.format(K) : ""),
          ((cycle.minimumIncrementalDepth > 0) ? "L" + xyzFormat.format(cycle.minimumIncrementalDepth) : ""),
          ((cycle.incrementalDepthReduction > 0) ? "R" +
            xyzFormat.format(1 - (cycle.incrementalDepthReduction / cycle.incrementalDepth)) : ""),
          feedOutput.format(F)
        );
      } else {
        var plunges = Math.max(Math.floor((cycle.retract - cycle.bottom) / cycle.incrementalDepth), 1);
        var incrementalDepth = -(cycle.retract - cycle.bottom) / plunges;
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(83),
          xOutput.format(x) + yOutput.format(y),
          "Z" + xyzFormat.format(cycle.retract),
          "I" + xyzFormat.format(incrementalDepth),
          "J" + xyzFormat.format(plunges),
          feedOutput.format(F)
        );
      }
      break;
    case "tapping":
      if (tool.type == TOOL_TAP_LEFT_HAND) {
        expandCyclePoint(x, y, z);
      } else {
        if (!F) {
          F = tool.getTappingFeedrate();
        }
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(84),
          getCommonCycle(x, y, cycle.retract, cycle.bottom),
          ((K > 0) ? "K" + kFormat.format(K) : ""),
          "R0", feedOutput.format(F)
        );
      }
      break;
    case "left-tapping":
      expandCyclePoint(x, y, z);
      break;
    case "right-tapping":
      if (!F) {
        F = tool.getTappingFeedrate();
      }
      writeBlock(
        gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(84),
        getCommonCycle(x, y, cycle.retract, cycle.bottom),
        ((K > 0) ? "K" + kFormat.format(K) : ""),
        "R0", feedOutput.format(F)
      );
      break;
    case "fine-boring":
      expandCyclePoint(x, y, z);
      break;
    case "back-boring":
      expandCyclePoint(x, y, z);
      break;
    case "reaming":
      writeBlock(
        gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(85),
        getCommonCycle(x, y, cycle.retract, cycle.bottom),
        ((K > 0) ? "K" + kFormat.format(K) : ""),
        feedOutput.format(F)
      );
      break;
    case "stop-boring":
      writeBlock(
        gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(86),
        getCommonCycle(x, y, cycle.retract, cycle.bottom),
        ((K > 0) ? "K" + kFormat.format(K) : ""),
        feedOutput.format(F)
      );
      break;
    case "manual-boring":
      expandCyclePoint(x, y, z);
      break;
    case "boring":
      writeBlock(
        gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(89),
        getCommonCycle(x, y, cycle.retract, cycle.bottom),
        ((K > 0) ? "K" + kFormat.format(K) : ""),
        feedOutput.format(F)
      );
      break;
    default:
      expandCyclePoint(x, y, z);
    }
  } else {
    if (cycleExpanded) {
      expandCyclePoint(x, y, z);
    } else {
      writeBlock(xOutput.format(x), yOutput.format(y));
    }
  }
}

function onCycleEnd() {
  if (!cycleExpanded) {
    writeBlock(gCycleModal.format(80));
    zOutput.reset();
  }
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
      return;
    }
    writeBlock(gMotionModal.format(0), x, y, z);
    feedOutput.reset(); // not required for 8040M
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
      var d = tool.diameterOffset;
      if (d > 99) {
        warning(localize("The diameter offset exceeds the maximum value."));
      }
      if (getProperty("useG16")) {
        writeBlock(getG16("XY"));
      } else {
        writeBlock(gPlaneModal.format(17));
      }
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        dOutput.reset();
        writeBlock(gMotionModal.format(1), gFormat.format(41), x, y, z, dOutput.format(d), f);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        dOutput.reset();
        writeBlock(gMotionModal.format(1), gFormat.format(42), x, y, z, dOutput.format(d), f);
        break;
      default:
        writeBlock(gMotionModal.format(1), gFormat.format(40), x, y, z, f);
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

function onRapid5D(_x, _y, _z, _a, _b, _c) {
  if (!currentSection.isOptimizedForMachine()) {
    error(localize("This post configuration has not been customized for 5-axis simultaneous toolpath."));
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
  var b = bOutput.format(_b);
  var c = cOutput.format(getDirectionalABC(previousABC.z, _c, cOutput, rotaryScale));
  if (x || y || z || a || b || c) {
    writeBlock(gMotionModal.format(0), x, y, z, a, b, c);
    feedOutput.reset(); // not required for 8040M
    previousABC = new Vector(_a, _b, _c);
  }
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed) {
  if (!currentSection.isOptimizedForMachine()) {
    error(localize("This post configuration has not been customized for 5-axis simultaneous toolpath."));
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
  var b = bOutput.format(_b);
  var c = cOutput.format(getDirectionalABC(previousABC.z, _c, cOutput, rotaryScale));
  f = feedOutput.format(feed);

  if (x || y || z || a || b || c) {
    writeBlock(gMotionModal.format(1), x, y, z, a, b, c, f);
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      feedOutput.reset(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(1), f);
    }
  }
  previousABC = new Vector(_a, _b, _c);
}

/** Calculate angles on rotary scale with signed direction. */
function getDirectionalABC(_startAngle, _endAngle, _output, _directionFlag) {
  var signedAngle = _endAngle;
  if (_directionFlag) {
    // angles are the same, set the previous output angle to the current angle so it is not output
    if (!abcFormat.areDifferent(_startAngle, _endAngle)) {
      _output.format(_startAngle);
    }
    // calculate the correct direction (sign) based on CLW/CCW direction
    var delta = abcFormat.getResultingValue(_endAngle - _startAngle);
    if (((delta < 0) && (delta > -180.0)) || (delta > 180.0)) {
      if (_endAngle == 0) {
        signedAngle = -Math.PI * 2;
      } else {
        signedAngle = -_endAngle;
      }
    }
  }
  return signedAngle;
}

// Start of onRewindMachine logic
/***** Be sure to add 'safeRetractDistance' to post getProperty(" ")*****/
var performRewinds = true; // enables the onRewindMachine logic
var safeRetractFeed = (unit == IN) ? 20 : 500;
var safePlungeFeed = (unit == IN) ? 10 : 250;
var stockAllowance = new Vector(toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN));

/** Allow user to override the onRewind logic. */
function onRewindMachineEntry(_a, _b, _c) {
  if (getProperty("gotContinuousCAxis")) {
    return true;
  }
  return false;
}

/** Retract to safe position before indexing rotaries. */
function moveToSafeRetractPosition(isRetracted) {
  retractPlane = calculateRetractPlane(previousABC);
  writeRetract(Z);
  if (getProperty("forceHomeOnIndexing")) {
    writeRetract(X, Y);
  }
}

/** Return from safe position after indexing rotaries. */
function returnFromSafeRetractPosition(position) {
  forceXYZ();
  xOutput.reset();
  yOutput.reset();
  zOutput.disable();
  onExpandedRapid(position.x, position.y, position.z);
  zOutput.enable();
  onExpandedRapid(position.x, position.y, position.z);
}

/** Intersect the point-vector with the stock box. */
function intersectStock(point, direction) {
  var intersection = getWorkpiece().getRayIntersection(point, direction, stockAllowance);
  return intersection === null ? undefined : intersection.second;
}

/** Calculates the retract point using the stock box and safe retract distance. */
function getRetractPosition(currentPosition, currentDirection) {
  var retractPos = intersectStock(currentPosition, currentDirection);
  if (retractPos == undefined) {
    if (tool.getFluteLength() != 0) {
      retractPos = Vector.sum(currentPosition, Vector.product(currentDirection, tool.getFluteLength()));
    }
  }
  if ((retractPos != undefined) && getProperty("safeRetractDistance")) {
    retractPos = Vector.sum(retractPos, Vector.product(currentDirection, getProperty("safeRetractDistance")));
  }
  return retractPos;
}

/** Determines if the angle passed to onRewindMachine is a valid starting position. */
function isRewindAngleValid(_a, _b, _c) {
  // make sure the angles are different from the last output angles
  if (!abcFormat.areDifferent(getCurrentDirection().x, _a) &&
      !abcFormat.areDifferent(getCurrentDirection().y, _b) &&
      !abcFormat.areDifferent(getCurrentDirection().z, _c)) {
    error(
      localize("REWIND: Rewind angles are the same as the previous angles: ") +
      abcFormat.format(_a) + ", " + abcFormat.format(_b) + ", " + abcFormat.format(_c)
    );
    return false;
  }
  
  // make sure angles are within the limits of the machine
  var abc = new Array(_a, _b, _c);
  var ix = machineConfiguration.getAxisU().getCoordinate();
  var failed = false;
  if ((ix != -1) && !machineConfiguration.getAxisU().isSupported(abc[ix])) {
    failed = true;
  }
  ix = machineConfiguration.getAxisV().getCoordinate();
  if ((ix != -1) && !machineConfiguration.getAxisV().isSupported(abc[ix])) {
    failed = true;
  }
  ix = machineConfiguration.getAxisW().getCoordinate();
  if ((ix != -1) && !machineConfiguration.getAxisW().isSupported(abc[ix])) {
    failed = true;
  }
  if (failed) {
    error(
      localize("REWIND: Rewind angles are outside the limits of the machine: ") +
      abcFormat.format(_a) + ", " + abcFormat.format(_b) + ", " + abcFormat.format(_c)
    );
    return false;
  }
  
  return true;
}

function onRewindMachine(_a, _b, _c) {
  
  if (!performRewinds) {
    error(localize("REWIND: Rewind of machine is required for simultaneous multi-axis toolpath and has been disabled."));
    return;
  }
  
  // Allow user to override rewind logic
  if (onRewindMachineEntry(_a, _b, _c)) {
    return;
  }
  
  // Determine if input angles are valid or will cause a crash
  if (!isRewindAngleValid(_a, _b, _c)) {
    error(
      localize("REWIND: Rewind angles are invalid:") +
      abcFormat.format(_a) + ", " + abcFormat.format(_b) + ", " + abcFormat.format(_c)
    );
    return;
  }
  
  // Work with the tool end point
  if (currentSection.getOptimizedTCPMode() == 0) {
    currentTool = getCurrentPosition();
  } else {
    currentTool = machineConfiguration.getOrientation(getCurrentDirection()).multiply(getCurrentPosition());
  }
  var currentABC = getCurrentDirection();
  var currentDirection = machineConfiguration.getDirection(currentABC);
  
  // Calculate the retract position
  var retractPosition = getRetractPosition(currentTool, currentDirection);

  // Output warning that axes take longest route
  if (retractPosition == undefined) {
    error(localize("REWIND: Cannot calculate retract position."));
    return;
  } else {
    var text = localize("REWIND: Tool is retracting due to rotary axes limits.");
    warning(text);
    writeComment(text);
  }

  // Move to retract position
  var position;
  if (currentSection.getOptimizedTCPMode() == 0) {
    position = retractPosition;
  } else {
    position = machineConfiguration.getOrientation(getCurrentDirection()).getTransposed().multiply(retractPosition);
  }
  onExpandedLinear(position.x, position.y, position.z, safeRetractFeed);
  
  //Position to safe machine position for rewinding axes
  moveToSafeRetractPosition(false);

  // Rotate axes to new position above reentry position
  xOutput.disable();
  yOutput.disable();
  zOutput.disable();
  onRapid5D(position.x, position.y, position.z, _a, _b, _c);
  xOutput.enable();
  yOutput.enable();
  zOutput.enable();

  // Move back to position above part
  if (currentSection.getOptimizedTCPMode() != 0) {
    position = machineConfiguration.getOrientation(new Vector(_a, _b, _c)).getTransposed().multiply(retractPosition);
  }
  returnFromSafeRetractPosition(position);

  // Plunge tool back to original position
  if (currentSection.getOptimizedTCPMode() != 0) {
    currentTool = machineConfiguration.getOrientation(new Vector(_a, _b, _c)).getTransposed().multiply(currentTool);
  }
  onExpandedLinear(currentTool.x, currentTool.y, currentTool.z, safePlungeFeed);
}
// End of onRewindMachine logic

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
      if (getProperty("useG16")) {
        writeBlock(getG16("XY"));
      }
      writeBlock(gAbsIncModal.format(90), conditional(!getProperty("useG16"), gPlaneModal.format(17)), gMotionModal.format(clockwise ? 2 : 3), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    case PLANE_ZX:
      if (getProperty("useG16")) {
        writeBlock(getG16("ZX"));
      }
      writeBlock(gAbsIncModal.format(90), conditional(!getProperty("useG16"), gPlaneModal.format(18)), gMotionModal.format(clockwise ? 2 : 3), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
      break;
    case PLANE_YZ:
      if (getProperty("useG16")) {
        writeBlock(getG16("YZ"));
      }
      writeBlock(gAbsIncModal.format(90), conditional(!getProperty("useG16"), gPlaneModal.format(19)), gMotionModal.format(clockwise ? 2 : 3), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else {
    switch (getCircularPlane()) {
    case PLANE_XY:
      if (getProperty("useG16")) {
        writeBlock(getG16("XY"));
      }
      writeBlock(gAbsIncModal.format(90), conditional(!getProperty("useG16"), gPlaneModal.format(17)), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), zOutput.format(z), feedOutput.format(feed));
      break;
    case PLANE_ZX:
      if (isHelical()) {
        linearize(tolerance);
        return;
      }
      if (getProperty("useG16")) {
        writeBlock(getG16("ZX"));
      }
      writeBlock(gAbsIncModal.format(90), conditional(!getProperty("useG16"), gPlaneModal.format(18)), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
      break;
    case PLANE_YZ:
      if (isHelical()) {
        linearize(tolerance);
        return;
      }
      if (getProperty("useG16")) {
        writeBlock(getG16("YZ"));
      }
      writeBlock(gAbsIncModal.format(90), conditional(!getProperty("useG16"), gPlaneModal.format(19)), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

function isProbeOperation() {
  return hasParameter("operation-strategy") && (getParameter("operation-strategy") == "probe");
}

function onParameter(name, value) {
  switch (name) {
  case "action":
    var errFlag = false;
    if (String(value).toUpperCase() == "USEVTABLE") {
      swapVTable(true, !vTableActive);
    } else if (String(value).toUpperCase() == "USEYTABLE") {
      swapVTable(false, vTableActive);
    } else {
      error(localize("Invalid action parameter: ") + value);
      return;
    }
    break;
  }
}

function parseToggle() {
  var stat = undefined;
  for (i = 1; i < arguments.length; i++) {
    if (String(arguments[0]).toUpperCase() == String(arguments[i]).toUpperCase()) {
      if (String(arguments[i]).toUpperCase() == "YES") {
        stat = true;
      } else if (String(arguments[i]).toUpperCase() == "NO") {
        stat = false;
      } else {
        stat = i - 1;
        break;
      }
    }
  }
  return stat;
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
  COMMAND_SPINDLE_CLOCKWISE:3,
  COMMAND_SPINDLE_COUNTERCLOCKWISE:4,
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
  if (!isLastSection() && (getNextSection().getTool().coolant != tool.coolant)) {
    setCoolant(COOLANT_OFF);
  }
  forceAny();
}

/** Calculates the retract plane based on the A-axis position. */
function calculateRetractPlane(_abc) {
  var plane = machineConfiguration.getRetractPlane();
  if (Math.abs(_abc.y) > (Math.PI / 2)) {
    plane -= Math.sin(Math.abs(_abc.y) - (Math.PI / 2)) * headOffset;
  }
  return plane;
}

/** Output block to do safe retract and/or move to home position. */
function writeRetract() {
  if (arguments.length == 0) {
    error(localize("No axis specified for writeRetract()."));
    return;
  }
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
      words.push("X" + parkPosition.x);
      break;
    case Y:
      words.push("Y" + parkPosition.y);
      break;
    case Z:
      words.push("Z" + xyzFormat.format(retractPlane));
      retracted = true; // specifies that the tool has been retracted to the safe plane
      zOutput.reset();
      break;
    default:
      error(localize("Bad axis specified for writeRetract()."));
      return;
    }
  }
  if (words.length > 0) {
    writeBlock(gMotionModal.format(0), gFormat.format(53), words); // retract
  }
}

function onClose() {
  setCoolant(COOLANT_OFF);
  onCommand(COMMAND_STOP_SPINDLE);

  gMotionModal.reset();
  writeBlock(gFormat.format(48), "S0");
  retractPlane = calculateRetractPlane(previousABC);
  writeRetract(Z);
  forceABC();
  // writeBlock(gFormat.format(53), aOutput.format(0), bOutput.format(0), cOutput.format(0));
  writeRetract(X, Y);
  previousABC = new Vector(0, 0, 0);
  forceXYZ();
  zOutput.reset();

  forceABC();
  forceWorkPlane();
  setWorkPlane(new Vector(0, 0, 0)); // reset working plane
  
  if (vTableActive) {
    swapVTable(false, false);
  }
  onImpliedCommand(COMMAND_END);
  writeBlock(mFormat.format(30)); // stop program, spindle stop

  //writeln("%");
}

function setProperty(property, value) {
  properties[property].current = value;
}
