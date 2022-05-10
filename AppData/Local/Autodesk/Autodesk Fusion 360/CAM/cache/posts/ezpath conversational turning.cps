/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  EZ Path Lathe post processor configuration.

  $Revision: 43233 c02df52f5419fc284f20cd633651d83ca2513058 $
  $Date: 2021-04-28 19:07:17 $
  
  FORKID {D2D450CD-C9D4-4249-957E-3C0B46FB67B3}
*/

description = "EZ Path Conversational Turning";
vendor = "Bridgeport";
vendorUrl = "https://www.autodesk.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic turning post for EZ Path conversational. Use tool comment field for tool id value. Use Turret 0 for Positional Turret, Turret 101 for QCTP on X- Post, Turret 102 for QCTP on X+ Post, Turret 103 for Gang Tooling on X- Post, Turret 104 for Gang Tooling on X+ Tool Post.";
extension = "PGM";
programNameIsInteger = false;
setCodePage("ascii");

capabilities = CAPABILITY_TURNING;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = false;
allowedCircularPlanes = 1 << PLANE_ZX; // allow ZX plane only

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
    value: false,
    scope: "post"
  },
  safePositionMethod: {
    title: "Safe Retracts",
    description: "Select your desired retract option.",
    type: "enum",
    group: 0,
    values: [
      {title: "Home Position", id: "homePosition"},
      {title: "Clearance Height", id: "clearanceHeight"}
    ],
    value: "clearanceHeight",
    scope: "post"
  },
  safePositionStyle: {
    title: "Safe retract style",
    description: "Select your desired order for the axes to retract.",
    type: "enum",
    group: 0,
    values: [
      {title: "Only X", id: "X"},
      {title: "Only Z", id: "Z"},
      {title: "Both X then Z", id: "XZ"},
      {title: "Both Z then X", id: "ZX"},
      {title: "Both same line", id: "singleLineXZ"}
    ],
    value: "XZ",
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
    value: 1000,
    scope: "post"
  },
  sequenceNumberIncrement: {
    title: "Sequence number increment",
    description: "The amount by which the sequence number is incremented by in each block.",
    group: 1,
    type: "integer",
    value: 10,
    scope: "post"
  },
  optionalStop: {
    title: "Optional stop",
    description: "Outputs optional stop in the code.",
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
  useRadius: {
    title: "Radius arcs",
    description: "If yes is selected, arcs are output using radius values rather than xc, zc.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  maximumSpindleSpeed: {
    title: "Max spindle speed",
    description: "Defines the maximum spindle speed allowed by your machines.",
    type: "integer",
    range: [0, 999999999],
    value: 6000,
    scope: "post"
  },
  spindleRangeLow: {
    title: "Low spindle speed range",
    description: "Speed to change from first to second gear. Enter '0' if machine is not geared.",
    type: "integer",
    range: [0, 999999999],
    value: 400,
    scope: "post"
  },
  spindleRangeHigh: {
    title: "High spindle speed range",
    description: "Speed to change from second to third gear . Enter '0' if machine does not have gear three.",
    type: "integer",
    range: [0, 999999999],
    value: 1000,
    scope: "post"
  },
  showNotes: {
    title: "Show notes",
    description: "Writes operation notes as comments in the outputted code.",
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
  homePositionX: {
    title: "Home position X",
    description: "X-axis home position.",
    type: "number",
    value: 0,
    scope: "post"
  },
  homePositionZ: {
    title: "Home position Z",
    description: "Z-axis home position.",
    type: "number",
    value: 0,
    scope: "post"
  },
  useConstantSurfaceSpeed: {
    title: "Has constant surface speed mode",
    description: "Specifies that machine has constant surface speed functionality",
    type: "boolean",
    value: true,
    scope: "post"
  },
  useComments: {
    title: "Allow comments",
    description: "Specifies that machine can take program comments",
    type: "boolean",
    value: true,
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

var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"AUXFUN M", decimals:0});

var spatialFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, zeropad:true, trim:false});
var xFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, zeropad:true, trim:false, scale:2}); // diameter mode
var yFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var zFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, zeropad:true, trim:false});
var iFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, zeropad:true, trim:false, scale:2}); // diameter mode
var rFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, zeropad:true, trim:false}); // radius
var feedFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, zeropad:true, trim:false});
var pitchFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, zeropad:true, trim:false});
var extendedPitchFormat = createFormat({decimals:6, forceDecimal:true, zeropad:true, trim:false});
var toolFormat = createFormat({decimals:0, width:2, zeropad:true});
var idFormat = createFormat({decimals:0});
var nFormat = createFormat({decimals:0, width:4, zeropad:true});
var rpmFormat = createFormat({decimals:0});
var sfmFormat = createFormat({decimals:2, forceDecimal:true, zeropad:true, trim:false});
var secFormat = createFormat({decimals:4, forceDecimal:true, zeropad:true, trim:false}); // seconds - range 0.001-99999.999
var milliFormat = createFormat({decimals:0}); // milliseconds // range 1-9999
var taperFormat = createFormat({decimals:1, scale:DEG});
var peckFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, zeropad:true, trim:false});
var integerFormat = createFormat({decimals:0, forceDecimal:false, trim:true});

