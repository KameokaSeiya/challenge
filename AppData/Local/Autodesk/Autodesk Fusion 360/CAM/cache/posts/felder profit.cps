/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Felder post processor configuration.

  $Revision: 43260 4f43db8214a8a35867cc776ccb63688a3ad5bbaa $
  $Date: 2021-05-12 10:32:38 $
  
  FORKID {6DE9880B-F0EF-4A26-98F9-A1712182565B}
*/

description = "Felder Profit";
vendor = "Felder";
vendorUrl = "https://www.felder-group.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic post for Felder Profit machines.  Define a Slot Mill cutter to use as a Saw Blade.";

extension = "tcn";
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
allowedCircularPlanes = undefined; // allow any circular motion

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
  homePositionX: {
    title: "X-axis home position",
    description: "Home position in X when a Stop command is programmed.",
    type: "number",
    value: 0,
    scope: "post"
  },
  homePositionY: {
    title: "Y-axis home position",
    description: "Home position in Y when a Stop command is programmed.",
    type: "number",
    value: 0,
    scope: "post"
  },
  useDrillToolNumber: {
    title: "Output the tool number for drilling operations",
    description: "Enable to output the tool number for drilling operations.  Normally required if using a drill head.",
    type: "boolean",
    value: false,
    scope: "post"
  },
};

var numberOfToolSlots = 9999;

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,=_-";

var gFormat = createFormat({prefix: "G", decimals: 0});
var mFormat = createFormat({prefix: "M", decimals: 0});

var xyzFormat = createFormat({decimals: (unit == MM ? 3 : 4)});
var xFormat = createFormat({decimals: (unit == MM ? 3 : 4)});
var abcFormat = createFormat({decimals: 3, forceDecimal: true, scale: DEG});
var feedFormat = createFormat({decimals: (unit == MM ? 4 : 4)});
var diameterFormat = createFormat({decimals: (unit == MM ? 3 : 4)});
var rpmFormat = createFormat({decimals: 0});
var secFormat = createFormat({decimals: 3, forceDecimal: true}); // seconds - range 0.001-1000
var taperFormat = createFormat({decimals: 1, scale: DEG});
var toolFormat = createFormat({decimals: 0});
var subFormat = createFormat({decimals:2, width:2, zeropad:true});

var xOutput = createVariable({prefix: "#1=", force: true}, xFormat);
var yOutput = createVariable({prefix: "#2=", force: true}, xyzFormat);
var zOutput = createVariable({prefix: "#3=", force: true}, xyzFormat);
var aOutput = createVariable({prefix: "#5=", force: true}, abcFormat);
var bOutput = createVariable({prefix: "B"}, abcFormat);
var cOutput = createVariable({prefix: "#4=", force: true}, abcFormat);
var feedOutput = createVariable({prefix: "#2008="}, feedFormat);
var sOutput = createVariable({prefix: "S", force: true}, rpmFormat);

// circular output
var iOutput = createReferenceVariable({prefix: "#31=", force: true}, xyzFormat);
var jOutput = createReferenceVariable({prefix: "#32=", force: true}, xyzFormat);

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
var holeCounter = 1;
var subProgramNumber = 0;
var firstCut = false;
var strictFace = false;
var invertX = false;
var isWorkingPlane = false;
var originalUnit;

var sawIsActive = false;

var sideZero = false;
var sideOne = false;
var sideThree = false;
var sideFour = false;
var sideFive = false;
var sideSix = false;

/**
  Writes the specified block.
*/
function writeBlock() {
  writeWords(arguments);
}

function formatComment(text) {
  return "$=" + filterText(String(text).toUpperCase(), permittedCommentChars).replace(/[()]/g, "");
}

/** Output a comment. */

function writeComment(text) {
  writeln(formatComment(text));
}

