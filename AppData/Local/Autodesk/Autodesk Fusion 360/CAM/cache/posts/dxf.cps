/**
  Copyright (C) 2015-2021 by Autodesk, Inc.
  All rights reserved.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {E251098A-758C-4C19-B8D9-8408A6BDAFC9}
*/

description = "AutoCAD DXF";
vendor = "Autodesk";
vendorUrl = "http://www.autodesk.com";
legal = "Copyright (C) 2015-2021 by Autodesk, Inc.";
certificationLevel = 2;

longDescription = "This post outputs the toolpath in the DXF (AutoCAD) file format. Note that the direction of the toolpath will only be preserved if you enabled the 'forceSameDirection' property which will trigger linearization of clockwise arcs. You can turn on 'onlyCutting' to get rid of the linking motion. And you can turn off 'includeDrill' to avoid points at the drilling positions. You can specify a specific layer by setting the property called 'layer'. If you enable the property 'putOperationsInSeparateLayers' each operation will be put into separate layers incremented by 1.";

capabilities = CAPABILITY_INTERMEDIATE | CAPABILITY_MILLING | CAPABILITY_JET;
extension = "dxf";
mimetype = "application/dxf";
setCodePage("utf-8");

minimumChordLength = spatial(0.00001, MM);
minimumCircularSweep = toRad(0.00001);
maximumCircularSweep = toRad(180);
allowHelicalMoves = false;
allowSpiralMoves = true;
allowedCircularPlanes = undefined; // only XY arcs

properties = {
  useTimeStamp: {
    title: "Time stamp",
    description: "Specifies whether to output a time stamp.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  onlyCutting: {
    title: "Only cutting",
    description: "If enabled only cutting passes will be output, all linking moves will be ignored.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  includeDrill: {
    title: "Include drill",
    description: "If enabled circles will be output for all drill positions.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  only2D: {
    title: "Output as 2D",
    description: "Only output toolpath as 2D.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  forceSameDirection: {
    title: "Force same direction",
    description: "Enable to keep the direction of the toolpath, clockwise arcs will be linearized.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  layer: {
    title: "Layer",
    description: "Sets the default layer.",
    type: "integer",
    value: 1,
    scope: "post"
  },
  putOperationsInSeparateLayers: {
    title: "Put operations in separate layers",
    description: "Enable this property to put each operation on its own layer.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  allowFullCircles: {
    title: "Output full circles",
    description: "Enable this property to output full 360 degree circles.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  allowPolylines: {
    title: "Output polylines",
    description: "Enable this property to output polylines for cutting operations.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  mergeCircles: {
    title: "Merge same circles",
    description: "Enable to combine multiple circular blocks around same circle.",
    type: "boolean",
    value: false,
    scope: "post"
  }
};

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var nFormat = createFormat({decimals:9});
var angleFormat = createFormat({decimals:6, scale:DEG});

/** Returns the layer for the current section. */
function getLayer() {
  // the layer to output into
  if (getProperty("putOperationsInSeparateLayers")) {
    return getProperty("layer") + getCurrentSectionId();
  }
  return getProperty("layer");
}

