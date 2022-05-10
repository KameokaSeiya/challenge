/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  ABB Rapid post processor configuration.
  
  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $

  FORKID {70730789-F71E-4A49-89E7-B5658ADA62F8}
*/

///////////////////////////////////////////////////////////////////////////////
//     CUSTOM NC COMMANDS - search for 'Machine specific output, modify as needed'
//
//     endEffectorCommandOn   - Modify this variable to define the commands to turn ON the end effector, if needed
//     endEffectorCommandOff  - Modify this variable to define the commands to turn OFF the end effector, if needed
//     setWeldingParameters() - to define the Arc welding settings: welddata, seamdata and weavedata
//
///////////////////////////////////////////////////////////////////////////////

description = "ABB Robotics - Rapid";
vendor = "ABB";
vendorUrl = "http://www.abb.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic ABB Rapid post. Please refer to the User Guide for programming specification and sample. Always validate with Robot Studio before loading any toolpath on your Robot.";

extension = "pgf";
programNameIsInteger = false;
setCodePage("ascii");

capabilities = CAPABILITY_MILLING | CAPABILITY_ADDITIVE;
tolerance = spatial(0.1, MM);

highFeedrate = (unit == IN) ? 100 : 1000;
minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = true;
allowSpiralMoves = true;
allowedCircularPlanes = 0;

