/**
  Copyright (C) 2015-2021 by Autodesk, Inc.
  All rights reserved.

  $Revision: 43151 08c79bb5b30997ccb5fb33ab8e7c8c26981be334 $
  $Date: 2021-02-19 00:25:13 $
  
  FORKID {2E27B627-115A-4A16-A853-5B9B9D9AF480}
*/

description = "Glowforge";
vendor = "Glowforge";
vendorUrl = "https://www.glowforge.com";
legal = "Copyright (C) 2015-2021 by Autodesk, Inc.";
certificationLevel = 2;

longDescription = "Generic post for Glowforge laser. The post will output the toolpath as SVG graphics which can then be uploaded directly to Glowforge.";

extension = "svg";
mimetype = "image/svg+xml";
setCodePage("utf-8");

capabilities = CAPABILITY_JET;

minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
allowHelicalMoves = true;
allowedCircularPlanes = (1 << PLANE_XY); // only XY arcs

properties = {
  aLineWidth: {
    title: "SVG stroke width (mm)",
    description: "The width of lines in the SVG in mm.",
    type: "number",
    value: 0.1,
    scope: "post"
  },
  aMargin: {
    title: "Margin (mm)",
    description: "Sets the margin in mm when 'Crop to Workpiece' is used.",
    type: "number",
    value: 2,
    scope: "post"
  },
  aCheckForRadiusCompensation: {
    title: "Disallow Sideways Compensation",
    description: "Check every operation for Sideways Compensation 'In Control'. Throw an error if enabled and Sideways Compensation is used.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  aWorkArea: {
    title: "Work area",
    description: "Select the method used to calculate the work area.  'Auto' = calculate from stock, 'Define' = use Work area dimensions, 'None' = use defined work origin.",
    type: "enum",
    values: [
      {title: "Auto", id: "auto"},
      {title: "Define", id: "work"},
      {title: "None", id: "none"}
    ],
    value: "auto",
    scope: "post"
  },
  aWorkAreaWidth: {
    title: "Work area width (mm)",
    description: "Work Area Width in mm, used when 'Work area' is set to 'Defined'. Typically the max cutting width of the Glowforge.",
    type: "number",
    value: 495,
    scope: "post"
  },
  aWorkAreaHeight: {
    title: "Work area height (mm)",
    description: "Height in mm, used when 'Work area' is set to 'Defined'. Typically the max cutting height of the Glowforge.",
    type: "number",
    value: 279,
    scope: "post"
  },
  aIgnoreLeadMoves: {
    title: "Ignore lead-in/lead-out moves",
    description: "Enable to ignore lead-in/lead-out moves.",
    type: "boolean",
    value: true,
    scope: "post"
  }
};

xyzFormat = createFormat({decimals:3});
decimalFormat = createFormat({decimals:3});

var POST_URL = "https://cam.autodesk.com/hsmposts?p=glowforge";

// Recommended colors for color mapping.
var COLOR_GREEN = "1FB714";
var COLOR_YELLOW = "FBF305";
var COLOR_DARK_GREEN = "006412";
var COLOR_ORANGE = "FF6403";
var COLOR_BROWN = "562C05";
var COLOR_RED = "DD0907";
var COLOR_TAN = "90713A";
var COLOR_MAGENTA = "F20884";
var COLOR_PURPLE = "4700A5";
var COLOR_BLUE = "0000D3";
var COLOR_CYAN = "02ABEA";
var COLOR_BLACK = "000000";

var COLOR_CYCLE = [COLOR_CYAN,
  COLOR_MAGENTA,
  COLOR_YELLOW,
  COLOR_RED,
  COLOR_GREEN,
  COLOR_BLUE,
  COLOR_ORANGE,
  COLOR_DARK_GREEN,
  COLOR_PURPLE,
  COLOR_BROWN,
  COLOR_TAN,
  COLOR_BLACK];

var MIN_COLORS = 6; // minimum number of colors

