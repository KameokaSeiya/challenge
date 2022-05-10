/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  OmniTurn Lathe post processor configuration.

  $Revision: 43214 98a796e814937a743ede7ca7e9131f7777db96a2 $
  $Date: 2021-04-13 21:49:26 $

  FORKID {C3C43C67-0960-4EC8-8F62-D39EB1E7B31D}
*/

description = "OmniTurn Turning";
vendor = "OmniTurn";
vendorUrl = "http://www.omniturn.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic turning post for OmniTurn. Use Turret 0 for Positional Turret, Turret 101 for QCTP on X- Post, Turret 102 for QCTP on X+ Post, Turret 103 for Gang Tooling on X- Post, Turret 104 for Gang Tooling on X+ Tool Post.";
extension = "nc";
programNameIsInteger = true;
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
highFeedRate = (unit == MM) ? 7600 : 300;

// user-defined properties
properties = {
  writeMachine: {
    title: "Write machine",
    description: "Output the machine settings in the header of the code.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  writeTools: {
    title: "Write tool list",
    description: "Output a tool list in the header of the code.",
    type: "boolean",
    value: false,
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
  useRadius: {
    title: "Radius arcs",
    description: "If yes is selected, arcs are outputted using radius values rather than IJK.",
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
  minimumSpindleSpeed: {
    title: "Min spindle speed",
    description: "Defines the minimum spindle speed for constant surface speed.",
    type: "integer",
    range: [0, 999999999],
    value: 50,
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
  autoEject: {
    title: "Auto eject",
    description: "Specifies whether the part should automatically eject at the end of a program.  'Slow' will perform a slow eject using M59.",
    type: "enum",
    values: [
      {title: "Yes", id: "true"},
      {title: "Slow", id: "slow"},
      {title: "Yes with unloader", id: "trueUnload"},
      {title: "Slow with unloader", id: "slowUnload"},
      {title: "No", id: "false"}
    ],
    group: 3,
    value: "false",
    scope: "post"
  },
  useZipLoader: {
    title: "Part/Bar loader",
    description: "Specifies type of part loader to use.",
    type: "enum",
    values: [
      {title: "Bar", id: "bar"},
      {title: "Part", id: "part"},
      {title: "Stop", id: "stop"},
      {title: "2part", id: "2part"},
      {title: "None", id: "none"}
    ],
    group: 3,
    value: "none",
    scope: "post"
  },
  stopTool: {
    title: "Stop tool",
    description: "Tool number for bar/part stop.",
    group: 3,
    type: "integer",
    value: 1,
    scope: "post"
  },
  unloaderTool: {
    title: "Unloader tool",
    description: "Tool number for unloader.",
    group: 3,
    type: "integer",
    value: 15,
    scope: "post"
  },
  homePositionX: {
    title: "Home position X",
    description: "X-axis home position.",
    group: 0,
    type: "number",
    value: 0,
    scope: "post"
  },
  homePositionZ: {
    title: "Home position Z",
    description: "Z-axis home position.",
    group: 0,
    type: "number",
    value: 0,
    scope: "post"
  },
  useWorkShift: {
    title: "G10 work shift",
    description: "Outputs G10 for work shift. Use 'Work shift X' and 'Work shift Z' to specify values.",
    group: 4,
    type: "boolean",
    value: false,
    scope: "post"
  },
  workShiftX: {
    title: "Work shift X",
    description: "Work shift X value for G10.",
    group: 4,
    type: "number",
    value: 0,
    scope: "post"
  },
  workShiftZ: {
    title: "Work shift Z",
    description: "Work shift Z value for G10.",
    group: 4,
    type: "number",
    value: 0,
    scope: "post"
  },
  useSimpleThread: {
    title: "Use simple threading cycle",
    description: "Enable to output multiple threading passes, disable to output single threading cycle.",
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

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

var gFormat = createFormat({prefix:"G", width:2, zeropad:true});
var mFormat = createFormat({prefix:"M", width:2, zeropad:true});

var spatialFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var xFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, scale:2}); // diameter mode
var yFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var zFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var rFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true}); // radius
var uprFormat = createFormat({decimals:(unit == MM ? 4 : 5), forceDecimal:true});
var upmFormat = createFormat({decimals:(unit == MM ? 0 : 1), forceDecimal:true});
var feedFormat = createFormat({decimals:(unit == MM ? 4 : 5), forceDecimal:true});
var iFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal: true, scale: 1});
var pitchFormat = createFormat({decimals:6, forceDecimal:true});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-99999.999
var milliFormat = createFormat({decimals:0}); // milliseconds // range 1-9999
var taperFormat = createFormat({decimals:1, scale:DEG});
var threadP1Format = createFormat({decimals:0, forceDecimal:false, trim:false, width:6, zeropad:true});
var threadPQFormat = createFormat({decimals:0, forceDecimal:false, trim:true, scale:(unit == MM ? 1000 : 10000)});
var peckFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var integerFormat = createFormat({decimals:0, forceDecimal:false, trim:true});