properties = {
  flipToolFrame: {
    title: "Flip tool frame",
    description: "Flip the tool frame (Z- is along the tool axis).",
    group: "parameters",
    type: "boolean",
    value: true,
    scope: "post"
  },
  firstPointType: {
    title: "First point move type",
    description: "Set if the first point is defined by joint angles (joints values are needed but arm configuration can be ignored) or using cartesian coordinates (robot arm configuration data are required but joints value can be ignored).",
    group: "configuration",
    type: "enum",
    values: [
      {title: "Cartesian", id: "Cartesian"},
      {title: "Joints", id: "Joints"}
    ],
    value: "Joints",
    scope: "post"
  },
  useSubfolder: {
    title: "Use subfolder",
    description: "Specifies if files should be saved in subfolder or not.",
    group: "general",
    type: "boolean",
    value: true,
    scope: "post"
  },
  useCoolants: {
    title: "Use coolants",
    description: "Specifies if Robot needs Coolant Codes",
    group: "general",
    type: "boolean",
    value: false,
    scope: "post"
  },
  nameLimitation: {
    title: "Toolpath name max 30 chars",
    description: "Check if each toolpath name has max 30 characters.",
    group: "general",
    type: "boolean",
    value: true,
    scope: "post"
  },
  robotStartJ1: {
    title: "Robot joint 1",
    description: "ABB robot joint value used for the initial position point before MoveL start.",
    group: "configuration",
    type: "number",
    value: 0,
    scope: "post"
  },
  robotStartJ2: {
    title: "Robot joint 2",
    description: "ABB robot joint value used for the initial position point before MoveL start.",
    group: "configuration",
    type: "number",
    value: 0,
    scope: "post"
  },
  robotStartJ3: {
    title: "Robot joint 3",
    description: "ABB robot joint value used for the initial position point before MoveL start.",
    group: "configuration",
    type: "number",
    value: 5,
    scope: "post"
  },
  robotStartJ4: {
    title: "Robot joint 4",
    description: "ABB robot joint value used for the initial position point before MoveL start.",
    group: "configuration",
    type: "number",
    value: -70,
    scope: "post"
  },
  robotStartJ5: {
    title: "Robot joint 5",
    description: "ABB robot joint value used for the initial position point before MoveL start.",
    group: "configuration",
    type: "number",
    value: 40,
    scope: "post"
  },
  robotStartJ6: {
    title: "Robot joint 6",
    description: "ABB robot joint value used for the initial position point before MoveL start.",
    group: "configuration",
    type: "number",
    value: 70,
    scope: "post"
  },
  robotToolData: {
    title: "Robot tool name (prefix)",
    description: "ABB robot tool name prefix to use.",
    group: "parameters",
    type: "string",
    value: "tADSK",
    scope: "post"
  },
  robotWorkObjectData: {
    title: "Robot workobject data name (prefix)",
    description: "ABB robot work object data prefix to use.",
    group: "parameters",
    type: "string",
    value: "wADSK",
    scope: "post"
  },
  robotConfiguration: {
    title: "Robot configuration",
    description: "ABB robot arm configuration.",
    group: "configuration",
    type: "string",
    value: "0,-1,0,1",
    scope: "post"
  },
  robotHeadAngle: {
    title: "Head angle",
    description: "ABB robot head angle around tool axis. X axis is 0 deg.",
    group: "proc",
    type: "number",
    value: 30,
    scope: "post"
  },
  robotZoneSmoothing: {
    title: "Robot smoothing value (Zone)",
    description: "ABB robot path smoothing value (zone).",
    group: "parameters",
    type: "integer",
    value: 1,
    scope: "post"
  },
  writeDateAndTime: {
    title: "Write date and time",
    description: "Output date and time in the header of the code.",
    group: "general",
    type: "boolean",
    value: true,
    scope: "post"
  },
  endEffectorBehavior: {
    title: "End-effector state",
    description: "Set the end-effector state (including behavior during flat toolpath transitions).",
    group: "proc",
    type: "enum",
    values: [
      {title: "OFF", id: "Off"},
      {title: "ON + links ON", id: "On"},
      {title: "ON + links OFF", id: "OnOff"}
    ],
    value: "Off",
    scope: "post"
  },
  fffToolData: {
    title: "Robot tool data",
    description: "ABB tool data used for FFF toolpath",
    group: "fff",
    type: "integer",
    value: 1,
    scope: "post"
  },
  fffBaseData: {
    title: "Robot base data",
    description: "ABB Work Object Coordinates System (WOCS) used for FFF toolpath",
    group: "fff",
    type: "integer",
    value: 1,
    scope: "post"
  },
  weldProcess: {
    title: "Welding mode",
    description: "Welding Technology Process ON",
    group: "proc",
    type: "boolean",
    value: false,
    scope: "post"
  },
  weldingSeamdata: {
    title: "Welding seamdata",
    description: "Describes how the seam is to be started and ended (refer to ABB manual for more details).",
    group: "weld",
    type: "string",
    value: "seam1",
    scope: "post"
  },
  weldingWelddata: {
    title: "Welding welddata",
    description: "Describes the actual welding phase (refer to ABB manual for more details).",
    group: "weld",
    type: "string",
    value: "weld1",
    scope: "post"
  },
  weldingWeavedata: {
    title: "Welding weavedata",
    description: "Describes how any weaving is to be carried out (refer to ABB manual for more details).",
    group: "weld",
    type: "string",
    value: "weave1",
    scope: "post"
  },
  weldingWaitTime: {
    title: "Welding wait time",
    description: "Instruction to wait a given amount of time in seconds.",
    group: "weld",
    type: "number",
    value: "0",
    scope: "post"
  }
};
groupDefinitions = {
  proc: {title: "Process", description: "Process post settings", order: 0},
  configuration: {title: "Configuration", description: "General robot configuration", order: 1},
  parameters: {title: "Parameters", description: "Robot parameters", order: 2},
  weld: {title: "Welding Settings", description: "Welding settings", collapsed:true, order: 3},
  fff: {title: "FFF Settings", description: "FFF settings", collapsed:true, order: 4},
  general: {title: "General", description: "Other post options", collapsed:true, order: 5}
};

var coolants = [
  {id: COOLANT_FLOOD},
  {id: COOLANT_MIST},
  {id: COOLANT_THROUGH_TOOL},
  {id: COOLANT_AIR},
  {id: COOLANT_AIR_THROUGH_TOOL},
  {id: COOLANT_SUCTION},
  {id: COOLANT_FLOOD_MIST},
  {id: COOLANT_FLOOD_THROUGH_TOOL},
  {id: COOLANT_OFF}
];

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:false});
var abcFormat = createFormat({decimals:3, forceDecimal:false});
var jointFormat = createFormat({decimals:4, forceDecimal:false});
var quatFormat = createFormat({decimals:8, forceDecimal:false});
var feedFormat = createFormat({decimals:0, forceDecimal:false, scale:1.0 / 60.0}); // mm/min -> mm/s
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3}); // seconds
var taperFormat = createFormat({decimals:1, scale:DEG});
var xOutput = createVariable({prefix:"", force:true}, xyzFormat);
var yOutput = createVariable({prefix:"", force:true}, xyzFormat);
var zOutput = createVariable({onchange:function () {retracted = false;}, prefix:"", force:true}, xyzFormat);
var feedOutput = createVariable({prefix:"v", force:true}, feedFormat);
var sOutput = createVariable({prefix:"", force:true}, rpmFormat);
var integerFormat = createFormat({decimals:0});

