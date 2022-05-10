/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Tormach Lathe post processor configuration.

  $Revision: 43214 98a796e814937a743ede7ca7e9131f7777db96a2 $
  $Date: 2021-04-13 21:49:26 $
  
  FORKID {693EAE9C-0F93-47F6-A5EF-8C22D24BA790}
*/

///////////////////////////////////////////////////////////////////////////////
// Turret Assignments
//
// The following tooling options are controlled by the Turret number associated
// with the tool in the tool library.
//
//   Turret 0 = Positional Turret
//   Turret 1 = Quick Change Front Tool Post
//   Turret 2 = Quick Change Rear Tool Post
//   Turret 3 = Gang Tooling on Front Tool Post
//   Turret 4 = Gang Tooling on Rear Tool Post
//
///////////////////////////////////////////////////////////////////////////////

description = "Tormach Turning (PathPilot)";
vendor = "Tormach";
vendorUrl = "http://www.tormach.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Turning post for Tormach PathPilot on Slant-PRO or RapidTurn. Use Turret 0 for Positional Turret, Turret 1 for QCTP on Front Post, Turret 2 for QCTP on Rear Post, Turret 3 for Gang Tooling on Front Post, Turret 4 for Gang Tooling on Rear Tool Post. Valid RapidTurn Turrets are 0/2/4.";

extension = "nc";
programNameIsInteger = false;
setCodePage("ascii");

capabilities = CAPABILITY_TURNING;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(359);
allowHelicalMoves = false;
allowedCircularPlanes = 1 << PLANE_ZX; // allow ZX plane only

// user-defined properties
properties = {
  writeHeader: {
    title: "Write header information",
    description: "If enabled, additional header information will be outputted.",
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
    value: 1,
    scope: "post"
  },
  sequenceNumberOperation: {
    title: "Sequence number at operation only",
    description: "Use sequence numbers at start of operation only.",
    group: 1,
    type: "boolean",
    value: true,
    scope: "post"
  },
  optionalStopTool: {
    title: "Optional stop between tools",
    description: "Outputs optional stop code prior to a tool change.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  optionalStopOperation: {
    title: "Optional stop between operations",
    description: "Outputs optional stop code prior between all operations.",
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
    value: 3500,
    scope: "post"
  },
  showNotes: {
    title: "Show notes",
    description: "Writes operation notes as comments in the outputted code.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  g53HomePositionX: {
    title: "G53 home position X",
    description: "G53 X-axis home position.",
    type: "number",
    value: 0,
    scope: "post"
  },
  g53HomePositionZ: {
    title: "G53 home position Z",
    description: "G53 Z-axis home position.",
    type: "number",
    value: 0,
    scope: "post"
  },
  useG28: {
    title: "Use G28",
    description: "Position X to home position at end of program.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  useG30Z: {
    title: "Use G30 Z#5422",
    description: "G30 blocks should contain Z#5422 code.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  useCoolant: {
    title: "Use Coolant",
    description: "Enable to allow the output of coolant codes.",
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
  {id: COOLANT_MIST, on: 7},
  {id: COOLANT_THROUGH_TOOL},
  {id: COOLANT_AIR},
  {id: COOLANT_AIR_THROUGH_TOOL},
  {id: COOLANT_SUCTION},
  {id: COOLANT_FLOOD_MIST},
  {id: COOLANT_FLOOD_THROUGH_TOOL},
  {id: COOLANT_OFF, off: 9}
];

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,=_-:+\\";

var nFormat = createFormat({prefix:"N", decimals:0});
var gFormat = createFormat({prefix:"G", decimals:1});
var mFormat = createFormat({prefix:"M", decimals:1, zeropad:true});

var spatialFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var xFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, scale:2}); // diameter mode
var yFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var zFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var rFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true}); // radius
var pFormat = createFormat({decimals:(unit === MM ? 3 : 4), forceDecimal:true}); // thread pitch
var iThreadFormat = createFormat({decimals:(unit === MM ? 3 : 4), forceDecimal:true, scale:2}); // thread offset for drive line
var jThreadFormat = createFormat({decimals:(unit === MM ? 3 : 4), forceDecimal:true, scale:2}); // thread initial thread depth
var kThreadFormat = createFormat({decimals:(unit === MM ? 3 : 4), forceDecimal:true, scale:2}); // thread depth, diameter mode
var kTapFormat = createFormat({decimals:(unit === MM ? 3 : 4), forceDecimal:true}); // thread pitch
var rThreadFormat = createFormat({decimals:1, forceDecimal:true, zeropad:true});
var qThreadFormat = createFormat({decimals:1, forceDecimal:true, zeropad:true});
var hThreadFormat = createFormat({decimals:0});
var feedFormat = createFormat({decimals:(unit == MM ? 4 : 5), forceDecimal:true});
var iFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal: true, scale: 1});
var pitchFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var toolFormat = createFormat({decimals:0, width:4, zeropad:true});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-99999.999
var milliFormat = createFormat({decimals:0}); // milliseconds // range 1-9999
var taperFormat = createFormat({decimals:1, scale:DEG});
var timeFormat = createFormat({width:2, zeropad:true, decimals:0});