var xOutput; // xOutput is defined in setDirectionX()
var yOutput = createVariable({prefix:"Y"}, yFormat);
var zOutput = createVariable({onchange:function () {retracted[Z] = false;}, prefix:"Z", force:true}, zFormat);
var feedOutput = createVariable({prefix:"F", force:true}, feedFormat);
var pitchOutput = createVariable({prefix:"F", force:true}, pitchFormat);
var extendedPitchOutput = createVariable({prefix:"L", force:true}, extendedPitchFormat);
var toolOutput = createVariable({prefix:"T", force:true}, toolFormat);
var idOutput = createVariable({prefix:"I", force:true}, idFormat);
var sOutput = createVariable({prefix:"S", force:true}, rpmFormat);
var rangeOutput = createReferenceVariable({}, gFormat);
var peckOutput = createVariable({prefix:"Q", force:true}, peckFormat);

// circular output
var iOutput; // iOutput is defined in setDirectionX()
var jOutput = createVariable({prefix:"YC"}, spatialFormat); // no scaling
var kOutput = createVariable({prefix:"ZC"}, spatialFormat); // no scaling

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91 //
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G98-99 / G94-95
var gSpindleModeModal = createModal({}, gFormat); // modal group 5 // G96-97
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-21
var gCycleModal = createModal({}, gFormat); // modal group 9 // G83, ...
var gRetractModal = createModal({}, gFormat); // modal group 10 //
var mOptionalModal = createModal({}, mFormat);

// fixed settings
var gotSecondarySpindle = false;
var gotTailStock = false;

var WARNING_WORK_OFFSET = 0;

var QCTP = 0;
var TURRET = 1;
var GANG = 2;

var FRONT = -1;
var REAR = 1;

// collected state
var sequenceNumber;
var currentWorkOffset;
var optionalSection = false;
var forceSpindleSpeed = false;
var toolingData;
var previousToolingData;
var retracted = new Array(false, false, false); // specifies that the tool has been retracted to the safe plane
var pathId = 0;

function getCode(code) {
  switch (code) {
  // case "PART_CATCHER_ON":
  // return mFormat.format(SPECIFY YOUR CODE HERE);
  // case "PART_CATCHER_OFF":
  // return mFormat.format(SPECIFY YOUR CODE HERE);
  // case "TAILSTOCK_ON":
  // return mFormat.format(SPECIFY YOUR CODE HERE);
  // case "TAILSTOCK_OFF":
  // return mFormat.format(SPECIFY YOUR CODE HERE);
  // case "ENGAGE_C_AXIS":
  // machineState.cAxisIsEngaged = true;
  // return cAxisEngageModal.format(UNSUPPORTED);
  // case "DISENGAGE_C_AXIS":
  // machineState.cAxisIsEngaged = false;
  // return cAxisEngageModal.format(UNSUPPORTED);
  // case "POLAR_INTERPOLATION_ON":
  // return gPolarModal.format(UNSUPPORTED);
  // case "POLAR_INTERPOLATION_OFF":
  // return gPolarModal.format(UNSUPPORTED);
  // case "STOP_LIVE_TOOL":
  // machineState.liveToolIsActive = false;
  // return mFormat.format(UNSUPPORTED);
  // case "STOP_MAIN_SPINDLE":
  // machineState.mainSpindleIsActive = false;
  // return mFormat.format(UNSUPPORTED);
  // case "STOP_SUB_SPINDLE":
  // machineState.subSpindleIsActive = false;
  // return mFormat.format(UNSUPPORTED);
  // case "START_LIVE_TOOL_CW":
  // machineState.liveToolIsActive = true;
  // return mFormat.format(UNSUPPORTED);
  // case "START_LIVE_TOOL_CCW":
  // machineState.liveToolIsActive = true;
  // return mFormat.format(UNSUPPORTED);
  // case "START_MAIN_SPINDLE_CW":
  //   machineState.mainSpindleIsActive = true;
  //   return mFormat.format(3);
  // case "START_MAIN_SPINDLE_CCW":
  //   machineState.mainSpindleIsActive = true;
  //   return mFormat.format(4);
  // case "START_SUB_SPINDLE_CW":
  // machineState.subSpindleIsActive = true;
  // return mFormat.format(UNSUPPORTED);
  // case "START_SUB_SPINDLE_CCW":
  // machineState.subSpindleIsActive = true;
  // return mFormat.format(UNSUPPORTED);
  // case "MAIN_SPINDLE_BRAKE_ON":
  // machineState.mainSpindleBrakeIsActive = true;
  // return cAxisBrakeModal.format(UNSUPPORTED);
  // case "MAIN_SPINDLE_BRAKE_OFF":
  // machineState.mainSpindleBrakeIsActive = false;
  // return cAxisBrakeModal.format(UNSUPPORTED);
  // case "SUB_SPINDLE_BRAKE_ON":
  // machineState.subSpindleBrakeIsActive = true;
  // return cAxisBrakeModal.format(UNSUPPORTED);
  // case "SUB_SPINDLE_BRAKE_OFF":
  // machineState.subSpindleBrakeIsActive = false;
  // return cAxisBrakeModal.format(UNSUPPORTED);
  // case "FEED_MODE_UNIT_REV":
  //   return ;
  // case "FEED_MODE_UNIT_MIN":
  //   return ;
  // case "CONSTANT_SURFACE_SPEED_ON":
  //   return "SETCSS";
  // case "CONSTANT_SURFACE_SPEED_OFF":
  //   return "SETRPM";
  // case "MAINSPINDLE_AIR_BLAST_ON":
  //   return mFormat.format(UNSUPPORTED);
  // case "MAINSPINDLE_AIR_BLAST_OFF":
  //   return mFormat.format(UNSUPPORTED);
  // case "SUBSPINDLE_AIR_BLAST_ON":
  //   return mFormat.format(UNSUPPORTED);
  // case "SUBSPINDLE_AIR_BLAST_OFF":
  //   return mFormat.format(UNSUPPORTED);
  // case "CLAMP_PRIMARY_CHUCK":
  //   return mFormat.format(UNSUPPORTED);
  // case "UNCLAMP_PRIMARY_CHUCK":
  //   return mFormat.format(UNSUPPORTED);
  // case "CLAMP_SECONDARY_CHUCK":
  //   return mFormat.format(UNSUPPORTED);
  // case "UNCLAMP_SECONDARY_CHUCK":
  //   return mFormat.format(UNSUPPORTED);
  // case "SPINDLE_SYNCHRONIZATION_ON":
  //   machineState.spindleSynchronizationIsActive = true;
  //   return gSynchronizedSpindleModal.format(UNSUPPORTED);
  // case "SPINDLE_SYNCHRONIZATION_OFF":
  //   machineState.spindleSynchronizationIsActive = false;
  //   return gSynchronizedSpindleModal.format(UNSUPPORTED);
  // case "START_CHIP_TRANSPORT":
  //   return mFormat.format(UNSUPPORTED);
  // case "STOP_CHIP_TRANSPORT":
  //   return mFormat.format(UNSUPPORTED);
  // case "OPEN_DOOR":
  //   return mFormat.format(UNSUPPORTED);
  // case "CLOSE_DOOR":
  //   return mFormat.format(UNSUPPORTED);
  default:
    error(localize("Command " + code + " is not defined."));
    return 0;
  }
}

