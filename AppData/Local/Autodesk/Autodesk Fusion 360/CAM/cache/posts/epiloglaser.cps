/**
  Copyright (C) 2015-2021 by Autodesk, Inc.
  All rights reserved.

  $Revision: 43234 a72c4ed6766913a74c158602410fe976f8cd540f $
  $Date: 2021-04-29 11:37:37 $
  
  FORKID {BD9FC5A6-277B-4D20-8FD5-7F70CC009C8D}
*/

description = "Epilog Laser";
vendor = "Epilog Laser";
vendorUrl = "https://www.epiloglaser.com";
legal = "Copyright (C) 2015-2021 by Autodesk, Inc.";
certificationLevel = 2;

longDescription = "Generic post for Epilog Laser. The post will output an HTML page with embedded SVG graphics which can then be printed using the installed Epilog Laser printer. " +
  "You can do both through-cutting and etching in the same program by enabling the 'useColorMapping' property. " +
  "When enabled, RED (255,0,0) will be used for through-cutting and GREEN (0,255,0) for etching. " +
  "You have to make sure to turn on color mapping and adjust the power settings correspondingly in the Epilog settings. " +
  "By default you will get BLUE (0,0,255) for both through-cutting and etching. " +
  "Enable the 'useWCS' property to force the part placement to match the WCS setting in the Setup. Otherwise the workpiece will be centered according to the given 'width' and 'height' properties. " +
  "Also keep in mind that you can choose the alignment of the workpiece in the print dialog (e.g. Top-Left corner).";

extension = "html";
mimetype = "text/html";
setCodePage("utf-8");

capabilities = CAPABILITY_JET;

minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
allowHelicalMoves = true;
allowedCircularPlanes = (1 << PLANE_XY); // only XY arcs

properties = {
  useWCS: {
    title: "Use WCS",
    description: "Do not center the toolpath.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  useTimeStamp: {
    title: "Use time stamp",
    description: "If enabled, a time stamp is outputted.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  width: {
    title: "Width(mm)",
    description: "Width in mm, used when useWCS is disabled.",
    type: "number",
    value: 1219.2,
    scope: "post"
  },
  height: {
    title: "Height(mm)",
    description: "Height in mm, used when useWCS is disabled.",
    type: "number",
    value: 609.6,
    scope: "post"
  },
  margin: {
    title: "Margin(mm)",
    description: "Sets the margin in mm.",
    type: "number",
    value: 0,
    scope: "post"
  },
  outputGuide: {
    title: "Output guide",
    description: "Enable to include help geometry.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  useColorMapping: {
    title: "Use color mapping",
    description: "Enable to use color mapping.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  embedInHTML: {
    title: "Embedded in HTML",
    description: "Enable to output SVG embedded in HTML.",
    type: "boolean",
    value: true,
    scope: "post"
  }
};

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4)});

// Recommended colors for color mapping.
var RED = "rgb(255,0,0)";
var GREEN = "rgb(0,255,0)";
var BLUE = "rgb(0,0,255)";
var YELLOW = "rgb(255,255,0)";
var MAGENTA = "rgb(255,0,255)";
var CYAN = "rgb(0,255,255)";

/** Returns the given spatial value in MM. */
function toMM(value) {
  return value * ((unit == IN) ? 25.4 : 1);
}