var xOutput; // xOutput is defined in setDirectionX()
var yOutput = createVariable({prefix:"Y"}, yFormat);
var zOutput = createVariable({prefix:"Z"}, zFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var pitchOutput = createVariable({prefix:"K", force:true}, pitchFormat);
var sOutput = createVariable({prefix:"S", force:true}, rpmFormat);
var pOutput = createVariable({prefix:"P", force:true}, pFormat);
var iThreadOutput = createVariable({prefix:"I", force:true}, iThreadFormat);
var jThreadOutput = createVariable({prefix:"J", force:true}, jThreadFormat);
var kThreadOutput = createVariable({prefix:"K", force:true}, kThreadFormat);
var kTapOutput = createVariable({prefix:"K", force:true}, kTapFormat);
var rThreadOutput = createVariable({prefix:"R", force:true}, rThreadFormat);
var qThreadOutput = createVariable({prefix:"Q", force:true}, qThreadFormat);
var hThreadOutput = createVariable({prefix:"H", force:true}, hThreadFormat);

// circular output
var kOutput = createReferenceVariable({prefix:"K"}, spatialFormat);
var iOutput; // iOutput is defined in setDirectionX()

var g92ROutput = createVariable({prefix:"R"}, zFormat); // no scaling

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G94-95
var gSpindleModeModal = createModal({}, gFormat); // modal group 5 // G96-97
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-21
var gCycleModal = createModal({}, gFormat); // modal group 9 // G81, ...
var gRetractModal = createModal({}, gFormat); // modal group 10 // G98-99

// fixed settings
var gotSecondarySpindle = false;
var gotTailStock = false;
var useSpindleTurn = false; // set to true if turning using the milling spindle

var WARNING_WORK_OFFSET = 0;

var QCTP = 0;
var TURRET = 1;
var GANG = 2;
var MILL_SPINDLE_TURN = 3;

var FRONT = -1;
var REAR = 1;

// collected state
var sequenceNumber;
var currentWorkOffset;
var optionalSection = false;
var forceSpindleSpeed = false;
var currentFeedId;
var toolingData;
var previousToolingData;
var maxGangToolLength = 0;

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

function formatSequenceNumber() {
  if (sequenceNumber > 99999) {
    sequenceNumber = getProperty("sequenceNumberStart");
  }
  var seqno = nFormat.format(sequenceNumber);
  sequenceNumber += getProperty("sequenceNumberIncrement");
  return seqno;
}

var showSequenceNumberNext = false;

/**
  Writes the specified block.
*/
function writeBlock() {
  var show = getProperty("showSequenceNumbers") || showSequenceNumberNext;
  var text = formatWords(arguments);
  if (show) {
    if (optionalSection) {
      if (text) {
        writeWords("/", formatSequenceNumber(), text);
        sequenceNumber += getProperty("sequenceNumberIncrement");
        showSequenceNumberNext = false;
      }
    } else {
      if (text) {
        writeWords2(formatSequenceNumber(), arguments);
        sequenceNumber += getProperty("sequenceNumberIncrement");
        showSequenceNumberNext = false;
      }
    }
  } else {
    if (text) {
      if (optionalSection) {
        writeWords2("/", arguments);
      } else {
        writeWords(arguments);
      }
    }
  }
}

/**
  Writes the specified optional block.
*/
function writeOptionalBlock() {
  var show = getProperty("showSequenceNumbers") || showSequenceNumberNext;
  var text = formatWords(arguments);
  if (show) {
    if (text) {
      writeWords("/", formatSequenceNumber(), words);
      sequenceNumber += getProperty("sequenceNumberIncrement");
      showSequenceNumberNext = false;
    }
  } else {
    if (text) {
      writeWords2("/", arguments);
    }
  }
}

function formatComment(text) {
  return ";" + filterText(text, permittedCommentChars).replace(/[()]/g, "");
}

function formatComment1(text) {
  return "(" + filterText(text, permittedCommentChars).replace(/[()]/g, "") + ")";
}

function formatMessage(text) {
  return "(msg, " + filterText(text, permittedCommentChars).replace(/[()]/g, "") + ")";
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

function writeComment1(text) {
  writeln(formatComment1(text));
}

function writeMessage(text) {
  writeln(formatMessage(text));
}

function formatCycleTime(ct) {
  var d = new Date(1899, 11, 31, 0, 0, ct + 0.5, 0);
  return timeFormat.format(d.getHours()) + ":" +
         timeFormat.format(d.getMinutes()) + ":" +
         timeFormat.format(d.getSeconds());
}

function onOpen() {
  if (getProperty("useRadius")) {
    maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
  }
  if (getProperty("sequenceNumberOperation")) {
    setProperty("showSequenceNumbers", false);
  }

  yOutput.disable();
  
  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");
  writeHeader1();

  if ((getNumberOfSections() > 0) && (getSection(0).workOffset == 0)) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      if (getSection(i).workOffset > 0) {
        error(localize("Using multiple work offsets is not possible if the initial work offset is 0."));
        return;
      }
    }
  }
}

