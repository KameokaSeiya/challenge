/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Milltronics Lathe post processor configuration.

  $Revision: 43214 98a796e814937a743ede7ca7e9131f7777db96a2 $
  $Date: 2021-04-13 21:49:26 $
  
  FORKID {7972FB04-C032-4057-8216-76837592730C}
*/

description = "Milltronics Turning";
vendor = "Milltronics";
vendorUrl = "https://www.milltronics.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic turning post for Milltronics. Use Turret 0 for Positional Turret, Turret 101 for QCTP on X- Post, Turret 102 for QCTP on X+ Post, Turret 103 for Gang Tooling on X- Post, Turret 104 for Gang Tooling on X+ Tool Post.";
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
  safePositionMethod: {
    title: "Safe Retracts",
    description: "Select your desired retract option.",
    type: "enum",
    group: 0,
    values: [
      {title: "G28", id: "G28"},
      {title: "G53", id: "G53"},
      {title: "Machine Tool Change Position (G47/G48)", id: "machineToolChange"},
      {title: "Machine Clearance (G45/G46)", id: "machineClearance"}
    ],
    value: "G28",
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
  optionalStop: {
    title: "Optional stop",
    description: "Outputs optional stop code during when necessary in the code.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  o8: {
    title: "8 Digit program number",
    description: "Specifies that an 8 digit program number is needed.",
    type: "boolean",
    value: false,
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
  useParametricFeed: {
    title: "Parametric feed",
    description: "Specifies the feed value that should be output using a Q value.",
    type: "boolean",
    value: false,
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
  g53HomePositionX: {
    title: "G53 home position X",
    description: "G53 X-axis home position.",
    group: 0,
    type: "number",
    value: 0,
    scope: "post"
  },
  g53HomePositionZ: {
    title: "G53 home position Z",
    description: "G53 Z-axis home position.",
    group: 0,
    type: "number",
    value: 0,
    scope: "post"
  },
  useSimpleThread: {
    title: "Use simple threading cycle",
    description: "Enable to output G92 simple threading cycle, disable to output G76 standard threading cycle.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  minimumThreadCut: {
    title: "Minimum thread cut depth",
    description: "Defines the depth in radius of the minimum desired thread cut when using 'constant amount' (P1,P2) for G76 threading.",
    type: "number",
    value: 0,
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

var gFormat = createFormat({prefix:"G", decimals:1});
var mFormat = createFormat({prefix:"M", decimals:1});

var spatialFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var xFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, scale:2}); // diameter mode
var yFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var zFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var rFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true}); // radius
var feedFormat = createFormat({decimals:(unit == MM ? 4 : 5), forceDecimal:true});
var iFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal: true, scale: 1});
var pitchFormat = createFormat({decimals:6, forceDecimal:true});
var toolFormat = createFormat({decimals:0, width:4, zeropad:true});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-99999.999
var milliFormat = createFormat({decimals:0}); // milliseconds // range 1-9999
var taperFormat = createFormat({decimals:1, scale:DEG});
var threadP1Format = createFormat({decimals:0, forceDecimal:false, trim:false, width:6, zeropad:true});
var threadPQFormat = createFormat({decimals:0, forceDecimal:false, trim:true, scale:(unit == MM ? 1000 : 10000)});
var peckFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var integerFormat = createFormat({decimals:0, forceDecimal:false, trim:true});
// var peckFormat = createFormat({decimals:0, forceDecimal:false, trim:false, width:4, zeropad:true, scale:(unit == MM ? 1000 : 10000)});

var xOutput; // xOutput is defined in setDirectionX()
var yOutput = createVariable({prefix:"Y"}, yFormat);
var zOutput = createVariable({onchange:function () {retracted[Z] = false;}, prefix:"Z"}, zFormat);

var feedOutput = createVariable({prefix:"F"}, feedFormat);
var pitchOutput = createVariable({prefix:"F", force:true}, pitchFormat);
var sOutput = createVariable({prefix:"S", force:true}, rpmFormat);

