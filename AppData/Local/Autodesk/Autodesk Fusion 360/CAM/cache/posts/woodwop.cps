/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  woodWOP post processor configuration.

  $Revision: 43238 4dbf8919a4db78dacd2bdabb94afe927f8cdf05e $
  $Date: 2021-05-03 12:19:40 $
  
  FORKID {2A265A9B-0B98-43a0-A447-177302864E1E}
*/

description = "woodWOP";
vendor = "HOMAG";
vendorUrl = "http://www.homag.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic woodWOP post with support for multi-axis machines. By default any drilling will be executed before all milling. You can turn off the 'doAllDrillingFirst' property to use the programmed order.";

extension = "mpr";
setCodePage("ascii");

capabilities = CAPABILITY_MILLING;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.3, MM); // avoid errors with smaller radii
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(90); // limit to 180deg for now to work around issues with 360deg arcs // limit to 90deg to avoid potential center calculation errors for CNC
allowHelicalMoves = true;
allowedCircularPlanes = (1 << PLANE_XY); // allow XY circular motion
mapWorkOrigin = false;

// user-defined properties
properties = {
  doAllDrillingFirst: {
    title: "Do all drilling first",
    description: "Enable to reorder toolpath to do all drilling first.",
    group: 0,
    type: "boolean",
    value: true,
    scope: "post"
  },
  useBoreToolNumber: {
    title: "Output tool number for drilling",
    description: "Enable to output tool numbers with drilling operations, disable to output the hole diameter.",
    group: 0,
    type: "boolean",
    value: true,
    scope: "post"
  },
  machineType: {
    title: "Machine type",
    description: "Select the machine type to output in the MAT command.",
    group: 0,
    type: "enum",
    values: [
      {title: "HOMAG", id: "HOMAG"},
      {title: "CF-HOMAG", id: "CF-HOMAG"},
      {title: "FK-HOMAG", id: "FK-HOMAG"},
      {title: "WEEKE", id: "WEEKE"}
    ],
    value: "WEEKE",
    scope: "post"
  },
  shiftOrigin: {
    title: "Shift origin to lower left corner",
    description: "Enable to shift the WCS origin to the lower left hand corner of the part.",
    group: 0,
    type: "boolean",
    value: true,
    scope: "post"
  },
  freeMotionParkPosition: {
    title: "Free motion park position",
    description: "Specifies where the machine should park after cutting.",
    group: 0,
    type: "integer",
    values: [
      0,
      1,
      2,
      3,
      4
    ],
    value: 1,
    scope: "post"
  },
  freeMotionAdditional: {
    title: "Free motion additional",
    description: "Specifies how much to add to the free motion park position (in mm).",
    group: 0,
    type: "number",
    value: 0,
    scope: "post"
  },
  isoOnly: {
    title: "Output NC code in ISO format",
    description: "Enable to output all operations in ISO format using the Universal Makro.",
    group: 0,
    type: "boolean",
    value: false,
    scope: "post"
  },
  showSequenceNumbers: {
    title: "Use sequence numbers",
    description: "Use sequence numbers for each ISO block.",
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
    value: 1,
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
  showNotes: {
    title: "Show notes",
    description: "Writes operation notes as comments in the ISO output code.",
    group: 1,
    type: "boolean",
    value: false,
    scope: "post"
  },
  zHomePosition: {
    title: "Z home position",
    description: "Z home position between multi-axis operations.",
    group: 2,
    type: "spatial",
    value: 100,
    scope: "post"
  },
  useSmoothing: {
    title: "Use smoothing",
    description: "Enables BSPLINE style smoothing for contours and multi-axis operations.",
    group: 3,
    type: "boolean",
    value: true,
    scope: "post"
  },
  smoothingPathDev: {
    title: "Path deviation",
    description: "Allowed linear path deviation for smoothing.",
    group: 4,
    type: "number",
    value: 0.02,
    scope: "post"
  },
  smoothingTrackDev: {
    title: "Angular deviation",
    description: "Allowed rotary angle deviation for smoothing.",
    group: 4,
    type: "number",
    value: 1,
    scope: "post"
  },
  useRadius: {
    title: "Radius arcs",
    description: "If yes is selected, arcs are output using radius values rather than IJK in ISO mode.",
    group: 5,
    type: "boolean",
    value: false,
    scope: "post"
  },
  useMultiAxisFeatures: {
    title: "Use ISO work planes",
    description: "Enable to output work planes for 3+2 operations in ISO mode.  Disable to output 3+2 operations using TCP in ISO mode.",
    group: 5,
    type: "boolean",
    value: false,
    scope: "post"
  },
  abcToler: {
    title: "A-axis tolerance",
    description: "The tolerance used to determine the output of the A-axis.",
    group: 5,
    type: "spatial",
    value: 0.001,
    scope: "post"
  }
};

var nFormat = createFormat({prefix:"N", decimals:0, width:4, zeropad:true});
var gFormat = createFormat({prefix:"G", decimals:0});

var xyzFormat = createFormat({decimals:4});
var eulerFormat = createFormat({decimals:3, scale:DEG});
var abcFormat = createFormat({decimals:3, forceDecimal:true, trim:false, scale:DEG});
var radianFormat = createFormat({decimals:3, forceDecimal:true});
var rFormat = createFormat({decimals:4});
var spatialFormat = createFormat({decimals:4});
var feedFormat = createFormat({decimals:3, scale:0.001});
var isoFeedFormat = createFormat({decimals:3, forceDecimal:true, trim:false, scale:0.001});
var integerFormat = createFormat({decimals:0});
var wcsFormat = createFormat({decimal:2, width:2, zeropad:true});

var xOutput = createVariable({prefix:"X"}, xyzFormat);
var yOutput = createVariable({prefix:"Y"}, xyzFormat);
var zOutput = createVariable({prefix:"Z"}, xyzFormat);
var aOutput = createRotaryVariable({prefix:"A"}, abcFormat);
var bOutput = createVariable({prefix:"B"}, abcFormat);
var cOutput = createVariable({prefix:"C"}, abcFormat);
var feedOutput = createVariable({prefix:"F"}, isoFeedFormat);

// circular output
var iOutput = createReferenceVariable({prefix:"I", force:true}, xyzFormat);
var jOutput = createReferenceVariable({prefix:"J", force:true}, xyzFormat);
var kOutput = createReferenceVariable({prefix:"K", force:true}, xyzFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...

// fixed settings
var useMultiAxisFeatures = true; // use #CS work planes
var useABCPrepositioning = true; // position ABC axes prior to #CS work plane
var retracted = false; // specifies that the tool has been retracted to the safe plane

var REDIRECT_ID = 99999;

// collected state
var inContour = false;
var contourId = 0;
var entityId = 0;
var currentFeed = -1;
var machining = [];
var definedWorkPlanes = [];
var virtualConfiguration = {};
var sequenceNumber;
var redirectBuffer = [];
var redirectIndex = 0;
var previousABC = new Vector(0, 0, 0);
var useISO;
var tcpActive;
var workOrigin;

/**
  Writes the specified block.
*/
function writeSimpleBlock() {
  writeWords(arguments);
}

/**
  Writes the specified ISO block
*/
function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }
  if (getProperty("showSequenceNumbers")) {
    if (sequenceNumber > 9999) {
      sequenceNumber = getProperty("sequenceNumberStart");
    }
    writeWords2(nFormat.format(sequenceNumber), arguments);
    sequenceNumber += getProperty("sequenceNumberIncrement");
  } else {
    writeWords(arguments);
  }
}