function writeHeader1() {
  if (programName) {
    writeComment("  " + localize("program") + ":   " + programName);
    if (programComment) {
      writeComment("             " + programComment);
    }
    writeComment("");
  }
}

function writeHeader2() {
  if (hasParameter("generated-by") && getParameter("generated-by")) {
    writeComment("            " + localize("CAM") + ": " + getParameter("generated-by"));
  }
  if (hasParameter("document-path") && getParameter("document-path")) {
    writeComment("       " + localize("Document") + ": " + getParameter("document-path"));
  }
  var eos = longDescription.indexOf(".");
  writeComment(localize(" Post Processor: ") + ((eos == -1) ? longDescription : longDescription.substr(0, eos + 1)));
  if ((typeof getHeaderVersion == "function") && getHeaderVersion()) {
    writeComment("   " + localize("Post version") + ": " + getHeaderVersion());
  }
  if ((typeof getHeaderDate == "function") && getHeaderDate()) {
    writeComment("  " + localize("Post modified") + ": " + getHeaderDate());
  }
  var d = new Date();
  writeComment("           " + localize("Date") + ": " + d.toLocaleDateString() + " " + d.toLocaleTimeString());

  writeComment("");
  writeComment(localize("== BE SURE TO PROPERLY SET THE G30 HOME POSITION FOR TOOL CHANGES =="));
  writeComment(localize("== MOVE THE Z-AXIS TO A POSITION THAT CLEARS ALL TOOLS AND PRESS THE SET G30 BUTTON =="));
  writeComment("");

  var tools = getToolTable();
  var comment = "";
  var totalCycleTime = 0;
  var numberOfSections = getNumberOfSections();
  if (tools.getNumberOfTools() > 0) {
    for (var i = 0; i < tools.getNumberOfTools(); ++i) {
      var tool = tools.getTool(i);
      var cycleTime = 0;
      var toolData = new ToolingData(tool);
      var toolPost = getToolPostText(toolData);
      comment = formatBuffer(comment, " -- " + localize("tool") + ":", 1);
      comment = formatBuffer(comment, tool.number, 11);
      comment = formatBuffer(comment, toolPost, 17);
      
      var outputBuffer = new Array();
      for (var j = 0; j < numberOfSections; ++j) {
        var section = getSection(j);
        var sectionTool = section.getTool();
        if (tool.number == sectionTool.number) {
          var operComment = localize("        op") + ": " + section.getParameter("operation-comment");
          cycleTime += section.getCycleTime();
          outputBuffer.push(operComment);
        }
      }
      totalCycleTime += cycleTime;
      comment = formatBuffer(comment, localize("cycle time") + ": " + formatCycleTime(cycleTime), 46);
      writeComment(comment);
      if (tool.comment) {
        writeComment("    " + tool.comment);
      }
      for (var j = 0; j < outputBuffer.length; ++j) {
        writeComment(outputBuffer[j]);
      }
    }
    writeComment("");
    writeComment(" " + localize("Total cycle time") + ": " + formatCycleTime(totalCycleTime));
    writeComment("");
  }
}