var forceSpindleSpeed = false;
var retracted = false; // specifies that the tool has been retracted to the safe plane
var firstLin = true; // set during onSection to reset first toolpath point
var pendingRadiusCompensation = -1;
var currentToolDataName = "";
var currentWorkObjectDataName = "";

var endEffectorState = 0; // initial state of the end effector (0 =off)
var wasEndEffectorOn = 0; // used to check previous value of endEffectorState

// Machine specific output, modify as needed
var endEffectorCommandOn = "==> END EFFECTOR ON: DEFINE YOUR CODE HERE IN THE POST"; // specifies the command to turn on the end effector
var endEffectorCommandOff = "==> END EFFECTOR OFF: DEFINE YOUR CODE HERE IN THE POST";  // specifies the command to turn off the end effector

var subfolderPath;
var subNames = new Array();
var speeddata = new Array();
var toolpathNames = new Array();
var predefinedspeed = new Array("v5", "v10", "v25", "v30", "v40", "v50", "v60", "v80", "v100", "v150", "v200", "v300", "v400", "v500", "v600", "v800", "v1000");
var permittedCommentChars = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,=_-+";

/**
  Writes the specified block.
*/
function writeBlock() {
  writeWords(arguments);
}

/**
  Formats a comment.
*/
function formatComment(text) {
  return "    ! " + filterText(String(text), permittedCommentChars).replace(/[()]/g, "");
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

function onOpen() {
  // Machine requires output only in MM
  unit = MM;

  setWordSeparator(",");

  if (getProperty("endEffectorBehavior") == "Off" && getProperty("weldProcess")) {
    error(subst(localize("In welding mode please activate the prefered end-effector state.")));
  }

  // create subfolder if requested
  if (getProperty("useSubfolder")) {
    subfolderPath = FileSystem.getCombinedPath(FileSystem.getFolderPath(getOutputPath()), programName);
    if (!FileSystem.isFolder(subfolderPath)) {
      FileSystem.makeFolder(subfolderPath);
    }
  }

  writeln("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>");
  writeln("<Program>");
  writeln("  <Module>mAutodesk.mod</Module>");
}

function onComment(message) {
  if (isRedirecting()) {
    writeComment(message);
  }
}

function writeRobotMove(x, y, z, i, j, k, feed) {
  customFeed(feed);
  if (firstLin) {
    firstLin = false;
    if (getProperty("firstPointType") == "Joints") {
      writeMoveAbsJ(getProperty("robotStartJ1"), getProperty("robotStartJ2"), getProperty("robotStartJ3"), getProperty("robotStartJ4"),
        getProperty("robotStartJ5"), getProperty("robotStartJ6"), feed);
      writeMoveL(x, y, z, i, j, k, getProperty("robotHeadAngle"), feed);
    } else {
      writeMoveJ(x, y, z, i, j, k, getProperty("robotHeadAngle"), feed);
    }
  } else {
    writeMoveL(x, y, z, i, j, k, getProperty("robotHeadAngle"), feed);
  }
}

function writeMoveAbsJ(j1, j2, j3, j4, j5, j6, feed) {
  writeBlock("    MoveAbsJ [[" + jointFormat.format(j1), jointFormat.format(j2), jointFormat.format(j3), jointFormat.format(j4), jointFormat.format(j5), jointFormat.format(j6) + "],[9E9,9E9,9E9,9E9,9E9,9E9]]\\NoEOffs," + feedOutput.format(feed) + ",fine," + currentToolDataName + ";");
}

function writeMoveL(x, y, z, i, j, k, angle, feed) {
  // calculates quaternion from toolaxis vector and given head angle
  var vz = new Vector();
  vz.x = i;
  vz.y = j;
  vz.z = k;
  var q = getQuaternionFromVector3AndRotationAngle(vz, angle);
  var x = xOutput.format(x);
  var y  = yOutput.format(y);
  var z  = zOutput.format(z);
  var qx = quatFormat.format(q.X);
  var qy = quatFormat.format(q.Y);
  var qz = quatFormat.format(q.Z);
  var qw = quatFormat.format(q.W);
  var feed = feedOutput.format(feed);
  var _weldingSeamdata = getProperty("weldingSeamdata");
  var _weldingWelddata = getProperty("weldingWelddata");
  var _weldingWeavedata = getProperty("weldingWeavedata");
  var _robotZoneSmoothing = getProperty("robotZoneSmoothing");

  if (getProperty("weldProcess")) {
    // Welding (ArcL motions needed)
    if (endEffectorState == 1) {
      if (wasEndEffectorOn == 0) {
        wasEndEffectorOn = 1;
        writeln("    ! Welding Move Starts (Arc is about to be established)");
        writeBlock("    ArcLStart [[" + x, y, z + "],[" + qw, qx, qy, qz + "],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]]," +
          feed, _weldingSeamdata, _weldingWelddata +
          "\\Weave:=" + _weldingWeavedata + ",fine," + currentToolDataName + "\\WObj:=" + currentWorkObjectDataName + ";"
        );
      } else {
        writeBlock("    ArcL [[" + x, y, z + "],[" + qw, qx, qy, qz + "],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]]," +
          feed, _weldingSeamdata, _weldingWelddata +
          "\\Weave:=" + _weldingWeavedata + ",z" + _robotZoneSmoothing, currentToolDataName + "\\WObj:=" + currentWorkObjectDataName + ";"
        );
      }
    } else {
      if (wasEndEffectorOn == 1) {
        wasEndEffectorOn = 0;
        writeBlock("    ArcL [[" + x, y, z + "],[" + qw, qx, qy, qz + "],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]]," +
          feed, _weldingSeamdata, _weldingWelddata +
          "\\Weave:=" + _weldingWeavedata + ",z" + _robotZoneSmoothing, currentToolDataName + "\\WObj:=" + currentWorkObjectDataName + ";"
        );
        writeBlock("    ! Welding Move Ends (Arc is about to be stopped)");
        writeBlock("    ArcLEnd [[" + x, y, z + "],[" + qw, qx, qy, qz + "],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]]," +
          feed, _weldingSeamdata, _weldingWelddata +
          "\\Weave:=" + _weldingWeavedata + ",z" + _robotZoneSmoothing, currentToolDataName + "\\WObj:=" + currentWorkObjectDataName + ";"
        );
        writeln("    WaitTime " + getProperty("weldingWaitTime") + ";");
      } else {
        writeBlock("    MoveL [[" + x, y, z + "],[" + qw, qx, qy, qz + "],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]]," +
          feed + ",z" + _robotZoneSmoothing, currentToolDataName + "\\WObj:=" + currentWorkObjectDataName + ";"
        );
      }
    }
  } else {
    // Milling (MoveL only) or Additive (actually end-effector on/off switch)
    if (endEffectorState == 1) {
      if (wasEndEffectorOn == 0) {
        wasEndEffectorOn = 1;
        if (!isFFFOperation(currentSection) && currentSection.type == TYPE_ADDITIVE) {
          writeComment("Additive Process Starts");
          setAdditiveProcessON();
        } else {
          writeComment("Cutting Move Starts");
        }
      }
    } else {
      if (wasEndEffectorOn == 1) {
        wasEndEffectorOn = 0;
        if (!isFFFOperation(currentSection) && currentSection.type == TYPE_ADDITIVE) {
          writeComment("Additive Process Ends");
          setAdditiveProcessOFF();
        } else {
          writeComment("Cutting Move Ends");
        }
      }
    }
    writeBlock("    MoveL [[" + x, y, z + "],[" + qw, qx, qy, qz + "],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]]," +
    feed + ",z" + _robotZoneSmoothing, currentToolDataName + "\\WObj:=" + currentWorkObjectDataName + ";");
  }
}

function writeMoveJ(x, y, z, i, j, k, angle, feed) {
  // calculates quaternion from toolaxis vector and given head angle
  var vz = new Vector();
  vz.x = i;
  vz.y = j;
  vz.z = k;
  var q = getQuaternionFromVector3AndRotationAngle(vz, angle);
  writeBlock("    MoveJ [[" + xOutput.format(x), yOutput.format(y), zOutput.format(z) + "],[" + quatFormat.format(q.W), quatFormat.format(q.X), quatFormat.format(q.Y),
    quatFormat.format(q.Z) + "],[" + getProperty("robotConfiguration") + "],[9E9,9E9,9E9,9E9,9E9,9E9]]," + feedOutput.format(feed) + ",z" + getProperty("robotZoneSmoothing"),
    currentToolDataName + "\\WObj:=" + currentWorkObjectDataName + ";");
}

function isDEDOperation() {
  return currentSection.strategy.indexOf("ded_") != -1;
}

var operationCounter = 0;
function onSection() {
  cancelRotation();
  if (!currentSection.isMultiAxis())  {
    setRotation(currentSection.workPlane);
  }

  // define the actual tool and workobject name (not available for FFF so using the properties directly)
  if (isFFFOperation(currentSection)) {
    currentToolDataName = getProperty("robotToolData") + getProperty("fffToolData");
    currentWorkObjectDataName = getProperty("robotWorkObjectData") + getProperty("fffBaseData");
  } else {
    currentToolDataName = getProperty("robotToolData") + tool.number;
    currentWorkObjectDataName = getProperty("robotWorkObjectData") + currentSection.workOffset;
  }

  firstLin = true;

  var counter = 1;
  var opName;
  if (hasParameter("operation-comment")) {
    opName = getParameter("operation-comment");
  } else if (hasParameter("notes")) {
    opName = getParameter("notes");
  } else {
    if (isFFFOperation(currentSection)) {
      opName = (programName + "_" + counter);
      counter = counter++;
    } else {
      opName = ("unnamed_" + counter);
      counter = counter++;
    }
  }

  opName = "m" + opName.replace(/[^a-zA-Z0-9_()+]/g, "_");

  if (getProperty("useSubfolder")) {
    folder = subfolderPath;
  } else {
    folder = FileSystem.getFolderPath(getOutputPath());
  }

  // write toolpath name in main program
  // load toolpath name/tool number/spindle speed in subNames array to be written later in Autodesk.mod file
  if (toolpathNames.length > 0 && toolpathNames.indexOf(opName) > -1) {
    ++operationCounter;
    opName += "_" + operationCounter;
  }
  if (getProperty("nameLimitation")) {
    if (opName.length > 30) {
      error(subst(localize("Toolpath Name '%1' is longer than 30 characters. Please modify it to less than 30 characters."), opName));
    }
  }
  writeBlock("  <Module>" + opName + ".mod</Module>");
  subNames.push(currentToolDataName + "!Spindle_ON " + sOutput.format(spindleSpeed) + "@" + opName);
  toolpathNames.push(opName);

  var path = FileSystem.getCombinedPath(folder, opName + ".mod");
  var procName = ("p" + opName.substring(1, opName.length));

  redirectToFile(path);
  writeln("%%%");
  writeln("  VERSION:1");
  writeln("  LANGUAGE:ENGLISH");
  writeln("%%%");
  writeln("");
  writeln("MODULE " + opName);
  writeln("  PROC " + procName + "()");

  // set coolant code if needed
  if (getProperty("useCoolants")) {
    setCoolant(tool.coolant);
  }
}

function isFFFOperation(section) {
  return section.getType() == TYPE_ADDITIVE && section.getTool().type == TOOL_MARKER;
}

function onMovement(movement) {
  // We can use a simple milling (subtractive) toolpaths as additive :
  // ignore all the onMovement stuff for FFF since the end effector switch
  // is handled in the onRapid and onLinearExtrude functions
  
  if (!isFFFOperation(currentSection)) {
    switch (movement) {
    case MOVEMENT_CUTTING:
    case MOVEMENT_FINISH_CUTTING:
      writeComment("Cutting Move Starts");
      setAdditiveProcessON();
      break;
    case MOVEMENT_PLUNGE:
      writeComment("Plunge Move Starts");
      break;
    case MOVEMENT_LEAD_IN:
      writeComment("Lead In Move Starts");
      break;
    case MOVEMENT_LEAD_OUT:
      writeComment("Lead Out Move Starts");
      setAdditiveProcessOFF();
      break;
    case MOVEMENT_LINK_TRANSITION:
      writeComment("Link Move Starts");
      if (getProperty("endEffectorBehavior") == "OnOff") {
        setAdditiveProcessOFF();
      }
      break;
    case MOVEMENT_BRIDGING:
      writeComment("Bridging Move Starts");
      break;
    case MOVEMENT_LINK_DIRECT:
      writeComment("Cutting Move Ends");
      break;
    case MOVEMENT_RAPID:
      writeComment("Rapid Move Starts");
      setAdditiveProcessOFF();
      break;
    }
  }
}

//  An end-effector is the device at the end of a robotic arm.
//  It may consist in different gripper/tool/etc. and the activation/deactivation code depends on the end-effector type.
//  These codes are to be customized by integrator and/or end-user.

function setAdditiveProcessON() {
  if (getProperty("endEffectorBehavior") != "Off" && endEffectorState == 0) {
    endEffectorState = 1;
    if (!getProperty("weldProcess")) {
      writeComment(endEffectorCommandOn);
    }
  }
}

function setAdditiveProcessOFF() {
  if (getProperty("endEffectorBehavior") != "Off" && endEffectorState == 1) {
    endEffectorState = 0;
    if (!getProperty("weldProcess")) {
      writeComment(endEffectorCommandOff);
    }
  }
}

/**
  put here the Arc welding settings: welddata, seamdata and weavedata
*/
function setWeldingParameters() {
  writeln("  PERS welddata " + getProperty("weldingWelddata") + ":=[0,0,[0,0,0.0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0]];");
  writeln("  PERS seamdata " + getProperty("weldingSeamdata") + ":=[0,0,[0,0,0,0,0,0,0,0,0],0,0,0,0,0,[0,0,0,0,0,0,0,0,0],0,0,[0,0,0,0,0,0,0,0,0],0,0,[0,0,0,0,0,0,0,0,0],0];");
  writeln("  PERS weavedata " + getProperty("weldingWeavedata") + ":=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];");
}

function onDwell(seconds) {
}

function onSpindleSpeed(spindleSpeed) {
  writeBlock(sOutput.format(spindleSpeed));
}

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

function onRapid(_x, _y, _z) {
  if (isFFFOperation(currentSection)) {
    setAdditiveProcessOFF();
  }
  var workPlane = currentSection.workPlane.forward;
  writeRobotMove(_x, _y, _z, workPlane.x, workPlane.y, workPlane.z, highFeedrate);
}

function onLinear(_x, _y, _z, feed) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode is not supported by robot."));
    return;
  }
  var workPlane = currentSection.workPlane.forward;
  writeRobotMove(_x, _y, _z, workPlane.x, workPlane.y, workPlane.z, feed);
}

