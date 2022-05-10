/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Result file generator probing and inspect surface

  $Revision: 43242 ddd07ea94d66036c6e5eff33f114d8012616601a $
  $Date: 2021-05-05 23:16:41 $
  
  FORKID {FF934B58-50E7-0763-431D-17ECD207B2CD}
*/

description = "Results file generator for probing and inspect surface";
vendor = "Autodesk";
vendorUrl = "http://www.autodesk.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;
 
longDescription = "Exports probing and inspection toolpaths as a mock results file.";

extension = "txt";
if (getCodePage() == 932) { // shift-jis is not supported
  setCodePage("ascii");
} else {
  setCodePage("ansi"); // setCodePage("utf-8");
}

capabilities = CAPABILITY_SETUP_SHEET;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(90);
probeMultipleFeatures = true;

properties = {
  pointDeviation: {
    title: "Point deviation allowance",
    description: "Specifies point deviation allowance.",
    group: 0,
    value: 0.1,
    scope: "post"
  },
  sizeDeviation: {
    title: "Size deviation allowance",
    description: "Specifies size deviation allowance.",
    group: 0,
    value: 0.1,
    scope: "post"
  },
  angleDeviation: {
    title: "Angle deviation allowance",
    description: "Specifies angle deviation allowance.",
    group: 0,
    value: 0.1,
    scope: "post"
  },
  positionDeviation: {
    title: "Position deviation allowance",
    description: "Specifies position deviation allowance.",
    group: 0,
    value: 0.1,
    scope: "post"
  }
};

// fixed settings
var maximumLineLength = 80; // the maximum number of charaters allowed in a line
const xAxis = 1;
const yAxis = 2;
const zAxis = 4;

// collected state
var pointNumber = 1;
var xyzFormat = createFormat({decimals:(unit == MM ? 4 : 5), forceDecimal:true});
var abcFormat = createFormat({decimals:(unit == MM ? 4 : 5), forceDecimal:true, scale:DEG});
var ijkFormat = createFormat({decimals:(unit == MM ? 6 : 8), forceDecimal:true});
var commentStart = ";";
var commentEnd = "";
var nominalXYZrot = new Vector();
var normalizedVector = new Vector();
var measuredXYZ = new Vector();
var currentMachineABC;
// var realRadius = 0;

function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }
  writeWords(arguments);
}

function formatComment(text) {
  return commentStart + String(text).replace(/[()]/g, "") + commentEnd;
}

function writeComment(text) {
  writeln(formatComment(text.substr(0, maximumLineLength - 2)));
}

function isProbeInUse() {
  for (var i = 0; i < getNumberOfSections(); ++i) {
    const sectionTool = getSection(i).getTool().type;
    if (sectionTool == TOOL_PROBE) {

      return true;
    }
  }
  return false;
}

// Create a random, signed deviation value within maxDeviation
function createRandomDeviation(maxDeviation) {
  const sign = Math.round(Math.random()) == 0 ? -1 : 1;
  const randomDeviation = sign * Math.random() * maxDeviation;
  return randomDeviation;
}

// Calculate the error for the size/angle
function getDirectionalError(dev, tol) {
  return dev - dev * tol / Math.abs(dev);
}

// Calculate length of 2D segment
function hypot(a, b) {
  return Math.sqrt(a * a + b * b);
}

// Calculate the radial error for the position
function getPositionError(devX, devY, tol) {
  const errorX = Math.abs(devX) - tol;
  const errorY = Math.abs(devY) - tol;
  return hypot(errorX, errorY);
}

// Add some random deviation to the size and display all data correctly
function randomSize(expectedSize) {
  const deviation = createRandomDeviation(getProperty("sizeDeviation"));
  const actualSize = expectedSize + deviation;
  // If deviation is greater than the tolerance and the stop action is set,
  // show tolerance and error message
  if (Math.abs(deviation) > cycle.toleranceSize && hasParameter("wrongSizeAction")) {
    // Size with tolerance shown
    writeBlock(
      "SIZE D" + xyzFormat.format(expectedSize),
      "  ACTUAL " + xyzFormat.format(actualSize),
      "  TOL " + xyzFormat.format(cycle.toleranceSize),
      "  DEV " + xyzFormat.format(deviation)
    );
    const error = getDirectionalError(deviation, cycle.toleranceSize);
    // Error value shown with error message
    writeBlock("\n          +++++OUT OF TOL+++++ ERROR ", xyzFormat.format(error) + "\n");
  } else {
    // Size without tolerance shown
    writeBlock(
      "SIZE D" + xyzFormat.format(expectedSize),
      "  ACTUAL " + xyzFormat.format(actualSize),
      "  DEV " + xyzFormat.format(deviation)
    );
  }
}