var xOutput = createVariable({onchange: function() {retracted[X] = false;}, prefix:"X"}, xFormat); // xOutput needs to be defined here it is called sooner in this post
var yOutput = createVariable({prefix:"Y"}, yFormat);
var zOutput = createVariable({onchange:function () {retracted[Z] = false;}, prefix:"Z"}, zFormat);
var dOutput = createVariable({prefix:"D"}, toolFormat);

var feedOutput = createVariable({prefix:"F"}, feedFormat);
var pitchOutput = createVariable({prefix:"F", force:true}, pitchFormat);
var sOutput = createVariable({prefix:"S", force:true}, rpmFormat);

// circular output
var kOutput = createReferenceVariable({prefix:"K", force:true}, spatialFormat);
var iOutput; // iOutput is defined in setDirectionX()
var threadIOutput = createVariable({prefix:"I", force:true}, spatialFormat);
var peckOutput = createVariable({prefix:"K", force:true}, peckFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G93,91
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G98-99 / G94-95
var gSpindleModeModal = createModal({}, gFormat); // modal group 5 // G96-97
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-21
var gCycleModal = createModal({}, gFormat); // modal group 9 // G81, ...
var gRetractModal = createModal({}, gFormat); // modal group 10 // G38-39

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
var cutOffWidth = 0;
var workpiece;

function getCode(code) {
  switch (code) {
  case "PART_CATCHER_ON":
    return mFormat.format(25);
  case "PART_CATCHER_OFF":
    return mFormat.format(26);
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
  case "START_MAIN_SPINDLE_CW":
    // machineState.mainSpindleIsActive = true;
    return mFormat.format(3);
  case "START_MAIN_SPINDLE_CCW":
    // machineState.mainSpindleIsActive = true;
    return mFormat.format(4);
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
  case "FEED_MODE_UNIT_REV":
    return gFeedModeModal.format(95);
  case "FEED_MODE_UNIT_MIN":
    return gFeedModeModal.format(94);
  case "CONSTANT_SURFACE_SPEED_ON":
    return gSpindleModeModal.format(96);
  case "CONSTANT_SURFACE_SPEED_OFF":
    return gSpindleModeModal.format(97);
  // case "MAINSPINDLE_AIR_BLAST_ON":
    // return mFormat.format(UNSUPPORTED);
  // case "MAINSPINDLE_AIR_BLAST_OFF":
    // return mFormat.format(UNSUPPORTED);
  // case "SUBSPINDLE_AIR_BLAST_ON":
    // return mFormat.format(UNSUPPORTED);
  // case "SUBSPINDLE_AIR_BLAST_OFF":
    // return mFormat.format(UNSUPPORTED);
  // case "CLAMP_PRIMARY_CHUCK":
    // return mFormat.format(UNSUPPORTED);
  // case "UNCLAMP_PRIMARY_CHUCK":
    // return mFormat.format(UNSUPPORTED);
  // case "CLAMP_SECONDARY_CHUCK":
    // return mFormat.format(UNSUPPORTED);
  // case "UNCLAMP_SECONDARY_CHUCK":
    // return mFormat.format(UNSUPPORTED);
  // case "SPINDLE_SYNCHRONIZATION_ON":
    // machineState.spindleSynchronizationIsActive = true;
    // return gSynchronizedSpindleModal.format(UNSUPPORTED);
  // case "SPINDLE_SYNCHRONIZATION_OFF":
    // machineState.spindleSynchronizationIsActive = false;
    // return gSynchronizedSpindleModal.format(UNSUPPORTED);
  // case "START_CHIP_TRANSPORT":
    // return mFormat.format(UNSUPPORTED);
  // case "STOP_CHIP_TRANSPORT":
    // return mFormat.format(UNSUPPORTED);
  // case "OPEN_DOOR":
    // return mFormat.format(UNSUPPORTED);
  // case "CLOSE_DOOR":
    // return mFormat.format(UNSUPPORTED);
  default:
    error(localize("Command " + code + " is not defined."));
    return 0;
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
  if (optionalSection) {
    writeWords2("/", arguments);
  } else {
    writeWords(arguments);
  }
}

function formatComment(text) {
  return "(" + filterText(String(text).toUpperCase(), permittedCommentChars).replace(/[()]/g, "") + ")";
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeBlock(gFormat.format(0), formatComment(text));
}

function onOpen() {
  workpiece = getWorkpiece();

  if (getProperty("useRadius")) {
    maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
  }

  yOutput.disable();
  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  var programId;
  if (programName) {
    programId = programName;
    if (programComment) {
      programId += " " + programComment;
    }
  }

  writeBlock(
    gFormat.format(90),
    gFormat.format(72), // diameter
    gUnitModal.format(unit == MM ? 71 : 70),
    formatFeedMode(FEED_PER_MINUTE),
    feedOutput.format(highFeedRate),
    formatComment(programId)
  );

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

  if (getProperty("useWorkShift")) {
    writeBlock(gFormat.format(10), "X" + xFormat.format(getProperty("workShiftX")), "Z" + zFormat.format(getProperty("workShiftZ")));
    forceXYZ();
  }

  if (getProperty("useZipLoader") != "none") {
    writeComment("START OF PART LOAD");
    var excessMain = workpiece.upper.z;
    switch (getProperty("useZipLoader")) {
    case "bar":
      // find cutoff process
      for (var i = 0; i < numberOfSections; ++i) {
        var section = getSection(i);
        //Cutoff process;
        if ((section.hasParameter("operation-strategy") && section.getParameter("operation-strategy") == "turningPart")  ||
            (section.hasParameter("operation-comment") && section.getParameter("operation-comment").toLowerCase() == "cutoff")) {
          cutOffWidth = (section.getTool().grooveWidth);
        }
      }
      writeBlock(mFormat.format(50), formatComment("bar mode"));
      writeBlock("T" + toolFormat.format(getProperty("stopTool")));
      writeBlock(xOutput.format(0), zOutput.format(workpiece.lower.z - cutOffWidth));
      writeBlock(mFormat.format(11), formatComment("open collet and feed"));
      writeBlock(zOutput.format(excessMain), "F" + upmFormat.format(unit == MM ? 500 : 20), formatComment("feed out slowly"));
      writeBlock(mFormat.format(97), "I" + integerFormat.format(10), "C" + integerFormat.format(1), "P" + integerFormat.format(1));
      onDwell(0.1);
      writeBlock(mFormat.format(10), formatComment("close collet"));
      writeBlock(mFormat.format(97) + "I10C1P1");
      writeBlock(mFormat.format(43), formatComment("retract pusher"));
      break;
    case "part":
      writeBlock(mFormat.format(51), formatComment("part mode"));
      writeBlock("T" + toolFormat.format(getProperty("stopTool")));
      writeBlock(xOutput.format(0), zOutput.format(excessMain));
      writeBlock(mFormat.format(47), formatComment("load new part"));
      writeBlock(mFormat.format(43), formatComment("retract pusher"));
      break;
    case "stop":
      writeBlock(mFormat.format(52), formatComment("stop mode"));
      writeBlock("T" + toolFormat.format(getProperty("stopTool")));
      writeBlock(xOutput.format(0), zOutput.format(excessMain));
      writeBlock(mFormat.format(47), formatComment("load new part"));
      writeBlock(mFormat.format(43), formatComment("retract pusher"));
      break;
    case "2part":
      writeBlock(mFormat.format(53), formatComment("2part mode"));
      writeBlock("T" + toolFormat.format(getProperty("stopTool")));
      writeBlock(xOutput.format(0), zOutput.format(excessMain));
      writeBlock(mFormat.format(47), formatComment("load new part"));
      writeBlock(mFormat.format(43), formatComment("retract pusher"));
      break;
    }
    // if autoEject is not turned on then turn it on.
    if (getProperty("autoEject") == "false") {
      setProperty("autoEject", "true");
    }
    writeComment("END OF PART LOAD");
  }
  onCommand(COMMAND_START_CHIP_TRANSPORT);
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
  currentFeedId = undefined;
  feedOutput.reset();
}

/** Force output of X, Y, Z, and F on next output. */
function forceAny() {
  forceXYZ();
  forceFeed();
}

function getFirstFeed(section) {
  var f;
  var feedPerRev = section.feedMode == FEED_PER_REVOLUTION;
  if (hasParameter("operation:tool_feedEntry")) {
    f =  feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry");
  } else if (hasParameter("operation:tool_feedCutting")) {
    f = feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting");
  }
  return f;
}

function formatFeedMode(mode) {
  var fMode = (mode == FEED_PER_REVOLUTION) ? getCode("FEED_MODE_UNIT_REV") : getCode("FEED_MODE_UNIT_MIN");
  if (fMode) {
    if (mode == FEED_PER_REVOLUTION) {
      feedFormat = createFormat({inherit:uprFormat});
      feedOutput = createVariable({prefix:"F"}, feedFormat);
    } else {
      feedFormat = createFormat({inherit:upmFormat});
      feedOutput = createVariable({prefix:"F"}, feedFormat);
    }
  }
  return fMode;
}

function getFeed(f) {
  return feedOutput.format(f); // use feed value
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
  xOutput = createVariable({onchange: function() {retracted[X] = false;}, prefix:"X"}, xFormat);
  iOutput = createReferenceVariable({prefix:"I", force:true}, iFormat);
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
      forceXYZ();
    }
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

  gFeedModeModal.reset();
  feedOutput.reset();
  writeBlock(formatFeedMode(currentSection.feedMode), feedOutput.format(getFirstFeed(currentSection)));

  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  
  if (insertToolCall) {
    // onCommand(COMMAND_COOLANT_OFF);
  
    if (!isFirstSection() && getProperty("optionalStop")) {
      onCommand(COMMAND_OPTIONAL_STOP);
    }

    if (tool.number > 99) {
      warning(localize("Tool number exceeds maximum value."));
    }
    var compensationOffset = tool.isTurningTool() ? tool.compensationOffset : tool.lengthOffset;
    if (compensationOffset > 99) {
      error(localize("Compensation offset is out of range."));
      return;
    }

    if ((toolingData.tooling == QCTP) || tool.getManualToolChange()) {
      var comment = formatComment(localize("CHANGE TO T") + tool.number + " " + localize("ON") + " " +
        localize((toolingData.toolPost == REAR) ? "REAR TOOL POST" : "FRONT TOOL POST"));
      writeBlock(mFormat.format(0), comment);
    }

    writeBlock(
      "T" + toolFormat.format(tool.number),
      conditional(tool.number != compensationOffset, dOutput.format(compensationOffset)),
      conditional(tool.comment, formatComment(tool.comment))
    );
    forceAny();
    gMotionModal.reset();
    writeBlock(
      gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), zOutput.format(initialPosition.z)
    );
  }

  if (gotTailStock) {
    writeBlock(currentSection.tailstock ? getCode("TAILSTOCK_ON") : getCode("TAILSTOCK_OFF"));
  }
  // writeBlock(mFormat.format(clampPrimaryChuck ? x : x));
  // writeBlock(mFormat.format(clampSecondaryChuck ? x : x));
  
  var tapping = hasParameter("operation:cycleType") &&
    ((getParameter("operation:cycleType") == "tapping") ||
    (getParameter("operation:cycleType") == "right-tapping") ||
    (getParameter("operation:cycleType") == "left-tapping") ||
    (getParameter("operation:cycleType") == "tapping-with-chip-breaking"));
  
  startSpindle(false, true, initialPosition);
  
  setRotation(currentSection.workPlane);

  if (currentSection.partCatcher) {
    engagePartCatcher(true);
  }

  if (insertToolCall || tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    
    writeBlock(
      gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), zOutput.format(initialPosition.z)
    );

    gMotionModal.reset();
  }

  // enable SFM spindle speed
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    startSpindle(false, false);
  }
  
  // set coolant after we have positioned at Z
  setCoolant(tool.coolant);

}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  var _seconds = clamp(0.1, seconds, 99999.999);
  writeBlock(gFormat.format(4), "F" + secFormat.format(_seconds));
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
      pendingRadiusCompensation = -1;
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gFormat.format(41));
        writeBlock(gMotionModal.format(0), x, y, z, dOutput.format(compensationOffset));
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gFormat.format(42));
        writeBlock(gMotionModal.format(0), x, y, z, dOutput.format(compensationOffset));
        break;
      default:
        writeBlock(gFormat.format(40));
        writeBlock(gMotionModal.format(0), x, y, z);
      }
    } else {
      writeBlock(gMotionModal.format(0), x, y, z);
    }
    forceFeed();
  }
}