/**
  Output a woodWOP comment.
*/
function writeSimpleComment(text) {
  writeSimpleBlock("\\ " + text);
}

/**
  Output an ISO comment.
*/
function writeComment(text) {
  writeBlock("(" + text + ")");
}

/**
  Output a KM comment.
*/
function writeKMComment(text) {
  writeVar("KM", text);
}

function writeVal(name, value) {
  writeln(name + "=" + value);
}

function writeVar(name, value) {
  writeln(name + "=\"" + value + "\"");
}

var SMOOTH_DEFINE = 0;
var SMOOTH_RESET = 1;
var SMOOTH_ENABLE = 2;
var SMOOTH_DISABLE = 3;
var currentSmoothing = SMOOTH_DISABLE;
var smoothing = {enabled:false, pathDev:0.02, trackDev:1};
function setSmoothing(type) {
  if (!smoothing.enabled || type == currentSmoothing ||
    (hasParameter("operation-strategy") && (getParameter("operation-strategy") == "drill"))) {
    return;
  }

  switch (type) {
  case SMOOTH_DEFINE:
    writeln(
      "#HSC[BSPLINE PATH_DEV=" + spatialFormat.format(smoothing.pathDev) +
      " TRACK_DEV=" + spatialFormat.format(smoothing.trackDev) + "]"
    );
    writeln("#SET SLOPE PROFIL[3]");
    currentSmoothing = SMOOTH_DISABLE;
    break;
  case SMOOTH_RESET:
    writeln("#SET SLOPE PROFIL");
    currentSmoothing = SMOOTH_DISABLE;
    break;
  case SMOOTH_ENABLE:
    writeln("#HSC ON");
    currentSmoothing = SMOOTH_ENABLE;
    break;
  case SMOOTH_DISABLE:
    writeln("#HSC OFF");
    currentSmoothing = SMOOTH_DISABLE;
    break;
  }
}

function coordinatesAreSame(xyz1, xyz2) {
  if (xyzFormat.getResultingValue(xyz1.x) != xyzFormat.getResultingValue(xyz2.x) ||
      xyzFormat.getResultingValue(xyz1.y) != xyzFormat.getResultingValue(xyz2.y) ||
      xyzFormat.getResultingValue(xyz1.z) != xyzFormat.getResultingValue(xyz2.z)) {
    return false;
  }
  return true;
}

function anglesAreSame(abc1, abc2) {
  if (eulerFormat.getResultingValue(abc1.x) != eulerFormat.getResultingValue(abc2.x) ||
      eulerFormat.getResultingValue(abc1.y) != eulerFormat.getResultingValue(abc2.y) ||
      eulerFormat.getResultingValue(abc1.z) != eulerFormat.getResultingValue(abc2.z)) {
    return false;
  }
  return true;
}

function getDefinedWorkPlane(sectionId) {
  for (var i = 0; i < definedWorkPlanes.length; i++) {
    if (definedWorkPlanes[i].section == sectionId) {
      return definedWorkPlanes[i];
    }
  }
  return definedWorkPlanes[0];
}