// Add some random deviation to the angle and display all data correctly
function randomAngle(expectedAngle) {
  const deviation = createRandomDeviation(getProperty("angleDeviation"));
  const actualAngle = expectedAngle + deviation;
  // If deviation is greater than the tolerance and the stop action is set,
  // show tolerance and error message
  if (Math.abs(deviation) > cycle.toleranceAngle && hasParameter("angleAskewAction")) {
    // Size with tolerance shown
    writeBlock(
      "ANG " + xyzFormat.format(expectedAngle),
      "  ACTUAL " + xyzFormat.format(actualAngle),
      "  TOL " + xyzFormat.format(cycle.toleranceAngle),
      "  DEV " + xyzFormat.format(deviation)
    );
    const error = getDirectionalError(deviation, cycle.toleranceAngle);
    // Error value shown with error message
    writeBlock("\n          +++++ANG OUT OF TOL+++++ ERROR ", xyzFormat.format(error) + "\n");
  } else {
    // Size without tolerance shown
    writeBlock(
      "ANG " + xyzFormat.format(expectedAngle),
      "  ACTUAL " + xyzFormat.format(actualAngle),
      "  DEV " + xyzFormat.format(deviation)
    );
  }
}

// Add some random deviation to the position and display all data correctly
function randomPosition(expectedX, expectedY, axisFlags) {
  const xFlag = axisFlags & xAxis;
  const yFlag = axisFlags & yAxis;
  const deviationX = xFlag ? createRandomDeviation(getProperty("positionDeviation")) : 0.0;
  const actualX = expectedX + deviationX;
  const deviationY = yFlag ? createRandomDeviation(getProperty("positionDeviation")) : 0.0;
  const actualY = expectedY + deviationY;
  // If either deviation is greater than the tolerance and the stop action is set,
  // show tolerance and error message
  if ((Math.abs(deviationX) > cycle.tolerancePosition || Math.abs(deviationY) > cycle.tolerancePosition) &&
      hasParameter("outOfPositionAction")) {
    // X position with tolerance shown
    writeBlock(
      "POSN X" + xyzFormat.format(expectedX),
      "  ACTUAL " + (xFlag ? xyzFormat.format(actualX) : "NaN"),
      "  TOL TP " + xyzFormat.format(cycle.tolerancePosition),
      "  DEV " + (xFlag ? xyzFormat.format(deviationX) : "NaN")
    );
    // Y position with tolerance shown
    writeBlock(
      "POSN Y" + xyzFormat.format(expectedY),
      "  ACTUAL " + (yFlag ? xyzFormat.format(actualY) : "NaN"),
      "  TOL TP " + xyzFormat.format(cycle.tolerancePosition),
      "  DEV " + (yFlag ? xyzFormat.format(deviationY) : "NaN")
    );
    const errorRadial = getPositionError(deviationX, deviationY, cycle.tolerancePosition);
    // Radial error value shown with error message
    writeBlock(
      "\n          +++++OUT OF POS+++++ ERROR TP ",
      xyzFormat.format(errorRadial) + " RADIAL\n"
    );
  } else {
    // X position without tolerance shown
    writeBlock(
      "POSN X" + xyzFormat.format(expectedX),
      "  ACTUAL " + (xFlag ? xyzFormat.format(actualX) : "NaN"),
      "  DEV " + (xFlag ? xyzFormat.format(deviationX) : "NaN")
    );
    // Y position without tolerance shown
    writeBlock(
      "POSN Y" + xyzFormat.format(expectedY),
      "  ACTUAL " + (yFlag ? xyzFormat.format(actualY) : "NaN"),
      "  DEV " + (yFlag ? xyzFormat.format(deviationY) : "NaN")
    );
  }
}

function randomAxialPosition(expectedPosition, axis) {
  const deviation = createRandomDeviation(getProperty("positionDeviation"));
  const actualPosition = expectedPosition + deviation;

  if (axis == xAxis) {
    writeBlock(
      "POSN X" + xyzFormat.format(expectedPosition),
      "  ACTUAL " + xyzFormat.format(actualPosition),
      "  DEV " + ijkFormat.format(deviation)
    );
  } else if (axis == yAxis) {
    writeBlock(
      "POSN Y" + xyzFormat.format(expectedPosition),
      "  ACTUAL " + xyzFormat.format(actualPosition),
      "  DEV " + ijkFormat.format(deviation)
    );
  } else if (axis == zAxis) {
    writeBlock(
      "POSN Z" + xyzFormat.format(expectedPosition),
      "  ACTUAL " + xyzFormat.format(actualPosition),
      "  DEV " + ijkFormat.format(deviation)
    );
  }
}