function onOpen() {
  originalUnit = unit;
  
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

  writeln("TPA\\ALBATROS\\EDICAD\\01.00:74:r0w0"); // all programs must start like this

  if (programName) {
    writeComment(programName);
  }
  if (programComment) {
    writeComment(programComment);
  }
  var sideList = "::SIDE=0;";
  writeln(sideList);
  workpiece = calculateWorkpiece(getSection(0));
  var xStock = (workpiece.upper.x - workpiece.lower.x);
  var yStock = (workpiece.upper.y - workpiece.lower.y);
  var zStock = (workpiece.upper.z - workpiece.lower.z);

  switch (unit) {
  case IN:
    writeBlock("::UNi", "DL=" + xyzFormat.format(xStock), "DH=" + xyzFormat.format(yStock), "DS=" + xyzFormat.format(zStock));
    break;
  case MM:
    writeBlock("::UNm", "DL=" + xyzFormat.format(xStock), "DH=" + xyzFormat.format(yStock), "DS=" + xyzFormat.format(zStock));
    break;
  }
  writeBlock("VAR{");
  writeBlock("}VAR");
  writeBlock("OPTI{");
  writeBlock("}OPTI");
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
  if (unit == IN) {
    return (feed * 25.4) / (currentSection.isMultiAxis() ? 1 : 1000);
  } else {
    return feed / (currentSection.isMultiAxis() ? 1 : 1000);
  }
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

function getWorkPlaneMachineABC(workPlane) {
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

var currentFaceNumber = 0;

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
    origin = new Vector(workpiece.lower.y, -workpiece.lower.z, workpiece.lower.x);
  } else if (isSameDirection(zAxis, new Vector(1, 0, 0))) {
    xAxis = new Vector(0, 1, 0);
    zAxis = new Vector(1, 0, 0);
    currentFaceNumber = 4;
    origin = new Vector(-workpiece.lower.y, -workpiece.lower.z, -workpiece.upper.x);
  } else if (isSameDirection(zAxis, new Vector(0, -1, 0))) {
    xAxis = new Vector(1, 0, 0);
    zAxis = new Vector(0, -1, 0);
    currentFaceNumber = 3;
    origin = new Vector(-workpiece.lower.x, -workpiece.lower.z, workpiece.lower.y);
  } else if (isSameDirection(zAxis, new Vector(0, 1, 0))) {
    xAxis = new Vector(-1, 0, 0);
    zAxis = new Vector(0, 1, 0);
    invertX = true;
    currentFaceNumber = 5;
    origin = new Vector(workpiece.lower.x, -workpiece.lower.z, -workpiece.upper.y);
  } else { // 3+2 operation outside of a predefined face
    currentFaceNumber = 1;
    xAxis = new Vector(1, 0, 0);
    zAxis = new Vector(0, 0, 1);
    origin = new Vector(-workpiece.lower.x, -workpiece.lower.y, -workpiece.upper.z);
    isWorkingPlane = true;
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
  var cutterComp = 0;
  var retracted = false; // specifies that the tool has been retracted to the safe plane
  sawIsActive = tool.type == TOOL_MILLING_SLOT; // String(tool.description).toUpperCase() == "BLADE";

  if (isFirstSection()) {
    writeln("SIDE#0{");
  }

  workPlaneABC = new Vector(0, 0, 0);

  // define working side and transformations
  setWorkingSide(currentSection.workPlane.forward, false);

  firstCut = false;
  retracted = false;

  if (insertToolCall) {
    retracted = true;
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
    (rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) ||
    (tool.clockwise != getPreviousSection().getTool().clockwise)) {
    if (spindleSpeed < 1) {
      error(localize("Spindle speed out of range."));
    }
    if (spindleSpeed > 99999) {
      warning(localize("Spindle speed exceeds maximum value."));
    }
  }

  forceXYZ();
  if (machineConfiguration.isMultiAxisConfiguration() && (currentSection.isMultiAxis() || isWorkingPlane || sawIsActive)) {
    if (!currentSection.isMultiAxis()) {
      workPlaneABC = getWorkPlaneMachineABC(currentSection.workPlane);
    }
  }

  forceAny();

  var initialPosition = getFramePosition(currentSection.getInitialPosition());

  if (hasParameter("operation:compensationType") && (getParameter("operation:compensationType") == "control")) {
    if (hasParameter("operation:compensation") && (getParameter("operation:compensation") == "left")) {
      cutterComp = 1;
    }
    if (hasParameter("operation:compensation") && (getParameter("operation:compensation") == "right")) {
      cutterComp = 2;
    } else {
      cutterComp = 0;
    }
  }
  if (hasParameter("operation:tool_feedCutting")) {
    feed = getFeed(getParameter("operation:tool_feedCutting"));
  }

  setFormats(currentSection.isMultiAxis());
  if (currentSection.isMultiAxis()) {
    unit = MM; // ISO files must be output in MM
    // Sub program ISO call
    var fileName = FileSystem.getFilename(FileSystem.replaceExtension(getOutputPath(), "xxx").split(".xxx", 1));
    var subName = fileName + subFormat.format(subProgramNumber) + ".iso";
    var path = FileSystem.getCombinedPath(FileSystem.getFolderPath(getOutputPath()), subName);
    subProgramNumber += 1;
    // subprogram ISO call
    writeBlock("W#1110{ ::WT2 WF=" + currentFaceNumber, "WS=1 #8098=..\\custom\\mcr\\iso.tmcr #8500=0 #8501=" + subName + " #8502=0 #8504=0 #8505=1 #8520=1 #8522=" + tool.number + " #8551=1 }W");
    redirectToFile(path);
    sideZero = true;
  } else if (!sawIsActive) {
    if (isWorkingPlane) {
      writeBlock(
        "W#203{::WTs WF=1", // header
        "#8015=0", // absolute
        xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), zOutput.format(initialPosition.z), // initial position
        "#201=1", "#203=1", // required parameters (machine, group)
        "#205=" + toolFormat.format(tool.number), // tool number
        "#1001=100", // tool type (must be 100)
        "#5=" + abcFormat.format(workPlaneABC.y), "#4=" + abcFormat.format(workPlaneABC.z), // rotary axes position
        "#9521=0", // rotation direction 0=default, 1=left, 2 = right
        "#47=1", // mandatory parameters
        "#9514=0", // DN4AX - 0 = interpolating axis
        "#2005=" + feedFormat.format(feed), // cutting feed
        "#2002=" + rpmFormat.format(spindleSpeed), // spindle speed
        "#9511=0", "#9512=0", // nesting geometry, 0 = disabled
        "#9513=0", // 1 = use chip deflector
        "#9520=0", // 0 = disable Z layer application, 1 = enable
        "#9515=0", // Z value of layer application
        "#9516=1", // 1 = Z value is absolute and NOT in direction of beta angle
        "#9517=0", // 0 = correction not active, 1 = correction above, 2 = correction below
        "}W"
      );
      sideZero = true;
    } else {
      if (!isCannedCycle() && !sawIsActive) {
        writeBlock(
          "W#89{", "::WTs WF=" + currentFaceNumber, "#201=1",
          "#2002=" + rpmFormat.format(spindleSpeed),
          "#2005=" + feedFormat.format(feed),
          "#203=1", "#8015=0",
          "#205=" + (tool.number),
          "#40=" + cutterComp,
          xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), zOutput.format(initialPosition.z),
          "}W"
        );
        sideZero = true;
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
}

function isCannedCycle() {
  if (!hasParameter("operation:cycleType")) {
    return false;
  }
  var cycleType = getParameter("operation:cycleType");
  var isCanned = false;
  if (!isWorkingPlane) {
    switch (cycleType) {
    case "drilling":
    case "counter-boring":
    case "chip-breaking":
    case "deep-drilling":
      isCanned = true;
      break;
    default:
      isCanned = false;
    }
  }
  return isCanned;
}

function onCyclePoint(x, y, z) {
  if (isWorkingPlane) {
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
  case "counter-boring":
    writeBlock("W#81{ ::WTp WF=" + currentFaceNumber, "#8015=0",
      xOutput.format(x), yOutput.format(y), zOutput.format(z),
      "#1002=" + diameterFormat.format(tool.diameter), "#201=1 #203=1",
      conditional(getProperty("useDrillToolNumber"), ("#205=" + tool.number)),
      "#2005=" + feedFormat.format(F), "#2002=" + rpmFormat.format(spindleSpeed),
      "}W");
    break;
  case "chip-breaking":
    if ((cycle.accumulatedDepth < cycle.depth) || (P > 0)) {
      expandCyclePoint(x, y, z);
    } else {
      writeBlock("W#85{ ::WTp WF=" + currentFaceNumber, "#8015=0",
        xOutput.format(x), yOutput.format(y), zOutput.format(z),
        "#9520=" + xyzFormat.format(cycle.incrementalDepth),
        "#1002=" + diameterFormat.format(tool.diameter), "#201=1 #203=1",
        conditional(getProperty("useDrillToolNumber"), ("#205=" + tool.number)),
        "#2005=" + feedFormat.format(F), "#2002=" + rpmFormat.format(spindleSpeed),
        "}W");
    }
    break;
  case "deep-drilling":
    writeBlock("W#85{ ::WTp WF=" + currentFaceNumber, "#8015=0",
      xOutput.format(x), yOutput.format(y), zOutput.format(z),
      "#9520=" + xyzFormat.format(cycle.incrementalDepth),
      "#1002=" + diameterFormat.format(tool.diameter), "#201=1 #203=1",
      conditional(getProperty("useDrillToolNumber"), ("#205=" + tool.number)),
      "#2005=" + feedFormat.format(F), "#2002=" + rpmFormat.format(spindleSpeed),
      "}W");
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
    if (isRedirecting()) {
      writeBlock(gMotionModal.format(0), x, y, z);
    } else {
      writeBlock("W#2201{", "::WTl WF=" + currentFaceNumber, x, y, z, "#8015=0", f, "}W");
    }

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
    if (currentSection.isMultiAxis()) {
      writeBlock(gMotionModal.format(1), x, y, z, f);
    } else {
      writeBlock("W#2201{", "::WTl WF=" + currentFaceNumber, x, y, z, "#8015=0", f, "}W");
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

  // horizontal saw cut
  if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))) {
    var workpiece = calculateWorkpiece(currentSection);
    zAxis = Vector.cross(currentSection.workPlane.forward, sawDirection);
    var x;
    var y;
    var z;
    var endX;
    var face;
    var toolRadius = tool.diameter / 2;
    if (isSameDirection(zAxis, new Vector(-1, 0, 0))) { // face 6
      face = 6;
      x = start.y;
      endX = end.y;
      y = start.x + toolRadius;
      z = start.z;
    } else if (isSameDirection(zAxis, new Vector(1, 0, 0))) { // face 4
      face = 4;
      x = start.y;
      endX = end.y;
      y = start.x - toolRadius - (workpiece.upper.x - workpiece.lower.x);
      z = start.z;
    } else if (isSameDirection(zAxis, new Vector(0, -1, 0))) { // face 3
      face = 3;
      x = start.x;
      endX = end.x;
      y = start.y + toolRadius;
      z = start.z;
    } else if (isSameDirection(zAxis, new Vector(0, 1, 0))) { // face 5
      face = 5;
      x = start.x;
      endX = end.x;
      y = start.y - toolRadius - (workpiece.upper.y - workpiece.lower.y);
      z = start.z;
    } else {
      error(localize("Horizontal saw cuts must be along a predefined (2-5) face."));
      return;
    }

    // horizontal saw cuts must be in postive direction
    var reverseX = 0;
    if (x > endX) {
      var temp = x;
      x = endX;
      endX = temp;
      reverseX = 1;
    }

    // Z-depth is a center of groove
    z += (tool.fluteLength / 2);

    writeBlock("W#1505"  + "{", "::WT2 WF=1"); // standard header
    writeBlock("#8098=..\\custom\\mcr\\horizzontalblade.tmcr"); // standard macro
    writeBlock("#8500=" + tool.number); // tool number
    writeBlock("#8501=" + xyzFormat.format(x)); // starting X
    writeBlock("#8502=" + xyzFormat.format(endX)); // ending X
    writeBlock("#8503=" + xyzFormat.format(z)); // center of cut along Z-axis of Face 1
    writeBlock("#8504=0"); // // tool compensation direction, 0 = none, 1 = left, 2 = right
    writeBlock("#8506=" + xyzFormat.format(Math.abs(y))); // depth of cut
    writeBlock("#8510=" + face); // face number
    writeBlock("#8511=" + reverseX); // 1 = invert path (xend -> xstart)
    writeBlock("}W");
    sawPreviousPosition = new Vector(_xyz.x, _xyz.y, _xyz.z);
    sawMoveType = MOVEMENT_RAPID;
    return;
  }

  if (hasParameter("operation:compensationType") && hasParameter("operation:compensation")) {
    // for saw cuts, conventional (right) cutting must be used
    // reverse direction of cut if climb (left) cutting is specified
    if (getParameter("operation:compensationType") != "control") {
      var dir = "right";
      if (getParameter("operation:compensation") == "left") {
        var temp = new Vector(start.x, start.y, start.z);
        start = new Vector(end.x, end.y, end.z);
        end = new Vector(temp.x, temp.y, temp.z);
        sawDirection.negate();
      }
      if (dir == "right") {
        offsetVector = Vector.product(Vector.cross(currentSection.workPlane.forward, sawDirection).getNormalized(), (tool.diameter / 2));
      } else if (getParameter("operation:compensation") == "left") {
        offsetVector = Vector.product(Vector.cross(sawDirection, currentSection.workPlane.forward).getNormalized(), (tool.diameter / 2));
      }
      start = Vector.sum(start, offsetVector);
      end = Vector.sum(end, offsetVector);
    }

    // calculate compensation direction based on bottom of cutter
    var compDir = 0;
    var crossVec = Vector.cross(new Vector(0, 0, 1), sawDirection).getNormalized();
    var dir = Vector.dot(currentSection.workPlane.forward, crossVec);
    if (sawOffset == -1) {
      compDir = dir < 0 ? 1 : 2;
    } else if (sawOffset == 1) {
      compDir = dir < 0 ? 2 : 1;
    }
  }

  var beta = workPlaneABC.y < 0 ? Math.PI + workPlaneABC.y : workPlaneABC.y;
  // var zDepth = abcFormat.getResultingValue(Math.cos(beta)) == 0 ? start.z : start.z / Math.cos(beta); // not used when ZABS = 1 (#8508)

  var x = xOutput.format(end.x);
  var y = yOutput.format(end.y);
  var f = feedOutput.format(getFeed(feed));

  if (x || y) {
    // var xyMove = (xyzFormat.areDifferent(sawPreviousPosition.x, _xyz.x) && xyzFormat.areDifferent(sawPreviousPosition.y, _xyz.y)) || isWorkingPlane;
    var xyMove = true;
    var yMove = xyzFormat.areDifferent(sawPreviousPosition.y, _xyz.y) && !xyMove;
    var sawCode = xyMove ? "1052" : (yMove ? "1051" : "1050");
    var entryFeed = hasParameter("operation:tool_feedEntry") ? getParameter("operation:tool_feedEntry") : feed;
    if (abcFormat.getResultingValue(workPlaneABC.z) >= 180) {
      workPlaneABC.setZ(workPlaneABC.z - Math.PI);
      workPlaneABC.setY(workPlaneABC.y - Math.PI);
    }
    writeBlock("W#" + sawCode  + // 1050 = X, 1051 = Y, 1052 = XY
      "{", "::WT2 WS=1"); // standard header
    writeBlock("#8098=..\\custom\\mcr\\iso.tmcr"); // standard macro
    writeBlock("#6=1"); // face selection, must be 1
    writeBlock("#8503=0"); // width of cut, 0 = 1 cut
    writeBlock(conditional(xyMove, "#8504=subang")); // must be set to 'subang'
    writeBlock(conditional(xyMove, "#8507=" + xyzFormat.format(start.z /*zDepth*/))); // Z-position of XY coordinates
    writeBlock(conditional(xyMove, "#8508=1")); // absolute Z
    writeBlock("#8509=2"); // saw type, must be set to 2
    writeBlock("#8510=" + xyzFormat.format(start.x)); // starting X
    writeBlock("#8511=" + xyzFormat.format(start.y)); // starting Y
    writeBlock("#8512=" + xyzFormat.format(start.z /*zDepth*/)); // Z-depth in direction of Beta angle
    writeBlock("#8514=1"); // machine, must be 1
    writeBlock("#8515=1"); // group, must be 1
    writeBlock("#8516=" + tool.number); // tool number
    writeBlock(conditional(!yMove, x)); // ending X
    writeBlock(conditional((xyMove || yMove), y)); // ending Y
    writeBlock(conditional(xyMove, "#8519=" + abcFormat.format(0))); // alpha angle (C-axis) (automatic when #8533=1)
    writeBlock(conditional(xyMove, "#8521=" + abcFormat.format(beta))); // beta angle (B-axis)
    writeBlock("#8522=" + rpmFormat.format(spindleSpeed)); // spindle speed
    writeBlock("#8523=" + f); // feed rate
    writeBlock("#8524=" + feedFormat.format(getFeed(entryFeed))); // entry feed
    writeBlock("#8525=" + compDir); // tool compensation direction, 0 = none, 1 = left, 2 = right
    writeBlock("#8526=0"); // 0 = single depth, 1 = two step depth
    writeBlock("#8527=0"); // 1 = calculate bow-string for starting point
    // conditional(xyMove, "#8531=0"), // 1 = defined as nesting geometry
    // conditional(xyMove, "#8532=0"), // 1 = defined as leftover area for nesting geometry
    writeBlock(conditional(xyMove, "#8533=1")); // 1 = enable XY final position (modul and alpha angle are automatic)
    writeBlock("}W");
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
    xOutput = createVariable({prefix: "X", force: true}, xFormat);
    yOutput = createVariable({prefix: "Y", force: true}, xyzFormat);
    zOutput = createVariable({prefix: "Z", force: true}, xyzFormat);
    aOutput = createVariable({prefix: "A", force: true}, abcFormat);
    cOutput = createVariable({prefix: "C", force: true}, abcFormat);
    iOutput = createReferenceVariable({prefix: "#31=", force: true}, xFormat);
    feedOutput = createVariable({prefix: "F"}, feedFormat);
  } else if (sawIsActive) {
    xOutput = createVariable({prefix: "#8517=", force: true}, xFormat);
    yOutput = createVariable({prefix: "#8518=", force: true}, xyzFormat);
    zOutput = createVariable({prefix: "#8512=", force: true}, xyzFormat);
    aOutput = createVariable({prefix: "#8521=", force: true}, abcFormat);
    cOutput = createVariable({prefix: "#8519=", force: true}, abcFormat);
    feedOutput = createVariable({force:true}, feedFormat);
  } else {
    xOutput = createVariable({prefix: "#1=", force: true}, xFormat);
    yOutput = createVariable({prefix: "#2=", force: true}, xyzFormat);
    zOutput = createVariable({prefix: "#3=", force: true}, xyzFormat);
    aOutput = createVariable({prefix: "#5=", force: true}, abcFormat);
    cOutput = createVariable({prefix: "#4=", force: true}, abcFormat);
    iOutput = createReferenceVariable({prefix: "#31=", force: true}, xFormat);
    feedOutput = createVariable({prefix: "#2008="}, feedFormat);
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
  var dir = clockwise ? (invertX ? 1 : 0) : (invertX ? 0 : 1);

  if (isFullCircle()) {
    if (isHelical()) {
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock("W#2101{", "::WTa", xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), "#34=" + dir, "#8015=0", feedOutput.format(getFeed(feed)), "}W");
      break;
    default:
      linearize(tolerance);
    }
  } else {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock("W#2101{", "::WTa", xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), "#34=" + dir, "#8015=0", feedOutput.format(getFeed(feed)), "}W");
      break;
    default:
      linearize(tolerance);
    }
  }
}

