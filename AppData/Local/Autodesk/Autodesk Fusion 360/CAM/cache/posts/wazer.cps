/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Wazer Waterjet post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {4734A7A2-732D-4843-BB24-F241D705D5FC}
*/

description = "Wazer Waterjet";
vendor = "Wazer";
vendorUrl = "http://www.wazer.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic post for Wazer waterjet.";

extension = "gcode";
setCodePage("ascii");

capabilities = CAPABILITY_JET;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = false;
allowedCircularPlanes = 0; // no arcs

// user-defined properties
properties = {
  writeMachine: {
    title: "Write machine",
    description: "Output the machine settings in the header of the code.",
    group: 2,
    type: "boolean",
    value: true,
    scope: "post"
  },
  showSequenceNumbers: {
    title: "Use sequence numbers",
    description: "Use sequence numbers for each block of outputted code.",
    group: 2,
    type: "boolean",
    value: false,
    scope: "post"
  },
  sequenceNumberStart: {
    title: "Start sequence number",
    description: "The number at which to start the sequence numbers.",
    group: 2,
    type: "integer",
    value: 10,
    scope: "post"
  },
  sequenceNumberIncrement: {
    title: "Sequence number increment",
    description: "The amount by which the sequence number is incremented by in each block.",
    group: 2,
    type: "integer",
    value: 5,
    scope: "post"
  },
  separateWordsWithSpace: {
    title: "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    group: 1,
    type: "boolean",
    value: true,
    scope: "post"
  },
  softwareVersion: {
    title: "Software Version",
    description: "Specifies the WAM software version.",
    group: 1,
    type: "number",
    value: 1.2,
    scope: "post"
  },
  material: {
    title: "Material",
    description: "Specifies the material to make use of the feed/speed database. Choose -Custom- to use pierceTime and feedrate Properties.",
    type: "enum",
    group: 0,
    values: [
      {title: "Stainless Steel 316", id: "StainlessSteel316"},
      {title: "Steel 4130", id: "Steel4130"},
      {title: "Aluminum 6061", id: "Aluminum6061"},
      {title: "Custom", id: "custom"}
    ],
    value: "StainlessSteel316",
    scope: "post"
  },
  pierceTime: {
    title: "Pierce time",
    description: "Specifies the pierce time if material type -Custom- is selected.",
    group: 1,
    type: "number",
    value: 0,
    scope: "post"
  },
  feedrate: {
    title: "Feedrate",
    description: "Specifies the feedrate if material type -Custom- is selected.",
    group: 1,
    type: "number",
    value: 0,
    scope: "post"
  }
};

var feedSpeedDatabase = [ // all values are defined in INCH
  {id: "StainlessSteel316", thickness: 0.016, pierceTime: 4, speedFineRate: 2.250, speedRoughRate: 2.893},
  {id: "StainlessSteel316", thickness: 0.031, pierceTime: 4, speedFineRate: 1.380, speedRoughRate: 1.774},
  {id: "StainlessSteel316", thickness: 0.063, pierceTime: 10, speedFineRate: 0.846, speedRoughRate: 1.087},
  {id: "StainlessSteel316", thickness: 0.125, pierceTime: 45, speedFineRate: 0.518, speedRoughRate: 0.667},
  {id: "Steel4130", thickness: 0.016, pierceTime: 3, speedFineRate: 2.247, speedRoughRate: 2.888},
  {id: "Steel4130", thickness: 0.031, pierceTime: 4, speedFineRate: 1.404, speedRoughRate: 1.805},
  {id: "Steel4130", thickness: 0.036, pierceTime: 5, speedFineRate: 1.278, speedRoughRate: 1.643},
  {id: "Steel4130", thickness: 0.048, pierceTime: 7, speedFineRate: 1.053, speedRoughRate: 1.353},
  {id: "Steel4130", thickness: 0.063, pierceTime: 11, speedFineRate: 0.878, speedRoughRate: 1.128},
  {id: "Steel4130", thickness: 0.125, pierceTime: 44, speedFineRate: 0.549, speedRoughRate: 0.705},
  {id: "Aluminum6061", thickness: 0.016, pierceTime: 2, speedFineRate: 7.970, speedRoughRate: 10.248},
  {id: "Aluminum6061", thickness: 0.031, pierceTime: 2, speedFineRate: 4.340, speedRoughRate: 5.580},
  {id: "Aluminum6061", thickness: 0.063, pierceTime: 6, speedFineRate: 2.363, speedRoughRate: 3.038},
  {id: "Aluminum6061", thickness: 0.125, pierceTime: 22, speedFineRate: 1.287, speedRoughRate: 1.654},
  {id: "Aluminum6061", thickness: 0.188, pierceTime: 46, speedFineRate: 0.902, speedRoughRate: 1.159},
  {id: "Aluminum6061", thickness: 0.250, pierceTime: 79, speedFineRate: 0.701, speedRoughRate: 0.901}
];