var resetFeed = false;

function onLinear(_x, _y, _z, feed) {
  if (isSpeedFeedSynchronizationActive()) {
    resetFeed = true;
    var threadPitch = getParameter("operation:threadPitch");
    var threadsPerInch = 1.0 / threadPitch; // per mm for metric
    writeBlock(formatFeedMode(FEED_PER_REVOLUTION), feedOutput.format(threadPitch));
    writeBlock(gMotionModal.format(1), xOutput.format(_x), yOutput.format(_y), zOutput.format(_z), "P");
    return;
  }
  if (resetFeed) {
    resetFeed = false;
    forceFeed();
  }
  writeBlock(formatFeedMode(currentSection.feedMode)); // switch back to correct feed unit if changed
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = getFeed(feed);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      dOutput.reset();
      pendingRadiusCompensation = -1;
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gFormat.format(41));
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), x, y, z, f, dOutput.format(compensationOffset));
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gFormat.format(42));
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), x, y, z, f, dOutput.format(compensationOffset));
        break;
      default:
        writeBlock(gFormat.format(40));
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), x, y, z, f);
      }
    } else {
      writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), x, y, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), f);
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
  var directionCode = (toolingData.toolPost == REAR) ? (clockwise ? 3 : 2) : (clockwise ? 2 : 3);

  if (isFullCircle()) {
    if (getProperty("useRadius") || isHelical()) { // radius mode does not support full arcs
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(directionCode), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gMotionModal.format(directionCode), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gMotionModal.format(directionCode), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else if (!getProperty("useRadius")) {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
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
      writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
  gMotionModal.reset();
}

function onCycle() {
}

var saveShowSequenceNumbers = true;
var pathBlockNumber = {start: 0, end: 0};

function onCyclePath() {
  // buffer all paths and stop feeds being output
  feedOutput.disable();
  redirectToBuffer();
  gMotionModal.reset();
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
  } else {
    error(localize("Unsupported passes type."));
    return;
  }
  // notes for G75
  // The return passes are at a fixed clearance distance (.02 IN) from the last cutting pass.
  // The G75 cycle can be used for either internal or external removal, and from the back.
  // Tool nose radius compensation can not be active when using the roughing cycle.

  // output cycle data
  switch (cycleType) {
  case "turning-canned-rough":
    writeBlock(gFormat.format(75),
      "U" + spatialFormat.format(Math.max(cycle.zStockToLeave, cycle.xStockToLeave)),
      "I" + spatialFormat.format(cycle.depthOfCut),
      getFeed(cycle.cutfeedrate)
    );
    break;
  default:
    error(localize("Unsupported turning canned cycle."));
  }
  
  for (var i = 0; i < cyclePath.length; ++i) {
    writeBlock(cyclePath[i]); // output cycle path
  }
  writeBlock("RF");
}

function getStartEndSequenceNumber(cyclePath, start) {
  if (start) {
    pathBlockNumber.start = sequenceNumber + conditional(saveShowSequenceNumbers, getProperty("sequenceNumberIncrement"));
    return pathBlockNumber.start;
  } else {
    pathBlockNumber.end = sequenceNumber + getProperty("sequenceNumberIncrement") + conditional(saveShowSequenceNumbers, (cyclePath.length - 1) * getProperty("sequenceNumberIncrement"));
    return pathBlockNumber.end;
  }
}

function getCommonCycle(x, y, z, r) {
  return [xOutput.format(x), yOutput.format(y),
    zOutput.format(z),
    "R" + spatialFormat.format(r)];
}

var threadNumber = 0;
function onCyclePoint(x, y, z) {
  if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1)) ||
      isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, -1))) {
    // check vector
  } else {
    expandCyclePoint(x, y, z);
    return;
  }

  switch (cycleType) {
  case "thread-turning":
    var inverted = (toolingData.toolPost == REAR) ? 1 : -1;
    var taper = cycle.incrementalX * inverted; // positive if taper goes down - delta radius
    var threadHeight = getParameter("operation:threadDepth");
    var firstDepthOfCut = threadHeight / Math.sqrt(getParameter("operation:numberOfStepdowns"));

    if (getProperty("useSimpleThread") ||
      (hasParameter("operation:infeedMode") && (getParameter("operation:infeedMode") != "reduced"))) {
      xOutput.reset();
      zOutput.reset();
      feedOutput.reset();
      var id = hasParameter("operation:machineInside") && getParameter("operation:machineInside") == 1;

      // find number of threads and count which thread we are on
      var numberOfThreads = 1;
      if ((hasParameter("operation:doMultipleThreads") && (getParameter("operation:doMultipleThreads") != 0))) {
        numberOfThreads = getParameter("operation:numberOfThreads");
      }
      if (isFirstCyclePoint()) {
        threadNumber += 1;
      }

      // return to start point
      var xStart = x - cycle.incrementalX + (id ? -xFormat.getMinimumValue() : xFormat.getMinimumValue());
      writeBlock(gMotionModal.format(0), zOutput.format(z - cycle.incrementalZ + ((cycle.pitch / numberOfThreads) * (threadNumber - 1))));
      writeBlock(gMotionModal.format(0), xOutput.format(xStart));
      gCycleModal.reset();
      writeBlock(
        gCycleModal.format(33),
        xOutput.format(x - cycle.incrementalX),
        zOutput.format(z),
        "I" + xFormat.format(firstDepthOfCut),
        "K" + spatialFormat.format(cycle.pitch),
        conditional(xFormat.isSignificant(taper), "A" + xFormat.format(taper)),
        "C" + spatialFormat.format(0),
        "O" // single pass
      );

      // reset thread number to zero if thread is finished.
      if (isLastCyclePoint() && numberOfThreads == threadNumber) {
        threadNumber = 0;
      }
    } else {
      if (isLastCyclePoint()) {
        var repeatPass = hasParameter("operation:nullPass") ? getParameter("operation:nullPass") : 0;
        var chamferWidth = 10; // Pullout-width is 1*thread-lead in 1/10's;
        var materialAllowance = 0; // Material allowance for finishing pass
        // must be between 0 and 30 degrees
        var cuttingAngle = 29; // Angle is not stored with tool. toDeg(tool.getTaperAngle());
        if (hasParameter("operation:infeedAngle")) {
          cuttingAngle = getParameter("operation:infeedAngle");
        }

        var zStart = zOutput.getCurrent();
        var xStart = x - cycle.incrementalX + (id ? -threadHeight + firstDepthOfCut : threadHeight - firstDepthOfCut);
        writeBlock(gMotionModal.format(0), zOutput.format(zStart));
        writeBlock(gMotionModal.format(0), xOutput.format(xStart));

        gCycleModal.reset();
        writeBlock(
          gCycleModal.format(33),
          xOutput.format(x - cycle.incrementalX),
          zOutput.format(z),
          "I" + xFormat.format(firstDepthOfCut), // constant volume
          "K" + spatialFormat.format(cycle.pitch),
          conditional(xFormat.isSignificant(taper), "A" + spatialFormat.format(taper)),
          "C" + spatialFormat.format(cuttingAngle)
          //"P", // controls the chamfer pullout. always at 45 degrees until it reaches x posiiton
        );

        // spring passes
        for (var i = 0; i < repeatPass; i++) {
          gCycleModal.reset();
          gMotionModal.reset();
          forceXYZ();
          writeBlock(gMotionModal.format(0), zOutput.format(zStart));
          writeBlock(gMotionModal.format(0), xOutput.format(xStart));
          writeBlock(
            gCycleModal.format(33),
            xOutput.format(x - cycle.incrementalX),
            zOutput.format(z),
            "I" + xFormat.format(firstDepthOfCut),
            "K" + spatialFormat.format(cycle.pitch),
            conditional(xFormat.isSignificant(taper), "A" + xFormat.format(taper)),
            "C" + spatialFormat.format(cuttingAngle),
            //"P", // controls the chamfer pullout. always at 45 degrees until it reaches x posiiton
            "O" // single finish pass
          );
          
        }
        forceFeed();
        gMotionModal.reset();
      }
    }
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
      onExpandedRapid(x, y, cycle.retract);
      writeBlock(
        gCycleModal.format(81),
        zOutput.format(z),
        feedOutput.format(F)
      );
      break;
    case "counter-boring":
      if (P > 0) {
        expandCyclePoint(x, y, z);
      } else {
        onExpandedRapid(x, y, cycle.retract);
        writeBlock(
          gCycleModal.format(81),
          zOutput.format(z),
          feedOutput.format(F)
        );
      }
      break;
    case "deep-drilling":
      if (P > 0) {
        expandCyclePoint(x, y, z);
      } else {
        writeBlock(
          gCycleModal.format(83),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F),
          peckOutput.format(cycle.incrementalDepth),
          "C" + spatialFormat.format(cycle.retract - cycle.stock),
          "L" + spatialFormat.format(unit == MM ? 5000 : 200)
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
      // G80 not output for turning
      gCycleModal.reset();
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
    writeBlock(sOutput.format(spindleSpeed));
  }
}