function onOpen() {
  if (getProperty("embedInHTML")) {
    writeln("<!DOCTYPE html>");
    writeln("<html>");
    writeln("<head><title>" + (programName ? programName : localize("Unnamed")) + " - Autodesk CAM" + "</title></head>");
    writeln("<body>");
    writeln("<!-- http://cam.autodesk.com -->");
    if (getProperty("useTimeStamp")) {
      var d = new Date();
      writeln("<!-- " + (d.getTime() * 1000) + " -->");
    }
  } else {
    writeln("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>");
  }

  var WIDTH = 210;
  var HEIGHT = 297;

  if (getProperty("margin") < 0) {
    error(localize("Margin must be 0 or positive."));
    return;
  }

  var box = getWorkpiece();
  var dx = toMM(box.upper.x - box.lower.x) + 2 * getProperty("margin");
  var dy = toMM(box.upper.y - box.lower.y) + 2 * getProperty("margin");

  log("Width: " + xyzFormat.format(dx));
  log("Height: " + xyzFormat.format(dy));

  var width = WIDTH;
  var height = HEIGHT;

  var useLandscape = false;

  if (getProperty("useWCS")) {
    width = dx;
    height = dy;
  } else {
    if ((dx > width) || (dy > height)) {
      if ((dx <= height) && (dy <= width)) {
        useLandscape = true;
        width = HEIGHT;
        height = WIDTH;
      }
    }

    log("Sheet width: " + xyzFormat.format(width));
    log("Sheet height: " + xyzFormat.format(height));

    if (dx > width) {
      warning(localize("Toolpath exceeds sheet width."));
    }
    if (dy > height) {
      warning(localize("Toolpath exceeds sheet height."));
    }
  }

  writeln("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" + xyzFormat.format(width) + "mm\" height=\"" + xyzFormat.format(height) + "mm\" viewBox=\"0 0 " + xyzFormat.format(width) + " " + xyzFormat.format(height) + "\">");

  // background
  // writeln("<rect x=\"" + xyzFormat.format(0) + "\" y=\"" + xyzFormat.format(0) + "\" width=\"" + xyzFormat.format(width) + "\" height=\"" + xyzFormat.format(height) + "\" style=\"fill:magenta;stroke:black;stroke-width:0.25;fill-opacity:0.01;stroke-opacity:0.25\"/>");

  // invert y axis
  writeln("<g transform=\"translate(" + xyzFormat.format(0) + ", " + xyzFormat.format(height) + ")\">");
  writeln("<g transform=\"scale(1, -1)\">");

  if (getProperty("useWCS")) {
    // adjust for margin
    writeln("<g transform=\"translate(" + xyzFormat.format(-toMM(box.lower.x) + getProperty("margin")) + ", " + xyzFormat.format(-toMM(box.lower.y) + getProperty("margin")) + ")\">");
  } else {
    // center on sheet
    writeln("<g transform=\"translate(" + xyzFormat.format(-toMM(box.lower.x) + (width - dx) / 2) + ", " + xyzFormat.format(-toMM(box.lower.y) + (height - dy) / 2) + ")\">");
  }

  // we output in mm always so scale from inches
  xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4), scale:(unit == MM) ? 1 : 25.4});

  // workpiece
  // writeln("<rect x=\"" + xyzFormat.format(box.lower.x) + "\" y=\"" + xyzFormat.format(box.lower.y) + "\" width=\"" + xyzFormat.format(box.upper.x - box.lower.x) + "\" height=\"" + xyzFormat.format(box.upper.y - box.lower.y) + "\" style=\"fill:green;stroke:black;stroke-width:0.25;fill-opacity:0.1;stroke-opacity:0.25\"/>");
}

function onComment(text) {
}

// From manual: Lines that you want to engrave rather than cut should be set .006" or greater.
var cuttingWidth = 0.001 * 25.4; // make sure we do vector cutting - and not raster - from manual - max 0.03"
var cuttingColor = BLUE; // color determines the cutting mode
var guideWidth = 0.5; // make sure this gets ignored
var guideColor = MAGENTA; // make sure this gets ignored

function onSection() {

  switch (tool.type) {
  case TOOL_WATER_JET: // allow any way for Epilog
    warning(localize("Using waterjet cutter but allowing it anyway."));
    break;
  case TOOL_LASER_CUTTER:
    break;
  case TOOL_PLASMA_CUTTER: // allow any way for Epilog
    warning(localize("Using plasma cutter but allowing it anyway."));
    break;
  /*
  case TOOL_MARKER: // allow any way for Epilog
    warning(localize("Using marker but allowing it anyway."));
    break;
  */
  default:
    error(localize("The CNC does not support the required tool."));
    return;
  }

  switch (currentSection.jetMode) {
  case JET_MODE_THROUGH:
    cuttingColor = getProperty("useColorMapping") ? RED : BLUE;
    break;
  case JET_MODE_ETCHING:
    cuttingColor = getProperty("useColorMapping") ? GREEN : BLUE;
    break;
  case JET_MODE_VAPORIZE:
    cuttingColor = getProperty("useColorMapping") ? GREEN : BLUE;
    warning(localize("Using unsupported vaporization. Using etching instead."));
    break;
  default:
    error(localize("Unsupported cutting mode."));
    return;
  }

  var remaining = currentSection.workPlane;
  if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
    error(localize("Tool orientation is not supported."));
    return;
  }
  setRotation(remaining);
}