function onOpen() {

  unit = MM; // output units are always in MM
  sequenceNumber = getProperty("sequenceNumberStart");
  useMultiAxisFeatures = getProperty("useMultiAxisFeatures");

  // smoothing variables
  smoothing.enabled = getProperty("useSmoothing");
  smoothing.pathDev = getProperty("smoothingPathDev");
  smoothing.trackDev = getProperty("smoothingTrackDev");

  // Define machine configuration if program has multi-axis operation(s)
  if (isMultiAxis() || getProperty("isoOnly")) {
    // physical machine configuration
    var headAngle = -39.18;
    var aAxis = createAxis({coordinate: 0, table: false, axis: [0, -Math.cos(toRad(headAngle)), -Math.sin(toRad(headAngle))], range: [-189, 189]});
    var cAxis = createAxis({coordinate: 2, table: false, axis: [0, 0, -1], range: [-365, 365], cyclic: false, reset:1});
    machineConfiguration = new MachineConfiguration(aAxis, cAxis);

    // virtual machine configuration expected by controller
    var virtualAAxis = createAxis({coordinate: 0, table: false, axis: [-1, 0, 0], range: [-99.99, 99.99]});
    var virtualCAxis = createAxis({coordinate: 2, table: false, axis: [0, 0, -1], cyclic: true}); // range: [-365, 365], cyclic: false});
    virtualConfiguration = new MachineConfiguration(virtualAAxis, virtualCAxis);

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

  if (programName) {
    writeSimpleComment(programName);
  }
  if (programComment) {
    writeSimpleComment(programComment);
  }

  writeln("[H");
  writeVar("VERSION", "4.0");
  writeVar("INCH", 0 /*(unit == IN) ? 1 : 0*/); // 0 mm, 1 inch // we map inches to mm
  writeVar("MAT", getProperty("machineType")); // HOMAG, CF-HOMAG, FK-HOMAG, WEEKE
  writeVar("OP", getProperty("doAllDrillingFirst") ? 1 : 0);
  writeVar("FM", getProperty("freeMotionParkPosition")); // free motion part posisiton 0-4
  writeVar("FW", spatialFormat.format(getProperty("freeMotionAdditional"))); // in mm

  var workpiece = getWorkpiece();
  var delta = Vector.diff(workpiece.upper, workpiece.lower);
  
  // variables
  writeln("");
  writeln("[001");
  /*
  writeVar("L", 0);
  writeVar("KM", "");
  writeVar("B", 0);
  writeVar("KM", "");
  writeVar("D", 0);
  writeVar("KM", "");
  */
  writeVar("i", 25.4);
  writeKMComment("Inch conversion");
  if (delta.isNonZero()) {
    writeVar("L", spatialFormat.format(delta.x));
    writeKMComment("Length");
    writeVar("W", spatialFormat.format(delta.y));
    writeKMComment("Width");
    writeVar("T", spatialFormat.format(delta.z));
    writeKMComment("Height");
  }
  writeVar("X", 0);
  writeKMComment("");
  writeVar("Y", 0);
  writeKMComment("");

  // workpiece
  if (delta.isNonZero()) {
    writeln("");
    writeln("<100 \\WerkStck\\");
    writeVar("LA", spatialFormat.format(delta.x));
    writeVar("BR", spatialFormat.format(delta.y));
    writeVar("DI", spatialFormat.format(delta.z));

    writeVar("FNX", spatialFormat.format(0));
    writeVar("FNY", spatialFormat.format(0));
    writeVar("AX", spatialFormat.format(0));
    writeVar("AY", spatialFormat.format(0));
  }

  if (!getProperty("isoOnly")) {
    var workPlaneID = 4;
    var id;
    var numberOfSections = getNumberOfSections();
    for (var i = 0; i < numberOfSections; ++i) {
      section = getSection(i);
      var euler = new Vector(0, 0, 0);
      var abc = new Vector(0, 0, 0);
      var origin = new Vector(0, 0, 0);
      if (!section.isMultiAxis()) {
        origin = getWorkOrigin(section);
        euler = section.workPlane.getEuler2(EULER_ZXZ_R); // used for contours
        abc = getWorkPlaneMachineABC(section.workPlane, false); // used for drilling
      }
      var found = false;
      for (var j = 0; j < definedWorkPlanes.length; ++j) {
        if (anglesAreSame(euler, definedWorkPlanes[j].euler) && (euler.isZero() || coordinatesAreSame(origin, definedWorkPlanes[j].origin))) {
          id = definedWorkPlanes[j].id;
          found = true;
          break;
        }
      }
      if (!found) {
        id = euler.isZero() ? "F0" : wcsFormat.format(workPlaneID++);
        var origin = id == "F0" ? new Vector(0, 0, 0) : origin;
        writeln("");
        writeln("[K");
        writeln("<00 \\Koordinatensystem\\");
        writeVar("NR", id);
        writeVar("XP", spatialFormat.format(origin.x)); // X-origin
        writeVar("XF", 1); // X-scale
        writeVar("YP", spatialFormat.format(origin.y)); // Y-origin
        writeVar("YF", 1); // Y-scale
        writeVar("ZP", spatialFormat.format(origin.z)); // Z-origin
        writeVar("ZF", 1); // Z-scale
        writeVar("D1", eulerFormat.format(euler.x)); // rotation about Z
        writeVar("KI", eulerFormat.format(euler.y)); // rotation about X'
        writeVar("D2", eulerFormat.format(euler.z)); // rotation about Z"
        writeVar("MI", 0); // mirrored
      }
      definedWorkPlanes.push({section:i, id:id, origin:origin, euler:euler, abc:abc, workPlane:section.workPlane});
    }
  }
}

function onComment(message) {
  var section = typeof currentSection == "undefined" ? getSection(0) : currentSection;
  if (section.isMultiAxis() || getProperty("isoOnly")) {
    writeComment(message);
  } else {
    writeSimpleComment(message);
  }
}

function createRotaryVariable(specifiers, format) {
  return new RotaryVariable(specifiers, format);
}

function RotaryVariable(specifiers, format) {
  if (!(this instanceof RotaryVariable)) {
    throw new Error(localize("RotaryVariable constructor called as a function."));
  }
  this.variable = createVariable(specifiers, format);
  this.format2 = format;
  this.current = 0;
}

RotaryVariable.prototype.format = function (value) {
  if (Math.abs(this.format2.getResultingValue(value) - this.format2.getResultingValue(this.current)) > getProperty("abcToler")) {
    this.current = value;
    return this.variable.format(value);
  } else {
    return this.variable.format(this.current);
  }
};

RotaryVariable.prototype.reset = function () {
  return this.variable.reset();
};

RotaryVariable.prototype.disable = function () {
  return this.variable.disable();
};

RotaryVariable.prototype.enable = function () {
  return this.variable.enable();
};

function onParameter(name, value) {
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

function forceFeed() {
  currentFeedId = undefined;
  feedOutput.reset();
}

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
  forceXYZ();
  forceABC();
  forceFeed();
}

var currentWorkPlaneABC = undefined;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

function cancelWorkPlane() {
  writeln("#CS OFF"); // cancel frame
  forceWorkPlane();
}

function setWorkPlane(abc, euler) {
  if (currentSection.isMultiAxis()) {
    return; // ignore
  }

  if (!((currentWorkPlaneABC == undefined) ||
        abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
        abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
        abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z))) {
    return; // no change
  }

  onCommand(COMMAND_UNLOCK_MULTI_AXIS);
  /* if (!retracted) {
    writeRetract(Z);
  }*/

  if (useMultiAxisFeatures) {
    if (machineConfiguration.isMultiAxisConfiguration() && useABCPrepositioning) {
      if (euler.isNonZero()) {
        var origin = getWorkOrigin(currentSection);
        writeln(
          "#CS ON[" +
          xyzFormat.format(origin.x) + "," + xyzFormat.format(origin.y) + "," + xyzFormat.format(origin.z) + "," +
          eulerFormat.format(euler.z) + "," + eulerFormat.format(euler.y) + "," + eulerFormat.format(euler.x) + "]"
        ); // set frame
      }
      gMotionModal.reset();
      var abc1 = getABC(abc);
      writeBlock(
        gMotionModal.format(0),
        conditional(machineConfiguration.isMachineCoordinate(0), "A" + abcFormat.format(abc1.x)),
        conditional(machineConfiguration.isMachineCoordinate(1), "B" + abcFormat.format(abc1.y)),
        conditional(machineConfiguration.isMachineCoordinate(2), "C" + abcFormat.format(abc1.z))
      );
    }
  } else {
    var abc1 = getABC(abc);
    writeBlock(
      gMotionModal.format(0),
      conditional(machineConfiguration.isMachineCoordinate(0), "A" + abcFormat.format(abc1.x)),
      conditional(machineConfiguration.isMachineCoordinate(1), "B" + abcFormat.format(abc1.y)),
      conditional(machineConfiguration.isMachineCoordinate(2), "C" + abcFormat.format(abc1.z))
    );
  }
  
  onCommand(COMMAND_LOCK_MULTI_AXIS);

  currentWorkPlaneABC = abc;
}