function onCommand(command) {
  switch (command) {
  case COMMAND_STOP:
    writeBlock(
      "W#102{", "::WTg",
      "WF=" + currentFaceNumber,
      xOutput.format(getProperty("homePositionX")),
      yOutput.format(getProperty("homePositionY")),
      "#205=" + toolFormat.format(tool.number),
      "#9505=99",
      "}W"
    );
    break;
  }
}

function onSectionEnd() {
  if (sawIsActive) { // Saw blade redirection
    flushSawMove(getCurrentPosition(), sawCuttingFeed);
  } else if (isRedirecting()) { // Multi-axis redirection
    closeRedirection();
    unit = originalUnit;
  }
  forceAny();
}

function onClose() {
  zOutput.reset();
  writeBlock("$=F #0");
  writeBlock("}SIDE");
  writeBlock("SIDE#1 {");
  writeBlock("$=F #1");
  writeBlock("}SIDE");
  writeBlock("SIDE#3 {");
  writeBlock("$=F #3");
  writeBlock("}SIDE");
  writeBlock("SIDE#4 {");
  writeBlock("$=F #4");
  writeBlock("}SIDE");
  writeBlock("SIDE#5 {");
  writeBlock("$=F #5");
  writeBlock("}SIDE");
  writeBlock("SIDE#6 {");
  writeBlock("$=F #6");
  writeBlock("}SIDE");
}

function setProperty(property, value) {
  properties[property].current = value;
}