var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"M", decimals:0});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 3), forceDecimal:true, trim:false});
var abcFormat = createFormat({decimals:3, forceDecimal:true, scale:DEG});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-1000
var feedFormat = createFormat({decimals:(unit == MM ? 3 : 3), forceDecimal:true, trim: false});

var xOutput = createVariable({prefix:"X", force: true}, xyzFormat);
var yOutput = createVariable({prefix:"Y", force: true}, xyzFormat);
var zOutput = createVariable({prefix:"Z"}, xyzFormat);
var aOutput = createVariable({prefix:"A"}, abcFormat);
var bOutput = createVariable({prefix:"B"}, abcFormat);
var cOutput = createVariable({prefix:"C"}, abcFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);

// circular output
var iOutput = createReferenceVariable({prefix:"I", force:true}, xyzFormat);
var jOutput = createReferenceVariable({prefix:"J", force:true}, xyzFormat);
var kOutput = createReferenceVariable({prefix:"K", force:true}, xyzFormat);

var gMotionModal = createModal({force:true}, gFormat); // modal group 1 // G0-G3, ...
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-22

// collected state
var sequenceNumber;

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
  return ";" + String(text).replace(/[()]/g, "");
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

var pierceTime;
var tableFeedrate;
var materialThickness = undefined;
var quality = undefined;

function getMaterialThickness (section) {
  if (hasGlobalParameter("stock-lower-z") && hasGlobalParameter("stock-upper-z")) {
    materialThickness = xyzFormat.format(Math.abs(getGlobalParameter("stock-lower-z") - getGlobalParameter("stock-upper-z")));
  } else {
    error(localize("Stock is not defined into your setup."));
    return undefined;
  }
  return materialThickness;
}

function getCuttingData(section) {
  materialThickness = getMaterialThickness(section);

  if (getProperty("material") == "custom") {
    pierceTime = getProperty("pierceTime");
    tableFeedrate = getProperty("feedrate");
    quality = "Custom";
  } else {
    var thickness;
    for (var c in feedSpeedDatabase) {
      thickness = (unit == MM ? feedSpeedDatabase[c].thickness * 25.4 : feedSpeedDatabase[c].thickness);
      if (feedSpeedDatabase[c].id == getProperty("material")) {
        if (materialThickness / thickness >= 1) { // find closest material thickness
          pierceTime = feedSpeedDatabase[c].pierceTime;
          getTableFeedrate(c, section);
        } else { // material thickness is less than minimum thickness in the database
          pierceTime = feedSpeedDatabase[c].pierceTime;
          getTableFeedrate(c, section);
          return;
        }
      }
    }
  }
}

function getTableFeedrate(c, section) {
  switch (section.quality) {
  case 1: // fine
    tableFeedrate = feedSpeedDatabase[c].speedFineRate;
    quality = "Fine";
    break;
  case 2: // medium
    tableFeedrate = feedSpeedDatabase[c].speedFineRate + ((feedSpeedDatabase[c].speedRoughRate - feedSpeedDatabase[c].speedFineRate) / 2);
    quality = "Medium";
    break;
  case 3: // rough
    tableFeedrate = feedSpeedDatabase[c].speedRoughRate;
    quality = "Rough";
    break;
  default:
    // medium quality as default
    tableFeedrate = feedSpeedDatabase[c].speedFineRate + ((feedSpeedDatabase[c].speedRoughRate - feedSpeedDatabase[c].speedFineRate) / 2);
    quality = "Medium";
  }
  if (unit == MM) {
    tableFeedrate *= 25.4;
  }
  return tableFeedrate;
}

