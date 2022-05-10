/**
  Copyright (C) 2018-2020 by Autodesk, Inc.
  All rights reserved.

  3D additive printer post configuration.

  $Revision: 43345 527164c2d477673e66ead26e77f99d29d25a5c2f $
  $Date: 2021-07-06 13:54:42 $
  
  FORKID {35875924-78F9-4BF9-A73D-25D50699D4C9}
*/

description = "Bresser";
vendor = "Bresser";
vendorUrl = "https://www.bresser.de/en/Weather-Time/3D-Printer/BRESSER-WIFI-3D-Printer.html";
legal = "Copyright (C) 2012-2020 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45633;

longDescription = "Post for exporting toolpath to the Bresser range of printers in gcode format";

extension = "g";
setCodePage("ascii");

capabilities = CAPABILITY_ADDITIVE;
highFeedrate = 9000;
// used for arc support or linearization
tolerance = spatial(0.002, MM); // may be set higher ?
minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.4, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = false; // disable helical support
allowSpiralMoves = false; // disable spiral support
allowedCircularPlanes = 1 << PLANE_XY; // allow XY circular motion

// user-defined properties
properties = {
  // temperature tower features
  _trigger: {
    title: "Trigger",
    description: "Specifies whether to use the Z-height or layer number as the trigger to change temperature of the active Extruder.",
    type: "enum",
    values: [
      {title: "Disabled", id: "disabled"},
      {title: "by Height", id: "height"},
      {title: "by Layer", id: "layer"}
    ],
    value: "disabled",
    scope: "post",
    group: "temperatureTower"
  },
  _triggerValue: {
    title: "Trigger Value",
    description: "This number specifies either the Z-height or the layer number increment on when a change should be triggered.",
    type: "number",
    value: 10,
    scope: "post",
    group: "temperatureTower"
  },
  tempStart: {
    title: "Start Temperature",
    description: "Specifies the starting temperature for the active Extruder (degrees C). Note that the temperature specified in the print settings will be overridden by this value.",
    type: "integer",
    value: 190,
    scope: "post",
    group: "temperatureTower"
  },
  tempInterval: {
    title: "Temperature Interval",
    description: "Every step, increase the temperature of the active Extruder by this amount (degrees C).",
    type: "integer",
    value: 5,
    scope: "post",
    group: "temperatureTower"
  }
};
  
groupDefinitions = {
  temperatureTower: {
    title: "Temperature Tower",
    description: "Temperature Towers are used to test new filaments in order to identify the best printing temperature. " +
      "When utilized, this functionality generates a Gcode file where the temperature increases by a set amount, every step in height or layer number.",
    collapsed: true,
    order: 0
  }
};

// needed for range checking, will be effectively passed from Fusion
var printerLimits = {
  x: {min: 0, max: 150.0}, // defines the x bed size
  y: {min: 0, max: 150.0}, // defines the y bed size
  z: {min: 0, max: 150.0} // defines the z bed size
};

// for information only
var bedCenter = {
  x: 75.0,
  y: 75.0,
  z: 0.0
};

var extruderOffsets = [[0, 0, 0], [0, 0, 0]];
var activeExtruder = 0; // track the active extruder.

var xyzFormat = createFormat({decimals: (unit == MM ? 3 : 4)});
var xFormat = createFormat({decimals: (unit == MM ? 3 : 4)});
var yFormat = createFormat({decimals: (unit == MM ? 3 : 4)});
var zFormat = createFormat({decimals: (unit == MM ? 3 : 4)});
var aFormat = createFormat({prefix: "A", width: 1, zeropad: false, decimals: 0});
var bFormat = createFormat({prefix: "B", width: 1, zeropad: false, decimals: 0});
var gFormat = createFormat({prefix: "G", width: 1, zeropad: false, decimals: 0});
var mFormat = createFormat({prefix: "M", width: 2, zeropad: true, decimals: 0});
var tFormat = createFormat({prefix: "T", width: 1, zeropad: false, decimals: 0});
var feedFormat = createFormat({decimals: (unit == MM ? 0 : 1)});
var integerFormat = createFormat({decimals:0});
var dimensionFormat = createFormat({decimals: (unit == MM ? 3 : 4), zeropad: false, suffix: (unit == MM ? "mm" : "in")});