function onLinearExtrude(_x, _y, _z, feed, _e) {
  if (isFFFOperation(currentSection)) {
    setAdditiveProcessON();
  }
  var workPlane = currentSection.workPlane.forward;
  writeRobotMove(_x, _y, _z, workPlane.x, workPlane.y, workPlane.z, feed);
}

function onRapid5D(_x, _y, _z, _i, _j, _k) {
  writeRobotMove(_x, _y, _z,  _i, _j, _k, highFeedrate);
}

function onLinear5D(_x, _y, _z, _i, _j, _k, feed) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode is not supported by robot."));
    return;
  }
  writeRobotMove(_x, _y, _z,  _i, _j, _k, feed);
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  linearize(tolerance);
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

function onCommand(command) {
  switch (command) {
  case COMMAND_STOP:
    writeBlock("");
    forceSpindleSpeed = true;
    return;
  case COMMAND_OPTIONAL_STOP:
    writeComment(""); // need variable
    return;
  case COMMAND_COOLANT_ON:
    setCoolant(COOLANT_FLOOD);
    return;
  case COMMAND_COOLANT_OFF:
    setCoolant(COOLANT_OFF);
    return;
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
  default:
    onUnsupportedCommand(command);
  }
}

function onSectionEnd() {
  writeln("  ENDPROC");
  writeln("ENDMODULE");
  closeRedirection();
}