function onOpen() {
  if (getProperty("material") != "custom" && (getProperty("pierceTime") != 0 || getProperty("feedrate") != 0)) {
    writeComment("Warning: The properties -Pierce Time- and / or -Feedrate- are only used if the property -material- is set to -Custom-.");
  }
  getCuttingData(getSection(0));
  zOutput.disable();

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");

  /*
  if (programName) {
    writeComment(programName);
  }
*/
  if (programComment) {
    writeComment(programComment);
  }

  var cuttingTime = 0;
  var rapidTime = 0;
  var totalTime = 0;
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    var rapidFeedrate = (unit == MM ? 1905 : 75);
    var cuttingDistance = section.getCuttingDistance();
    var rapidDistance = section.getRapidDistance();
    cuttingTime += (cuttingDistance / tableFeedrate * 60);
    rapidTime += (rapidDistance / rapidFeedrate * 60);
  }
  totalTime = (cuttingTime + rapidTime);

  if (hasGlobalParameter("document-path")) {
    var documentPath = getGlobalParameter("document-path");
  }
  writeComment("-------------------------------Cut file parameters------------------------");
  writeComment("Input file name : " + documentPath);
  writeComment("Material name : " + getProperty("material"));
  writeComment("Material thickness : " + getMaterialThickness(getSection(0)) + (unit == MM ? "MM" : "IN"));
  writeComment("Cut Time: " + formatCycleTime(totalTime));
  writeComment("-------------------------------Do not modify the Gcode file---------------");
  
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

  // absolute coordinates and feed per min
  writeBlock(gAbsIncModal.format(90));

  switch (unit) {
  case IN:
    writeBlock(gUnitModal.format(20));
    break;
  case MM:
    writeBlock(gUnitModal.format(21));
    break;
  }

  var stock = getWorkpiece();
  writeBlock(mFormat.format(1403)); // initialize pumps
  writeBlock(mFormat.format(1405), "X" + xyzFormat.format(stock.lower.x), "Y" + xyzFormat.format((stock.upper.y))); // get job top left corner points
  writeBlock(mFormat.format(1406), "X" + xyzFormat.format(stock.upper.x), "Y" + xyzFormat.format((stock.lower.y)));  // get bottom right corner points
  writeBlock(mFormat.format(1407), "S" + pierceTime); // pierce time-based on the selected material
  writeBlock(mFormat.format(1410), getProperty("softwareVersion")); // software version number
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
}

function onParameter(name, value) {
}

var currentWorkPlaneABC = undefined;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
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
    return new Vector();
  }
  
  if (!machineConfiguration.isABCSupported(abc)) {
    error(
      localize("Work plane is not supported") + ":"
      + conditional(machineConfiguration.isMachineCoordinate(0), " A" + abcFormat.format(abc.x))
      + conditional(machineConfiguration.isMachineCoordinate(1), " B" + abcFormat.format(abc.y))
      + conditional(machineConfiguration.isMachineCoordinate(2), " C" + abcFormat.format(abc.z))
    );
  }

  var tcp = false;
  if (tcp) {
    setRotation(W); // TCP mode
  } else {
    var O = machineConfiguration.getOrientation(abc);
    var R = machineConfiguration.getRemainingOrientation(abc, W);
    setRotation(R);
  }
  
  return abc;
}

function formatCycleTime(cycleTime) {
  cycleTime += 0.5; // round up
  var seconds = cycleTime % 60 | 0;
  var minutes = ((cycleTime - seconds) / 60 | 0) % 60;
  var hours = (cycleTime - minutes * 60 - seconds) / (60 * 60) | 0;
  if (hours > 0) {
    return subst(localize("%1h:%2m:%3s"), hours, minutes, seconds);
  } else if (minutes > 0) {
    return subst(localize("%1m:%2s"), minutes, seconds);
  } else {
    return subst(localize("%1s"), seconds);
  }
}

