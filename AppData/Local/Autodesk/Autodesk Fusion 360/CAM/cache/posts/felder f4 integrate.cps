/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Felder post processor configuration.

  $Revision:$
  $Date:$

  FORKID {B8E29875-2F66-48C2-8304-2D098C415DD5}
*/

description = "Felder F4 Integrate";
vendor = "Felder";
vendorUrl = "https://www.felder-group.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic post for Felder F4 Integrate machines.  Define a Slot Mill cutter to use as a Saw Blade.";

extension = "f4g";
setCodePage("ascii");

capabilities = CAPABILITY_MILLING;
tolerance = spatial(0.002, MM);

highFeedrate = (unit == IN) ? 200 : 5000;
minimumChordLength = spatial(0.01, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = true;
allowedCircularPlanes = 1 << PLANE_XY; // allow XY plane only

// user-defined properties
properties = {
  xRapidRate: {
    title: "X-axis rapid rate",
    description: "The rapid rate for the X-axis in Meters per Minute.",
    type: "number",
    value: 60,
    scope: "post"
  },
  yRapidRate: {
    title: "Y-axis rapid rate",
    description: "The rapid rate for the Y-axis in Meters per Minute.",
    type: "number",
    value: 75,
    scope: "post"
  },
  zRapidRate: {
    title: "Z-axis rapid rate",
    description: "The rapid rate for the Z-axis in Meters per Minute.",
    type: "number",
    value: 23,
    scope: "post"
  },
  safeRetractDistance: {
    title: "Safe retract distance",
    description: "The safe Z value used when rewinding rotary axes.",
    type: "number",
    value: 0,
    scope: "post"
  },
  ignoreSawLeadIn: {
    title: "Ignore saw lead-in/out moves",
    description: "Enable to ignore lead-in/out moves on saw cuts so simulation is consistent with machine movement.  If disabled, the lead-in/out moves must be tangent to the saw cut.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  shiftOrigin: {
    title: "Shift origin to lower left corner",
    description: "Enable to shift the WCS origin to the lower left hand corner of the part.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  workingArea: {
    title: "Working area",
    description: "Define the used working area on machine.",
    type: "string",
    value: "AD1",
    scope: "post"
  },
  outfit: {
    title: "Tool outfit",
    description: "Set the used tool outfit for machining.",
    type: "string",
    value: "Default",
    scope: "post"
  },
  subprogramPath: {
    title: "Output path for subprogram files",
    description: "Specifies the desired output path for subprogram files. The Default is the current output folder",
    type: "string",
    group: 4,
    value: "Default",
    scope: "post"
  },
  useFilesForSubprograms: {
    title: "Create external subprograms",
    description: "Create subprogram files for multi-axis operations.",
    type: "boolean",
    value: true,
    group: 4,
    scope: "post"
  },
  minSubfileLength: {
    title: "Minimum line count of subprogram file",
    description: "Enter the minimum line count to consider for creating a tool path subprogram file.  Setting the value to 0 will create an external subprogram for all multi-axis operations.",
    type: "number",
    value: 10000,
    group: 4,
    scope: "post"
  }
};

var numberOfToolSlots = 9999;

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,=_-";

var gFormat = createFormat({prefix: "G", decimals: 0});
var mFormat = createFormat({prefix: "M", decimals: 0});

var xyzFormat = createFormat({decimals: (unit == MM ? 3 : 4)});
var xFormat = createFormat({decimals: (unit == MM ? 3 : 4)});
var abcFormat = createFormat({decimals: 3, forceDecimal: false, scale: DEG});
var feedFormat = createFormat({decimals: (unit == MM ? 4 : 4)});
var rpmFormat = createFormat({decimals: 0});
var secFormat = createFormat({decimals: 3, forceDecimal: true}); // seconds - range 0.001-1000
var taperFormat = createFormat({decimals: 1, scale: DEG});
var toolFormat = createFormat({decimals: 0});
var feedFormat = createFormat({decimals:(unit == MM ? 0 : 0)});
var subFormat = createFormat({decimals:2, width:2, zeropad:true});

var xOutput = createVariable({prefix: "X"}, xFormat);
var yOutput = createVariable({prefix: "Y"}, xyzFormat);
var zOutput = createVariable({prefix: "Z"}, xyzFormat);
var aOutput = createVariable({prefix: "A"}, abcFormat);
var bOutput = createVariable({prefix: "B"}, abcFormat);
var cOutput = createVariable({prefix: "C"}, abcFormat);
var feedOutput = createVariable({prefix: "F"}, feedFormat);
var sOutput = createVariable({prefix: "S", force: true}, rpmFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var tOutput = createVariable({prefix: " T", force: true}, toolFormat);

// circular output
var iOutput = createReferenceVariable({prefix: "I", force: true}, xyzFormat);
var jOutput = createReferenceVariable({prefix: "J", force: true}, xyzFormat);
var kOutput = createReferenceVariable({prefix: "K"}, xyzFormat);

var gMotionModal = createModal({force: true}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange: function() {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G93-94
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-21
var gCycleModal = createModal({}, gFormat); // modal group 9 // G81, ...
var gRetractModal = createModal({}, gFormat); // modal group 10 // G98-99

var WARNING_WORK_OFFSET = 0;

// collected state
var sequenceNumber;
var currentWorkOffset;
var subProgramNumber = 0;
var strictFace = false;
var invertX = false;
var isWorkingPlane = false;
var virtualPlaneCounter = 0;

var sawIsActive = false;

var sideZero = false;
var sideOne = false;
var sideThree = false;
var sideFour = false;
var sideFive = false;
var sideSix = false;
var previousFaceName = "";

/**
  Writes the specified block.
*/
function writeBlock() {
  writeWords(arguments);
}

function formatComment(text) {
  return "# " + filterText(String(text).toUpperCase(), permittedCommentChars).replace(/[()]/g, "");
}

function formatVirtualPlaneName(text, counter) {
  return " T\"" + filterText(String(text).toUpperCase(), permittedCommentChars).replace(/ /g, "_") + "_" + counter + "\"";
}

/** Output a comment. */

function writeComment(text) {
  writeln(formatComment(text));
}

function onOpen() {
  if (true) { // note: setup your machine here
    var aAxis = createAxis({coordinate: 0, table: false, axis: [-0.766044, 0, 0.642788], range: [-181, 181], preference: 1});
    var cAxis = createAxis({coordinate: 2, table: false, axis: [0, 0, -1], range: [-270, 270], preference: 1});
    machineConfiguration = new MachineConfiguration(aAxis, cAxis);

    setMachineConfiguration(machineConfiguration);
    optimizeMachineAngles2(0); // TCP mode
  }

  if (!machineConfiguration.isMachineCoordinate(0)) {
    aOutput.disable();
  }
  if (!machineConfiguration.isMachineCoordinate(1)) {
    bOutput.disable();
  }
  if (!machineConfiguration.isMachineCoordinate(2)) {
    cOutput.disable();
  }

  sequenceNumber = getProperty("sequenceNumberStart");

  writeln("[HEADER]"); // all programs must start like this
  workpiece = getWorkpiece();
  var xStock = (workpiece.upper.x - workpiece.lower.x);
  var yStock = (workpiece.upper.y - workpiece.lower.y);
  var zStock = (workpiece.upper.z - workpiece.lower.z);
  writeBlock("l=" + xyzFormat.format(xStock));
  writeBlock("h=" + xyzFormat.format(yStock));
  writeBlock("t=" + xyzFormat.format(zStock));
  switch (unit) {
  case IN:
    writeBlock("isinch=1");
    break;
  case MM:
    writeBlock("isinch=0");
    break;
  }
  writeBlock("area=" + getProperty("workingArea"));
  writeBlock("offsetx=0");
  writeBlock("offsety=0");
  writeBlock("offsetz=0");
  writeBlock("rawxm=0");
  writeBlock("rawym=0");
  writeBlock("rawzm=0");
  writeBlock("rawxp=0");
  writeBlock("rawyp=0");
  writeBlock("rawzp=0");
  writeBlock("outfit='" + getProperty("outfit") + "'");
  if (programName) {
    // writeBlock("comment='" + programName + "'");
  }
  if (programComment) {
    writeBlock("comment='" + programComment + "'");
  }
  writeBlock("[/header]");
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

// calculate output feed rate in Meters per Minute, ISO feeds are in MM per Minute
function getFeed(feed) {
  // if (unit == IN) {
  //   return (feed * 25.4) / (currentSection.isMultiAxis() ? 1 : 1000);
  // } else {
  //   return feed / (currentSection.isMultiAxis() ? 1 : 1000);
  // }
  return feed;
}

// calculate output rapid rate in Meters per Minute
function getRapidRate(_x, _y, _z) {
  var xyz = getCurrentPosition();
  var x = xFormat.areDifferent(_x, xyz.x);
  var y = xyzFormat.areDifferent(_y, xyz.y);
  var z = xyzFormat.areDifferent(_z, xyz.z);

  var feed = 100000;
  feed = x ? ((getProperty("xRapidRate") < feed) ? getProperty("xRapidRate") : feed) : feed;
  feed = y ? ((getProperty("yRapidRate") < feed) ? getProperty("yRapidRate") : feed) : feed;
  feed = z ? ((getProperty("zRapidRate") < feed) ? getProperty("zRapidRate") : feed) : feed;
  feed = (feed == 100000) ? getProperty("zRapidRate") : feed;

  return feed;
}

function getWorkPlaneMachineABC(workPlane, rotate) {
  var W = workPlane; // map to global frame
  // Workplane angles are between 0-360 : Beta=B, Alpha=C
  var abc = W.getTurnAndTilt(Y, Z);
  if (abc.y < 0) {
    abc.setY(-abc.y);
    abc.setZ(abc.z + Math.PI);
  }
  if (abc.z < 0) {
    abc.setZ(abc.z + (Math.PI * 2));
  }
  if (abcFormat.format(abc.z) > 270) {
    abc.setZ(abc.z - (Math.PI * 2));
  }

  // TCP mode is supported
  if (rotate) {
    var tcp = true;
    if (tcp) {
      setRotation(W); // TCP mode
    } else {
      var O = machineConfiguration.getOrientation(abc);
      var R = machineConfiguration.getRemainingOrientation(abc, W);
      setRotation(R);
    }
  }
  return abc;
}

var currentFaceNumber = 0;
var currentFaceName = "TOP";

function calculateWorkpiece(section) {
  var workpiece = getWorkpiece();

  // don't shift origin, expand stock to include workplane origin
  if (!getProperty("shiftOrigin")) {
    var xStock = (workpiece.upper.x - workpiece.lower.x);
    var yStock = (workpiece.upper.y - workpiece.lower.y);
    var expansion = new Vector(section.workOrigin.x, section.workOrigin.y, workpiece.lower.z);
    workpiece.expandTo(expansion);

    var upperZ = workpiece.lower.z;
    workpiece = new BoundingBox(
      new Vector(0, 0, -workpiece.upper.z),
      new Vector(workpiece.upper.x, workpiece.upper.y, upperZ)
    );

    // make sure stock does not shrink if workplane origin is positive of the stock origin
    var length = (workpiece.upper.x - workpiece.lower.x);
    var width = (workpiece.upper.y - workpiece.lower.y);
    if (length < xStock || width < yStock) {
      workpiece = new BoundingBox(
        new Vector(workpiece.lower.x, workpiece.lower.y, workpiece.lower.z),
        new Vector(workpiece.lower.x + (length < xStock ? xStock : 0), workpiece.lower.y + (width < yStock ? yStock : 0), workpiece.upper.z)
      );
    }
  }
  return workpiece;
}

function setWorkingSide(forward) {
  var zAxis = forward;
  // var redirectSection = false;
  isWorkingPlane = false;
  var workpiece = calculateWorkpiece(currentSection);
  var W = currentSection.workPlane;
  var zAxis = forward;
  var xAxis = new Vector(1, 0, 0);
  invertX = false;
  var origin;
  if (isSameDirection(zAxis, new Vector(0, 0, 1)) || currentSection.isMultiAxis() || sawIsActive) {
    currentFaceName = currentSection.isMultiAxis() ? "BASE" : "TOP";
    currentFaceNumber = 1;
    isWorkingPlane = (sawIsActive && !isSameDirection(zAxis, new Vector(0, 0, 1)));
    xAxis = new Vector(1, 0, 0);
    zAxis = new Vector(0, 0, 1);
    origin = new Vector(-workpiece.lower.x, -workpiece.lower.y, currentSection.isMultiAxis() ? -workpiece.lower.z : -workpiece.upper.z);
  } else if (isSameDirection(zAxis, new Vector(-1, 0, 0))) {
    xAxis = new Vector(0, -1, 0);
    zAxis = new Vector(-1, 0, 0);
    invertX = true;
    currentFaceNumber = 6;
    currentFaceName = "LEFT";
    origin = new Vector(workpiece.lower.y, -workpiece.lower.z, workpiece.lower.x);
  } else if (isSameDirection(zAxis, new Vector(1, 0, 0))) {
    xAxis = new Vector(0, 1, 0);
    zAxis = new Vector(1, 0, 0);
    currentFaceNumber = 4;
    currentFaceName = "RIGHT";
    origin = new Vector(-workpiece.lower.y, -workpiece.lower.z, -workpiece.upper.x);
  } else if (isSameDirection(zAxis, new Vector(0, -1, 0))) {
    xAxis = new Vector(1, 0, 0);
    zAxis = new Vector(0, -1, 0);
    currentFaceNumber = 3;
    currentFaceName = "FRONT";
    origin = new Vector(-workpiece.lower.x, -workpiece.lower.z, workpiece.lower.y);
  } else if (isSameDirection(zAxis, new Vector(0, 1, 0))) {
    xAxis = new Vector(-1, 0, 0);
    zAxis = new Vector(0, 1, 0);
    invertX = true;
    currentFaceNumber = 5;
    currentFaceName = "BACK";
    origin = new Vector(workpiece.lower.x, -workpiece.lower.z, -workpiece.upper.y);
  } else { // 3+2 operation outside of a predefined face
    if (tool.type != TOOL_DRILL) {
      xAxis = new Vector(1, 0, 0);
      zAxis = new Vector(0, 0, 1);
      currentFaceNumber = 1;
      currentFaceName = "TOP";
      origin = new Vector(-workpiece.lower.x, -workpiece.lower.y, -workpiece.upper.z);
      isWorkingPlane = true;
    } else {
      currentFaceName = "G500";
      return;
    }
  }
  setTranslation(origin);
  var yAxis = Vector.cross(zAxis, xAxis);
  var O = new Matrix(xAxis, yAxis, zAxis);
  var R = O.getTransposed().multiply(W);
  setRotation(R);
}

function onSection() {
  // writeComment(getParameter("operation-comment")); // temp
  cancelTransformation();
  var insertToolCall = isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number);
  sawIsActive = tool.type == TOOL_MILLING_SLOT; // String(tool.description).toUpperCase() == "BLADE";

  workPlaneABC = new Vector(0, 0, 0);

  // define working side and transformations
  setWorkingSide(currentSection.workPlane.forward, false);

  if (insertToolCall) {
    if (tool.number > numberOfToolSlots) {
      warning(localize("Tool number exceeds maximum value."));
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
    (rpmFormat.areDifferent(tool.spindleRPM, sOutput.getCurrent())) ||
    (tool.clockwise != getPreviousSection().getTool().clockwise)) {
    if (tool.spindleRPM < 1) {
      error(localize("Spindle speed out of range."));
    }
    if (tool.spindleRPM > 99999) {
      warning(localize("Spindle speed exceeds maximum value."));
    }
  }

  forceXYZ();
  if (machineConfiguration.isMultiAxisConfiguration() && (currentSection.isMultiAxis() || isWorkingPlane || sawIsActive)) {
    if (!currentSection.isMultiAxis()) {
      workPlaneABC = getWorkPlaneMachineABC(currentSection.workPlane, true);
    }
  }

  forceAny();

  var initialPosition = getFramePosition(currentSection.getInitialPosition());

  if (hasParameter("operation:tool_feedCutting")) {
    feed =  feedOutput.format(getFeed(getParameter("operation:tool_feedCutting")));
  }

  setFormats(currentSection.isMultiAxis());
  if (currentSection.isMultiAxis()) {
    writeBlock(currentFaceName);
    writeComment(getParameter("operation-comment"));
    // Sub program ISO call
    if (getProperty("useFilesForSubprograms")) {
      redirectToBuffer();
    }
    writeWords("G61");
    var abc = currentSection.getInitialToolAxisABC();
    writeBlock("G90 G40 G101", "T" + tool.number,
      xOutput.format(initialPosition.x), yOutput.format(initialPosition.y),  zOutput.format(initialPosition.z),
      aOutput.format(abc.x), cOutput.format(abc.z),
      "S" + tool.spindleRPM + " " + mFormat.format(tool.clockwise ? 3 : 4));
    forceAny();
    sideZero = true;
  } else if (!sawIsActive) {
    if (isWorkingPlane) {
      writeBlock(currentFaceName);
      writeComment(getParameter("operation-comment"));
      if  (tool.type != TOOL_DRILL) {
        writeBlock("G90 G101 T" + tool.number,
          xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), zOutput.format(initialPosition.z),
          "B" + abcFormat.format(workPlaneABC.y) + " C" +  abcFormat.format(workPlaneABC.z),
          "S" + tool.spindleRPM + "U0");
      }
      sideZero = true;
    } else {
      if (!isCannedCycle() && !sawIsActive) {
        writeBlock(currentFaceName);
        writeComment(getParameter("operation-comment"));
        writeBlock("G90 G40 G100 T" + toolFormat.format(tool.number),
          xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), zOutput.format(initialPosition.z),
          "S" + tool.spindleRPM);
        sideZero = true;
      } else if (isCannedCycle() && !sawIsActive) {
        if (currentFaceName == "G500") {
          writeComment(getParameter("operation-comment"));
        } else {
          // drilling with cycle in faces
          writeBlock(currentFaceName);
          writeComment(getParameter("operation-comment"));
          // writeBlock("G90 G40 G100 T" + toolFormat.format(tool.number),
          //   xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), zOutput.format(initialPosition.z),
          //   "S" + tool.spindleRPM);
          // "U0Q0;0;0;0;0;0;0W0;0;0;0;0;0;0");
          sideZero = true;
        }
      }
    }
  }
}

function moveWCS(x, y, z) {
  xOutput.offset = x;
  yOutput.offset = y;
  zOutput.offset = z;
  if (x != 0 && y != 0 && z != 0) {
    strictFace = true;
  } else {
    strictFace = false;
  }
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.001, seconds, 99999.999);
  writeBlock(gFormat.format(4), "P" + secFormat.format(seconds));
}

function onCycle() {
  if (sawIsActive) {
    error(localize("Cycles are not allowed when using a saw blade."));
    return;
  }

  if (currentFaceName == "G500") {
    // drilling with cycle using virtual plane
    var workpiece = getWorkpiece();
    var cyclePoint = getCyclePoint(0);
    cyclePoint.setZ(cycle.stock);
    var cyclePointWorld = currentSection.workPlane.multiply(cyclePoint);
    var origin = Vector.diff(cyclePointWorld, workpiece.lower);
    var abc = getWorkPlaneMachineABC(currentSection.workPlane, false);
    virtualPlaneCounter += 1;
    writeBlock(currentFaceName + formatVirtualPlaneName(getParameter("operation-comment"), virtualPlaneCounter) +
      " X" + xyzFormat.format(origin.x) + " Y" + xyzFormat.format(origin.y) + " Z" + xyzFormat.format(origin.z) +
      " B" + abcFormat.format(abc.y) + " C" +  abcFormat.format(abc.z));
    setTranslation(cyclePoint.getNegated());
  }
}

function isCannedCycle() {
  if (!hasParameter("operation:cycleType") || tool.type != TOOL_DRILL) {
    return false;
  }
  var cycleType = getParameter("operation:cycleType");
  var isCanned = false;
  if (!isWorkingPlane) {
    switch (cycleType) {
    case "drilling":
    case "chip-breaking":
    case "deep-drilling":
      isCanned = true;
      break;
    default:
      isCanned = false;
    }
  } else {
    isCanned = true;
  }
  return isCanned;
}

function onCyclePoint(x, y, z) {
  if (currentFaceName == "G500" && isFirstCyclePoint()) { // TAG: setTranslation in onCycle does not affect the first point
    x += getTranslation().x;
    y += getTranslation().y;
    z += getTranslation().z;
  }

  if (isWorkingPlane || tool.type != TOOL_DRILL) {
    expandCyclePoint(x, y, z);
    return;
  }
  var F = getFeed(cycle.feedrate);
  var P = (cycle.dwell == 0) ? 0 : clamp(0.001, cycle.dwell, 99999.999); // in seconds

  switch (cycleType) {
  case "tapping":
  case "left-tapping":
  case "right-tapping":
    error(localize("Tapping is not supported"));
    return;
  case "back-boring":
    error(localize("Back boring is not supported"));
    return;
  case "drilling":
    writeBlock("G81 " +  xOutput.format(x), yOutput.format(y), zOutput.format(z),
      "T" + toolFormat.format(tool.number),
      feedOutput.format(F), sOutput.format(tool.spindleRPM));
    break;
  case "counter-boring":
    expandCyclePoint(x, y, z);
    break;
  case "chip-breaking":
    if ((cycle.accumulatedDepth < cycle.depth) || (P > 0)) {
      expandCyclePoint(x, y, z);
    } else {
      writeBlock("G81 " +  xOutput.format(x), yOutput.format(y), zOutput.format(z),
        "T" + toolFormat.format(tool.number),
        feedOutput.format(F), sOutput.format(tool.spindleRPM));
    }
    break;
  case "deep-drilling":
    writeBlock("G81 " +  xOutput.format(x), yOutput.format(y), zOutput.format(z),
      "T" + toolFormat.format(tool.number),
      feedOutput.format(F), sOutput.format(tool.spindleRPM));
    break;
  default:
    expandCyclePoint(x, y, z);
  }
}

function onCycleEnd() {
  if (!cycleExpanded) {
    zOutput.reset();
  }
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

function onRapid(_x, _y, _z) {
  if (sawIsActive) {
    flushSawMove(getCurrentPosition(), sawCuttingFeed);
    return;
  }
  var feed = getRapidRate(_x, _y, _z);
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = feedOutput.format(feed);
  var current = getCurrentPosition();
  if ((xFormat.areDifferent(current.x, _x) || xyzFormat.areDifferent(current.y, _y) || xyzFormat.areDifferent(current.z, _z)) &&
    !isCannedCycle()) {
    writeBlock(gMotionModal.format(0), x, y, z);
    // feedOutput.reset();
  }
}

function onLinear(_x, _y, _z, feed) {
  if (sawIsActive) {
    linearSawMove(_x, _y, _z, feed);
    return;
  }

  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = feedOutput.format(getFeed(feed));
  var current = getCurrentPosition();

  if ((xFormat.areDifferent(current.x, _x) || xyzFormat.areDifferent(current.y, _y) || xyzFormat.areDifferent(current.z, _z))) {
    if (pendingRadiusCompensation >= 0) {
      var invert = false;
      if (currentFaceName == "LEFT" || currentFaceName == "BACK") {invert = true;}
      pendingRadiusCompensation = -1;
      var d = tool.diameterOffset;
      if (d > 99) {
        warning(localize("The diameter offset exceeds the maximum value."));
      }
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        if (invert) {
          writeBlock(gFormat.format(42), gMotionModal.format(1),  x, y, z, f);
        } else {
          writeBlock(gFormat.format(41), gMotionModal.format(1),  x, y, z, f);
        }
        break;
      case RADIUS_COMPENSATION_RIGHT:
        if (invert) {
          writeBlock(gFormat.format(41), gMotionModal.format(1),  x, y, z, f);
        } else {
          writeBlock(gFormat.format(42), gMotionModal.format(1),  x, y, z, f);
        }
        break;
      default:
        writeBlock(gFormat.format(40), gMotionModal.format(1),  x, y, z, f);
      }
    } else {
      writeBlock(gMotionModal.format(1), x, y, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      feedOutput.reset(); // force feed on next line
    } else {
      feedOutput.reset(); // force feed on next line
    }
  }
}

var sawMoveType = MOVEMENT_RAPID;
var sawDirection;
var sawPreviousPosition;
var sawCuttingFeed;
function linearSawMove(_x, _y, _z, feed) {
  var moveDirection = Vector.diff(new Vector(_x, _y, _z), getCurrentPosition()).getNormalized();
  if (movement == MOVEMENT_LEAD_IN) { // buffer lead-in move and save direction
    if (getProperty("ignoreSawLeadIn")) {
      sawPreviousPosition = new Vector(_x, _y, _z);
      return;
    }
    sawPreviousPosition = getCurrentPosition();
    sawMoveType = MOVEMENT_LEAD_IN;
    sawDirection = moveDirection;
    return;
  } else if (movement == MOVEMENT_LEAD_OUT) { // check lead-out direction and flush motion
    if (getProperty("ignoreSawLeadIn") && sawMoveType != MOVEMENT_CUTTING) {
      return;
    }
    sawMoveType = MOVEMENT_LEAD_OUT;
    if (getProperty("ignoreSawLeadIn")) {
      flushSawMove(getCurrentPosition(), sawCuttingFeed);
      return;
    } else if (Vector.diff(moveDirection, sawDirection).length > toPreciseUnit(0.001, IN)) {
      error(localize("Lead-out direction does not match cut direction."));
    } else {
      flushSawMove(new Vector(_x, _y, _z), sawCuttingFeed);
    }
    return;
  } else if ((movement != MOVEMENT_CUTTING) && (movement != MOVEMENT_FINISH_CUTTING) && (movement != MOVEMENT_REDUCED)) { // ignore non-cutting moves
    sawPreviousPosition = new Vector(_x, _y, _z);
    return;
  }

  // cutting move
  if (sawMoveType == MOVEMENT_LEAD_IN) { // check lead-in direction
    if (Vector.diff(moveDirection, sawDirection).length > toPreciseUnit(0.001, IN)) {
      error(localize("Lead-in direction does not match cut direction."));
      return;
    }
  } else if (sawMoveType == MOVEMENT_CUTTING) { // flush consecutive cutting motions
    // buffer moves in same direction
    if (Vector.diff(moveDirection, sawDirection).length > toPreciseUnit(0.001, IN)) {
      flushSawMove(getCurrentPosition(), sawCuttingFeed);
      sawMoveType = MOVEMENT_CUTTING;
    }
  }

  // buffer cutting move in case of lead-out move
  sawPreviousPosition = sawPreviousPosition == undefined ? getCurrentPosition() : sawPreviousPosition;
  sawDirection = Vector.diff(new Vector(_x, _y, _z), sawPreviousPosition).getNormalized();
  sawCuttingFeed = feed;
  sawMoveType = MOVEMENT_CUTTING;
}

var sawOffset = 1; // -1 = offset from saw to line, 0 = no offset, 1 = offset from line to saw
function flushSawMove(_xyz, feed) {
  if (sawMoveType == MOVEMENT_RAPID) { // nothing to output
    return;
  }

  // saw cuts require that the tool be on the profile line
  var start = new Vector(sawPreviousPosition.x, sawPreviousPosition.y, sawPreviousPosition.z);
  var end = new Vector(_xyz.x, _xyz.y, _xyz.z);
  var offsetVector = new Vector(0, 0, 0);
  var compDir = 0;
  var entryFeed = hasParameter("operation:tool_feedEntry") ? getParameter("operation:tool_feedEntry") : feed;

  var dir = getParameter("operation:compensation") == "left" ? -1 : 1;

  // horizontal saw cut
  if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))) {
    var workpiece = calculateWorkpiece(currentSection);
    if (dir == -1) {
      zAxis = Vector.cross(currentSection.workPlane.forward, sawDirection);
    } else {
      zAxis = Vector.cross(sawDirection, currentSection.workPlane.forward);
    }
    var x;
    var y;
    var z;
    var endX;
    var face;
    var toolRadius = tool.diameter / 2;
    if (getParameter("operation:compensationType") == "control") {
      error(localize("Cannot calculate workplane for horizontal saw cut."));
      return;
    }
    if (isSameDirection(zAxis, new Vector(-1, 0, 0))) { // face 6
      face = 6;
      currentFaceName = "LEFT";
      x = start.y;
      endX = end.y;
      y = -(start.x + toolRadius);
      z = start.z + (workpiece.upper.z - workpiece.lower.z);
    } else if (isSameDirection(zAxis, new Vector(1, 0, 0))) { // face 4
      face = 4;
      currentFaceName = "RIGHT";
      x = start.y;
      endX = end.y;
      y = start.x - toolRadius - (workpiece.upper.x - workpiece.lower.x);
      z = start.z + (workpiece.upper.z - workpiece.lower.z);
    } else if (isSameDirection(zAxis, new Vector(0, -1, 0))) { // face 3
      face = 3;
      currentFaceName = "FRONT";
      x = start.x;
      endX = end.x;
      y = -(start.y + toolRadius);
      z = start.z + (workpiece.upper.z - workpiece.lower.z);
    } else if (isSameDirection(zAxis, new Vector(0, 1, 0))) { // face 5
      face = 5;
      currentFaceName = "BACK";
      x = start.x;
      endX = end.x;
      y = start.y - toolRadius - (workpiece.upper.y - workpiece.lower.y);
      z = start.z + (workpiece.upper.z - workpiece.lower.z);
    } else {
      var debug = false;
      var leadIn = getParameter("operation:entry_distance", toUnit(0.1, IN));
      leadIn = leadIn == 0 ? toUnit(0.1, IN) : leadIn;
      // leadin not in radius direction
      if (dir == -1) {
        offsetVector = Vector.cross(currentSection.workPlane.forward, sawDirection).getNormalized();
      } else {
        offsetVector = Vector.cross(sawDirection, currentSection.workPlane.forward).getNormalized();
      }
      // calculate plane rotation
      var angle = Math.atan2(offsetVector.y, offsetVector.x);
      var mx = Matrix.getZRotation(angle).getTransposed();
 
      // calculate start/end moves at outer edge of saw, adjust for the lead-in move
      var offset = (tool.diameter / 2) - leadIn;
      // var offset = -leadIn;
      var xyzStart = Vector.sum(start, Vector.product(offsetVector.negated, offset));
      var xyzEnd = Vector.sum(end, Vector.product(offsetVector.negated, offset));

      // calculate origin in TOP wcs
      var origin = new Vector(xyzStart.x, xyzStart.y, 0);

      if (debug) {
        writeln("offsetVector = " + offsetVector.getNormalized());
        writeln("offset = " + offset);
        writeln("start = " + start);
        writeln("end = " + end);
        writeln("shiftedStart = " + xyzStart);
        writeln("shiftedEnd = " + xyzEnd);
      }
      // move start and end points based on new origin
      xyzStart = Vector.diff(xyzStart, origin);
      xyzEnd = Vector.diff(xyzEnd, origin);

      // rotate saw move to plane of cut
      var xyzStart = mx.multiply(xyzStart);
      var xyzEnd = mx.multiply(xyzEnd);
      if (debug) {
        writeln("rotatedStart = " + xyzStart);
        writeln("rotatedEnd = " + xyzEnd);
      }
      writeBlock("TOP");
      virtualPlaneCounter += 1;
      currentFaceName = gFormat.format(500)  + formatVirtualPlaneName(getParameter("operation-comment"), virtualPlaneCounter) +
      " X" + xyzFormat.format(origin.x) + " Y" + xyzFormat.format(origin.y) +
        " Z" + xyzFormat.format(0) + " B" + abcFormat.format(toRad(90)) + " C" + abcFormat.format(angle);
    
      x = Math.abs(xyzStart.x) * dir;
      endX = Math.abs(xyzEnd.x) * dir;
  
      y = -leadIn; // xyzStart.y;
      z = start.z + (workpiece.upper.z - workpiece.lower.z);
    }

    // horizontal saw cuts must be in postive direction
    var reverseX = 0;
    if (x < endX) {
      var temp = x;
      x = endX;
      endX = temp;
      reverseX = 1;
    }

    // Z-depth is a center of groove
    z += (tool.fluteLength / 2);
    // flip cutting direction for left and back face when comp right is used
    var reverseComp;
    if (currentFaceName == "LEFT" || currentFaceName == "BACK") {
      reverseComp = dir == -1 ? "L1" : "L0";
    } else {
      reverseComp = dir == -1 ? "L0" : "L1";
    }

    writeBlock(currentFaceName);
    writeComment(getParameter("operation-comment"));
    writeBlock("G111" + tOutput.format(tool.number),
      "X" + xOutput.format(x) + ";" + xyzFormat.format(endX), // starting X, ending X
      "Y" + yOutput.format(z) + ";" + xyzFormat.format(z), // center of cut along Z-axis of Face 1
      "Z" + zOutput.format(y),  // depth of cut
      reverseComp, // cutting direction
      "D40",
      "S" + tool.spindleRPM + " F" + feedFormat.format(feed) + " H" + feedFormat.format(entryFeed)
    );
    sawPreviousPosition = new Vector(_xyz.x, _xyz.y, _xyz.z);
    sawMoveType = MOVEMENT_RAPID;
    return;
  }

  if (hasParameter("operation:compensationType") && hasParameter("operation:compensation")) {
    
    // for saw cuts, conventional (left) cutting must be used
    // reverse direction of cut if (right) cutting is specified

    if (getParameter("operation:compensationType") != "control") {
      var dir = "left";
      if (getParameter("operation:compensation") == "right") {
        var temp = new Vector(start.x, start.y, start.z);
        start = new Vector(end.x, end.y, end.z);
        end = new Vector(temp.x, temp.y, temp.z);
        sawDirection.negate();
      }
      // if (dir == "right") {
      //   offsetVector = Vector.product(Vector.cross(currentSection.workPlane.forward, sawDirection).getNormalized(), (tool.diameter / 2));
      // } else if (getParameter("operation:compensation") == "left") {
      offsetVector = Vector.product(Vector.cross(sawDirection, currentSection.workPlane.forward).getNormalized(), (tool.diameter / 2));
      // }
      start = Vector.sum(start, offsetVector);
      end = Vector.sum(end, offsetVector);
    }
    // calculate compensation direction based on bottom of cutter
    // var compDir = 0;
    // var crossVec = Vector.cross(new Vector(0, 0, 1), sawDirection).getNormalized();
    // var dir = Vector.dot(currentSection.workPlane.forward, crossVec);
    // if (sawOffset == -1) {
    //   compDir = dir < 0 ? 41 : 42;
    // } else if (sawOffset == 1) {
    //   compDir = dir < 0 ? 42 : 41;
    // }
  }

  var beta = workPlaneABC.y < 0 ? Math.PI + workPlaneABC.y : workPlaneABC.y;
  // beta = toRad(90) - beta;
  beta -= toRad(90);
  
  var xyVector = new Vector(offsetVector.x, offsetVector.y, 0).normalized;
  var startX = start.x + (Math.tan(beta) * (Math.abs(start.z) * xyVector.x));
  var endX = end.x + (Math.tan(beta) * (Math.abs(end.z) * xyVector.x));
  var startY = start.y + (Math.tan(beta) * (Math.abs(start.z) * xyVector.y));
  var endY = end.y + (Math.tan(beta) * (Math.abs(end.z) * xyVector.y));
  var x = xOutput.format(endX);
  var y = yOutput.format(endY);

  var f = feedOutput.format(getFeed(feed));

  if (x || y) {
    var xyMove = true;
    var yMove = xyzFormat.areDifferent(sawPreviousPosition.y, _xyz.y) && !xyMove;
    var entryFeed = hasParameter("operation:tool_feedEntry") ? getParameter("operation:tool_feedEntry") : feed;
    if (abcFormat.getResultingValue(workPlaneABC.z) >= 180) {
      workPlaneABC.setZ(workPlaneABC.z - Math.PI);
      workPlaneABC.setY(workPlaneABC.y - Math.PI);
    }
    writeBlock(currentFaceName);
    writeComment(getParameter("operation-comment"));

    writeBlock("G111" + tOutput.format(tool.number),
      "X" + xOutput.format(startX) + ";" + conditional(!yMove, x),
      "Y" + yOutput.format(startY) + ";" + conditional((xyMove || yMove), y),
      "Z" + zOutput.format(start.z),
      conditional(xyMove, "B" + abcFormat.format(-beta)), // beta angle (B-axis)
      ((getParameter("operation:compensation")) != "left" ? "L1" : "L0"),
      /*"D"*+ compDir,*/
      "D40",
      "S" + tool.spindleRPM + " F" + feedFormat.format(feed) + " H" + feedFormat.format(entryFeed)
    );

    // writeBlock("G111" + tOutput.format(tool.number),
    //   "X" + xOutput.format(startX) + ";" + conditional(!yMove, x),
    //   "Y" + yOutput.format(startY) + ";" + conditional((xyMove || yMove), y),
    //   "Z" + zOutput.format(start.z),
    //   conditional(xyMove, "B" + abcFormat.format(beta)), // beta angle (B-axis)
    //   /*"D"*+ compDir,*/
    //   "D40",
    //   "S" + tool.spindleRPM + " F" + feedFormat.format(feed) + " H" + feedFormat.format(entryFeed)
    // );
  }
  sawPreviousPosition = new Vector(_xyz.x, _xyz.y, _xyz.z);
  sawMoveType = MOVEMENT_RAPID;
}