function formatBuffer(_buffer, _text, _column) {
  var result = "";
  var spaces = "                                      ";
  if (_column == 1) {
    result = _text;
  } else {
    result = _buffer;
    if (result.length < (_column - 1)) {
      result += spaces.substr(1, _column - (result.length + 1));
    }
    result = result.substr(0, _column - 1) + _text;
  }
  return result;
}

function writeInitMachineState() {
  if (!useSpindleTurn) {
    writeBlock(gFormat.format(7)); // Diameter mode
  }
  writeBlock(gPlaneModal.format(18)); // XZ plane

  switch (unit) {
  case IN:
    writeBlock(gUnitModal.format(20));
    break;
  case MM:
    writeBlock(gUnitModal.format(21));
    break;
  }

  writeBlock(gFormat.format(54)); // WCS 1
  writeBlock(gFormat.format(40)); // radius compensation off
  writeBlock(gFormat.format(90)); // Absolute mode
  writeln("");
  goHomeZ(); // fully retract Z

  // getProperty("maximumSpindleSpeed") // not supported
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
  if (useSpindleTurn) {
    this.tooling = MILL_SPINDLE_TURN;
    if (_tool.turret == 1 || _tool.turret == 3) {
      this.toolPost = FRONT;
    } else {
      this.toolPost = REAR;
    }
  } else {
    switch (_tool.turret) {
    // Positional Turret
    case 0:
      this.tooling = TURRET;
      this.toolPost = REAR;
      break;
    // QCTP X-
    case 1:
      this.tooling = QCTP;
      this.toolPost = FRONT;
      break;
    // QCTP X+
    case 2:
      this.tooling = QCTP;
      this.toolPost = REAR;
      break;
    // Gang Tooling X-
    case 3:
      this.tooling = GANG;
      this.toolPost = FRONT;
      break;
    // Gang Tooling X+
    case 4:
      this.tooling = GANG;
      this.toolPost = REAR;
      break;
    default:
      error(localize("Turret number must be in the range of 0-4."));
      break;
    }
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
  // turning using Milling Spindle
  if (useSpindleTurn) {
    xFormat.setScale(toolingData.toolPost == FRONT ? -1 : 1);
    iFormat.setScale(toolingData.toolPost == FRONT ? -1 : 1);
  } else {
    xFormat.setScale(toolingData.toolPost == FRONT ? Math.abs(xFormat.getScale()) * -1 : Math.abs(xFormat.getScale()));
    iFormat.setScale(toolingData.toolPost == FRONT ? Math.abs(iFormat.getScale()) * -1 : Math.abs(iFormat.getScale()));
  }
  xOutput = createVariable({prefix:"X"}, xFormat);
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
  
  if (isFirstSection()) {
    if (getProperty("writeHeader")) {
      writeHeader2();
    }
    writeInitMachineState();
  }

  var forceToolAndRetract = optionalSection && !currentSection.isOptional();
  optionalSection = currentSection.isOptional();

  var turning = (currentSection.getType() == TYPE_TURNING);
  
  var insertToolCall = forceToolAndRetract || isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number);

  var retracted = false; // specifies that the tool has been retracted to the safe plane

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

  if (insertToolCall && !isFirstSection()) {
    onCommand(COMMAND_COOLANT_OFF);
    onCommand(COMMAND_STOP_SPINDLE);
  }
  
  if (insertToolCall || newSpindle || newWorkOffset) {
    // retract to safe plane
    retracted = true;
    if (!isFirstSection()) {
      goHomeZ();
    }
    forceXYZ();
  }

  writeln("");
  writeToolComment(currentSection, toolingData);

  // optional stop
  if (!isFirstSection() && ((insertToolCall && getProperty("optionalStopTool")) || getProperty("optionalStopOperation"))) {
    onCommand(COMMAND_OPTIONAL_STOP);
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

  if (getProperty("sequenceNumberOperation")) {
    showSequenceNumberNext = true;
  }

  if (insertToolCall) {
    if (!retracted) {
      goHomeZ();
      retracted = true;
    }

    if (tool.number > 99) {
      warning(localize("Tool number exceeds maximum value."));
    }
    
    if ((toolingData.tooling == QCTP) || tool.getManualToolChange()) {
      var comment = formatComment1(localize("CHANGE TO T") + tool.number + " " + localize("ON") + " " +
        localize((toolingData.toolPost == REAR) ? "REAR TOOL POST" : "FRONT TOOL POST"));
      writeBlock(mFormat.format(0), comment);
    }

    var compensationOffset = tool.isTurningTool() ? tool.compensationOffset : tool.lengthOffset;
    if (compensationOffset > 99) {
      error(localize("Compensation offset is out of range."));
      return;
    }
    writeBlock("T" + toolFormat.format(tool.number * 100 + compensationOffset));
    if (tool.comment) {
      writeComment(" " + tool.comment);
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
      return;
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

  if (gotTailStock) {
    writeBlock(getCode(currentSection.tailstock ? "TAILSTOCK_ON" : "TAILSTOCK_OFF"));
  }

  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  startSpindle(false, true, initialPosition);
  
  gFeedModeModal.reset();
  if (currentSection.feedMode == FEED_PER_REVOLUTION) {
    writeBlock(getCode("FEED_MODE_UNIT_REV"));
  } else {
    writeBlock(getCode("FEED_MODE_UNIT_MIN"));
  }
  
  setRotation(currentSection.workPlane);

  if (!retracted) {
    if (getCurrentPosition().z < initialPosition.z) {
      writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
    }
  }

  if (insertToolCall || tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    gMotionModal.reset();
    writeBlock(
      gAbsIncModal.format(90), gMotionModal.format(0),
      xOutput.format(initialPosition.x), yOutput.format(initialPosition.y)
    );
    writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
    gMotionModal.reset();
  }

  // enable SFM spindle speed
  if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
    startSpindle(false, false);
  }

  if (currentSection.partCatcher) {
    engagePartCatcher(true);
  }

  if (insertToolCall || retracted) {
    gPlaneModal.reset();
  }
}

function writeToolComment(_section, _toolingData) {
  if (_toolingData.toolChange) {
    writeComment(" ==============================================================");
    writeComment("    " + localize("Tool") + ": " + _toolingData.number);
    if (_toolingData.comment) {
      writeComment(_toolingData.comment);
    }
    writeComment(" " + localize("Tooling") + ": " + getToolPostText(_toolingData));
  } else {
    writeComment(" ..   ..   ..   ..   ..   ..   ..   ..   ..   ..   ..   ..   ..");
  }
  writeComment("      " + localize("Op") + ": " + _toolingData.operationComment);
  writeComment("    " + localize("Time") + ": " + formatCycleTime(_section.getCycleTime()));
  writeComment("       Z" + ": " + spatialFormat.format(_section.getGlobalZRange().getMinimum()));
}

function getToolPostText(_toolingData) {
  var comment;
  switch (_toolingData.tooling) {
  case MILL_SPINDLE_TURN:
    switch (_toolingData.toolPost) {
    case FRONT:
      comment = "Mill Spindle Turning -X";
      break;
    case REAR:
      comment = "Mill Spindle Turning +X";
      break;
    default:
      comment = "Mill Spindle Turning (unknown)";
      break;
    }
    break;
  case QCTP:
    switch (_toolingData.toolPost) {
    case FRONT:
      comment = "Quick Change Front Tool Post";
      break;
    case REAR:
      comment = "Quick Change Rear Tool Post";
      break;
    default:
      comment = "Quick Change Unknown Tool Post";
      break;
    }
    break;
  case TURRET:
    comment = "Turret";
    break;
  case GANG:
    switch (_toolingData.toolPost) {
    case FRONT:
      comment = "Gang - Front Tool Post";
      break;
    case REAR:
      comment = "Gang - Rear Tool Post";
      break;
    default:
      comment = "Gang - unknown";
      break;
    }
    break;
  default:
    comment = "unknown";
  }
  return comment;
}

// allow manual insertion of comma delimited g-code
function onPassThrough(text) {
  var commands = String(text).split(",");
  for (var text in commands) {
    writeBlock(commands[text]);
  }
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  milliseconds = clamp(1, seconds * 1000, 99999999);
  writeBlock(/*gFeedModeModal.format(94),*/ gFormat.format(4), "P" + milliFormat.format(milliseconds));
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

function goHomeZ() {
  if (useSpindleTurn) {
    writeBlock(gFormat.format(30));
  /*
  } else if ((toolingData.tooling == GANG) || (previousToolingData.tooling == GANG)) {
    if (_forceG30) {
      writeBlock(gFormat.format(30));
    } else {
      writeComment(localize("...pull back to safe Z..."));
      maxGangToolLength = Math.max(maxGangToolLength, toolingData.toolLength);
      maxGangToolLength = Math.max(maxGangToolLength, getProperty("gangToolSafeMargin"));
      writeBlock(zOutput.format(maxGangToolLength));
    }
  */
  } else {
    writeBlock(gFormat.format(30), conditional(getProperty("useG30Z"), "Z#5422")); // retract/park
  }
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
    var threadPitch = tool.threadPitch;
    var threadsPerInch = 1.0 / threadPitch; // per mm for metric
    writeBlock(gMotionModal.format(33), xOutput.format(_x), yOutput.format(_y), zOutput.format(_z), pitchOutput.format(1 / threadsPerInch));
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
  var feedMode = getCode((currentSection.feedMode === FEED_PER_REVOLUTION) ? "FEED_MODE_UNIT_REV" : "FEED_MODE_UNIT_MIN");
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      writeBlock(gPlaneModal.format(18));
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(feedMode, gMotionModal.format(1), gFormat.format(41), x, y, z, f);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(feedMode, gMotionModal.format(1), gFormat.format(42), x, y, z, f);
        break;
      default:
        writeBlock(feedMode, gMotionModal.format(1), gFormat.format(40), x, y, z, f);
      }
    } else {
      writeBlock(gMotionModal.format(1), x, y, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(feedMode, gMotionModal.format(1), f);
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
  var feedMode = getCode((currentSection.feedMode === FEED_PER_REVOLUTION) ? "FEED_MODE_UNIT_REV" : "FEED_MODE_UNIT_MIN");

  if (isFullCircle()) {
    if (getProperty("useRadius") || isHelical()) { // radius mode does not support full arcs
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gAbsIncModal.format(90), feedMode, gPlaneModal.format(17), gMotionModal.format(directionCode), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gAbsIncModal.format(90), feedMode, gPlaneModal.format(18), gMotionModal.format(directionCode ? 2 : 3), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gAbsIncModal.format(90), feedMode, gPlaneModal.format(19), gMotionModal.format(directionCode ? 2 : 3), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else if (!getProperty("useRadius")) {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gAbsIncModal.format(90), feedMode, gPlaneModal.format(17), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gAbsIncModal.format(90), feedMode, gPlaneModal.format(18), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gAbsIncModal.format(90), feedMode, gPlaneModal.format(19), gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
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
      writeBlock(gPlaneModal.format(17), feedMode, gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gPlaneModal.format(18), feedMode, gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gPlaneModal.format(19), feedMode, gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

function onCycle() {
}

function getCommonCycle(x, y, z, r) {
  forceXYZ(); // force xyz on first drill hole of any cycle
  return [xOutput.format(x), yOutput.format(y),
    zOutput.format(z),
    "R" + spatialFormat.format(r)];
}

function onCyclePoint(x, y, z) {
  switch (cycleType) {
  case "thread-turning":
    if (!isLastCyclePoint()) {
      return;
    }
    if (xFormat.isSignificant(cycle.incrementalX)) {
      error(localize("Tapered threading cycle is not supported on this control."));
      return;
    }
    var external = true;
    var inverted = toolingData.toolPost == FRONT ? -1 : 1;
    if (hasParameter("operation:tool_internalThread")) {
      external = getParameter("operation:tool_internalThread") == 0;
    } else {
      external = inverted ? cycle.retract < x : x < cycle.retract;
    }
    var driveLine = cycle.retract;
    var threadPasses = getParameter("operation:numberOfStepdowns");
    var threadHeight = getParameter("operation:threadDepth");
    var firstDepthOfCut = threadHeight / threadPasses;
    var repeatPass = hasParameter("operation:nullPass") ? getParameter("operation:nullPass") : 0;
    var threadCrest = external ? x + threadHeight : x - threadHeight;
    var cuttingAngle = 30; // Angle is not stored with tool. toDeg(tool.getTaperAngle());
    if (hasParameter("operation:infeedAngle")) {
      cuttingAngle = getParameter("operation:infeedAngle");
    }
    var p = cycle.pitch;

    // forces "Apply back to front" cycle style to thread from -Z to +Z
    var backFromFront = hasParameter("operation:applyStockOffsetBackFromFront") && (getParameter("operation:applyStockOffsetBackFromFront") === 1);
    var pos = backFromFront ? currentSection.getFinalPosition() : currentSection.getInitialPosition();
    var backZ;
    var frontZ;
    if (backFromFront) {
      backZ = pos.z;
      frontZ = z;
      z = currentSection.getInitialPosition().z;
    } else {
      backZ = z;
      frontZ = pos.z;
    }

    if (pos) {
      writeBlock(xOutput.format(pos.x));
      writeBlock(zOutput.format(frontZ));
    }

    var iVal = threadCrest - driveLine;
    var jVal = firstDepthOfCut;
    var rVal = (getParameter("operation:infeedMode") === "constant") ? 1 : 2;
    var qVal = cuttingAngle;
    var hVal = repeatPass;
    // writeln("p= " + p +  "  driveline= " + driveLine + "  threadCrest= " + threadCrest + "  threadHeight= " + threadHeight);

    writeBlock(
      gMotionModal.format(76),
      pOutput.format(p),
      zOutput.format(backZ),
      iThreadOutput.format(iVal * inverted),
      jThreadOutput.format(jVal),
      kThreadOutput.format(threadHeight),
      rThreadOutput.format(rVal),
      qThreadOutput.format(qVal),
      conditional(hVal, hThreadOutput.format(hVal))
    );
    break;
  case "drilling":
  case "counter-boring":
  case "chip-breaking":
  case "deep-drilling":
  case "reaming":
    expandCyclePoint(x, y, z);
    return;
  case "tapping":
    var threadsPerInch = getParameter("operation:tool_threadPitch"); // per mm for metric
    writeBlock(gMotionModal.format(33.1), zOutput.format(z), kTapOutput.format(threadsPerInch));
    break;
  }
}

function onCycleEnd() {
  if (!cycleExpanded) {
    switch (cycleType) {
    case "thread-turning":
      feedOutput.reset();
      xOutput.reset();
      zOutput.reset();
      break;
    case "drilling":
    case "counter-boring":
    case "chip-breaking":
    case "deep-drilling":
    case "reaming":
      writeBlock(gCycleModal.format(80));
      break;
    case "stock-transfer":
      break;
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
    startSpindle(false, false, getFramePosition(currentSection.getInitialPosition()), spindleSpeed);
  }
}

function startSpindle(tappingMode, forceRPMMode, initialPosition, rpm) {
  var spindleDir;
  var spindleMode;
  var _spindleSpeed = spindleSpeed;
  if (rpm !== undefined) {
    _spindleSpeed = rpm;
  }
  var maxSpeed = "";
  gSpindleModeModal.reset();
  
  if ((getSpindle() == SPINDLE_SECONDARY) && !gotSecondarySpindle) {
    error(localize("Secondary spindle is not available."));
    return;
  }
 
  if (false /*tappingMode*/) {
    spindleDir = getCode("RIGID_TAPPING");
  } else {
    if (getSpindle() == SPINDLE_SECONDARY) {
      spindleDir = tool.clockwise ? getCode("START_SUB_SPINDLE_CW") : getCode("START_SUB_SPINDLE_CCW");
    } else {
      spindleDir = tool.clockwise ? getCode("START_MAIN_SPINDLE_CW") : getCode("START_MAIN_SPINDLE_CCW");
    }
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
      maxSpeed = "D" + rpmFormat.format(maximumSpindleSpeed);
      spindleMode = getCode("CONSTANT_SURFACE_SPEED_ON");
    }
  } else {
    spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF");
  }
  if (getSpindle(true) == SPINDLE_SECONDARY) {
    writeBlock(
      spindleMode,
      maxSpeed,
      sOutput.format(_spindleSpeed),
      spindleDir
    );
  } else {
    writeBlock(
      spindleMode,
      maxSpeed,
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
    return;
  case COMMAND_COOLANT_ON:
    setCoolant(COOLANT_FLOOD);
    return;
  case COMMAND_LOCK_MULTI_AXIS:
    return;
  case COMMAND_UNLOCK_MULTI_AXIS:
    return;
  case COMMAND_START_CHIP_TRANSPORT:
    return;
  case COMMAND_STOP_CHIP_TRANSPORT:
    return;
  case COMMAND_BREAK_CONTROL:
    return;
  case COMMAND_TOOL_MEASURE:
    return;
  case COMMAND_ACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    return;
  case COMMAND_DEACTIVATE_SPEED_FEED_SYNCHRONIZATION:
    return;

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
      error(localize("Secondary spindle not available."));
      break;
    }
    break;
  case COMMAND_SPINDLE_COUNTERCLOCKWISE:
    switch (currentSection.spindle) {
    case SPINDLE_PRIMARY:
      writeBlock(mFormat.format(4));
      break;
    case SPINDLE_SECONDARY:
      error(localize("Secondary spindle not available."));
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
      error(localize("Secondary spindle not available."));
      break;
    }
    break;
  case COMMAND_ORIENTATE_SPINDLE:
    if (getSpindle() == 0) {
      writeBlock(mFormat.format(19)); // use P or R to set angle (optional)
    } else {
      error(localize("Secondary spindle not available."));
    }
    break;
  //case COMMAND_CLAMP: // add support for clamping
  //case COMMAND_UNCLAMP: // add support for clamping
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
    writeBlock(gFormat.format(53), gMotionModal.format(0), "X" + xFormat.format(getProperty("g53HomePositionX"))); // retract
    writeBlock(gFormat.format(53), gMotionModal.format(0), "Z" + zFormat.format(getProperty("g53HomePositionZ"))); // retract
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

  if (hasParameter("operation-strategy") && (getParameter("operation-strategy") == "turningPart")) {
    // handle parting here if desired
  }
}

function onClose() {
  writeln("");

  optionalSection = false;

  onCommand(COMMAND_COOLANT_OFF);
  onCommand(COMMAND_STOP_SPINDLE);

  // we might want to retract in Z before X
  goHomeZ();

  if (getProperty("useG28")) {
    writeBlock(gFormat.format(28));
    xOutput.reset();
    yOutput.reset();
  }

  forceXYZ();
  if (!machineConfiguration.hasHomePositionX() && !machineConfiguration.hasHomePositionY()) {
    // writeBlock(gFormat.format(28)); // return to home
  } else {
    var homeX;
    if (machineConfiguration.hasHomePositionX()) {
      homeX = xOutput.format(machineConfiguration.getHomePositionX());
    }
    var homeY;
    if (yOutput.isEnabled() && machineConfiguration.hasHomePositionY()) {
      homeY = yOutput.format(machineConfiguration.getHomePositionY());
    }
    writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), homeX, homeY, zOutput.format(machineConfiguration.getRetractPlane()));
  }

  onImpliedCommand(COMMAND_END);
  onImpliedCommand(COMMAND_STOP_SPINDLE);
  writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off
  writeln("%");
}

function setProperty(property, value) {
  properties[property].current = value;
}