function startSpindle(tappingMode, forceRPMMode, initialPosition) {
  var spindleDir;
  var _spindleSpeed;
  var spindleMode;
  var maxSpeed = "";
  gSpindleModeModal.reset();
  gSpindleModeModal.reset();

  if ((getSpindle() == SPINDLE_SECONDARY) && !gotSecondarySpindle) {
    error(localize("Secondary spindle is not available."));
    return;
  }

  if (getSpindle() == SPINDLE_SECONDARY) {
    spindleDir = tool.clockwise ? getCode("START_SUB_SPINDLE_CW") : getCode("START_SUB_SPINDLE_CCW");
  } else {
    spindleDir = tool.clockwise ? getCode("START_MAIN_SPINDLE_CW") : getCode("START_MAIN_SPINDLE_CCW");
  }

  var maximumSpindleSpeed = (tool.maximumSpindleSpeed > 0) ? Math.min(tool.maximumSpindleSpeed, getProperty("maximumSpindleSpeed")) : getProperty("maximumSpindleSpeed");
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    _spindleSpeed = tool.surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0);
    if (forceRPMMode) { // RPM mode is forced until move to initial position
      if (xFormat.getResultingValue(initialPosition.x) == 0) {
        _spindleSpeed = maximumSpindleSpeed;
      } else {
        _spindleSpeed = Math.min((_spindleSpeed * ((unit == MM) ? 1000.0 : 12.0) / (Math.PI * Math.abs(initialPosition.x * 2))), maximumSpindleSpeed);
      }
      spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF");
      writeBlock(
        spindleMode,
        sOutput.format(_spindleSpeed),
        spindleDir
      );
    } else {
      spindleMode = getCode("CONSTANT_SURFACE_SPEED_ON");
      writeBlock(
        spindleMode,
        sOutput.format(_spindleSpeed),
        spindleDir
      );
      writeBlock(gFormat.format(76), sOutput.format(getProperty("minimumSpindleSpeed")));
      writeBlock(gFormat.format(77), sOutput.format(maximumSpindleSpeed));
    }
  } else {
    _spindleSpeed = spindleSpeed;
    spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF");
    writeBlock(
      spindleMode,
      sOutput.format(_spindleSpeed),
      spindleDir
    );
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
  case COMMAND_SPINDLE_CLOCKWISE:
    switch (currentSection.spindle) {
    case SPINDLE_PRIMARY:
      writeBlock(mFormat.format(3));
      break;
    case SPINDLE_SECONDARY:
      // writeBlock(mFormat.format());
      break;
    }
    break;
  case COMMAND_SPINDLE_COUNTERCLOCKWISE:
    switch (currentSection.spindle) {
    case SPINDLE_PRIMARY:
      writeBlock(mFormat.format(4));
      break;
    case SPINDLE_SECONDARY:
      // writeBlock(mFormat.format());
      break;
    }
    break;
  case COMMAND_START_SPINDLE:
    onCommand(tool.clockwise ? COMMAND_SPINDLE_CLOCKWISE : COMMAND_SPINDLE_COUNTERCLOCKWISE);
    return;
  case COMMAND_STOP_SPINDLE:
    switch (currentSection.spindle) {
    case SPINDLE_PRIMARY:
      writeBlock(mFormat.format(5));
      break;
    case SPINDLE_SECONDARY:
      // writeBlock(mFormat.format());
      break;
    }
    break;
  case COMMAND_ORIENTATE_SPINDLE:
    if (getSpindle() == 0) {
      writeBlock(mFormat.format(19)); // use P or R to set angle (optional)
    } else {
      // writeBlock(mFormat.format());
    }
    break;
  //case COMMAND_CLAMP: // TAG: add support for clamping
  //case COMMAND_UNCLAMP: // TAG: add support for clamping
  default:
    onUnsupportedCommand(command);
  }
}