function onRapid5D(_x, _y, _z, _a, _b, _c) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(_a);
  var b = bOutput.format(_b);
  var c = cOutput.format(_c);
  writeBlock(gMotionModal.format(0), x, y, z, a, b, c);
  feedOutput.reset();
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(_a);
  var b = bOutput.format(_b);
  var c = cOutput.format(_c);
  var f = feedOutput.format(getFeed(feed));
  if (x || y || z || a || b || c) {
    writeBlock(gMotionModal.format(1), x, y, z, a, b, c, f);
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      feedOutput.reset(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(1), f);
    }
  }
}

function setFormats(multiAxis) {
  xFormat = createFormat({decimals: (unit == MM ? 3 : 4), scale: (invertX ? -1 : 1)});
  if (multiAxis) {
    xOutput = createVariable({prefix: "X"}, xFormat);
    yOutput = createVariable({prefix: "Y"}, xyzFormat);
    zOutput = createVariable({prefix: "Z"}, xyzFormat);
    aOutput = createVariable({prefix: "A"}, abcFormat);
    cOutput = createVariable({prefix: "C"}, abcFormat);
    iOutput = createReferenceVariable({prefix: "I", force: true}, xFormat);
    feedOutput = createVariable({prefix: "F"}, feedFormat);
  } else if (sawIsActive) {
    xOutput = createVariable({force: true}, xFormat);
    yOutput = createVariable({force: true}, xyzFormat);
    zOutput = createVariable({force: true}, xyzFormat);
  } else {
    xOutput = createVariable({prefix: "X", force: true}, xFormat);
    yOutput = createVariable({prefix: "Y", force: true}, xyzFormat);
    zOutput = createVariable({prefix: "Z", force: true}, xyzFormat);
    aOutput = createVariable({prefix: "A", force: true}, abcFormat);
    cOutput = createVariable({prefix: "C", force: true}, abcFormat);
    iOutput = createReferenceVariable({prefix: "I", force: true}, xFormat);
    feedOutput = createVariable({prefix: "F"}, feedFormat);
  }
}