var closestABC = false; // choose closest machine angles
var currentMachineABC;

function getWorkPlaneMachineABC(workPlane, rotate) {
  // calculate ISO plane
  if (useISO) {
    return getWorkPlaneMachineISO(workPlane, rotate);
  }

  var W = workPlane; // map to global frame

  // Workplane angles are between -360 - 360 : Beta=A, Alpha=C
  var abc = W.getTurnAndTilt(Y, Z);
  if (abc.y != 0) {
    abc.setZ(Math.PI + abc.z); // axis rotates in opposite direction, can't specify direction with Turn and Tilt
  }
  if (abc.y < 0) {
    abc.setY(-abc.y);
    abc.setZ(abc.z + Math.PI);
  }
  if (abc.z < 0) {
    abc.setZ(abc.z + (Math.PI * 2));
  }
  if (eulerFormat.format(abc.z) > 360) {
    abc.setZ(abc.z - (Math.PI * 2));
  }
  return abc;
}

function getWorkPlaneMachineISO(workPlane, rotate) {
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

/** calculates the virtual ABC position from the physical ABC position */
function getABC(_abc) {
  var axis = machineConfiguration.getDirection(_abc);
  var both = virtualConfiguration.getABCByDirectionBoth(axis);

  var abc1 = remapABC(both.first, _abc);
  var abc2 = remapABC(both.second, _abc);

  var abc = new Vector(abc1.x, abc1.y, abc1.z);
  if (Math.abs(abc2.x - _abc.x) < Math.abs(abc1.x - _abc.x)) {
    abc = new Vector(abc2.x, abc2.y, abc2.z);
  }
  if (abcFormat.format(abc.x) == 0) { // protect against C0 when tool is vertical
    abc.setZ(previousABC.z);
  }

  if (!virtualConfiguration.getAxisV().isCyclic()) {
    if ((radianFormat.getResultingValue(abc.x) < virtualConfiguration.getAxisU().getRange().getMinimum()) ||
        (radianFormat.getResultingValue(abc.x) > virtualConfiguration.getAxisU().getRange().getMaximum())) {
      error(subst(localize("A%1 is outside of the virtual limits of the machine"), abcFormat.format(abc.x)));
      return abc;
    }
    if ((radianFormat.getResultingValue(abc.z) < virtualConfiguration.getAxisV().getRange().getMinimum()) ||
        (radianFormat.getResultingValue(abc.z) > virtualConfiguration.getAxisV().getRange().getMaximum())) {
      error(subst(localize("C%1 is outside of the virtual limits of the machine"), abcFormat.format(abc.z)));
      return abc;
    }
  }
  return abc;
}

/** calculate the closest virtual C-axis to the physical C-axis position */
function remapABC(_abc, _currentABC) {
  var abc = new Vector(_abc.x, _abc.y, _abc.z);
  if (abcFormat.getResultingValue(_abc.x) == 0 && abcFormat.getResultingValue(_abc.z) == 0) {
    abc.setZ(cOutput.getCurrent());
  }
  var dist = Math.abs(abc.z - _currentABC.z);

  if (virtualConfiguration.getAxisV().isCyclic() || ((_abc.z + Math.PI * 2) <= virtualConfiguration.getAxisV().getRange().getMaximum())) {
    var dist1 = Math.abs((_abc.z + Math.PI * 2) - _currentABC.z);
    if (dist1 < dist) {
      dist = dist1;
      abc.setZ(_abc.z + Math.PI * 2);
    }
  }
  if (virtualConfiguration.getAxisV().isCyclic() || ((_abc.z - Math.PI * 2) >= virtualConfiguration.getAxisV().getRange().getMinimum())) {
    var dist1 = Math.abs((_abc.z - Math.PI * 2) - _currentABC.z);
    if (dist1 < dist) {
      dist = dist1;
      abc.setZ(_abc.z - Math.PI * 2);
    }
  }
  return abc;
}

function getWorkOrigin(section) {
  var workpiece = getWorkpiece();
  var shift = workpiece.lower;
  var origin = Vector.diff(section.workOrigin, shift);
  return origin;
}

function onSection() {

  // origin is always at lower left of part, except for 3+2 operations, which use the operation origin
  workOrigin = currentSection.workOrigin;
  var forward = currentSection.workPlane.forward;
  cancelTransformation();
  if (getProperty("shiftOrigin") &&
     (currentSection.isMultiAxis() || isSameDirection(forward, new Vector(0, 0, 1))) ||
     (!getProperty("isoOnly") && (getParameter("operation-strategy", "") == "drill") && (Math.abs(Vector.dot(forward, new Vector(0, 0, 1))) < 1e-7))) { // horizontal drilling
    var workpiece = getWorkpiece();
    var shift = currentSection.workPlane.getTransposed().multiply(workpiece.lower);
    setTranslation(new Vector(-shift.x, -shift.y, -shift.z));
  }

  useISO = currentSection.isMultiAxis() || getProperty("isoOnly");
  tcpActive = true;

  var abc = new Vector(0, 0, 0);
  var abcPlane = new Vector(0, 0, 0);
  if (useISO) {
    if (currentSection.isMultiAxis()) {
      abc = currentSection.getInitialToolAxisABC();
    } else { // pure 3D
      abc = getWorkPlaneMachineABC(currentSection.workPlane, !useMultiAxisFeatures);
      if (useMultiAxisFeatures) {
        var euler = currentSection.workPlane.getEuler2(EULER_ZYX_R);
        abcPlane = new Vector(euler.x, euler.y, euler.z);
        tcpActive = abc.isZero();
      }
    }
    redirectToBuffer(); // ISO operations output in onClose along with all other operations

    var comment = hasParameter("operation-comment") ? getParameter("operation-comment") : "";
    var notes = (getProperty("showNotes") && hasParameter("notes")) ? getParameter("notes") : "";
    if (comment || notes) {
      writeln("");
      writeln("<101 \\Kommentar\\");
      if (comment) {
        writeKMComment(comment);
        if (notes) {
          writeKMComment("");
        }
      }
      if (notes) {
        var lines = String(notes).split("\n");
        var r1 = new RegExp("^[\\s]+", "g");
        var r2 = new RegExp("[\\s]+$", "g");
        for (line in lines) {
          var comment = lines[line].replace(r1, "").replace(r2, "");
          if (comment) {
            writeKMComment(comment);
          }
        }
      }
    }

    var initialPosition = getFramePosition(currentSection.getInitialPosition());
    var tcpPosition = tcpActive ? initialPosition : currentSection.workPlane.multiply(initialPosition);
    writeln("");
    writeln("<153\\Universal Makro\\");
    writeVar("LOCAL", 1);
    writeVar("XA", xyzFormat.format(tcpPosition.x)); // initial XYZ position
    writeVar("YA", xyzFormat.format(tcpPosition.y));
    writeVar("ZA", xyzFormat.format(tcpPosition.z));
    writeVar("WI", abcFormat.format(abc.z)); // initial C-axis rotation
    writeVar("WZ", tool.number);
    writeVar("SM", 1); // rpm mode
    writeVar("S_", integerFormat.format(spindleSpeed));
    if (hasParameter("operation:tool_feedCutting")) {
      writeVar("F_", isoFeedFormat.format(getParameter("operation:tool_feedCutting")));
    }
    writeVar("WWP", 0); // 1 = evaluate woodWOP parameters
    writeVar("BBA", 0); // 1 = evaluate processing range
    writeVar("KRI", 0); // 1 = spindle is not orientated perpendicular
    writeVar("P1", 0); // parameters
    writeVar("P2", 0);
    writeVar("P3", 0);
    writeVar("P4", 0);
    writeVar("PX1", 0); // operation range
    writeVar("PY1", 0);
    writeVar("PX2", 0);
    writeVar("PY2", 0);

    writeln("");
    writeln("STARTLOCAL");
    writeln("L UNCVK40");

    if (spindleSpeed != 0) {
      writeln("\"STRSPINDEL\"");
    }
    setSmoothing(SMOOTH_DEFINE);

    if (tcpActive) {
      writeln("#RTCP ON");
      forceAny();
    } else {
      writeln("#RTCP ON"); // required with #CS plane
      forceWorkPlane();
      setWorkPlane(abc, abcPlane);
      forceXYZ();
    }

    gMotionModal.reset();
    if (tcpActive) { // multi-axis
      var abc1 = getABC(abc);
      writeBlock(gMotionModal.format(0), cOutput.format(abc1.z));
      writeBlock(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), aOutput.format(abc1.x));
      writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
      previousABC = new Vector(abc1.x, abc1.y, abc1.z);
    } else { // 3 + 2
      writeBlock(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), zOutput.format(initialPosition.z));
    }
  }
}