/** Select a subset of colors so our preferred color pallet is used (and not simply the color with the lowest hex value first). */
function selectColors() {
  var requiredColors = Math.max(MIN_COLORS, getNumberOfSections()); // makes sure that more than enough colors get made
  var finalColorCycle = [];
  var numColors = COLOR_CYCLE.length;

  // if the number of default colors is too small, we will build lighter shades of those colors to fill in the extra needed colors
  var alphaSteps = Math.ceil(requiredColors / numColors);
  var alphaStepSize = 1 / (alphaSteps + 1);  // + 1 stops the last alpha blend stage for all colors being FFFFFF
  var alphaStepIndex = 0;
  var colorIndex = 0;
  var finalColorCycle = [];

  for (var i = 0; i < requiredColors; i++) {
    finalColorCycle.push(alphaBlendHexColor(COLOR_CYCLE[colorIndex], 1 - (alphaStepSize * alphaStepIndex)));
    colorIndex += 1;  // next color
    if (colorIndex >= numColors) {
      colorIndex = 0;  // start back at the first color
      alphaStepIndex++;  // next lighter shade
    }
  }

  // reset all color related variables to allow re-runs
  machineState.activeColorCycle = sortColors(finalColorCycle);
}

function compareHexValues(a, b) {
  if (a.hexValue < b.hexValue) {
    return -1;
  }
  if (a.hexValue > b.hexValue) {
    return 1;
  }
  return 0;
}

/** Glowforge doesn't respect the order of operations in the SVG file, it re-sorts them by the hex color value in ascending order
    so here the color cycle is sorted to preserve op order from CAM. */
function sortColors(inputColors) {
  var mappedColors = new Array();
  for (var color in inputColors) {
    mappedColors.push({hexColor: "#" + inputColors[color], hexValue: parseInt(inputColors[color], 16)});
  }
  mappedColors.sort(compareHexValues);

  var returnColors = new Array();
  for (var color in mappedColors) {
    returnColors.push(mappedColors[color].hexColor);
  }
  return returnColors;
}

/** Returns a hex color that is alphaPercent lighter than the input color. */
function alphaBlendHexColor(hexColorString, alphaPercent) {
  // alphaPercent needs to be converted from a float to a fraction of 255
  var alpha = alphaPercent;

  // hex color needs to be converted from a hex string to its constituent parts:
  var red = parseInt(hexColorString.substring(0, 2), 16);
  var green = parseInt(hexColorString.substring(2, 4), 16);
  var blue = parseInt(hexColorString.substring(4, 6), 16);

  return [alphaBlend(red, alpha), alphaBlend(green, alpha), alphaBlend(blue, alpha)].join("");
}

/** Returns properly padded 2 digit hex strings for RGB color channels. */
function toHexColorChannel(decimal) {
  var hex = decimal.toString(16);
  return (hex.length === 1 ? "0" : "") + hex;
}

/** Alpha blend a color channel white. */
function alphaBlend(colorChannel, alpha) {
  return toHexColorChannel(Math.round((1 - alpha) * 255 + alpha * colorChannel));
}

/** Called on the start of each section, initalizes the first color from the active color cycle. */
function nextColor() {
  machineState.currentColorIndex++;
  if (machineState.currentColorIndex >= machineState.activeColorCycle.length) {
    error(localize("Not enough colors were generated!"));
  }

  machineState.currentHexColor = machineState.activeColorCycle[machineState.currentColorIndex];
}

var useFillForSection = false; // should the current section be cut (using a stroke) or etched (using a fill)?
/** For Etch/Vaporize/Engrave, returns fill settings, otherwise none. */
function fill() {
  if (useFillForSection) {
    return "fill=\"" + machineState.currentHexColor + "\"";
  }
  return "fill=\"none\"";
}

/** for through cuts, returns stroke settings, otherwise none */
function stroke() {
  if (useFillForSection) {
    return "stroke=\"none\"";
  }
  return "stroke=\"" + machineState.currentHexColor + "\" stroke-width=\"" + getProperty("aLineWidth") + "\"";
}