// circular output
var kOutput = createReferenceVariable({prefix:"K"}, spatialFormat);
var iOutput; // iOutput is defined in setDirectionX()
var threadP1Output = createVariable({prefix:"P", force:true}, threadP1Format);
var threadP2Output = createVariable({prefix:"P", force:true}, threadPQFormat);
var threadQOutput = createVariable({prefix:"Q", force:true}, threadPQFormat);
var threadIOutput = createVariable({prefix:"I", force:true}, spatialFormat);
var g92IOutput = createVariable({prefix:"I"}, zFormat); // no scaling
var peckOutput = createVariable({prefix:"Q", force:true}, peckFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G93,91
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G98-99 / G94-95
var gSpindleModeModal = createModal({}, gFormat); // modal group 5 // G96-97
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-21
var gCycleModal = createModal({}, gFormat); // modal group 9 // G81, ...
var gRetractModal = createModal({}, gFormat); // modal group 10 // G38-39

// fixed settings
var firstFeedParameter = 500;
var gotSecondarySpindle = true;
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
var activeMovements; // do not use by default
var currentFeedId;
var toolingData;
var previousToolingData;
var retracted = new Array(false, false, false); // specifies that the tool has been retracted to the safe plane

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
    return gFeedModeModal.format(99);
  case "FEED_MODE_UNIT_MIN":
    return gFeedModeModal.format(98);
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
  if (getProperty("showSequenceNumbers")) {
    if (optionalSection) {
      if (text) {
        writeWords("/", "N" + sequenceNumber, text);
      }
    } else {
      writeWords2("N" + sequenceNumber, arguments);
    }
    sequenceNumber += getProperty("sequenceNumberIncrement");
  } else {
    if (optionalSection) {
      writeWords2("/", arguments);
    } else {
      writeWords(arguments);
    }
  }
}

/**
  Writes the specified optional block.
*/
function writeOptionalBlock() {
  if (getProperty("showSequenceNumbers")) {
    var words = formatWords(arguments);
    if (words) {
      writeWords("/", "N" + sequenceNumber, words);
      sequenceNumber += getProperty("sequenceNumberIncrement");
    }
  } else {
    writeWords2("/", arguments);
  }
}