function onSpindleSpeed(spindleSpeed) {
  if (useISO) { // cannot output spindle speed in the middle of a tpaCAD contour
    writeVar("S_A", integerFormat.format(spindleSpeed));
  }
}

function onDwell(seconds) {
}

function onCycle() {
}

function onCyclePoint(x, y, z) {
  if (useISO) {
    expandCyclePoint(x, y, z);
  } else {
    machining.push({id:-1, sectionId:getCurrentSectionId(), p:new Vector(x, y, z), cycle:cycle});
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

// buffer straight line moves to reduce profile size
var linearMove;
var linearFeed;
var linearDirection;
var linearIsBuffered = false;

function pushLinear(x, y, z, feed) {
  // don't output duplicate points
  var currentPosition = getCurrentPosition();
  if ((xyzFormat.getResultingValue(x - currentPosition.x) == 0) && (xyzFormat.getResultingValue(y - currentPosition.y) == 0) &&
      (xyzFormat.getResultingValue(z - currentPosition.z) == 0)) { // ignore zero length lines
    return;
  }

  // buffer moves in same direction
  var dir = Vector.diff(new Vector(x, y, z), getCurrentPosition()).getNormalized();
  if (linearIsBuffered) {
    if (isSameDirection(dir, linearDirection) && feed == linearFeed) {
      linearMove = new Vector(x, y, z);
      return;
    }
    flushLinear(linearMove.x, linearMove.y, linearMove.z, linearFeed);
  }

  // buffer move if next record is linear
  if (getNextRecord().getType() == RECORD_LINEAR) {
    linearMove = new Vector(x, y, z);
    linearFeed = feed;
    linearDirection = dir;
    linearIsBuffered = true;
  } else {
    flushLinear(x, y, z, feed);
  }
}

function flushLinear(x, y, z, feed) {
  writeln("");
  writeln("$E" + entityId);
  writeln("KL");
  writeVal("X", xyzFormat.format(x));
  writeVal("Y", xyzFormat.format(y));
  writeVal("Z", xyzFormat.format(z));
  entityId += 1;

  linearIsBuffered = false;
}

function onRapid(_x, _y, _z) {
  if (useISO) {
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);
    if (x || y || z) {
      if (pendingRadiusCompensation >= 0) {
        error(localize("Radius compensation mode cannot be changed at rapid traversal."));
        return;
      }
      setSmoothing(SMOOTH_DISABLE);
      writeBlock(gMotionModal.format(0), x, y, z);
      forceFeed();
    }
    return;
  }

  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation is not supported."));
    return;
  }

  if (linearIsBuffered) {
    flushLinear(linearMove.x, linearMove.y, linearMove.z, linearFeed);
  }

  if (inContour) {
    machining.push({id:contourId, sectionId:getCurrentSectionId(), entities:entityId, feed:currentFeed});
    inContour = false;
  }
}