function formatSequenceNumber() {
  if (sequenceNumber > 9999) {
    sequenceNumber = getProperty("sequenceNumberStart");
  }
  var seqno = nFormat.format(sequenceNumber);
  sequenceNumber += getProperty("sequenceNumberIncrement");
  return seqno;
}

/**
  Writes the specified block.
*/
function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }
  var mOptionalOut = mOptionalModal.format(optionalSection ? 88 : 89);
  if (getProperty("showSequenceNumbers")) {
    if (optionalSection) {
      if (mOptionalOut) {
        writeWords2(formatSequenceNumber(), mOptionalOut);
      }
      writeWords2(formatSequenceNumber(), arguments);
    } else {
      if (mOptionalOut) {
        writeWords2(formatSequenceNumber(), mOptionalOut);
      }
      writeWords2(formatSequenceNumber(), arguments);
    }
  } else {
    if (optionalSection) {
      if (mOptionalOut) {
        writeWords(mOptionalOut);
      }
      writeWords(arguments);
    } else {
      if (mOptionalOut) {
        writeWords(mOptionalModal.format(89));
      }
      writeWords(arguments);
    }
  }
}

function formatComment(text) {
  if (!getProperty("useComments")) {
    return "";
  }
  return "(" + filterText(String(text).toUpperCase(), permittedCommentChars).replace(/[()']/g, "") + ")";
}

/**
  Output a comment.
*/
function writeComment(text) {
  if (formatComment(text)) {
    writeln(formatComment(text));
  }
}

function onOpen() {
  if (getProperty("useRadius")) {
    maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
  }
  mOptionalModal.format(89);

  yOutput.disable();
  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");
  writeln("0000 EZPATH|SX 1 MODE|" + ((unit == MM) ? "MM" : "INCH"));

  if (programName) {
    var programId;
    programId = programName;
    if (programComment) {
      writeComment(programId + " " + programComment);
    } else {
      writeComment(programId);
    }
  } else {
    error(localize("Program name has not been specified."));
    return;
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
      writeComment("  " + localize("description") + ": " + description);
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
        var compensationOffset = tool.isTurningTool() ? tool.compensationOffset : tool.lengthOffset;
        var comment = "T" + toolFormat.format(tool.number * 100 + compensationOffset % 100) + " " +
          (tool.diameter != 0 ? "D=" + spatialFormat.format(tool.diameter) + " " : "") +
          (tool.isTurningTool() ? localize("NR") + "=" + spatialFormat.format(tool.noseRadius) : localize("CR") + "=" + spatialFormat.format(tool.cornerRadius)) +
          (tool.taperAngle > 0 && (tool.taperAngle < Math.PI) ? " " + localize("TAPER") + "=" + taperFormat.format(tool.taperAngle) + localize("deg") : "") +
          (zRanges[tool.number] ? " - " + localize("ZMIN") + "=" + spatialFormat.format(zRanges[tool.number].getMinimum()) : "") +
           " - " + localize(getToolTypeName(tool.type));
        writeComment(comment);
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

function forceFeed() {
  feedOutput.reset();
}

/** Force output of X, Y, Z, and F on next output. */
function forceAny() {
  forceXYZ();
  forceFeed();
}

function getFeed(f) {
  var _f = (currentSection.feedMode != FEED_PER_REVOLUTION) ? f / spindleSpeed : f;
  return feedOutput.format(_f); // use feed value
}

function getSpindle() {
  if (getNumberOfSections() == 0) {
    return SPINDLE_PRIMARY;
  }
  if (getCurrentSectionId() < 0) {
    return getSection(getNumberOfSections() - 1).spindle == 0;
  }
  if (currentSection.getType() == TYPE_TURNING) {
    return currentSection.spindle;
  } else {
    if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))) {
      return SPINDLE_PRIMARY;
    } else if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, -1))) {
      if (!gotSecondarySpindle) {
        error(localize("Secondary spindle is not available."));
      }
      return SPINDLE_SECONDARY;
    } else {
      return SPINDLE_PRIMARY;
    }
  }
}