// Start of onRewindMachine logic
/***** Be sure to add 'safeRetractDistance' to post getProperty(" ")*****/
var performRewinds = true; // enables the onRewindMachine logic
var safeRetractFeed = (unit == IN) ? 20 : 1500;
var safePlungeFeed = (unit == IN) ? 10 : 1000;
var stockAllowance = new Vector(toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN));

/** Allow user to override the onRewind logic. */
function onRewindMachineEntry(_a, _b, _c) {
  return false;
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
  }

  // Move to retract position
  var position;
  if (currentSection.getOptimizedTCPMode() == 0) {
    position = retractPosition;
  } else {
    position = machineConfiguration.getOrientation(getCurrentDirection()).getTransposed().multiply(retractPosition);
  }
  onExpandedLinear(position.x, position.y, position.z, safeRetractFeed);

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
  if (sawIsActive) {
    linearize(tolerance);
    return;
  }
  var start = getCurrentPosition();
  var dir = clockwise ? (invertX ? 3 : 2) : (invertX ? 2 : 3);
  var invert = false;
  if (currentFaceName == "LEFT" || currentFaceName == "BACK") {invert = true;}

  if (isFullCircle()) {
    if (isHelical()) {
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(dir), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0),  feedOutput.format(getFeed(feed)));
      break;
    default:
      linearize(tolerance);
    }
  } else {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(dir), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0),  feedOutput.format(getFeed(feed)));
      break;
    default:
      linearize(tolerance);
    }
  }
}

