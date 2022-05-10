/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Simulation CLD post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {A110AA28-D6B1-4fbb-B598-EAB9866DA91A}
*/

description = "Simulation CLD";
vendor = "Autodesk";
vendorUrl = "http://www.autodesk.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;

longDescription = "This post demonstrates how to output the toolpath into an easy to parse format for further processing.";

capabilities = CAPABILITY_INTERMEDIATE;
extension = "cld";
setCodePage("utf-8");

// user-defined properties
properties = {
  useFeed: {
    title: "Use feed",
    description: "Enable to use F output.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  useComments: {
    title: "Output comments",
    description: "Enable to allow the usage of comments",
    type: "boolean",
    value: true,
    scope: "post"
  },
  useModalOutput: {
    title: "Use modal output",
    description: "Enable to output values that change.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  forceMultiAxis: {
    title: "Force multi-axis",
    description: "Enable to use 3-axis indexed as 5-axis.",
    type: "boolean",
    value: false,
    scope: "post"
  }
};

var xyzFormat = createFormat({decimals:4});
var tFormat = createFormat({decimals:6});
var feedFormat = createFormat({decimals:4});
var xOutput = createVariable({prefix:" X"}, xyzFormat);
var yOutput = createVariable({prefix:" Y"}, xyzFormat);
var zOutput = createVariable({prefix:" Z"}, xyzFormat);
var txOutput = createVariable({prefix:" TX"}, tFormat);
var tyOutput = createVariable({prefix:" TY"}, tFormat);
var tzOutput = createVariable({prefix:" TZ"}, tFormat);
var fOutput = createVariable({prefix:" F"}, feedFormat);

function onComment(text) {
  if (getProperty("useComments")) {
    writeln("# " + text);
  }
}

function onOpen() {
  writeln("UNIT " + ((unit == IN) ? "IN" : "MM"));

  var workpiece = getWorkpiece();
  var delta = Vector.diff(workpiece.upper, workpiece.lower);
  if (delta.isNonZero()) {
    writeln(
      "STOCK " + xyzFormat.format(workpiece.lower.x) + " " + xyzFormat.format(workpiece.lower.y) + " " + xyzFormat.format(workpiece.lower.z) + " " +
      xyzFormat.format(workpiece.upper.x) + " " + xyzFormat.format(workpiece.upper.y) + " " + xyzFormat.format(workpiece.upper.z)
    );
  }

  if (!getProperty("useFeed")) {
    fOutput.disable();
  }

  if (!getProperty("useModalOutput")) {
    xOutput.setForce(true);
    yOutput.setForce(true);
    zOutput.setForce(true);
    txOutput.setForce(true);
    tyOutput.setForce(true);
    tzOutput.setForce(true);
    fOutput.setForce(true);
  }
}

var indexedTA = new Vector(0, 0, 1);

function onSection() {
  writeln(
    "TOOL " + tool.number + " " + xyzFormat.format(tool.diameter) + " " + xyzFormat.format(tool.cornerRadius) + " " + xyzFormat.format(tool.fluteLength)
  );

  // convert coordinates into WCS
  setTranslation(currentSection.workOrigin);
  setRotation(currentSection.workPlane);

  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  var ta = getFrameDirection(currentSection.getInitialToolAxis());
  indexedTA = ta;
  writeln(
    "MOVE" + xOutput.format(initialPosition.x) + yOutput.format(initialPosition.y) + zOutput.format(initialPosition.z) + txOutput.format(ta.x) + tyOutput.format(ta.y) + tzOutput.format(ta.z)
  );
}

function onRapid(x, y, z) {
  if (getProperty("forceMultiAxis")) {
    onRapid5D(x, y, z, indexedTA.x, indexedTA.y, indexedTA.z);
    return;
  }

  var _x = xOutput.format(x);
  var _y = yOutput.format(y);
  var _z = zOutput.format(z);
  if (_x || _y || _z) {
    writeln("RAPID" + _x + _y + _z);
  }
}

function onLinear(x, y, z, feed) {
  if (getProperty("forceMultiAxis")) {
    onLinear5D(x, y, z, indexedTA.x, indexedTA.y, indexedTA.z, feed);
    return;
  }

  var _x = xOutput.format(x);
  var _y = yOutput.format(y);
  var _z = zOutput.format(z);
  var _f = fOutput.format(feed);
  if (_x || _y || _z) { // we dont care about feed here
    writeln("CUT" + _x + _y + _z + _f);
  }
}

function onRapid5D(x, y, z, tx, ty, tz) {
  var _x = xOutput.format(x);
  var _y = yOutput.format(y);
  var _z = zOutput.format(z);
  var _tx = txOutput.format(tx);
  var _ty = tyOutput.format(ty);
  var _tz = tzOutput.format(tz);
  if (_x || _y || _z || _tx || _ty || _tz) {
    writeln("RAPID" + _x + _y + _z + _tx + _ty + _tz);
  }
}

function onLinear5D(x, y, z, tx, ty, tz, feed) {
  var _x = xOutput.format(x);
  var _y = yOutput.format(y);
  var _z = zOutput.format(z);
  var _tx = txOutput.format(tx);
  var _ty = tyOutput.format(ty);
  var _tz = tzOutput.format(tz);
  var _f = fOutput.format(feed);
  if (_x || _y || _z || _tx || _ty || _tz) { // we dont care about feed here
    writeln("CUT" + _x + _y + _z + _tx + _ty + _tz + _f);
  }
}

function setProperty(property, value) {
  properties[property].current = value;
}