function formatComment(text) {
  return "(" + filterText(String(text).toUpperCase(), permittedCommentChars).replace(/[()]/g, "") + ")";
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

function onOpen() {
  if (getProperty("useRadius")) {
    maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
  }

  yOutput.disable();
  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");
  writeln("%");

  if (programName) {
    var programId;
    try {
      programId = getAsInt(programName);
    } catch (e) {
      error(localize("Program name must be a number."));
      return;
    }
    if (getProperty("o8")) {
      if (!((programId >= 1) && (programId <= 99999999))) {
        error(localize("Program number is out of range."));
        return;
      }
    } else {
      if (!((programId >= 1) && (programId <= 9999))) {
        error(localize("Program number is out of range."));
        return;
      }
    }
    if ((programId >= 8000) && (programId <= 9999)) {
      warning(localize("Program number is reserved by tool builder."));
    }
    var oFormat = createFormat({width:(getProperty("o8") ? 8 : 4), zeropad:true, decimals:0});
    if (programComment) {
      writeln("O" + oFormat.format(programId) + " " + formatComment(programComment));
    } else {
      writeln("O" + oFormat.format(programId));
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
  
  // turn off trig help (avoid endpoint errors)
  writeBlock("PB81=2");

  // absolute coordinates and feed per min
  writeBlock(gFeedModeModal.format(98), gAbsIncModal.format(93));

  switch (unit) {
  case IN:
    writeBlock(gUnitModal.format(20));
    break;
  case MM:
    writeBlock(gUnitModal.format(21));
    break;
  }

  writeBlock(gFormat.format(50), sOutput.format(getProperty("maximumSpindleSpeed")));

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

function FeedContext(id, description, feed) {
  this.id = id;
  this.description = description;
  this.feed = feed;
}

function getFeed(f) {
  if (activeMovements) {
    var feedContext = activeMovements[movement];
    if (feedContext != undefined) {
      if (!feedFormat.areDifferent(feedContext.feed, f)) {
        if (feedContext.id == currentFeedId) {
          return ""; // nothing has changed
        }
        forceFeed();
        currentFeedId = feedContext.id;
        return "F#" + (firstFeedParameter + feedContext.id);
      }
    }
    currentFeedId = undefined; // force Q feed next time
  }
  return feedOutput.format(f); // use feed value
}

function initializeActiveFeeds() {
  activeMovements = new Array();
  var movements = currentSection.getMovements();
  var feedPerRev = currentSection.feedMode == FEED_PER_REVOLUTION;
  
  var id = 0;
  var activeFeeds = new Array();
  if (hasParameter("operation:tool_feedCutting")) {
    if (movements & ((1 << MOVEMENT_CUTTING) | (1 << MOVEMENT_LINK_TRANSITION) | (1 << MOVEMENT_EXTENDED))) {
      var feedContext = new FeedContext(id, localize("Cutting"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_CUTTING] = feedContext;
      activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
      activeMovements[MOVEMENT_EXTENDED] = feedContext;
    }
    ++id;
    if (movements & (1 << MOVEMENT_PREDRILL)) {
      feedContext = new FeedContext(id, localize("Predrilling"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeMovements[MOVEMENT_PREDRILL] = feedContext;
      activeFeeds.push(feedContext);
    }
    ++id;
  }
  
  if (hasParameter("operation:finishFeedrate")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var finishFeedrateRel;
      if (hasParameter("operation:finishFeedrateRel")) {
        finishFeedrateRel = getParameter("operation:finishFeedrateRel");
      } else if (hasParameter("operation:finishFeedratePerRevolution")) {
        finishFeedrateRel = getParameter("operation:finishFeedratePerRevolution");
      }
      var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? finishFeedrateRel : getParameter("operation:finishFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  }
  
  if (hasParameter("operation:tool_feedEntry")) {
    if (movements & (1 << MOVEMENT_LEAD_IN)) {
      var feedContext = new FeedContext(id, localize("Entry"), feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_IN] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LEAD_OUT)) {
      var feedContext = new FeedContext(id, localize("Exit"), feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_OUT] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:noEngagementFeedrate")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(id, localize("Direct"), feedPerRev ? getParameter("operation:noEngagementFeedrateRel") : getParameter("operation:noEngagementFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting") &&
             hasParameter("operation:tool_feedEntry") &&
             hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(
        id,
        localize("Direct"),
        Math.max(
          feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"),
          feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"),
          feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit")
        )
      );
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  }
  
  if (hasParameter("operation:reducedFeedrate")) {
    if (movements & (1 << MOVEMENT_REDUCED)) {
      var feedContext = new FeedContext(id, localize("Reduced"), feedPerRev ? getParameter("operation:reducedFeedrateRel") : getParameter("operation:reducedFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_REDUCED] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedRamp")) {
    if (movements & ((1 << MOVEMENT_RAMP) | (1 << MOVEMENT_RAMP_HELIX) | (1 << MOVEMENT_RAMP_PROFILE) | (1 << MOVEMENT_RAMP_ZIG_ZAG))) {
      var feedContext = new FeedContext(id, localize("Ramping"), feedPerRev ? getParameter("operation:tool_feedRampRel") : getParameter("operation:tool_feedRamp"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_RAMP] = feedContext;
      activeMovements[MOVEMENT_RAMP_HELIX] = feedContext;
      activeMovements[MOVEMENT_RAMP_PROFILE] = feedContext;
      activeMovements[MOVEMENT_RAMP_ZIG_ZAG] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedPlunge")) {
    if (movements & (1 << MOVEMENT_PLUNGE)) {
      var feedContext = new FeedContext(id, localize("Plunge"), feedPerRev ? getParameter("operation:tool_feedPlungeRel") : getParameter("operation:tool_feedPlunge"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_PLUNGE] = feedContext;
    }
    ++id;
  }
  if (true) { // high feed
    if ((movements & (1 << MOVEMENT_HIGH_FEED)) || (highFeedMapping != HIGH_FEED_NO_MAPPING)) {
      var feed;
      if (hasParameter("operation:highFeedrateMode") && getParameter("operation:highFeedrateMode") != "disabled") {
        feed = getParameter("operation:highFeedrate");
      } else {
        feed = this.highFeedrate;
      }
      var feedContext = new FeedContext(id, localize("High Feed"), feed);
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_HIGH_FEED] = feedContext;
      activeMovements[MOVEMENT_RAPID] = feedContext;
    }
    ++id;
  }
  
  for (var i = 0; i < activeFeeds.length; ++i) {
    var feedContext = activeFeeds[i];
    writeBlock("#" + (firstFeedParameter + feedContext.id) + "=" + feedFormat.format(feedContext.feed), formatComment(feedContext.description));
  }
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
  iOutput = createReferenceVariable({prefix:"I"}, iFormat);
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
    // retract to safe plane
    if (!isFirstSection() && insertToolCall) {
      onCommand(COMMAND_COOLANT_OFF);
    }
    writeRetract();
    forceXYZ();
  }

  writeln("");

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
      writeBlock("T" + toolFormat.format(tool.number * 100 + compensationOffset), mFormat.format(6));
    } else {
      writeBlock("T" + toolFormat.format(tool.number * 100 + compensationOffset));
    }
    
    if (tool.comment) {
      writeComment(tool.comment);
    }
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
    if (workOffset > 6) {
      error(localize("Work offset out of range."));
    } else {
      if (workOffset != currentWorkOffset) {
        writeBlock(gFormat.format(53 + workOffset)); // G54->G59
        currentWorkOffset = workOffset;
      }
    }
  }

  // set coolant after we have positioned at Z
  setCoolant(tool.coolant);

  forceAny();
  gMotionModal.reset();

  gFeedModeModal.reset();
  if (currentSection.feedMode == FEED_PER_REVOLUTION) {
    writeBlock(getCode("FEED_MODE_UNIT_REV"));
  } else {
    writeBlock(getCode("FEED_MODE_UNIT_MIN"));
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
  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  startSpindle(false, true, initialPosition);
  
  setRotation(currentSection.workPlane);

  if (currentSection.partCatcher) {
    engagePartCatcher(true);
  }
  
  gMotionModal.reset();

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

  if (getProperty("useParametricFeed") &&
      hasParameter("operation-strategy") &&
      (getParameter("operation-strategy") != "drill") && // legacy
      !(currentSection.hasAnyCycle && currentSection.hasAnyCycle())) {
    if (!insertToolCall &&
        activeMovements &&
        (getCurrentSectionId() > 0) &&
        ((getPreviousSection().getPatternId() == currentSection.getPatternId()) && (currentSection.getPatternId() != 0))) {
      // use the current feeds
    } else {
      initializeActiveFeeds();
    }
  } else {
    activeMovements = undefined;
  }

}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  var _seconds = clamp(0.001, seconds, 99999.999);
  writeBlock(gFormat.format(4), "P" + secFormat.format(_seconds));
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
        writeBlock(gMotionModal.format(0), gFormat.format(41), x, y, z);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gMotionModal.format(0), gFormat.format(42), x, y, z);
        break;
      default:
        writeBlock(gMotionModal.format(0), gFormat.format(40), x, y, z);
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
    writeBlock(gMotionModal.format(32), xOutput.format(_x), yOutput.format(_y), zOutput.format(_z), pitchOutput.format(1 / threadsPerInch));
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
      pendingRadiusCompensation = -1;
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(41), x, y, z, f);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(42), x, y, z, f);
        break;
      default:
        writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(40), x, y, z, f);
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
  var directionCode = (toolingData.toolPost == REAR) ? (clockwise ? 2 : 3) : (clockwise ? 3 : 2);

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
}

function onCycle() {
}

var saveShowSequenceNumbers = true;
var pathBlockNumber = {start: 0, end: 0};

function onCyclePath() {
  saveShowSequenceNumbers = getProperty("showSequenceNumbers");

  // buffer all paths and stop feeds being output
  feedOutput.disable();
  setProperty("showSequenceNumbers", false);
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
  } else if (cycle.profileRoughingCycle == 1) {
    verticalPasses = true;
  } else {
    error(localize("Unsupported passes type."));
    return;
  }
  // output cycle data
  switch (cycleType) {
  case "turning-canned-rough":
    writeBlock("P117=0"); // sets relief type: 0 for pattern, 1 for 45 deg. 45 cannot do pockets.
    writeBlock(gFormat.format(verticalPasses ? 72 : 71),
      "P" + (getStartEndSequenceNumber(cyclePath, true)),
      "Q" + (getStartEndSequenceNumber(cyclePath, false)),
      "I" + xFormat.format(cycle.xStockToLeave),
      "K" + spatialFormat.format(cycle.zStockToLeave),
      "R" + spatialFormat.format(cycle.retractLength),
      "D" + spatialFormat.format(cycle.depthOfCut),
      getFeed(cycle.cutfeedrate)
    );
    break;
  default:
    error(localize("Unsupported turning canned cycle."));
  }
  
  for (var i = 0; i < cyclePath.length; ++i) {
    if (i == 0 || i == (cyclePath.length - 1)) { // write sequence number on first and last line of the cycle path
      setProperty("showSequenceNumbers", true);
      if ((i == 0 && pathBlockNumber.start != sequenceNumber) || (i == (cyclePath.length - 1) && pathBlockNumber.end != sequenceNumber)) {
        error(localize("Mismatch of start/end block number in turning canned cycle."));
        return;
      }
    }
    writeBlock(cyclePath[i]); // output cycle path
    setProperty("showSequenceNumbers", saveShowSequenceNumbers); // reset property to initial state
  }
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
  // forceXYZ(); // force xyz on first drill hole of any cycle
  return [xOutput.format(x), yOutput.format(y),
    zOutput.format(z),
    "R" + spatialFormat.format(r)];
}

var threadStart;
var threadEnd;
function moveToThreadStart(x, y, z) {
  var cuttingAngle = 0;
  if (hasParameter("operation:infeedAngle")) {
    cuttingAngle = getParameter("operation:infeedAngle");
  }
  if (cuttingAngle != 0) {
    var zz;
    if (isFirstCyclePoint()) {
      threadStart = getCurrentPosition();
      threadEnd = new Vector(x, y, z);
    } else {
      var zz = threadStart.z - (Math.abs(threadEnd.x - x) * Math.tan(toRad(cuttingAngle)));
      writeBlock(gMotionModal.format(0), zOutput.format(zz));
      xOutput.reset();
      zOutput.reset();
      g92IOutput.reset();
      feedOutput.reset();
      threadStart.setZ(zz);
      threadEnd = new Vector(x, y, z);
    }
  }
}

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
    if (isFirstCyclePoint()) {
      var threadHeight = getParameter("operation:threadDepth");
      var chamferAngle = Math.atan2(cycle.pitch, threadHeight) - Math.atan(cycle.incrementalX, cycle.incrementalZ); // angle to get out of thread + taper angle.
      chamferAngle = clamp(0, chamferAngle, Math.PI / 2); // champer angle must be between 0 and 90 deg.
      writeBlock("P103=" + spatialFormat.format(cycle.pitch)); // width of chamfer angle
      writeBlock("P104=" + taperFormat.format(chamferAngle)); // angle of chamfer measure from X axis.
    }
    if (getProperty("useSimpleThread")) {
      var i = -cycle.incrementalX * inverted; // positive if taper goes down - delta radius
      moveToThreadStart(x, y, z);
      var threadsPerInch = 1.0 / cycle.pitch; // per mm for metric
      var f = 1 / threadsPerInch;
      writeBlock(
        gMotionModal.format(92),
        xOutput.format(x - cycle.incrementalX),
        yOutput.format(y),
        zOutput.format(z),
        conditional(zFormat.isSignificant(i), g92IOutput.format(i)),
        feedOutput.format(f)
      );
    } else {
      if (isLastCyclePoint()) {
        // thread height and depth of cut
        var threadHeight = getParameter("operation:threadDepth");
        var firstDepthOfCut = threadHeight / getParameter("operation:numberOfStepdowns");
     
        // first G76 block
        var repeatPass = hasParameter("operation:nullPass") ? getParameter("operation:nullPass") : 0;
        var chamferWidth = 10; // Pullout-width is 1*thread-lead in 1/10's;
        var materialAllowance = 0; // Material allowance for finishing pass
        var cuttingAngle = 60; // Angle is not stored with tool. toDeg(tool.getTaperAngle());
        if (hasParameter("operation:infeedAngle")) {
          cuttingAngle = getParameter("operation:infeedAngle");
        }
        var pcode = repeatPass * 10000 + chamferWidth * 100 + cuttingAngle;
        gCycleModal.reset();

        var threadInfeedMode = "constant";
        if (hasParameter("operation:infeedMode")) {
          threadInfeedMode = getParameter("operation:infeedMode");
        }

        //  Cutting Method:
        //  P1 = Constant Amount/1 Edge
        //  P2 = Constant Amount/Both Edges
        //  P3 = Constant Depth/One Edge
        //  P4 = Constant Depth/Both Edges >>>>>> not supported
         
        var threadCuttingMode = 3;
        if (threadInfeedMode == "reduced") {
          threadCuttingMode = 1;
        } else if (threadInfeedMode == "constant") {
          threadCuttingMode = 3;
        } else if (threadInfeedMode == "alternate") {
          threadCuttingMode = 2;
        } else {
          error(localize("Unsupported Infeed Mode."));
          return;
        }

        writeBlock("P130=", spatialFormat.format(getProperty("minimumThreadCut"))); // minimum cut
        writeBlock("P131=" + integerFormat.format(repeatPass)); // spring passes

        var i = -cycle.incrementalX * inverted; // positive if taper goes down - delta radius
        gCycleModal.reset();
        // add q? what would that look like.
        writeBlock(
          gCycleModal.format(76),
          xOutput.format(x),
          zOutput.format(z),
          conditional(zFormat.isSignificant(i), threadIOutput.format(i)),
          "D" + spatialFormat.format(firstDepthOfCut),
          "A" + spatialFormat.format(cuttingAngle),
          "P" + integerFormat.format(threadCuttingMode),
          "K" + spatialFormat.format(threadHeight),
          pitchOutput.format(cycle.pitch)
        );
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
      writeBlock(gFormat.format(38));
      writeBlock(
        gCycleModal.format(81),
        getCommonCycle(x, y, z, cycle.retract),
        feedOutput.format(F)
      );
      break;
    case "counter-boring":
      writeBlock(gFormat.format(38));
      if (P > 0) {
        writeBlock(
          gCycleModal.format(82),
          getCommonCycle(x, y, z, cycle.retract),
          "P" + secFormat.format(P),
          feedOutput.format(F)
        );
      } else {
        writeBlock(
          gCycleModal.format(81),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    case "chip-breaking":
      if ((cycle.accumulatedDepth < cycle.depth) || (P > 0)) {
        expandCyclePoint(x, y, z);
      } else {
        writeBlock(gFormat.format(38));
        writeBlock(
          gCycleModal.format(74),
          getCommonCycle(x, y, z, cycle.retract),
          peckOutput.format(cycle.incrementalDepth),
          conditional(cycle.chipBreakDistance > 0, "E" + spatialFormat.format(cycle.chipBreakDistance)),
          feedOutput.format(F)
        );
      }
      break;
    case "deep-drilling":
      if (P > 0) {
        expandCyclePoint(x, y, z);
      } else {
        writeBlock(gFormat.format(38));
        writeBlock(
          gCycleModal.format(83),
          getCommonCycle(x, y, z, cycle.retract),
          peckOutput.format(cycle.incrementalDepth),
          // conditional(P > 0, "P" + milliFormat.format(P)),
          feedOutput.format(F)
        );
      }
      break;
    case "tapping":
    case "left-tapping":
    case "right-tapping":
      F = tool.getThreadPitch();
      // left handed and right handed tapping determined by spindle direction. Machine only supports rigid tapping cycle.
      writeBlock(gFormat.format(38));
      writeBlock(
        gCycleModal.format(84),
        getCommonCycle(x, y, z, cycle.retract),
        // "P" + milliFormat.format(P),
        pitchOutput.format(F)
      );
      break;
    /*
    case "tapping-with-chip-breaking":
    case "left-tapping-with-chip-breaking":
    case "right-tapping-with-chip-breaking":
      F = tool.getThreadPitch() * rpmFormat.getResultingValue(spindleSpeed);
      startSpindle(true, false);
      writeBlock(
        gCycleModal.format((tool.type == TOOL_TAP_LEFT_HAND ? 74 : 84)),
        getCommonCycle(x, y, z, cycle.retract),
        "P" + milliFormat.format(P),
        peckOutput.format(cycle.incrementalDepth),
        feedOutput.format(F)
      );
      break;

    case "fine-boring":
      writeBlock(
        gCycleModal.format(76),
        getCommonCycle(x, y, z, cycle.retract),
        "P" + milliFormat.format(P), // not optional
        "Q" + xFormat.format(cycle.shift),
        feedOutput.format(F)
      );
      break;
    */
    case "reaming":
      if (P > 0) {
        writeBlock(
          gCycleModal.format(89),
          getCommonCycle(x, y, z, cycle.retract),
          "P" + secFormat.format(P),
          feedOutput.format(F)
        );
      } else {
        writeBlock(
          gCycleModal.format(85),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    case "stop-boring":
      if (P > 0) {
        expandCyclePoint(x, y, z);
      } else {
        writeBlock(
          gCycleModal.format(86),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    case "boring":
      if (P > 0) {
        writeBlock(
          gCycleModal.format(89),
          getCommonCycle(x, y, z, cycle.retract),
          "P" + secFormat.format(P), // not optional
          feedOutput.format(F)
        );
      } else {
        writeBlock(
          gCycleModal.format(85),
          getCommonCycle(x, y, z, cycle.retract),
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
      g92IOutput.reset();
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
    } else {
      writeBlock(gFormat.format(50), sOutput.format(maximumSpindleSpeed));
      spindleMode = getCode("CONSTANT_SURFACE_SPEED_ON");
    }
  } else {
    _spindleSpeed = spindleSpeed;
    spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF");
  }
  if (getSpindle(true) == SPINDLE_SECONDARY) {
    writeBlock(
      spindleMode,
      sOutput.format(_spindleSpeed),
      spindleDir
    );
  } else {
    writeBlock(
      spindleMode,
      sOutput.format(_spindleSpeed),
      spindleDir
    );
  }
  // wait for spindle here if required
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
      writeBlock(mFormat.format(143));
      break;
    }
    break;
  case COMMAND_SPINDLE_COUNTERCLOCKWISE:
    switch (currentSection.spindle) {
    case SPINDLE_PRIMARY:
      writeBlock(mFormat.format(4));
      break;
    case SPINDLE_SECONDARY:
      writeBlock(mFormat.format(144));
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
      writeBlock(mFormat.format(145));
      break;
    }
    break;
  case COMMAND_ORIENTATE_SPINDLE:
    if (getSpindle() == 0) {
      writeBlock(mFormat.format(19)); // use P or R to set angle (optional)
    } else {
      writeBlock(mFormat.format(119));
    }
    break;
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
    writeRetract(X);
    writeRetract(Z);
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
  var method = getProperty("safePositionMethod");

  // define home positions
  var _xHome;
  var _yHome;
  var _zHome;
  if (method == "G28") {
    _xHome = toPreciseUnit(0, MM);
    _yHome = toPreciseUnit(0, MM);
    _zHome = toPreciseUnit(0, MM);
  } else {
    _xHome = machineConfiguration.hasHomePositionX() ? machineConfiguration.getHomePositionX() : getProperty("g53HomePositionX");
    _yHome = machineConfiguration.hasHomePositionY() ? machineConfiguration.getHomePositionY() : toPreciseUnit(0, MM);
    _zHome = machineConfiguration.getRetractPlane() != 0 ? machineConfiguration.getRetractPlane() : getProperty("g53HomePositionZ");
  }

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
      switch (method) {
      case "machineToolChange":
        words.push(gFormat.format(48));
        break;
      case "machineClearance":
        words.push(gFormat.format(46));
        break;
      case "G28":
        words.push("U" + xFormat.format(_xHome));
        break;
      default:
        words.push("X" + xFormat.format(_xHome));
      }
      retracted[X] = true;
      xOutput.reset();
      break;
    case Y:
      if (yOutput.isEnabled()) {
        words.push((method == "G28" ? "V" : "Y") + yFormat.format(_yHome));
        yOutput.reset();
      }
      break;
    case Z:
      switch (method) {
      case "machineToolChange":
        words.push(gFormat.format(47));
        break;
      case "machineClearance":
        words.push(gFormat.format(45));
        break;
      case "G28":
        words.push("W" + zFormat.format(_zHome));
        break;
      default:
        words.push("Z" + zFormat.format(_zHome));
      }
      retracted[Z] = true;
      zOutput.reset();
      break;
    case XZ:
      switch (method) {
      case "machineToolChange":
        words.push(gFormat.format(48));
        words.push(gFormat.format(47));
        break;
      case "machineClearance":
        words.push(gFormat.format(46));
        words.push(gFormat.format(45));
        break;
      case "G28":
        words.push("U" + xFormat.format(_xHome));
        words.push("W" + zFormat.format(_zHome));
        break;
      default:
        words.push("X" + xFormat.format(_xHome));
        words.push("Z" + zFormat.format(_zHome));
        break;
      }
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
    switch (method) {
    case "G28":
      writeBlock(gFormat.format(28), singleLineRetract ? words : words[i]);
      break;
    case "G53":
      gMotionModal.reset();
      writeBlock(gFormat.format(53), gMotionModal.format(0), singleLineRetract ? words : words[i]);
      break;
    default:
      error(localize("Unsupported safe position method."));
      return;
    }
    if (singleLineRetract) {
      break;
    }
  }
  singleLineRetract = false; // singleLineRetract reset
}

function onClose() {
  writeln("");

  optionalSection = false;

  onCommand(COMMAND_COOLANT_OFF);
  
  onCommand(COMMAND_STOP_CHIP_TRANSPORT);

  writeRetract();// change this to writeRetract(XZ) to force retract in XZ at the end of the program as a default

  onImpliedCommand(COMMAND_END);
  onImpliedCommand(COMMAND_STOP_SPINDLE);
  writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off
  writeln("%");
}

function setProperty(property, value) {
  properties[property].current = value;
}