function onLinear(_x, _y, _z, feed) {
  if (useISO) {
    setSmoothing(SMOOTH_ENABLE);

    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);
    var f = feedOutput.format(feed);
    if (x || y || z) {
      if (pendingRadiusCompensation >= 0) {
        pendingRadiusCompensation = -1;
        switch (radiusCompensation) {
        case RADIUS_COMPENSATION_LEFT:
          writeBlock(gMotionModal.format(1), x, y, z, f, gFormat.format(41));
          break;
        case RADIUS_COMPENSATION_RIGHT:
          writeBlock(gMotionModal.format(1), x, y, z, f, gFormat.format(42));
          break;
        default:
          writeBlock(gMotionModal.format(1), x, y, z, f, gFormat.format(40));
        }
      } else {
        writeBlock(gMotionModal.format(1), x, y, z, f);
      }
    } else if (f) {
      if (getNextRecord().isMotion()) { // try not to output feed without motion
        forceFeed(); // force feed on next line
      } else {
        writeBlock(gMotionModal.format(1), f);
      }
    }
    return;
  }

  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation is not supported."));
    return;
  }

  /*
  if ((movement != MOVEMENT_CUTTING) && (movement != MOVEMENT_FINISH_CUTTING)) {
    if (inContour) {
      machining.push({id:contourId, sectionId:getCurrentSectionId(), entities:entityId, feed:currentFeed});
      inContour = false;
    }
    return;
  }
*/

  if (!inContour) {
    writeln("");
    contourId += 1;
    writeln("]" + contourId);
    entityId = 0;

    var start = getCurrentPosition();
    writeln("");
    writeln("$E" + entityId);
    writeln("KP");
    writeVal("X", xyzFormat.format(start.x));
    writeVal("Y", xyzFormat.format(start.y));
    writeVal("Z", xyzFormat.format(start.z));
    writeVal("KO", getDefinedWorkPlane(getCurrentSectionId()).id);
    entityId += 1;

    currentFeed = feed;
    inContour = true;
  }

  if ((movement == MOVEMENT_CUTTING) || (movement == MOVEMENT_FINISH_CUTTING)) {
    currentFeed = feed;
  }
  // currentFeed = Math.min(currentFeed, feed);
  
  pushLinear(_x, _y, _z, feed);
}

function onRapid5D(_x, _y, _z, _a, _b, _c) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode cannot be changed at rapid traversal."));
    return;
  }

  var abc = getABC(new Vector(_a, _b, _c));

  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(abc.x);
  var b = bOutput.format(abc.y);
  var c = cOutput.format(abc.z);
  if (x || y || z || a || b || c) {
    setSmoothing(SMOOTH_DISABLE);
    writeBlock(gMotionModal.format(0), x, y, z, a, b, c);
    forceFeed();
  }
  previousABC = new Vector(abc.x, abc.y, abc.z);
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for 5-axis move."));
    return;
  }

  setSmoothing(SMOOTH_ENABLE);
  var abc = getABC(new Vector(_a, _b, _c));

  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(abc.x);
  var b = bOutput.format(abc.y);
  var c = cOutput.format(abc.z);
  var f = feedOutput.format(feed);
  if (x || y || z || a || b || c) {
    writeBlock(gMotionModal.format(1), x, y, z, a, b, c, f);
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(1), f);
    }
  }
  previousABC = new Vector(abc.x, abc.y, abc.z);
}

// Start of onRewindMachine logic
/***** Be sure to add 'safeRetractDistance' to post getProperty(" ")*****/
var performRewinds = true; // enables the onRewindMachine logic
var safeRetractFeed = (unit == IN) ? 20 : 500;
var safePlungeFeed = (unit == IN) ? 10 : 250;
var stockAllowance = new Vector(toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN));

/** Allow user to override the onRewind logic. */
function onRewindMachineEntry(_a, _b, _c) {
  return false;
}

/** Retract to safe position before indexing rotaries. */
function moveToSafeRetractPosition(isRetracted) {
  if (getProperty("zHomePosition") <= getCurrentPosition().z) {
    error(localize("Z-Home position must be higher than current Z position during a retract and reconfigure."));
    return;
  }
  writeRetract(Z);
}

/** Return from safe position after indexing rotaries. */
function returnFromSafeRetractPosition(position, abc) {
  forceXYZ();
  xOutput.reset();
  yOutput.reset();
  zOutput.reset();
  onRapid5D(position.x, position.y, position.z, abc.x, abc.y, abc.z);
  //zOutput.enable();
  //onExpandedRapid(position.x, position.y, position.z);
}

/** Intersect the point-vector with the stock box. */
function intersectStock(point, direction) {
  var stock = getWorkpiece();
  stock.expandTo(Vector.sum(stock.lower, getTranslation()));
  stock.expandTo(Vector.sum(stock.upper, getTranslation()));
  var intersection = stock.getRayIntersection(point, direction, stockAllowance);
  return intersection === null ? undefined : intersection.second;
}