var activePathElements = [];
function addPathElement() {
  var args = Array.slice(arguments, 0);

  // don't allow moves after a rapid or similar move
  if (arguments[0] === "M") {
    if (machineState.allowMoveCommand) {
      // if this is a move, this should disable further moves untill rapid or similar is detected.
      machineState.allowMoveCommand = false;
    } else {
      // skip rendering this move command since it was not preceeded by a rapid move
      return;
    }
  }

  activePathElements.push(args.join(" "));
}

function finishPath() {
  if (!activePathElements || activePathElements.length === 0) {
    error(localize("An operation resulted in no detectable paths!"));
    return;
  }

  var opComment = hasParameter("operation-comment") ? getParameter("operation-comment") : "[No Title]";

  writeln("<g id=\"operation-" + (1 + currentSection.getId()) + "\">");
  writeln("    <title>" + opComment + " (" + localize("Op") + ": " + (1 + currentSection.getId()) + "/" + getNumberOfSections() + ")</title>");
  writeln(
    "    <path d=\"" + activePathElements.join("\n             ") +
    "\" " +
    fill() +
    " " +
    stroke() +
    "/>"
  );
  writeln("</g>");
  activePathElements = [];
  machineState.allowMoveCommand = true;
}

/** return true if the program should halt because of missing radius compensation in the computer */
function isRadiusCompensationInvalid() {
  if (getProperty("aCheckForRadiusCompensation") && (radiusCompensation != RADIUS_COMPENSATION_OFF)) {
    error(localize(subst("Operation: %1. The Sideways Compensation type 'In Control' is not supported. This must be set to 'In Computer' in the passes tab.", (1 + currentSection.getId()))));
    return;
  }
}

function printVector(v) {
  return decimalFormat.format(v.x) + "," + decimalFormat.format(v.y);
}

var machineState;

/** Global state. */
function resetState() {
  return {
    // selected colors to use for this run
    activeColorCycle: null,
    // the hex string of the current color
    currentHexColor: null,
    // the index of the current color
    currentColorIndex: -1,
    // track if the next path element can be a move command
    allowMoveCommand: null,
    // is the work area too small?
    workAreaTooSmall: false
  };
}

function onOpen() {
  unit = MM; // machine requires input in MM

  if (getProperty("aMargin") < 0) {
    error(localize("Margin must be 0 or positive."));
    return;
  }

  // reset all per-run state
  machineState = resetState();
  
  // select colors now that the number of ops is available
  selectColors();

  // calculate workpiece dimensions
  var stock = getWorkpiece();
  var workpiece = getWorkpiece();
  workpiece.expandTo(new Vector(0, 0, 0)); // include origin of WCS, which is always 0,0,0
  var delta = Vector.diff(workpiece.upper, workpiece.lower);
  var marginX = getProperty("aMargin");
  var marginY = getProperty("aMargin");
  if (getProperty("aWorkArea") == "work") { // use work area size specified in properties
    var width = Math.max(getProperty("aWorkAreaWidth"), delta.x);
    var height = Math.max(getProperty("aWorkAreaHeight"), delta.y);
    machineState.workAreaTooSmall = width > getProperty("aWorkAreaWidth") || height > getProperty("aWorkAreaHeight");
    marginX = (width - delta.x) / 2;
    marginY = (height - delta.y) / 2;
  }
  workpiece.expandTo(new Vector((workpiece.lower.x - marginX), (workpiece.lower.y - marginY), 0));
  workpiece.expandTo(new Vector((workpiece.upper.x + marginX), (workpiece.upper.y + marginY), 0));
  delta = Vector.diff(workpiece.upper, workpiece.lower);

  // calculate translations
  var translateX = 0;
  var translateY = 0;
  
  if (getProperty("aWorkArea") !== "none") {
    translateX = -workpiece.lower.x;
    translateY = workpiece.upper.y;
  }

  writeln("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>");
  writeln("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" + delta.x + "mm\" height=\"" + delta.y + "mm\" viewBox=\"0 0 " + delta.x + " " + delta.y + "\">");
  writeln("<desc>Created with " + description + " for Fusion 360 CAM and HSM. To download visit: " + POST_URL + "</desc>");

  // write a comment explaining what info we got from the CAM system about the stock and coordinate system
  writeln("<!-- CAM Setup Info:");
  writeln("Work Area Width: " + delta.x + "mm");
  writeln("Work Area Height: " + delta.y + "mm");
  if (machineState.workAreaTooSmall) {
    writeln("### WORK AREA IS TOO SMALL ###");
    warning(localize("Work area is too small"));
  }
  writeln("Stock box Upper Right: " + printVector(stock.upper));
  writeln("Stock box Lower Left: " + printVector(stock.lower));
  writeln("Origin: " + "0,0");
  writeln("Selected Colors: " + machineState.activeColorCycle.join(", "));
  writeln("-->");

  // translate + scale operation to flip the Y axis so the output is in the same x/y orientation it was in Fusion 360
  writeln("<g id=\"global-translation-frame\" transform=\"translate(" + decimalFormat.format(translateX) + ", " + decimalFormat.format(translateY) + ") scale(1, -1)\">");
}