/**
  quaternion object
*/
function Quaternion (type) {
  this.type = type;
  this.W = 1;
  this.X = 0;
  this.Y = 0;
  this.Z = 0;
}

/**
  converts a vectorZ and a rotation angle around it to a quaternion
*/
function getQuaternionFromVector3AndRotationAngle(vectorZ, angleInDegrees) {
  // X is rotated about standard XY-plane, not provided Z-axis
  var vectorX = new Vector();
  if (Math.abs(vectorZ.x) == 1) {
    // if tool axis is align with X axis
    vectorX = Matrix.getXRotation(toRad(angleInDegrees)).transposed.multiply(new Vector(1, 0, 0));
  } else if (Math.abs(vectorZ.y) == 1) {
    // if tool axis is align with Y axis
    vectorX = Matrix.getYRotation(toRad(angleInDegrees)).transposed.multiply(new Vector(1, 0, 0));
  } else {
    // any other cases
    vectorX = Matrix.getZRotation(toRad(angleInDegrees)).transposed.multiply(new Vector(1, 0, 0));
  }

  // X and Z form a non-orthogonal matrix, so cannot use standard matrix calculations
  var yAxis = Vector.cross(vectorZ, vectorX).normalized;
  var xAxis = Vector.cross(yAxis, vectorZ).normalized;
  var yAxis = Vector.cross(vectorZ, xAxis).normalized;

  m = new Matrix(xAxis, yAxis, vectorZ).transposed;

  if (getProperty("flipToolFrame")) {
    m = Matrix.getAxisRotation(new Vector(0, 1, 0), Math.PI).multiply(m);
  }
  
  var q = getQuaternionFromMatrix3x3(m);
  return q;
}