function onOpen() {
  // use this to force unit to mm
  // xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4), scale:(unit == MM) ? 1 : 25.4});

  if (getProperty("allowFullCircles")) {
    maximumCircularSweep = toRad(360);
  }
  if (!getProperty("mergeCircles")) {
    minimumChordLength = spatial(0.01, MM);
    minimumCircularSweep = toRad(0.01);
  }

  writeln("999");
  writeln("Generated by Autodesk CAM - http://cam.autodesk.com");

  if (getProperty("useTimeStamp")) {
    var d = new Date();
    writeln("999");
    writeln("Generated at " + d);
  }

  writeln("0");
  writeln("SECTION");

  writeln("2");
  writeln("HEADER");
  
  writeln("9");
  writeln("$ACADVER");
  writeln("1");
  writeln("AC1006");

  writeln("9");
  writeln("$ANGBASE");
  writeln("50");
  writeln("0"); // along +X

  writeln("9");
  writeln("$ANGDIR");
  writeln("70");
  writeln("0"); // ccw arcs
  
  writeln("0");
  writeln("ENDSEC");

  writeln("0");
  writeln("SECTION");
  writeln("2");
  writeln("BLOCKS");
  writeln("0");
  writeln("ENDSEC");

  var box = new BoundingBox(); // always includes origin
  for (var i = 0; i < getNumberOfSections(); ++i) {
    box.expandToBox(getSection(i).getGlobalBoundingBox());
  }

  writeln("9");
  writeln("$EXTMIN");
  writeln("10"); // X
  writeln(xyzFormat.format(box.lower.x));
  writeln("20"); // Y
  writeln(xyzFormat.format(box.lower.y));
  writeln("30"); // Z
  writeln(xyzFormat.format(box.lower.z));

  writeln("9");
  writeln("$EXTMAX");
  writeln("10"); // X
  writeln(xyzFormat.format(box.upper.x));
  writeln("20"); // Y
  writeln(xyzFormat.format(box.upper.y));
  writeln("30"); // Z
  writeln(xyzFormat.format(box.upper.z));

  writeln("0");
  writeln("SECTION");
  writeln("2");
  writeln("ENTITIES");
  // entities start here
}

function onComment(text) {
}

var drillingMode = false;

function onSection() {
  var remaining = currentSection.workPlane;
  if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
    error(localize("Tool orientation is not supported."));
    return;
  }
  setRotation(remaining);

  drillingMode = hasParameter("operation-strategy") && (getParameter("operation-strategy") == "drill");
}

function onParameter(name, value) {
}

function onDwell(seconds) {
}

function onCycle() {
}

function onCyclePoint(x, y, z) {
  if (!getProperty("includeDrill")) {
    return;
  }

  writeln("0");
  writeln("POINT");
  writeln("8"); // layer
  writeln(getLayer());
  writeln("62"); // color
  writeln(1);

  writeln("10"); // X
  writeln(xyzFormat.format(x));
  writeln("20"); // Y
  writeln(xyzFormat.format(y));
  writeln("30"); // Z
  writeln(xyzFormat.format(z));
}

function onCycleEnd() {
}

function getColor(_movement) {
  switch (_movement) {
  case MOVEMENT_CUTTING:
  case MOVEMENT_REDUCED:
  case MOVEMENT_FINISH_CUTTING:
    return 1;
  case MOVEMENT_RAPID:
  case MOVEMENT_HIGH_FEED:
    if (getProperty("onlyCutting")) {
      return undefined; // skip
    }
    return 3;
  case MOVEMENT_LEAD_IN:
  case MOVEMENT_LEAD_OUT:
  case MOVEMENT_LINK_TRANSITION:
  case MOVEMENT_LINK_DIRECT:
    if (getProperty("onlyCutting")) {
      return undefined; // skip
    }
    return 2;
  default:
    if (getProperty("onlyCutting")) {
      return undefined; // skip
    }
    return 4;
  }
}

function writeLine(x, y, z) {
  if (drillingMode) {
    return; // ignore since we only want points
  }

  if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
    error(localize("Compensation in control is not supported."));
    return;
  }
  
  var color = getColor(movement);
  if (color == undefined) {
    return;
  }

  var start = getCurrentPosition();
  if (getProperty("only2D")) {
    if (!xyzFormat.areDifferent(start.x, x) &&
        !xyzFormat.areDifferent(start.y, y)) {
      return; // ignore vertical
    }
  }

  writeln("0");
  writeln("LINE");
  writeln("8"); // layer
  writeln(getLayer());
  writeln("62"); // color
  writeln(color);

  writeln("10"); // X
  writeln(xyzFormat.format(start.x));
  writeln("20"); // Y
  writeln(xyzFormat.format(start.y));
  writeln("30"); // Z
  writeln(xyzFormat.format(getProperty("only2D") ? 0 : start.z));

  writeln("11"); // X
  writeln(xyzFormat.format(x));
  writeln("21"); // Y
  writeln(xyzFormat.format(y));
  writeln("31"); // Z
  writeln(xyzFormat.format(getProperty("only2D") ? 0 : z));
}

var polyline = new Array();