function onSection() {
  getCuttingData(currentSection);
  writeln("");
  
  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment(comment);
    }
  }

  if (hasParameter("operation:compensation")) {
    writeComment("Cut path : " + getParameter("operation:compensation"));
  }

  if (quality) {
    writeComment("Cut quality : " + quality);
  }

  switch (tool.type) {
  case TOOL_WATER_JET:
    break;
  default:
    error(localize("The CNC does not support the required tool/process. Only water jet cutting is supported."));
    return;
  }
  
  switch (currentSection.jetMode) {
  case JET_MODE_THROUGH:
    break;
  case JET_MODE_ETCHING:
    error(localize("Etch cutting mode is not supported."));
    break;
  case JET_MODE_VAPORIZE:
    error(localize("Vaporize cutting mode is not supported."));
    break;
  default:
    error(localize("Unsupported cutting mode."));
    return;
  }
  
  { // pure 3D
    var remaining = currentSection.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported."));
      return;
    }
    setRotation(remaining);
  }

  forceAny();

  // var initialPosition = getFramePosition(currentSection.getInitialPosition());
  // writeBlock(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y));
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.001, seconds, 99999.999);
  writeBlock(gFormat.format(4), "S" + secFormat.format(seconds));
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
  error(localize("Radius compensation is not supported."));
  return;
}

function onPower(power) {
  if (power) {
    writeBlock(mFormat.format(3));
    writeBlock(mFormat.format(8));
    writeBlock(gFormat.format(4), "S" + secFormat.format(pierceTime));
  } else {
    var endPauseScaleVariable = 0.15;
    writeBlock(gFormat.format(4), "S" + secFormat.format(endPauseScaleVariable * pierceTime));
    writeBlock(mFormat.format(9));
    writeBlock(gFormat.format(4), "S" + secFormat.format(1));
    writeBlock(mFormat.format(5));
    writeBlock(gFormat.format(4), "S" + secFormat.format(1));
    writeln("");
  }
}

function onRapid(_x, _y, _z) {
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
  // at least one axis is required
  if (pendingRadiusCompensation >= 0) {
    // ensure that we end at desired position when compensation is turned off
    xOutput.reset();
    yOutput.reset();
  }
  var f = feedOutput.format(tableFeedrate ? tableFeedrate : feed);

  var maximumLineLength = toPreciseUnit(5, MM);
  var startXYZ = getCurrentPosition();
  var endXYZ = new Vector(_x, _y, _z);

  var length = Vector.diff(startXYZ, endXYZ).length;
  if (length > maximumLineLength) {
    var numberOfSegments = Math.max(Math.ceil(length / maximumLineLength), 1);
    for (var i = 1; i <= numberOfSegments; ++i) {
      var p = Vector.lerp(startXYZ, endXYZ, i * 1.0 / numberOfSegments);
      var x = xOutput.format(p.x);
      var y = yOutput.format(p.y);
      writeBlock(gMotionModal.format(1), x, y, f);
      setCurrentPosition(p);
    }
  } else {
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    if (x || y) {
      if (pendingRadiusCompensation >= 0) {
        pendingRadiusCompensation = -1;
        switch (radiusCompensation) {
        case RADIUS_COMPENSATION_LEFT:
          writeBlock(gMotionModal.format(1), gFormat.format(41), x, y, f);
          break;
        case RADIUS_COMPENSATION_RIGHT:
          writeBlock(gMotionModal.format(1), gFormat.format(42), x, y, f);
          break;
        default:
          writeBlock(gMotionModal.format(1), gFormat.format(40), x, y, f);
        }
      } else {
        writeBlock(gMotionModal.format(1), x, y, f);
      }
    }
  }
}

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
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

var mapCommand = {
  COMMAND_STOP:0,
  COMMAND_OPTIONAL_STOP:1
};

function onCommand(command) {
  switch (command) {
  case COMMAND_POWER_ON:
    return;
  case COMMAND_POWER_OFF:
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
  feedOutput.reset();
}

function onClose() {
  writeBlock(mFormat.format(1404));
}

function setProperty(property, value) {
  properties[property].current = value;
}