function ejectPart() {
  gMotionModal.reset();
  writeComment("START OF PART EJECT");
  if (getProperty("autoEject") == "trueUnload" || getProperty("autoEject") == "slowUnload") {
    forceXYZ();
    writeBlock("T" + toolFormat.format(getProperty("unloaderTool")), xOutput.format(0), zOutput.format(0));
  }
  writeBlock(mFormat.format(5));
  if (getProperty("autoEject") == "slow" || getProperty("autoEject") == "slowUnload") {
    writeBlock(mFormat.format(59));
  }
  writeBlock(mFormat.format(48));
  if (getProperty("autoEject") == "trueUnload" || getProperty("autoEject") == "slowUnload") {
    writeBlock(getCode("PART_CATCHER_ON"));
    onDwell(0.5);
    writeBlock(getCode("PART_CATCHER_OFF"));
  }
  writeComment(localize("END OF PART EJECT"));
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
  // cancel SFM mode to preserve spindle speed
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    startSpindle(false, true, getFramePosition(currentSection.getFinalPosition()));
  }

  if (currentSection.partCatcher) {
    engagePartCatcher(false);
  }

  forceAny();
}

/** Output block to do safe retract and/or move to home position. */
var XZ = 4;
function writeRetract() {
  var words = []; // store all retracted axes in an array
  var singleLineRetract = false; // enables retract of all axes in a single block
  var retractAxes = []; // axes to retract

  // define home positions
  var _xHome = getProperty("homePositionX");
  var _yHome;
  var _zHome = getProperty("homePositionZ");

  if (arguments.length > 0) {
    for (var i in arguments) {
      retractAxes.push(arguments[i]);
      singleLineRetract = arguments[i] == XZ ? true : singleLineRetract;
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

  // format home positions
  for (var i = 0; i < retractAxes.length; ++i) {
    switch (retractAxes[i]) {
    case X:
      words.push(xOutput.format(_xHome));
      retracted[X] = true;
      xOutput.reset();
      break;
    case Y:
      if (yOutput.isEnabled()) {
        words.push(yOutput.format(_yHome));
        yOutput.reset();
      }
      break;
    case Z:
      words.push(zOutput.format(_zHome));
      retracted[Z] = true;
      zOutput.reset();
      break;
    case XZ:
      words.push(xOutput.format(_xHome));
      words.push(zOutput.format(_zHome));
      retracted[X] = true;
      retracted[Z] = true;
      xOutput.reset();
      zOutput.reset();
      break;
    default:
      error(localize("Unsupported axis specified for writeRetract()."));
      return;
    }
  }

  for (var i = 0; i < words.length; ++i) {
    writeBlock(gMotionModal.format(0), singleLineRetract ? words : words[i]);
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
  writeRetract();// change this to writeRetract(XZ) to force retract in XZ at the end of the program as a default

  onImpliedCommand(COMMAND_END);
  onCommand(COMMAND_STOP_SPINDLE);

  if (getProperty("autoEject") != "false") {
    ejectPart();
  }

  writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off

  if (getProperty("useZipLoader") == "bar") {
    writeBlock("}1", formatComment("sub 1: new bar"));
    forceXYZ();
    writeBlock(xOutput.format(0), zOutput.format(workpiece.lower.z - cutOffWidth));
    writeBlock(mFormat.format(48), formatComment("eject remnant"));
    writeBlock("T" + toolFormat.format(getProperty("stopTool")));
    writeBlock(mFormat.format(47), formatComment("load new bar"));
    onDwell(3);
    writeBlock(mFormat.format(97) + "I10C1P2");
    onDwell(0.1);
    writeBlock(mFormat.format(99));
    writeBlock("}2", formatComment("sub 2: no more bars"));
    writeBlock(mFormat.format(11), formatComment("open collet and feed"));
    writeBlock(mFormat.format(31), formatComment("cancel cycle repeat"));
    writeBlock(mFormat.format(30), formatComment("no more bars"));
    writeBlock(mFormat.format(99));
  }
}

function setProperty(property, value) {
  properties[property].current = value;
}