function pushPolyline(x, y, z, _bulge, _insert) {
  if (drillingMode) {
    return; // ignore since we only want points
  }
  if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
    error(localize("Compensation in control is not supported."));
    return;
  }

  if ((movement == MOVEMENT_CUTTING) || (movement == MOVEMENT_REDUCED) || (movement == MOVEMENT_FINISH_CUTTING)) {
    // store previous position as start of polyline
    var start = getCurrentPosition();
    if (polyline.length == 0) {
      polyline.push({vertex:start, bulge:0});
    }

    if (getProperty("only2D")) { // ignore vertical moves with 2D profiles
      if (!xyzFormat.areDifferent(start.x, x) &&
          !xyzFormat.areDifferent(start.y, y)) {
        return; // ignore vertical
      }
    } else if (xyzFormat.areDifferent(polyline[0].vertex.z, z)) { // flush polyline with 3D move
      writePolyline();
      writeLine(x, y, z);
      return;
    }

    // set previous vertex to start of circle
    if (_bulge != 0) {
      polyline[polyline.length - 1].bulge = _bulge;
    }

    // push position onto polyline stack
    polyline.push({vertex:new Vector(x, y, z), bulge:0});
    if (!_insert && !getNextRecord().isMotion()) {
      writePolyline();
    }
  } else { // non-cutting move
    writePolyline();
    writeLine(x, y, z);
  }
}

function writePolyline() {
  if (polyline.length <= 1) { // a polyline has not been defined
    polyline.length = 0;
    return;
  }

  var closed = 0;
  if (Vector.diff(polyline[0].vertex, polyline[polyline.length - 1].vertex).length <= 0.002) {
    polyline[polyline.length - 1] = polyline[0];
    closed = 1;
  }

  var color = getColor(MOVEMENT_CUTTING);
  if (color == undefined) {
    return;
  }

  writeln("0");
  writeln("POLYLINE");
  writeln("8"); // layer
  writeln(getLayer());
  writeln("62"); // color
  writeln(color);
  writeln("66"); // vertices follow
  writeln("1");
  writeln("70"); // polyline flag
  writeln(closed);

  for (var i = 0; i < polyline.length; ++i) {
    writeln("0");
    writeln("VERTEX");
    writeln("8"); // layer
    writeln(getLayer());
    writeln("10"); // X
    writeln(xyzFormat.format(polyline[i].vertex.x));
    writeln("20"); // Y
    writeln(xyzFormat.format(polyline[i].vertex.y));
    if (polyline[i].bulge != 0) { // circle bulge
      writeln("42");
      writeln(xyzFormat.format(polyline[i].bulge));
    }
  }
  writeln("0");
  writeln("SEQEND");
  writeln("8"); // layer
  writeln(getLayer());
  polyline.length = 0;
}

function onRapid(x, y, z) {
  writePolyline();
  writeLine(x, y, z);
}

function onLinear(x, y, z, feed) {
  if (getProperty("allowPolylines")) {
    pushPolyline(x, y, z, 0, false);
  } else {
    writePolyline();
    writeLine(x, y, z);
  }
}

function onRapid5D(x, y, z, dx, dy, dz) {
  onExpandedRapid(x, y, z);
}

function onLinear5D(x, y, z, dx, dy, dz, feed) {
  onExpandedLinear(x, y, z);
}

var circleBuffer;
var circleIsBuffered = false;
var circleStart;
function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  var nextCircle = getNextRecord().getType() == 11; // TAG: RECORD_CIRCULAR is 10, but should be 11
  if (circleIsBuffered) {
    if (Vector.diff(circleBuffer.center, new Vector(cx, cy, cz)).length < toPreciseUnit(0.2, MM)) {
      circleBuffer.sweep += getCircularSweep();
      circleBuffer.end = new Vector(x, y, z);
      if (circleBuffer.sweep >= (Math.PI * 2 - toRad(0.01)) || !nextCircle) {
        writeCircle(circleBuffer, feed);
      }
      return;
    }
  } else if (nextCircle && getProperty("mergeCircles")) {
    circleBuffer = {
      center:new Vector(cx, cy, cz),
      start:getCurrentPosition(),
      end:new Vector(x, y, z),
      clockwise:clockwise,
      radius:getCircularRadius(),
      sweep:getCircularSweep()
    };
    circleStart = getCurrentPosition();
    circleIsBuffered = true;
    return;
  }
  if (circleIsBuffered) {
    writeCircle(circleBuffer, feed);
  }

  circleBuffer = {
    center:new Vector(cx, cy, cz),
    start:getCurrentPosition(),
    end:new Vector(x, y, z),
    clockwise:clockwise,
    radius:getCircularRadius(),
    sweep:getCircularSweep()
  };
  circleStart = getCurrentPosition();
  circleIsBuffered = true;
  writeCircle(circleBuffer, feed);
  return;
}