function onSectionEnd() {
  if (sawIsActive) { // Saw blade redirection
    flushSawMove(getCurrentPosition(), sawCuttingFeed);
  } else if (isRedirecting()) { // Multi-axis redirection
    var redirectedLines = (String(getRedirectionBuffer()).split(EOL));
    closeRedirection();
    if (redirectedLines.length > getProperty("minSubfileLength")) {
      var fileName = FileSystem.getFilename(FileSystem.replaceExtension(getOutputPath(), "xxx").split(".xxx", 1));
      var subName = fileName + subFormat.format(subProgramNumber) + ".iso";
      var path = FileSystem.getFolderPath(getOutputPath());
      if (getProperty("subprogramPath").toUpperCase() != "DEFAULT") {
        path = FileSystem.getCombinedPath(path, getProperty("subprogramPath"));
        if (!FileSystem.isFolder(path)) {
          FileSystem.makeFolder(path);
        }
      }
      path = FileSystem.getCombinedPath(path, subName);
      subProgramNumber += 1;
      // subprogram ISO call
      writeBlock(gFormat.format(105), xOutput.format(0), yOutput.format(0), zOutput.format(0) + " P\"" + path + "\"" + "T" + tool.number);
      setFormats(true);
      redirectToFile(path);
      for (line in redirectedLines) {
        if (redirectedLines[line].indexOf("G61") == -1 && redirectedLines[line].indexOf("G101") == -1) {
          writeBlock(redirectedLines[line]);
        }
      }
      writeBlock(gFormat.format(60));
      writeBlock(mFormat.format(2));
      closeRedirection();
    } else {
      for (line in redirectedLines) {
        writeBlock(redirectedLines[line]);
      }
      writeBlock(gFormat.format(60));
    }
  }
  forceAny();
}

function onClose() {
}

function setProperty(property, value) {
  properties[property].current = value;
}
