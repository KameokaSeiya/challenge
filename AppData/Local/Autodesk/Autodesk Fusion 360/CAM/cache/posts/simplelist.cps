/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Export to simple list post processor configuration.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {A110AA28-D6B1-4fbb-B598-EAB9866DA91A}
*/

description = "Export toolpath to simple list";
vendor = "Autodesk";
vendorUrl = "http://www.autodesk.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;

longDescription = "This post demonstrates how to output the toolpath into an easy to parse format for further processing. The output coordinates are the starting position, end position, and tool orientation.";

capabilities = CAPABILITY_INTERMEDIATE;
extension = "dat";
setCodePage("utf-8");

var xyzFormat = createFormat({decimals:4});
var tFormat = createFormat({decimals:6});

function onOpen() {
  var workpiece = getWorkpiece();
  var delta = Vector.diff(workpiece.upper, workpiece.lower);
}

var X;
var Y;
var Z;
var TX;
var TY;
var TZ;

function setP(x, y, z, tx, ty, tz) {
  if (X != undefined) {
    writeln(
      xyzFormat.format(X) + ", " + xyzFormat.format(Y) + ", " + xyzFormat.format(Z) + "; " +
      xyzFormat.format(x) + ", " + xyzFormat.format(y) + ", " + xyzFormat.format(z) + "; " +
      tFormat.format(tx) + ", " + tFormat.format(ty) + ", " + tFormat.format(tz) + ";"
    );
  }
  X = x;
  Y = y;
  Z = z;
  TX = tx;
  TY = ty;
  TZ = tz;
}

function onSection() {
/*
  if (!isFirstSection()) {
    error("Only one section allowed.");
    return;
  }
*/

  // convert coordinates into WCS
  setTranslation(currentSection.workOrigin);
  setRotation(currentSection.workPlane);

  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  var ta = getFrameDirection(currentSection.getInitialToolAxis());

  X = undefined;
  setP(initialPosition.x, initialPosition.y, initialPosition.z, ta.x, ta.y, ta.z);
}

function onRapid(x, y, z) {
  onExpandedLinear(x, y, z, TX, TY, TZ);
}

function onLinear(x, y, z, feed) {
  onLinear5D(x, y, z, TX, TY, TZ);
}

function onRapid5D(x, y, z, tx, ty, tz) {
  onLinear5D(x, y, z, tx, ty, tz);
}

function onLinear5D(x, y, z, tx, ty, tz, feed) {
  setP(x, y, z, tx, ty, tz);
}