function onParameter(name, value) {
}

function onDwell(seconds) {
}

function onCycle() {
}

function onCyclePoint(x, y, z) {
}

function onCycleEnd() {
}

function writeLine(x, y) {
  if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
    error(localize("Compensation in control is not supported."));
    return;
  }
  
  switch (movement) {
  case MOVEMENT_CUTTING:
  case MOVEMENT_REDUCED:
  case MOVEMENT_FINISH_CUTTING:
    break;
  case MOVEMENT_RAPID:
  case MOVEMENT_HIGH_FEED:
  case MOVEMENT_LEAD_IN:
  case MOVEMENT_LEAD_OUT:
  case MOVEMENT_LINK_TRANSITION:
  case MOVEMENT_LINK_DIRECT:
  default:
    return; // skip
  }

  var start = getCurrentPosition();
  if ((xyzFormat.format(start.x) == xyzFormat.format(x)) &&
      (xyzFormat.format(start.y) == xyzFormat.format(y))) {
    return; // ignore vertical
  }
  writeln("<line x1=\"" + xyzFormat.format(start.x) + "\" y1=\"" + xyzFormat.format(start.y) + "\" x2=\"" + xyzFormat.format(x) + "\" y2=\"" + xyzFormat.format(y) + "\" fill=\"none\" stroke=\"" + cuttingColor + "\" stroke-width=\"" + cuttingWidth + "\"/>");
  if (getProperty("outputGuide")) {
    writeln("<line x1=\"" + xyzFormat.format(start.x) + "\" y1=\"" + xyzFormat.format(start.y) + "\" x2=\"" + xyzFormat.format(x) + "\" y2=\"" + xyzFormat.format(y) + "\" fill=\"none\" stroke=\"" + guideColor + "\" stroke-width=\"" + guideWidth + "\"/>");
  }
}

function onRapid(x, y, z) {
  writeLine(x, y);
}

function onLinear(x, y, z, feed) {
  writeLine(x, y);
}

function onRapid5D(x, y, z, dx, dy, dz) {
  onExpandedRapid(x, y, z);
}

function onLinear5D(x, y, z, dx, dy, dz, feed) {
  onExpandedLinear(x, y, z);
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  // linearize(tolerance);
  // return;

  if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
    error(localize("Compensation in control is not supported."));
    return;
  }
  
  switch (movement) {
  case MOVEMENT_CUTTING:
  case MOVEMENT_REDUCED:
  case MOVEMENT_FINISH_CUTTING:
    break;
  case MOVEMENT_RAPID:
  case MOVEMENT_HIGH_FEED:
  case MOVEMENT_LEAD_IN:
  case MOVEMENT_LEAD_OUT:
  case MOVEMENT_LINK_TRANSITION:
  case MOVEMENT_LINK_DIRECT:
  default:
    return; // skip
  }

  var start = getCurrentPosition();

  var largeArc = (getCircularSweep() > Math.PI) ? 1 : 0;
  var sweepFlag = isClockwise() ? 0 : 1;
  var d = [
    "M", xyzFormat.format(start.x), xyzFormat.format(start.y),
    "A", xyzFormat.format(getCircularRadius()), xyzFormat.format(getCircularRadius()), 0, largeArc, sweepFlag, xyzFormat.format(x), xyzFormat.format(y)
  ].join(" ");
  writeln("<path d=\"" + d + "\" fill=\"none\" stroke=\"" + cuttingColor + "\" stroke-width=\"" + cuttingWidth + "\"/>");
  if (getProperty("outputGuide")) {
    writeln("<path d=\"" + d + "\" fill=\"none\" stroke=\"" + guideColor + "\" stroke-width=\"" + guideWidth + "\"/>");
  }
}

function onCommand() {
}

function onSectionEnd() {
}

function onClose() {
  writeln("</g>");
  writeln("</g>");
  writeln("</g>");
  writeln("</svg>");

  if (getProperty("embedInHTML")) {
    writeln("</body>");
    writeln("</html>");
  }
}

function setProperty(property, value) {
  properties[property].current = value;
}