/** Calculates the retract point using the stock box and safe retract distance. */
function getRetractPosition(currentPosition, currentDirection) {
  var retractPos = intersectStock(currentPosition, currentDirection);
  if ((retractPos == undefined) || (Vector.diff(currentPosition, retractPos).length > tool.getBodyLength())) {
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

  var abc = getABC(new Vector(_a, _b, _c));

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
      abcFormat.format(abc.x) + ", " + abcFormat.format(abc.y) + ", " + abcFormat.format(abc.z)
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
  onLinear5D(position.x, position.y, position.z, currentABC.x, currentABC.y, currentABC.z, safeRetractFeed);
  
  // Cancel so that tool doesn't follow tables
  //writeBlock(gFormat.format(49), formatComment("TCPC OFF"));

  // Position to safe machine position for rewinding axes
  moveToSafeRetractPosition(false);

  // Rotate axes to new position above reentry position
  xOutput.disable();
  yOutput.disable();
  zOutput.disable();
  onRapid5D(position.x, position.y, position.z, _a, _b, _c);
  xOutput.enable();
  yOutput.enable();
  zOutput.enable();

  // Reinstate
  // writeBlock(gFormat.format(234), //hFormat.format(tool.lengthOffset), formatComment("TCPC ON"));

  // Move back to position above part
  if (currentSection.getOptimizedTCPMode() != 0) {
    position = machineConfiguration.getOrientation(new Vector(_a, _b, _c)).getTransposed().multiply(retractPosition);
  }
  returnFromSafeRetractPosition(position, new Vector(_a, _b, _c));

  // Plunge tool back to original position
  if (currentSection.getOptimizedTCPMode() != 0) {
    currentTool = machineConfiguration.getOrientation(new Vector(_a, _b, _c)).getTransposed().multiply(currentTool);
  }
  onLinear5D(currentTool.x, currentTool.y, currentTool.z, _a, _b, _c, safePlungeFeed);
}
// End of onRewindMachine logic

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  if (useISO) {
    isoCircular(clockwise, cx, cy, cz, x, y, z, feed);
    return;
  }

  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }

  if (linearIsBuffered) {
    flushLinear(linearMove.x, linearMove.y, linearMove.z, linearFeed);
  }

  /*
  if ((movement != MOVEMENT_CUTTING) && (movement != MOVEMENT_FINISH_CUTTING)) {
    if (inContour) {
      machining.push({id:contourId, sectionId:getCurrentSectionId(), entities:entityId, feed:currentFeed});
      inContour = false;
    }
    return;
  }
*/

  if (!inContour) {
    writeln("");
    writeln("]" + contourId);
    contourId += 1;
    entityId = 0;

    var start = getCurrentPosition();
    writeln("");
    writeln("$E" + entityId);
    writeln("KP");
    writeVal("X", xyzFormat.format(start.x));
    writeVal("Y", xyzFormat.format(start.y));
    writeVal("Z", xyzFormat.format(start.z));
    writeVal("KO", getDefinedWorkPlane(getCurrentSectionId()).id);
    entityId += 1;

    currentFeed = feed;
    inContour = true;
  }

  if ((movement == MOVEMENT_CUTTING) || (movement == MOVEMENT_FINISH_CUTTING)) {
    currentFeed = feed;
  }
  // currentFeed = Math.min(currentFeed, feed);

  switch (getCircularPlane()) {
  case PLANE_XY:
    writeln("");
    writeln("$E" + entityId);
    writeln("KA");
    writeVal("X", xyzFormat.format(x));
    writeVal("Y", xyzFormat.format(y));
    writeVal("Z", xyzFormat.format(z));
    // var ip = getPositionU(0.5);
    // writeVal("I", xyzFormat.format(ip.x));
    // writeVal("J", xyzFormat.format(ip.y));
    // writeVal("K", xyzFormat.format(ip.z));
    writeVal("R", rFormat.format(getCircularRadius() + toPreciseUnit(0.002, MM))); // around rounding issue
    var small = Math.abs(getCircularSweep()) <= Math.PI;
    if (small) {
      writeVal("DS", clockwise ? 0 : 1);
    } else {
      writeVal("DS", clockwise ? 2 : 3);
    }
    entityId += 1;
    break;
  default:
    linearize(tolerance);
  }
}

function isoCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }

  var start = getCurrentPosition();

  if (isFullCircle()) {
    if (getProperty("useRadius") || isHelical()) { // radius mode does not support full arcs
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    case PLANE_ZX:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
      break;
    case PLANE_YZ:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else if (!getProperty("useRadius")) {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    case PLANE_ZX:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
      break;
    case PLANE_YZ:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
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
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), feedOutput.format(feed));
      break;
    case PLANE_ZX:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), feedOutput.format(feed));
      break;
    case PLANE_YZ:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

function onCommand(command) {
}

function onSectionEnd() {
  if (useISO) {
    writeRetract(Z);
    if (aOutput.getCurrent != 0) {
      writeBlock(gMotionModal.format(0), aOutput.format(0));
    }
    if (cOutput.getCurrent != 0) {
      writeBlock(gMotionModal.format(0), cOutput.format(0));
    }
    if (tcpActive) {
      writeln("#RTCP OFF");
    } else {
      cancelWorkPlane();
      writeln("#RTCP OFF");
    }
    setSmoothing(SMOOTH_DISABLE);
    setSmoothing(SMOOTH_RESET);
    writeln("L UNCHK40");
    writeln("ENDLOCAL");
  }

  if (isRedirecting()) {
    redirectBuffer[redirectIndex] = getRedirectionBuffer();
    closeRedirection();
    machining.push({id:REDIRECT_ID, index:redirectIndex++});
  } else if (inContour) {
    machining.push({id:contourId, sectionId:getCurrentSectionId(), entities:entityId, feed:currentFeed});
    inContour = false;
  }
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
      if (!machineConfiguration.hasHomePositionX()) {
        error(localize("A home position has not been defined in X."));
        return;
      }
      words.push(xOutput.format(machineConfiguration.getHomePositionX()));
      break;
    case Y:
      if (!machineConfiguration.hasHomePositionY()) {
        error(localize("A home position has not been defined in Y."));
        return;
      }
      words.push(yOutput.format(machineConfiguration.getHomePositionY()));
      break;
    case Z:
      if (getProperty("zHomePosition") > getCurrentPosition().z) {
        words.push(zOutput.format(getProperty("zHomePosition")));
        retracted = true; // specifies that the tool has been retracted to the safe plane
      }
      break;
    default:
      error(localize("Bad axis specified for writeRetract()."));
      return;
    }
  }
  if (words.length > 0) {
    writeBlock(gMotionModal.format(0), words); // retract
  }
}