function ToolingData(_tool) {
  switch (_tool.turret) {
  // Positional Turret
  case 0:
    this.tooling = TURRET;
    this.toolPost = REAR;
    break;
  // QCTP X-
  case 101:
    this.tooling = QCTP;
    this.toolPost = FRONT;
    break;
  // QCTP X+
  case 102:
    this.tooling = QCTP;
    this.toolPost = REAR;
    break;
  // Gang Tooling X-
  case 103:
    this.tooling = GANG;
    this.toolPost = FRONT;
    break;
  // Gang Tooling X+
  case 104:
    this.tooling = GANG;
    this.toolPost = REAR;
    break;
  default:
    error(localize("Turret number must be 0 (main turret), 101 (QCTP X-), 102 (QCTP X+, 103 (gang tooling X-), or 104 (gang tooling X+)."));
    break;
  }
  this.number = _tool.number;
  this.comment = _tool.comment;
  this.toolLength = _tool.bodyLength;
  // HSMWorks returns 0 in tool.bodyLength
  if ((tool.bodyLength == 0) && hasParameter("operation:tool_bodyLength")) {
    this.toolLength = getParameter("operation:tool_bodyLength");
  }
}

function setDirectionX() {
  xFormat.setScale(toolingData.toolPost == FRONT ? Math.abs(xFormat.getScale()) * -1 : Math.abs(xFormat.getScale()));
  iFormat.setScale(toolingData.toolPost == FRONT ? Math.abs(iFormat.getScale()) * -1 : Math.abs(iFormat.getScale()));
  xOutput = createVariable({onchange: function() {retracted[X] = false;}, prefix:"X", force:true}, xFormat);
  iOutput = createVariable({prefix:"XC"}, iFormat);
}

function onSection() {
  if (currentSection.getType() != TYPE_TURNING) {
    if (!hasParameter("operation-strategy") || (getParameter("operation-strategy") != "drill")) {
      if (currentSection.getType() == TYPE_MILLING) {
        error(localize("Milling toolpath is not supported."));
      } else {
        error(localize("Non-turning toolpath is not supported."));
      }
      return;
    }
  }

  var forceToolAndRetract = optionalSection && !currentSection.isOptional();
  optionalSection = currentSection.isOptional();

  var turning = (currentSection.getType() == TYPE_TURNING);
  
  var insertToolCall = forceToolAndRetract || isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number) ||
    (tool.compensationOffset != getPreviousSection().getTool().compensationOffset) ||
    (tool.diameterOffset != getPreviousSection().getTool().diameterOffset) ||
    (tool.lengthOffset != getPreviousSection().getTool().lengthOffset);
 
  var newSpindle = isFirstSection() ||
    (getPreviousSection().spindle != currentSection.spindle);
  var newWorkOffset = isFirstSection() ||
    (getPreviousSection().workOffset != currentSection.workOffset); // work offset changes

  // determine which tooling holder is used
  if (!isFirstSection()) {
    previousToolingData = toolingData;
  }
  toolingData = new ToolingData(tool);
  toolingData.operationComment = "";
  if (hasParameter("operation-comment")) {
    toolingData.operationComment = getParameter("operation-comment");
  }
  toolingData.toolChange = insertToolCall;
  if (isFirstSection()) {
    previousToolingData = toolingData;
  }

  setDirectionX();

  if (insertToolCall || newSpindle || newWorkOffset) {
    if (!isFirstSection() && insertToolCall) {
      onCommand(COMMAND_COOLANT_OFF);
      writeRetract();
    }
      
    forceXYZ();
  }

  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment(comment);
    }
  }
  
  if (getProperty("showNotes") && hasParameter("notes")) {
    var notes = getParameter("notes");
    if (notes) {
      var lines = String(notes).split("\n");
      var r1 = new RegExp("^[\\s]+", "g");
      var r2 = new RegExp("[\\s]+$", "g");
      for (var line in lines) {
        var comment = lines[line].replace(r1, "").replace(r2, "");
        if (comment) {
          writeComment(comment);
        }
      }
    }
  }

  var compensationOffset = tool.isTurningTool() ? tool.compensationOffset : tool.lengthOffset;
  if (compensationOffset > 99) {
    error(localize("Compensation offset is out of range."));
    return;
  }
  
  if (insertToolCall) {
    onCommand(COMMAND_COOLANT_OFF);
  
    if (!isFirstSection() && getProperty("optionalStop")) {
      onCommand(COMMAND_OPTIONAL_STOP);
    }

    if (tool.number > 99) {
      warning(localize("Tool number exceeds maximum value."));
    }

    var comment = formatComment(localize("CHANGE TO T") + tool.number + " " + localize("ON") + " " +
        localize((toolingData.toolPost == REAR) ? "REAR TOOL POST" : "FRONT TOOL POST"));

    var toolId = parseInt(tool.comment, 10);
    if (isNaN(toolId)) {
      toolId = tool.number;
      writeBlock("TLCHG", idOutput.format(toolId), toolOutput.format(tool.number), toolFormat.format(compensationOffset));
      writeComment(localize("Using tool number as id. Use tool comment for id if needed."));
      if (tool.comment) {
        writeComment(tool.comment);
      }
    } else {
      writeBlock("TLCHG", idOutput.format(toolId), toolOutput.format(tool.number), toolFormat.format(compensationOffset));
    }

  }

  forceAny();
  gMotionModal.reset();
  
  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  startSpindle(false, true, initialPosition);
  
  setRotation(currentSection.workPlane);

  if (insertToolCall) {
    writeBlock("RAPID ABS", xOutput.format(initialPosition.x), zOutput.format(initialPosition.z));
  }
  
  // set coolant
  setCoolant(tool.coolant);

}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  var _seconds = clamp(0.001, seconds, 99999.999);
  writeBlock("DWELL", "S" + secFormat.format(_seconds));
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