/**
  converts a rotation matrix 3x3 to a quaternion
*/
function getQuaternionFromMatrix3x3(rotationMatrix) {
  var m00 = rotationMatrix.getElement(0, 0);
  var m01 = rotationMatrix.getElement(1, 0);
  var m02 = rotationMatrix.getElement(2, 0);
  var m10 = rotationMatrix.getElement(0, 1);
  var m11 = rotationMatrix.getElement(1, 1);
  var m12 = rotationMatrix.getElement(2, 1);
  var m20 = rotationMatrix.getElement(0, 2);
  var m21 = rotationMatrix.getElement(1, 2);
  var m22 = rotationMatrix.getElement(2, 2);

  var qw = 0;
  var qx = 0;
  var qy = 0;
  var qz = 0;
  var s = 0;

  // compute the quaternion
  if (m00 + m11 + m22 > 2.99999999) {
    qw = 1;
    qx = 0;
    qy = 0;
    qz = 0;
  } else if (m00 + m11 + m22 + 1 > 0.00000001) {
    S = Math.sqrt(m00 + m11 + m22 + 1) * 2;
    qw = 0.25 * S;
    qx = (m21 - m12) / S;
    qy = (m02 - m20) / S;
    qz = (m10 - m01) / S;
  } else if (m00 > m11 && m00 > m22) {
    if (1.0 + m00 - m11 - m22 <= 0) {error(localize("Quaternion calculation error"));}
    S = Math.sqrt(1.0 + m00 - m11 - m22) * 2;
    qw = (m21 - m12) / S;
    qx = 0.25 * S;
    qy = (m01 + m10) / S;
    qz = (m02 + m20) / S;
  } else if (m11 > m22) {
    if (1.0 + m11 - m00 - m22 <= 0) {error(localize("Quaternion calculation error"));}
    S = Math.sqrt(1.0 + m11 - m00 - m22) * 2;
    qw = (m02 - m20) / S;
    qx = (m01 + m10) / S;
    qy = 0.25 * S;
    qz = (m12 + m21) / S;
  } else {
    if (1.0 + m22 - m00 - m11 <= 0) {error(localize("Quaternion calculation error"));}
    S = Math.sqrt(1.0 + m22 - m00 - m11) * 2;
    qw = (m10 - m01) / S;
    qx = (m02 + m20) / S;
    qy = (m12 + m21) / S;
    qz = 0.25 * S;
  }

  // return result
  var q = new Quaternion();
  q.W = qw;
  q.X = qx;
  q.Y = qy;
  q.Z = qz;
  return q;
}