function writeCircle(circleData, feed) {
  circleIsBuffered = false;
  setCurrentPosition(circleData.start);
  if (getCircularPlane() != PLANE_XY) {
    // start and end angle reference is unknown
    linearize(tolerance);
    return;
  }

  if (circleData.clockwise && getProperty("forceSameDirection")) {
    linearize(tolerance);
    return;
  }

  if (getProperty("only2D")) {
    if (getCircularPlane() != PLANE_XY) {
      linearize(tolerance);
      return;
    }
  }

  if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
    error(localize("Compensation in control is not supported."));
    return;
  }

  var fullCircle = Math.abs(circleData.sweep) >= (Math.PI * 2 - 0.001);
  if (getProperty("allowPolylines")) {
    if ((getCircularPlane() != PLANE_XY) || fullCircle) {
      writePolyline();
    } else {
      if (circleData.sweep > Math.PI) { // maximum sweep of 180 deg for circles in a polyline
        var end = Vector.diff(circleData.center, circleData.start);
        end = Vector.sum(circleData.center, end);
        pushPolyline(end.x, end.y, end.z, circleData.clockwise ? -1 : 1, true);
        circleData.sweep -= Math.PI;
      }
      var bulge = Math.tan(circleData.sweep / 4) * (circleData.clockwise ? -1 : 1);
      pushPolyline(circleData.end.x, circleData.end.y, circleData.end.z, bulge, false);
      return;
    }
  }

  var color = getColor(movement);
  if (color == undefined) {
    return;
  }

  writeln("0");
  writeln(fullCircle ? "CIRCLE" : "ARC");
  writeln("8"); // layer
  writeln(getLayer());
  writeln("62"); // color
  writeln(color);

  writeln("10"); // X
  writeln(xyzFormat.format(circleData.center.x));
  writeln("20"); // Y
  writeln(xyzFormat.format(circleData.center.y));
  writeln("30"); // Z
  writeln(xyzFormat.format(getProperty("only2D") ? 0 : circleData.center.z));

  writeln("40"); // radius
  writeln(xyzFormat.format(circleData.radius));

  if (!fullCircle) {
    var start = getCurrentPosition();
    var startAngle = Math.atan2(circleData.start.y - circleData.center.y, circleData.start.x - circleData.center.x);
    var endAngle = Math.atan2(circleData.end.y - circleData.center.y, circleData.end.x - circleData.center.x);
    // var endAngle = startAngle + (clockwise ? -1 : 1) * getCircularSweep();
    if (circleData.clockwise) { // we must be ccw
      var temp = startAngle;
      startAngle = endAngle;
      endAngle = temp;
    }

    writeln("50"); // start angle
    writeln(angleFormat.format(startAngle));
    writeln("51"); // end angle
    writeln(angleFormat.format(endAngle));
  }
  
  if (getCircularPlane() != PLANE_XY) {
    validate(!getProperty("only2D"), "Invalid handling on onCircular().");
    var n = getCircularNormal();
    writeln("210"); // X
    writeln(nFormat.format(n.x));
    writeln("220"); // Y
    writeln(nFormat.format(n.y));
    writeln("230"); // Y
    writeln(nFormat.format(n.z));
  }
}

function onCommand() {
}

function onSectionEnd() {
}

function onClose() {
  writeln("0");
  writeln("ENDSEC");
  writeln("0");
  writeln("EOF");
}

function setProperty(property, value) {
  properties[property].current = value;
}