function areXZSame(x, z) {
  return (xFormat.getResultingValue(x) == xFormat.getResultingValue(xOutput.getCurrent())) &&
    (zFormat.getResultingValue(z) == zFormat.getResultingValue(zOutput.getCurrent()));
}

function onRapid(_x, _y, _z) {
  if (areXZSame(_x, _z)) {
    return;
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      error(localize("Radius compensation is not supported."));
      pendingRadiusCompensation = -1;
    } else {
      writeBlock("RAPID ABS", x, y, z);
    }
    forceFeed();
  }
}

var resetFeed = false;

function onLinear(_x, _y, _z, feed) {
  if (areXZSame(_x, _z)) {
    return;
  }
  if (isSpeedFeedSynchronizationActive()) {
    error(localize("Speed/feed synchronization is not supported."));
    return;
  }
  if (resetFeed) {
    resetFeed = false;
    forceFeed();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = getFeed(feed);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      error(localize("Radius compensation is not supported."));
      pendingRadiusCompensation = -1;
    } else {
      writeBlock("LINEAR ABS", x, y, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock("LINEAR ABS", f);
    }
  }
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  if (isSpeedFeedSynchronizationActive()) {
    error(localize("Speed-feed synchronization is not supported for circular moves."));
    return;
  }
  
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }

  var start = getCurrentPosition();
  var directionCode = (toolingData.toolPost == REAR) ? (clockwise ? "CW" : "CCW") : (clockwise ? "CCW" : "CW");

  if (isFullCircle()) {
    if (getProperty("useRadius") || isHelical()) { // radius mode does not support full arcs
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock("ARC|CNTRPT ABS", directionCode, xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx), jOutput.format(cy), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock("ARC|CNTRPT ABS", directionCode, xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx), kOutput.format(cz), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock("ARC|CNTRPT ABS", directionCode, xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy), kOutput.format(cz), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else if (!getProperty("useRadius")) {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock("ARC|CNTRPT ABS", directionCode, xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx), jOutput.format(cy), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock("ARC|CNTRPT ABS", directionCode, xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx), kOutput.format(cz), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock("ARC|CNTRPT ABS", directionCode, xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy), kOutput.format(cz), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else { // use radius mode
    var r = getCircularRadius();
    if (toDeg(getCircularSweep()) > (180 + 1e-9)) {
      r = -r; // allow up to <360 deg arcs
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock("ARC|RADIUS ABS", directionCode, xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock("ARC|RADIUS ABS", directionCode, xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock("ARC|RADIUS ABS", directionCode, xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

function onCycle() {
}

// calculates start and end of stock at top of part for threading operations
var saveShowSequenceNumbers = true;
var pathBlockNumber = {start: 0, end: 0};

function onCyclePath() {
  saveShowSequenceNumbers = getProperty("showSequenceNumbers");

  // buffer all paths and stop feeds being output
  setProperty("showSequenceNumbers", false);
  redirectToBuffer();
  if ((hasParameter("operation:grooving") && getParameter("operation:grooving").toUpperCase() != "OFF")) {
    forceXYZ();
  }
}

function onCyclePathEnd() {
  setProperty("showSequenceNumbers", saveShowSequenceNumbers); // reset property to initial state
  feedOutput.enable();
  var cyclePath = String(getRedirectionBuffer()).split(EOL); // get cycle path from buffer
  closeRedirection();
  for (var line in cyclePath) { // remove empty elements
    if (cyclePath[line] == "") {
      cyclePath.splice(line);
    }
  }

  var verticalPasses;
  if (cycle.profileRoughingCycle == 0) {
    verticalPasses = false;
  } else if (cycle.profileRoughingCycle == 1) {
    verticalPasses = true;
  } else {
    error(localize("Unsupported passes type."));
    return;
  }
  var inside = hasParameter("operation:machineInside") && getParameter("operation:machineInside") == 1;
  // output cycle data
  switch (cycleType) {
  case "turning-canned-rough":
    var f = (currentSection.feedMode != FEED_PER_REVOLUTION) ? cycle.cutfeedrate / spindleSpeed : cycle.cutfeedrate;
    pathId++;
    writeBlock(
      "ROUGH",
      rpmFormat.format(pathId),
      verticalPasses ? "3" : inside ? "2" : "1",
      xOutput.format(cycle.xStockToLeave),
      zOutput.format(cycle.zStockToLeave),
      "F" + spatialFormat.format(f),
      spatialFormat.format(f),
      spatialFormat.format(f),
      "S" + spatialFormat.format(cycle.depthOfCut),
      "C" + spatialFormat.format(cycle.clearance),
      "W" + spatialFormat.format(45),
      "W" + spatialFormat.format(cycle.retractLength),
      "D2", // negative cutting direction
      "U2", // undercut check off
      "A2" // autoround off
    );
    break;
  default:
    error(localize("Unsupported turning canned cycle."));
  }
  
  writeBlock("STARTPATH", integerFormat.format(pathId));
  for (var i = 0; i < cyclePath.length; ++i) {
    writeBlock(cyclePath[i]); // output cycle path
    setProperty("showSequenceNumbers", saveShowSequenceNumbers); // reset property to initial state
  }
  writeBlock("PATHSTOP");
}

function getCommonCycle(s, d, r) {
  // forceXYZ(); // force xyz on first drill hole of any cycle
  return [zOutput.format(s),
    "D" + spatialFormat.format(d),
    "C" + spatialFormat.format(r - s)];
}

function getThreadStockPoints(x, y, z) {
  // check for parameters
  if (!hasParameter("operation:threadDepth") ||
      !hasParameter("operation:stockOffsetBack") ||
      !hasParameter("operation:stockOffsetFront")) {
    error(localize("Mandatory cycle property not defined."));
    return undefined;
  }

  // calculate axial and radial offset directions
  var axialOffset = new Vector(-cycle.incrementalX, 0, -cycle.incrementalZ);
  var axialDirection = axialOffset.getNormalized();
  var radialDirection = new Vector(1, 0, 0);

  // get required parameters
  var threadHeight = getParameter("operation:threadDepth");
  var backOffset = getParameter("operation:stockOffsetBack") / axialDirection.z;
  var frontOffset = getParameter("operation:stockOffsetFront") / axialDirection.z;
  var lengthOfCut = (axialOffset.length - (backOffset + frontOffset));

  // final position at depth of threading moves
  var endPoint = new Vector(x, y, z);

  // calculate top of stock points
  var stockEnd = Vector.sum(endPoint, Vector.product(axialDirection, backOffset));
  var stockPoint = {};
  stockPoint.second = Vector.sum(stockEnd, Vector.product(radialDirection, threadHeight));
  stockPoint.first = Vector.sum(stockPoint.second, Vector.product(axialDirection, lengthOfCut));
  return stockPoint;
}

function onCyclePoint(x, y, z) {
  if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1)) ||
      isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, -1))) {
    // check direction
  } else {
    expandCyclePoint(x, y, z);
    return;
  }

  switch (cycleType) {
  case "thread-turning":
    if (isLastCyclePoint()) {
      // get infeed type
      var threadInfeedMode = "constant";
      if (hasParameter("operation:infeedMode")) {
        threadInfeedMode = getParameter("operation:infeedMode");
      }
      if (threadInfeedMode == "alternate") {
        error(localize("Alternate infeed type not supported in canned cycle."));
        return;
      }

      // thread height and depth of cut
      var threadHeight = getParameter("operation:threadDepth");
      var firstDepthOfCut = threadHeight - Math.abs(getCyclePoint(0).x - x);
      var secondDepthOfCut = threadInfeedMode == "constant" ? firstDepthOfCut : (getNumberOfCyclePoints() > 1 ? Math.abs(getCyclePoint(0).x - getCyclePoint(1).x) : firstDepthOfCut);
      var minimumDepthOfCut = getNumberOfCyclePoints() > 1 ? Math.abs(x - getCurrentPosition().x) : firstDepthOfCut;
      var repeatPass = hasParameter("operation:nullPass") ? getParameter("operation:nullPass") : 0;
      var id = hasParameter("operation:machineInside") && getParameter("operation:machineInside") == 1;
      var threadClearance = Math.abs(cycle.clearance - (id ? Math.min(x, x - cycle.incrementalX) - threadHeight : Math.max(x, x - cycle.incrementalX) + threadHeight));
      var cuttingAngle = 29; // Angle is not stored with tool. toDeg(tool.getTaperAngle());
      if (hasParameter("operation:infeedAngle")) {
        cuttingAngle = getParameter("operation:infeedAngle");
      }

      // start and end of thread on physical part
      var stockPoints = getThreadStockPoints(x, y, z);

      zOutput.reset();
      writeBlock(
        "THREAD",
        id ? "2" : "1",
        extendedPitchOutput.format(cycle.pitch),
        "H" + spatialFormat.format(threadHeight),
        "S" + spatialFormat.format(firstDepthOfCut),
        spatialFormat.format(threadInfeedMode == "constant" ? firstDepthOfCut : secondDepthOfCut),
        spatialFormat.format(threadInfeedMode == "constant" ? firstDepthOfCut : minimumDepthOfCut),
        "#" + integerFormat.format(repeatPass),
        "C" + spatialFormat.format(threadClearance),
        zOutput.format(z - cycle.incrementalZ),
        spatialFormat.format(z),
        "D" + xFormat.format(stockPoints.first.x),
        xFormat.format(stockPoints.second.x),
        spatialFormat.format(cuttingAngle)
      );
      forceFeed();
    }
    return;
  case "tapping":
  case "left-tapping":
  case "right-tapping":
    repositionToCycleClearance(cycle, x, y, z);
    var P = !cycle.dwell ? 0 : clamp(0.001, cycle.dwell, 99999.999); // in seconds
    writeBlock(
      "TAP",
      getCommonCycle(cycle.stock, cycle.depth, cycle.retract),
      conditional(P > 0, "T" + secFormat.format(P)),
      pitchOutput.format(tool.getThreadPitch())
    );
    return;
  }

  if (!getProperty("useCycles")) {
    expandCyclePoint(x, y, z);
    return;
  }

  if (isFirstCyclePoint()) {
    repositionToCycleClearance(cycle, x, y, z);

    var F = cycle.feedrate;
    var P = !cycle.dwell ? 0 : clamp(0.001, cycle.dwell, 99999.999); // in seconds

    switch (cycleType) {
    case "drilling":
      writeBlock(
        "DRILL",
        zOutput.format(cycle.stock),
        "D" + spatialFormat.format(cycle.depth),
        "T" + spatialFormat.format(0),
        "C" + spatialFormat.format(cycle.retract - cycle.stock),
        feedOutput.format(F)
      );
      break;
    case "counter-boring":
      if (P > 0) {
        expandCyclePoint(x, y, z);
      } else {
        writeBlock(
          "DRILL",
          getCommonCycle(cycle.stock, cycle.depth, cycle.retract),
          "T" + spatialFormat.format(0),
          feedOutput.format(F)
        );
      }
      break;
    case "deep-drilling":
      if (P > 0) {
        expandCyclePoint(x, y, z);
      } else {
        writeBlock(
          "DRILL",
          getCommonCycle(cycle.stock, cycle.depth, cycle.retract),
          "T" + spatialFormat.format(cycle.incrementalDepth),
          spatialFormat.format(cycle.incrementalDepth),
          feedOutput.format(F)
        );
      }
      break;

    default:
      expandCyclePoint(x, y, z);
    }
  } else {
    if (cycleExpanded) {
      expandCyclePoint(x, y, z);
    } else {
      var _x = xOutput.format(x);
      var _y = yOutput.format(y);
      var _z = zOutput.format(z);
      if (!_x && !_y && !_z) {
        switch (gPlaneModal.getCurrent()) {
        case 17: // XY
          xOutput.reset(); // at least one axis is required
          _x = xOutput.format(x);
          break;
        case 18: // ZX
          zOutput.reset(); // at least one axis is required
          _z = zOutput.format(z);
          break;
        case 19: // YZ
          yOutput.reset(); // at least one axis is required
          _y = yOutput.format(y);
          break;
        }
      }
      writeBlock(_x, _y, _z);
    }
  }
}

function onCycleEnd() {
  if (!cycleExpanded) {
    switch (cycleType) {
    case "thread-turning":
      forceFeed();
      xOutput.reset();
      zOutput.reset();
      break;
    default:
    }
  }
}

var currentCoolantMode = COOLANT_OFF;
var coolantOff = undefined;

function setCoolant(coolant) {
  // cancel coolant if necessary
  if ((coolant != COOLANT_OFF) && (currentCoolantMode != COOLANT_OFF) && (coolant != currentCoolantMode)) {
    setCoolant(COOLANT_OFF);
  }
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
  if ((getProperty("useCoolant") != undefined) && !getProperty("useCoolant")) {
    return undefined;
  }
  if (!coolants) {
    error(localize("Coolants have not been defined."));
  }
  if (isProbeOperation()) { // avoid coolant output for probing
    coolant = COOLANT_OFF;
  }
  if (coolant == currentCoolantMode) {
    return undefined; // coolant is already active
  }

  var multipleCoolantBlocks = new Array(); // create a formatted array to be passed into the output line
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

function onSpindleSpeed(spindleSpeed) {
  if (rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) {
    writeBlock("SETRPM", sOutput.format(spindleSpeed));
  }
}

function startSpindle(tappingMode, forceRPMMode, initialPosition) {
  var spindleDir;
  var _spindleSpeed;
  var spindleMode;
  var maxSpeed = "";

  var maximumSpindleSpeed = (tool.maximumSpindleSpeed > 0) ? Math.min(tool.maximumSpindleSpeed, getProperty("maximumSpindleSpeed")) : getProperty("maximumSpindleSpeed");
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    if (!getProperty("useConstantSurfaceSpeed")) {
      error(localize("Constant surface speed is not supported."));
      return;
    }
    _spindleSpeed = tool.surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0);
    writeBlock("SETCSS", rangeOutput.format(getSpindleRange(maximumSpindleSpeed), 0), "C" + sfmFormat.format(_spindleSpeed), sOutput.format(maximumSpindleSpeed));
  
  } else {
    writeBlock("SETRPM", rangeOutput.format(getSpindleRange(spindleSpeed), 0), sOutput.format(spindleSpeed));
  }
}

function getSpindleRange(_spindleSpeed) {
  var speed = rpmFormat.getResultingValue(_spindleSpeed);
  if (getProperty("spindleRangeLow") == 0) {
    return 0;
  } else if (speed <= getProperty("spindleRangeLow")) {
    return 1;
  } else if (speed <= getProperty("spindleRangeHigh") || getProperty("spindleRangeHigh") == 0) {
    return 2;
  } else {
    return 3;
  }
}

function onCommand(command) {
  switch (command) {
  case COMMAND_COOLANT_OFF:
    setCoolant(COOLANT_OFF);
    break;
  case COMMAND_COOLANT_ON:
    setCoolant(COOLANT_FLOOD);
    break;
  case COMMAND_LOCK_MULTI_AXIS:
    break;
  case COMMAND_UNLOCK_MULTI_AXIS:
    break;
  case COMMAND_START_CHIP_TRANSPORT:
    // getCode("START_CHIP_TRANSPORT");
    break;
  case COMMAND_STOP_CHIP_TRANSPORT:
    // getCode("STOP_CHIP_TRANSPORT");
    break;
  case COMMAND_BREAK_CONTROL:
    break;
  case COMMAND_TOOL_MEASURE:
    break;
  case COMMAND_ACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    break;
  case COMMAND_DEACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    break;
  case COMMAND_STOP:
    writeBlock(mFormat.format(0));
    forceSpindleSpeed = true;
    break;
  case COMMAND_OPTIONAL_STOP:
    writeBlock(mFormat.format(1));
    break;
  case COMMAND_END:
    writeBlock(mFormat.format(2));
    break;
  // case COMMAND_SPINDLE_CLOCKWISE:
  //   switch (currentSection.spindle) {
  //   case SPINDLE_PRIMARY:
  //     break;
  //   case SPINDLE_SECONDARY:
  //     break;
  //   }
  //   break;
  // case COMMAND_SPINDLE_COUNTERCLOCKWISE:
  //   switch (currentSection.spindle) {
  //   case SPINDLE_PRIMARY:
  //     break;
  //   case SPINDLE_SECONDARY:
  //     break;
  //   }
  //   break;
  // case COMMAND_START_SPINDLE:
  //   onCommand(tool.clockwise ? COMMAND_SPINDLE_CLOCKWISE : COMMAND_SPINDLE_COUNTERCLOCKWISE);
  //   return;
  case COMMAND_STOP_SPINDLE:
    switch (currentSection.spindle) {
    case SPINDLE_PRIMARY:
      writeBlock(mFormat.format(5));
      break;
    case SPINDLE_SECONDARY:
      break;
    }
    break;
  // case COMMAND_ORIENTATE_SPINDLE:
  //   if (getSpindle() == 0) {
  //   } else {
  //   }
  //   break;
  //case COMMAND_CLAMP: // TAG: add support for clamping
  //case COMMAND_UNCLAMP: // TAG: add support for clamping
  default:
    onUnsupportedCommand(command);
  }
}

function engagePartCatcher(engage) {
  if (engage) {
    // catch part here
    writeBlock(getCode("PART_CATCHER_ON"), formatComment(localize("PART CATCHER ON")));
  } else {
    onCommand(COMMAND_COOLANT_OFF);
    writeRetract();
    writeBlock(getCode("PART_CATCHER_OFF"), formatComment(localize("PART CATCHER OFF")));
    forceXYZ();
  }
}

function onSectionEnd() {

  if (currentSection.partCatcher) {
    engagePartCatcher(false);
  }

  // forceAny();
}

/** Output block to do safe retract and/or move to home position. */
function writeRetract() {
  var words = []; // store all retracted axes in an array
  var singleLineRetract = false;
  var retractAxes = []; // axes to retract
  var method = getProperty("safePositionMethod");

  // define home positions
  var _xHome;
  var _yHome;
  var _zHome;
  if (method == "clearanceHeight") {
    return;
  }
  _xHome = getProperty("homePositionX");
  _zHome = getProperty("homePositionZ");

  if (arguments.length > 0) {
    for (var i in arguments) {
      retractAxes.push(arguments[i]);
    }
  } else {
    switch (getProperty("safePositionStyle")) {
    case "X":
      retractAxes.push(X);
      break;
    case "Z":
      retractAxes.push(Z);
      break;
    case "XZ":
      retractAxes.push(X, Z);
      break;
    case "ZX":
      retractAxes.push(Z, X);
      break;
    case "singleLineXZ":
      singleLineRetract = true;
      retractAxes.push(X, Z);
      break;
    }
  }

  for (var i = 0; i < retractAxes.length; ++i) {
    switch (retractAxes[i]) {
    case X:
      setCurrentPositionX(_xHome);
      var out = xOutput.format(_xHome) + (!singleLineRetract ? getWordSeparator() + zOutput.format(getCurrentPosition().z) : "");
      words.push(out);
      retracted[X] = true;
      xOutput.reset();
      break;
    case Y:
      if (yOutput.isEnabled()) {
        var yOut = retractAxes.indexOf(Y) !== -1 ? _yHome : getCurrentPosition().y;
        words.push(yOutput.format(_yHome));
        yOutput.reset();
      }
      break;
    case Z:
      setCurrentPositionZ(_zHome);
      var out = (!singleLineRetract ? xOutput.format(getCurrentPosition().x) + getWordSeparator() : "") + zOutput.format(_zHome);
      words.push(out);
      retracted[Z] = true;
      zOutput.reset();
      break;
    default:
      error(localize("Unsupported axis specified for writeRetract()."));
      return;
    }
  }

  for (var i = 0; i < words.length; ++i) {
    writeBlock(conditional((singleLineRetract ? words : words[i]) != "", "RAPID ABS"), singleLineRetract ? words : words[i]);
    if (singleLineRetract) {
      break;
    }
  }
  singleLineRetract = false; // singleLineRetract reset
}

function onClose() {

  optionalSection = false;

  onCommand(COMMAND_COOLANT_OFF);
  
  onCommand(COMMAND_STOP_CHIP_TRANSPORT);

  forceXYZ();
  writeRetract();

  onImpliedCommand(COMMAND_END);
  onImpliedCommand(COMMAND_STOP_SPINDLE);
  writeBlock(mFormat.format(2)); // stop program, spindle stop, coolant off
}

function setProperty(property, value) {
  properties[property].current = value;
}