function autodeskOut() {
  speeddata.sort();

  if (getProperty("useSubfolder")) {
    folder = subfolderPath;
    pathAutodesk = FileSystem.getCombinedPath(folder, "mAutodesk.mod");
  } else {
    var pathAutodesk = FileSystem.getCombinedPath(FileSystem.getFolderPath(getOutputPath()), "mAutodesk.mod");
  }
  redirectToFile(pathAutodesk);
  writeln("%%%");
  writeln("  VERSION:1");
  writeln("  LANGUAGE:ENGLISH");
  writeln("%%%");
  writeln("");
  writeln("MODULE mAUTODESK");
  writeln("");
  for (var i = 0; i < speeddata.length; ++i) {
    var number = speeddata[i].slice(1, speeddata[i].length);
    writeln("  PERS speeddata " + speeddata[i] + ":=[" + number + ",500,5000,1000];");
  }
  writeln("");
  if (getProperty("weldProcess")) {
    setWeldingParameters();
    writeln("");
  }
  writeln("  PROC main()");
  if (hasGlobalParameter("generated-by")) {
    var value = getGlobalParameter("generated-by");
    writeBlock("    ! Generated by AUTODESK " + value);
  }
  if (getProperty("writeDateAndTime")) {
    var d = new Date();
    writeBlock(localize("    ! Creation date") + ": " + d.toLocaleDateString() + " " + d.toLocaleTimeString());
  }
  writeln("");
  writeln("    ! Acceleration and jerk/ramp (percentage)");
  writeln("    AccSet 20,20;");
  writeln("");
  writeln("    ! Configurations");
  writeln("    ConfJ\\On;");
  writeln("    ConfL\\Off;");
  
  var prevTool = 9999;
  var prevSpindle = 9999;

  // write total list of toolpaths and tool change/spindle speed only when changed
  for (var i = 0; i < subNames.length; ++i) {
    var toolNo = subNames[i].slice(0, subNames[i].indexOf("!"));
    subNames[i] = subNames[i].slice(subNames[i].indexOf("!"), subNames[i].length);
    var spindleSpe = subNames[i].slice(0, subNames[i].indexOf("@"));
    subNames[i] = subNames[i].slice(subNames[i].indexOf("@") + 1, subNames[i].length);

    if (toolNo != prevTool) {
      writeln("");
      writeln("    ! Load Tool");
      writeln("    !Tool_Change " + toolNo + ";");
      writeln("");
      prevTool = toolNo;
    }

    if (spindleSpe != prevSpindle) {
      writeln("    ! Spindle On/Speed");
      writeln("    " + spindleSpe + ";");
      writeln("");
      prevSpindle = spindleSpe;
    }

    var procName = ("p" + subNames[i].substring(1, subNames[i].length));
    writeln("    " + procName + ";");
  }

  writeln("");
  writeln("    ! Spindle Off");
  writeln("    !Spindle_OFF;");
  writeln("");
  writeln("    ConfJ\\On;");
  writeln("    ConfL\\On;");
  writeln("    Stop;");
  writeln("  ENDPROC");
  writeln("ENDMODULE");
  closeRedirection();
  return;
}