function randomSurfacePoint() {
  var randomPoint = createRandomDeviation(getProperty("pointDeviation"));
  var toolRadius = currentSection.getTool().diameter / 2;
  writeBlock(
    "G800 N" + pointNumber,
    "X" + xyzFormat.format(cycle.nominalX),
    "Y" + xyzFormat.format(cycle.nominalY),
    "Z" + xyzFormat.format(cycle.nominalZ),
    "I" + ijkFormat.format(cycle.nominalI),
    "J" + ijkFormat.format(cycle.nominalJ),
    "K" + ijkFormat.format(cycle.nominalK),
    conditional(hasParameter("operation:inspectSurfaceOffset"), " O" + xyzFormat.format(getParameter("operation:inspectSurfaceOffset"))) +
    conditional(hasParameter("operation:inspectUpperTolerance"), " U" + xyzFormat.format(getParameter("operation:inspectUpperTolerance"))) +
    conditional(hasParameter("operation:inspectLowerTolerance"), " L" + xyzFormat.format(getParameter("operation:inspectLowerTolerance")))
  );
  
  var positionVector = new Vector(cycle.nominalX, cycle.nominalY, cycle.nominalZ);
  var directionVector = new Vector(cycle.nominalI, cycle.nominalJ, cycle.nominalK);
  directionVector = directionVector.getNormalized();
  directionVector.multiply(toolRadius + randomPoint);
  positionVector = Vector.sum(positionVector, directionVector);
  writeBlock(
    "G801 N" + pointNumber,
    "X" + xyzFormat.format(positionVector.x),
    "Y" + xyzFormat.format(positionVector.y),
    "Z" + xyzFormat.format(positionVector.z),
    "R" + xyzFormat.format(toolRadius)
  );
}

function writteG331() {
  var cadWorkPlane = currentSection.getModelPlane().getTransposed();
  var cadOrigin = currentSection.getModelOrigin().getNegated();
  var cadEuler = cadWorkPlane.getEuler2(EULER_XYZ_S);
  writeBlock(
    "G331" +
    " N" + pointNumber +
    " A" + abcFormat.format(cadEuler.x) +
    " B" + abcFormat.format(cadEuler.y) +
    " C" + abcFormat.format(cadEuler.z) +
    " X" + xyzFormat.format(cadOrigin.x) +
    " Y" + xyzFormat.format(cadOrigin.y) +
    " Z" + xyzFormat.format(cadOrigin.z)
  );
}

function writteG330() {
  var orientation = (machineConfiguration.isMultiAxisConfiguration() && currentMachineABC != undefined) ? machineConfiguration.getOrientation(currentMachineABC) : currentSection.workPlane;
  var abc = orientation.getEuler2(EULER_XYZ_S);
  writeBlock(
    "G330" +
    " N" + pointNumber +
    " A" + abcFormat.format(abc.x) +
    " B" + abcFormat.format(abc.y) +
    " C" + abcFormat.format(abc.z) +
    " X0 Y0 Z0 I0 R0"
  );
}

var componentNumber = 1;
function writeComponentFeature() {
  writeBlock("-------------------------------------------------------------------");
  writeBlock("   COMPONENT NO " + componentNumber, "                   FEATURE NO " + pointNumber);
  writeBlock("-------------------------------------------------------------------");
}

function writeCycleDepth(depth) {
  writeBlock("CYCLEDEPTH ", xyzFormat.format(depth));
}

/** Convert approach to sign. */
function approach(value) {
  validate((value == "positive") || (value == "negative"), "Invalid approach.");
  return (value == "positive") ? 1 : -1;
}

function onOpen() {
  if (true) {
    var aAxis = createAxis({coordinate:0, table:true, axis:[1, 0, 0]});
    var cAxis = createAxis({coordinate:2, table:true, axis:[0, 0, 1]});

    machineConfiguration = new MachineConfiguration(aAxis, cAxis);

    setMachineConfiguration(machineConfiguration);
    optimizeMachineAngles2(0); // map tip mode - we compensate below
  }

  return;
}