function onClose() {

  for (var i = 0; i < machining.length; ++i) {
    var m = machining[i];
    var tool  = 0;
    var wpData;
    var forward;
    if (m.id != REDIRECT_ID) {
      wpData = getDefinedWorkPlane(m.sectionId);
      forward = wpData.workPlane.forward;
      tool = getSection(m.sectionId).getTool();
    }
    writeln("");

    if (m.id == REDIRECT_ID) {
      write(redirectBuffer[m.index]);
    } else if (m.id < 0) {
      if (wpData.id == "F0") { // XY drilling operation
        writeln("<102 \\BohrVert\\");
        writeVar("XA", xyzFormat.format(m.p.x));
        writeVar("YA", xyzFormat.format(m.p.y));
        writeVar("TI", xyzFormat.format(m.cycle.depth));
        if (getProperty("useBoreToolNumber")) {
          writeVar("TNO", tool.number);
        } else {
          writeVar("DU", spatialFormat.format(tool.diameter));
        }
        writeVar("F_", feedFormat.format(m.cycle.feedrate));
      } else if (Math.abs(Vector.dot(forward, new Vector(0, 0, 1)) < 1e-7)) { // horizontal drilling
        var BM;
        var WI = "";
        if (isSameDirection(forward, new Vector(1, 0, 0))) {
          BM = "XM";
        } else if (isSameDirection(forward, new Vector(-1, 0, 0))) {
          BM = "XP";
        } else if (isSameDirection(forward, new Vector(0, 1, 0))) {
          BM = "YM";
        } else if (isSameDirection(forward, new Vector(0, -1, 0))) {
          BM = "YP";
        } else {
          BM = "C";
          WI = eulerFormat.format(wpData.abc.z);
        }
        m.p.setZ(m.p.z + m.cycle.depth);
        var xyz = wpData.workPlane.multiply(m.p);
        writeln("<103 \\BohrHoriz\\");
        writeVar("XA", xyzFormat.format(xyz.x));
        writeVar("YA", xyzFormat.format(xyz.y));
        writeVar("ZA", xyzFormat.format(xyz.z));
        writeVar("BM", BM);
        if (WI) {
          writeVar("WI", WI);
        }
        writeVar("TI", xyzFormat.format(m.cycle.depth));
        if (getProperty("useBoreToolNumber")) {
          writeVar("TNO", tool.number);
        } else {
          writeVar("DU", spatialFormat.format(tool.diameter));
        }
        writeVar("F_", feedFormat.format(m.cycle.feedrate));
        // writeVar("KO", wpData.id);
      } else { // 3+2 drilling operation
        m.p.setZ(m.p.z + m.cycle.depth);
        var xyz = m.p; // wpData.workPlane.multiply(m.p);
        writeln("<104 \\BohrUniv\\");
        writeVar("XA", xyzFormat.format(xyz.x));
        writeVar("YA", xyzFormat.format(xyz.y));
        writeVar("ZA", xyzFormat.format(xyz.z));
        // writeVar("CA", eulerFormat.format(wpData.abc.z));
        // writeVar("WI", eulerFormat.format(wpData.abc.y));
        writeVar("TI", xyzFormat.format(m.cycle.depth));
        if (getProperty("useBoreToolNumber")) {
          writeVar("TNO", tool.number);
        } else {
          writeVar("DU", spatialFormat.format(tool.diameter));
        }
        writeVar("F_", feedFormat.format(m.cycle.feedrate));
        writeVar("KO", wpData.id);
      }
    } else if (getDefinedWorkPlane(m.sectionId).id == "F0") { // vertical contour
      writeln("<105 \\Konturfraesen\\");
      writeVar("EA", m.id + ":" + 0);
      writeVar("MDA", "SEN");
      writeVar("EE", m.id + ":" + (m.entities - 1));
      writeVar("MDE", "SEN_AB");
      writeVar("RK", "NOWRK");
      writeVar("TNO", tool.number);
      writeVar("ZA", "@0"); // ignore all Z in program
      writeVar("F_", feedFormat.format(m.feed));
      writeVar("SM", 1); // rpm
      if (getProperty("useSmoothing")) {
        writeVar("KG", 2); // 0 = off, 1 = Contour mode, 2 = Bspline Mode
        writeVar("MBA", spatialFormat.format(getProperty("smoothingPathDev")));
        writeVar("MWA", spatialFormat.format(getProperty("smoothingTrackDev")));
      }
      writeVar("S_A", integerFormat.format(tool.spindleRPM)); // use cutting speed, cannot output spindle speed in the middle of a contour
    } else if (Math.abs(Vector.dot(forward, new Vector(0, 0, 1))) < 1e-7) { // horizontal contour
      writeln("<133 \\Horizontal Konturfraesen\\");
      writeVar("EA", m.id + ":" + 0);
      writeVar("MDA", "SEN");
      writeVar("RK", "NOWRK");
      writeVar("EE", m.id + ":" + (m.entities - 1));
      writeVar("MDE", "SEN_AB");
      writeVar("EM", 0);
      writeVar("RI", 1);
      writeVar("TNO", tool.number);
      writeVar("SM", 1); // rpm
      writeVar("S_A", integerFormat.format(tool.spindleRPM)); // use cutting speed, cannot output spindle speed in the middle of a contour
      writeVar("F_", feedFormat.format(m.feed));
      writeVar("AB", 0); // distance to programmed contour
      writeVar("ZM", "@0"); // Z-mass
      if (getProperty("useSmoothing")) {
        writeVar("KG", 2); // 0 = off, 1 = Contour mode, 2 = Bspline Mode
        writeVar("MBA", spatialFormat.format(getProperty("smoothingPathDev")));
        writeVar("MWA", spatialFormat.format(getProperty("smoothingTrackDev")));
      }
    } else { // 3+2 contour
      writeln("<140 \\Vektor Konturfraesen\\");
      writeVar("EA", m.id + ":" + 0);
      writeVar("MDA", "SEN");
      writeVar("RK", "NOWRK");
      writeVar("EE", m.id + ":" + (m.entities - 1));
      writeVar("MDE", "SEN_AB");
      writeVar("EM", 0);
      writeVar("RI", 1);
      writeVar("TNO", tool.number);
      writeVar("SM", 1); // rpm
      writeVar("S_A", integerFormat.format(tool.spindleRPM)); // use cutting speed, cannot output spindle speed in the middle of a contour
      writeVar("F_", feedFormat.format(m.feed));
      writeVar("AB", 0); // distance to programmed contour
      writeVar("ZM", "@0"); // Z-mass
      if (getProperty("useSmoothing")) {
        writeVar("KG", 2); // 0 = off, 1 = Contour mode, 2 = Bspline Mode
        writeVar("MBA", spatialFormat.format(getProperty("smoothingPathDev")));
        writeVar("MWA", spatialFormat.format(getProperty("smoothingTrackDev")));
      }
    }
  }

  writeln("");
  writeln("<101 \\Kommentar\\");
  if (programName) {
    writeKMComment(programName);
  }
  if (programComment) {
    writeKMComment(programComment);
  }
  writeVar("KAT", "Kommentar");
  writeVar("MNM", "Kommentar");

  writeln("!");
}

function setProperty(property, value) {
  properties[property].current = value;
}