function customFeed(feed) {
  var nonStandard = predefinedspeed.indexOf(feedOutput.format(feed));
  if (speeddata.length == 0) {
    if (nonStandard == -1) {
      speeddata.push(feedOutput.format(feed));
    }
  } else {
    var i = 0;
    do {
      if (speeddata[i] == feedOutput.format(feed)) {
        break;
      }
      i++;
    } while (i < speeddata.length);
    if (i == speeddata.length && nonStandard == -1) {
      speeddata.push(feedOutput.format(feed));
    }
  }
}

function onTerminate() {
  if (getProperty("useSubfolder")) {
    var outputPath = getOutputPath();
    var programFilename = FileSystem.getFilename(outputPath);
    var newFolder = subfolderPath + "\\" + programFilename;
    FileSystem.copyFile(outputPath, newFolder);
    FileSystem.remove(outputPath);

    var file = new TextFile(FileSystem.getFolderPath(getOutputPath()) + "\\" + programFilename, true, "ansi");
    file.writeln("This is a dummy file.");
    file.writeln("Your program files are located here: " + (FileSystem.getFolderPath(getOutputPath()) + "\\" + programName));
    file.close();
  }
}

function onClose() {
  writeBlock("</Program>");
  autodeskOut();
}

function setProperty(property, value) {
  properties[property].current = value;
}