function onComment(text) {
  writeln("<!--" + text + "-->");
}

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
  case TOOL_MARKER: // allow any way for Epilog
    warning(localize("Using marker but allowing it anyway."));
    break;
  default:
    error(localize("The CNC does not support the required tool."));
    return;
  }

  // use Jet Mode to decide if the shape should be filled or have no fill
  switch (currentSection.jetMode) {
  case JET_MODE_THROUGH:
    useFillForSection = false;
    break;
  case JET_MODE_ETCHING:
  case JET_MODE_VAPORIZE:
    useFillForSection = true;
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
  nextColor();
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

function ignoreMove() {
  switch (movement) {
  case MOVEMENT_CUTTING:
  case MOVEMENT_REDUCED:
  case MOVEMENT_FINISH_CUTTING:
    break;
  case MOVEMENT_LEAD_IN:
  case MOVEMENT_LEAD_OUT:
    if (getProperty("aIgnoreLeadMoves")) {
      machineState.allowMoveCommand = true;
      return true;
    }
    break;
  case MOVEMENT_RAPID:
  case MOVEMENT_HIGH_FEED:
  case MOVEMENT_LINK_TRANSITION:
  case MOVEMENT_LINK_DIRECT:
  default:
    machineState.allowMoveCommand = true;
    return true;
  }
  return false;
}

function writeLine(x, y) {
  isRadiusCompensationInvalid();
  if (ignoreMove()) {
    return;
  }

  var start = getCurrentPosition();
  if ((xyzFormat.format(start.x) == xyzFormat.format(x)) &&
      (xyzFormat.format(start.y) == xyzFormat.format(y))) {
    return; // ignore vertical
  }

  addPathElement("M", xyzFormat.format(start.x), xyzFormat.format(start.y));
  addPathElement("L", xyzFormat.format(x), xyzFormat.format(y));
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
  isRadiusCompensationInvalid();
  if (ignoreMove()) {
    return;
  }

  var start = getCurrentPosition();

  var largeArc = (getCircularSweep() > Math.PI) ? 1 : 0;
  var sweepFlag = isClockwise() ? 0 : 1;
  addPathElement("M", xyzFormat.format(start.x), xyzFormat.format(start.y));
  addPathElement("A", xyzFormat.format(getCircularRadius()), xyzFormat.format(getCircularRadius()), 0, largeArc, sweepFlag, xyzFormat.format(x), xyzFormat.format(y));
}

function onCommand() {
}

function onSectionEnd() {
  finishPath();
}

function onClose() {
  writeln("</g>");
  // draw an untranslated box to represent the work are boundary on top of everything
  if (machineState.workAreaTooSmall) {
    writeln("<rect id=\"work-area-boundary\" x=\"" + 0 + "\" y=\"" + 0 + "\" width=\"" + decimalFormat.format(getProperty("aWorkAreaWidth")) + "\" height=\"" + decimalFormat.format(getProperty("aWorkAreaHeight")) + "\" style=\"fill:none;stroke:red;stroke-width:1;\"/>");
  }
  writeln("</svg>");
}

function setProperty(property, value) {
  properties[property].current = value;
}