function onSection() {
  if (isFirstSection() && isProbeInUse()) {
    const currentDate = new Date();
    var partPath = getGlobalParameter("autodeskcam:part-path", undefined);
    if (FileSystem.isFile(partPath)) {
      var destPartPath = FileSystem.getCombinedPath(getOutputPath(), programName + "_PART.stl");
      FileSystem.copyFile(partPath, destPartPath);
    }
    var resFile;
    if (getProperty("singleResultsFile")) {
      resFile = getParameter("job-description", "") + "-RESULTS ";
    } else {
      resFile = getParameter("operation-comment", "") + "-RESULTS";
    }
    resFile = resFile.replace(/:/g, "-");
    resFile = resFile.replace(/[^a-zA-Z0-9 -]/g, "");
    resFile = resFile.replace(/\s/g, "-");
    writeln("START");
    writeln("RESULTSFILE " + resFile);
    writeln("DOCUMENTID " + getGlobalParameter("document-id", ""));
    writeln("MODELVERSION " + getGlobalParameter("model-version", ""));
    writeln(
      "TIMESTAMP " + currentDate.getFullYear() % 100 +
      ("0" + (currentDate.getMonth() + 1)).slice(-2) + currentDate.getDate() + " " + currentDate.getHours() +
      ("0" + currentDate.getMinutes()).slice(-2) +
      ("0" + currentDate.getSeconds()).slice(-2)
    );
  }
  if (tool.type == TOOL_PROBE) {
    writeBlock("\n");
    writeln("TOOLPATHID " + getParameter("autodeskcam:operation-id", ""));
    writeln("TOOLPATH " + getParameter("operation-comment", ""));
    writteG331();
    writteG330();
  } else {
    return;
  }
}

function onProbe() {
  return;
}

function onParameter() {
  return;
}

function onCycle() {
  if (isInspectionOperation()) {
    randomSurfacePoint();
  }
  return;
}

function onCyclePoint(x, y, z) {
  if (isProbeOperation()) {
    var toolRadius = currentSection.getTool().diameter / 2;
    var contactDepth = z - cycle.depth + toolRadius;
    writeCycleDepth(contactDepth);
    writeComponentFeature();
  }
  switch (cycleType) {
  case "probing-x":
    var contactX = x + approach(cycle.approach1) * (cycle.probeClearance + toolRadius);
    randomAxialPosition(contactX, xAxis);
    break;
  case "probing-y":
    var contactY = y + approach(cycle.approach1) * (cycle.probeClearance + toolRadius);
    randomAxialPosition(contactY, yAxis);
    break;
  case "probing-z":
    randomAxialPosition(z - cycle.depth, zAxis); // For probing-z, contact depth is at tool tip
    break;

  case "probing-x-channel":
  case "probing-x-channel-not-symmetric":
  case "probing-x-channel-with-island":
  case "probing-x-wall":
  case "probing-x-wall-not-symmetric":
    randomSize(cycle.width1);
    randomPosition(x, y, xAxis);
    break;

  case "probing-y-channel":
  case "probing-y-channel-not-symmetric":
  case "probing-y-channel-with-island":
  case "probing-y-wall":
  case "probing-y-wall-not-symmetric":
    randomSize(cycle.width1);
    randomPosition(x, y, yAxis);
    break;

  case "probing-xy-inner-corner":
  case "probing-xy-outer-corner":
    var cornerX = x + approach(cycle.approach1) * (cycle.probeClearance + toolRadius);
    var cornerY = y + approach(cycle.approach2) * (cycle.probeClearance + toolRadius);
    randomPosition(cornerX, cornerY, xAxis | yAxis);
    break;

  case "probing-xy-pcd-hole":
  case "probing-xy-pcd-boss":
  case "probing-xy-pcd-hole-with-island":
    break;

  case "probing-xy-rectangular-hole":
  case "probing-xy-rectangular-hole-with-island":
  case "probing-xy-rectangular-boss":
  case "probing-xy-rectangular-hole-with-z":
  case "probing-xy-rectangular-hole-island-with-z":
  case "probing-xy-rectangular-boss-with-z":
    randomSize(cycle.width1);
    randomPosition(x, y, xAxis);
    ++pointNumber;
    writeComponentFeature();
    randomSize(cycle.width2);
    randomPosition(x, y, yAxis);
    break;

  case "probing-x-plane-angle":
  case "probing-y-plane-angle":
    randomAngle(cycle.nominalAngle);
    break;

  case "probing-xy-circular-hole":
  case "probing-xy-circular-hole-with-island":
  case "probing-xy-circular-boss":
  case "probing-xy-circular-partial-hole":
  case "probing-xy-circular-partial-boss":
  case "probing-xy-circular-partial-hole-with-island":
  case "probing-xy-circular-hole-with-z":
  case "probing-xy-circular-hole-island-with-z":
  case "probing-xy-circular-boss-with-z":
    randomSize(cycle.width1);
    randomPosition(x, y, xAxis | yAxis);
    break;
  }
}

function onCycleEnd() {
  if (cycle.incrementComponent == 1) {
    componentNumber++;
    pointNumber = 0;
  }
  ++pointNumber;
  return;
}

function onSectionEnd() {
  return;
}

function onClose() {
  if (isProbeInUse()) {
    writeln("END");
  }
  return;
}

function setProperty(property, value) {
  properties[property].current = value;
}