var gMotionModal = createModal({force: true}, gFormat); // modal group 1 - G0-G3, ...
var gPlaneModal = createModal({onchange: function () {gMotionModal.reset();}}, gFormat); // modal group 2 - G17-19 - actually unused
var gAbsIncModal = createModal({}, gFormat); // modal group 3 - G90-91

var xOutput = createVariable({prefix: "X"}, xFormat);
var yOutput = createVariable({prefix: "Y"}, yFormat);
var zOutput = createVariable({prefix: "Z"}, zFormat);
var feedOutput = createVariable({prefix: "F"}, feedFormat);
var eOutput = createVariable({prefix: "E"}, xyzFormat); // extrusion length
var sOutput = createVariable({prefix: "S", force: true}, xyzFormat); // parameter temperature or speed
var iOutput = createReferenceVariable({prefix:"I", force:true}, xyzFormat); // circular output
var jOutput = createReferenceVariable({prefix:"J", force:true}, xyzFormat); // circular output

// generic functions

// writes the specified block.
function writeBlock() {
  writeWords(arguments);
}

function writeComment(text) {
  writeln(";" + text);
}

// onOpen helper functions

function formatCycleTime(cycleTime) {
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

function getPrinterGeometry() {
  machineConfiguration = getMachineConfiguration();

  // get the printer geometry from the machine configuration
  printerLimits.x.min = 0 - machineConfiguration.getCenterPositionX();
  printerLimits.y.min = 0 - machineConfiguration.getCenterPositionY();
  printerLimits.z.min = 0 + machineConfiguration.getCenterPositionZ();

  printerLimits.x.max = machineConfiguration.getWidth() - machineConfiguration.getCenterPositionX();
  printerLimits.y.max = machineConfiguration.getDepth() - machineConfiguration.getCenterPositionY();
  printerLimits.z.max = machineConfiguration.getHeight() + machineConfiguration.getCenterPositionZ();

  // can be used in the post for documenting purpose.
  bedCenter.x = (machineConfiguration.getWidth() / 2.0) - machineConfiguration.getCenterPositionX();
  bedCenter.y = (machineConfiguration.getDepth() / 2.0) - machineConfiguration.getCenterPositionY();
  bedCenter.z = machineConfiguration.getCenterPositionZ();

  // get the extruder configuration
  extruderOffsets[0][0] = machineConfiguration.getExtruderOffsetX(1);
  extruderOffsets[0][1] = machineConfiguration.getExtruderOffsetY(1);
  extruderOffsets[0][2] = machineConfiguration.getExtruderOffsetZ(1);
  if (numberOfExtruders > 1) {
    extruderOffsets[1] = [];
    extruderOffsets[1][0] = machineConfiguration.getExtruderOffsetX(2);
    extruderOffsets[1][1] = machineConfiguration.getExtruderOffsetY(2);
    extruderOffsets[1][2] = machineConfiguration.getExtruderOffsetZ(2);
  }
}

function onOpen() {
  getPrinterGeometry();

  if (programName) {
    writeComment(programName);
  }
  if (programComment) {
    writeComment(programComment);
  }

  writeComment("Printer name: " + machineConfiguration.getVendor() + " " + machineConfiguration.getModel());
  writeComment("Print time: " + formatCycleTime(printTime));
  writeComment("Extruder 1 material used: " + dimensionFormat.format(getExtruder(1).extrusionLength));
  writeComment("Extruder 1 material name: " + getExtruder(1).materialName);
  writeComment("Extruder 1 filament diameter: " + dimensionFormat.format(getExtruder(1).filamentDiameter));
  writeComment("Extruder 1 nozzle diameter: " + dimensionFormat.format(getExtruder(1).nozzleDiameter));
  writeComment("Extruder 1 offset x: " + dimensionFormat.format(extruderOffsets[0][0]));
  writeComment("Extruder 1 offset y: " + dimensionFormat.format(extruderOffsets[0][1]));
  writeComment("Extruder 1 offset z: " + dimensionFormat.format(extruderOffsets[0][2]));
  writeComment("Extruder 1 max temp: " + integerFormat.format(getExtruder(1).temperature));

  if (hasGlobalParameter("ext2-extrusion-len") &&
    hasGlobalParameter("ext2-nozzle-dia") &&
    hasGlobalParameter("ext2-temp") && hasGlobalParameter("ext2-filament-dia") &&
    hasGlobalParameter("ext2-material-name")
  ) {
    writeComment("Extruder 2 material used: " + dimensionFormat.format(getExtruder(2).extrusionLength));
    writeComment("Extruder 2 material name: " + getExtruder(2).materialName);
    writeComment("Extruder 2 filament diameter: " + dimensionFormat.format(getExtruder(2).filamentDiameter));
    writeComment("Extruder 2 nozzle diameter: " + dimensionFormat.format(getExtruder(2).nozzleDiameter));
    writeComment("Extruder 2 offset x: " + dimensionFormat.format(extruderOffsets[1][0]));
    writeComment("Extruder 2 offset y: " + dimensionFormat.format(extruderOffsets[1][1]));
    writeComment("Extruder 2 offset z: " + dimensionFormat.format(extruderOffsets[1][2]));
    writeComment("Extruder 2 max temp: " + integerFormat.format(getExtruder(2).temperature));
  }
  writeComment("Bed temp: " + integerFormat.format(bedTemp));
  writeComment("Layer count: " + integerFormat.format(layerCount));

  writeComment("Width: " + dimensionFormat.format(printerLimits.x.max));
  writeComment("Depth: " + dimensionFormat.format(printerLimits.y.max));
  writeComment("Height: " + dimensionFormat.format(printerLimits.z.max));
  writeComment("Center x: " + dimensionFormat.format(bedCenter.x));
  writeComment("Center y: " + dimensionFormat.format(bedCenter.y));
  writeComment("Center z: " + dimensionFormat.format(bedCenter.z));
  writeComment("Count of bodies: " + integerFormat.format(partCount));
  writeComment("Fusion version: " + getGlobalParameter("version"));
}

//generic helper functions

function setFeedRate(value) {
  if (value > highFeedrate) {
    value = highFeedrate;
  }
  if (unit == IN) {
    value /= 25.4;
  }
  feedOutput.reset();
  writeBlock(gFormat.format(1), feedOutput.format(value));
}

function forceXYZE() {
  xOutput.reset();
  yOutput.reset();
  zOutput.reset();
  eOutput.reset();
}

function onSection() {
  var range = currentSection.getBoundingBox();
  axes = ["x", "y", "z"];
  formats = [xFormat, yFormat, zFormat];
  for (var element in axes) {
    var min = formats[element].getResultingValue(range.lower[axes[element]]);
    var max = formats[element].getResultingValue(range.upper[axes[element]]);
    if (printerLimits[axes[element]].max < max || printerLimits[axes[element]].min > min) {
      error(localize("A toolpath is outside of the build volume."));
    }
  }

  // apparently no code for defining the unit ?
  writeBlock(gAbsIncModal.format(90)); // absolute spatial co-ordinates
  // homing Z
  writeBlock(gFormat.format(28));
  writeBlock(mFormat.format(132), "X Y Z A B"); // read home position from eeprom

  // lower build plate
  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  writeBlock(gMotionModal.format(1), zOutput.format(initialPosition.z), feedOutput.format(toPreciseUnit(highFeedrate, MM)));

  writeBlock(gFormat.format(161), "X Y", feedOutput.format(toPreciseUnit(highFeedrate, MM)));

  writeBlock(mFormat.format(651));

  // apparently A100 for ABS, 80 for PLA 20 for idle
  // Check the material name for changing the A value
  var aValue = 100;
  var materialName = "";

  materialName = getExtruder(activeExtruder + 1).materialName;
  materialName = materialName.toUpperCase();
  materialName = materialName.substr(0, 3);
  if (materialName == "PLA") {
    aValue = 80;
  }
  writeBlock(mFormat.format(907), xOutput.format(100), yOutput.format(100), zOutput.format(40), aFormat.format(aValue), bFormat.format(20));

  writeBlock(mFormat.format(82)); // absolute extrusion co-ordinates
  forceXYZE();

  onExtruderChange(0);

  writeBlock(gFormat.format(92), eOutput.format(0));
  forceXYZE();
}

// miscellaneous entry functions

function onComment(message) {
  writeComment(message);
}

function onParameter(name, value) {
  switch (name) {
  // feedrate is set before rapid moves and extruder change
  case "feedRate":
    setFeedRate(value);
    break;
  }
}

// additive entry functions

function onBedTemp(temp, wait) {
  if (wait) {
    writeBlock(mFormat.format(7), tFormat.format(0));
  } else {
    writeBlock(mFormat.format(140), sOutput.format(temp));
  }
}

function onExtruderChange(id) {
  if (id < numberOfExtruders) {
    writeBlock(mFormat.format(108), tFormat.format(id));
    activeExtruder = id;
    forceXYZE();
  } else {
    error(localize("This printer doesn't support the extruder ") + integerFormat.format(id) + " !");
  }
}

function onExtrusionReset(length) {
  eOutput.reset();
  writeBlock(gFormat.format(92), eOutput.format(length));
}

function onExtruderTemp(temp, wait, id) {
  if (getProperty("_trigger") != "disabled" && (getCurrentPosition().z == 0)) {
    temp = getProperty("tempStart"); // override temperature with the starting temperature for the temp tower feature
  }
  if (id < numberOfExtruders) {
    if (wait) {
      writeBlock(mFormat.format(6), tFormat.format(id));
    } else {
      writeBlock(mFormat.format(104), sOutput.format(temp), tFormat.format(id));
    }
  } else {
    error(localize("This printer doesn't support the extruder ") + integerFormat.format(id) + " !");
  }
}

function onFanSpeed(speed, id) {
  if (speed == 0) {
    writeBlock(mFormat.format(107));
  } else {
    writeBlock(mFormat.format(106), sOutput.format(speed));
  }
}

var nextTriggerValue;
var newTemperature;
var maximumExtruderTemp = 260;
function executeTempTowerFeatures(num) {
  if (getProperty("_trigger") != "disabled") {
    var multiplier = getProperty("_trigger") == "height" ? 100 : 1;
    var currentValue = getProperty("_trigger") == "height" ? xyzFormat.format(getCurrentPosition().z * 100) : (num - 1);
    if (num == 1) { // initialize
      nextTriggerValue = getProperty("_triggerValue") * multiplier;
      newTemperature = getProperty("tempStart");
    } else {
      if (currentValue >= nextTriggerValue) {
        newTemperature += getProperty("tempInterval");
        nextTriggerValue += getProperty("_triggerValue") * multiplier;
        if (newTemperature <= maximumExtruderTemp) {
          onExtruderTemp(newTemperature, false, activeExtruder);
        } else {
          error(subst(
            localize("Requested extruder temperature of '%1' exceeds the maximum value of '%2'."), newTemperature, maximumExtruderTemp)
          );
        }
      }
    }
  }
}

function onLayer(num) {
  executeTempTowerFeatures(num);
  writeComment("Layer : " + integerFormat.format(num) + " of " + integerFormat.format(layerCount));
}

// motion entry functions

function onRapid(_x, _y, _z) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    writeBlock(gMotionModal.format(0), x, y, z);
    feedOutput.reset();
  }
}

function onLinearExtrude(_x, _y, _z, _f, _e) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = feedOutput.format(_f);
  var e = eOutput.format(_e);
  if (x || y || z || f || e) {
    writeBlock(gMotionModal.format(1), x, y, z, f, e);
  }
}

function onCircularExtrude(_clockwise, _cx, _cy, _cz, _x, _y, _z, _f, _e) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = feedOutput.format(_f);
  var e = eOutput.format(_e);
  var start = getCurrentPosition();
  var i = iOutput.format(_cx - start.x, 0);
  var j = jOutput.format(_cy - start.y, 0);
  
  switch (getCircularPlane()) {
  case PLANE_XY:
    writeBlock(gMotionModal.format(_clockwise ? 2 : 3), x, y, i, j, f, e);
    break;
  default:
    linearize(tolerance);
  }
}

function onClose() {
  writeBlock(gFormat.format(162), "Z", feedOutput.format((unit == MM ? 1800 : 70.866)));
  writeBlock(gFormat.format(28), "X Y");
  writeBlock(mFormat.format(132), "X Y A B");
  writeBlock(mFormat.format(652));
  writeBlock(gAbsIncModal.format(91));
  writeBlock(mFormat.format(18));
}
