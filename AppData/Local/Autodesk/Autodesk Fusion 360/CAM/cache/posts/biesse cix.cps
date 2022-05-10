/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  Biesse CIX Router post processor configuration.

  $Revision: 43156 ed99ea5122fa82b7050e9f71895a891fca9aebee $
  $Date: 2021-02-25 16:35:58 $
  
  FORKID {3BEE5C15-D027-4C42-91E8-3B93CF79BD1E}
*/

///////////////////////////////////////////////////////////////////////////////
//                        MANUAL NC COMMANDS
//
// The following ACTION commands are supported by this post.
//
//     Hood         - The Hood position (SHP)
//
///////////////////////////////////////////////////////////////////////////////

description = "Biesse CIX Router";
vendor = "Biesse";
vendorUrl = "http://www.biesse.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic Biesse router post for CIX format.";

extension = "cix";
programNameIsInteger = true;
setCodePage("ascii");

capabilities = CAPABILITY_MILLING;
tolerance = spatial(0.002, MM);
mapWorkOrigin = false;

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = false;
allowedCircularPlanes = 1; // allow only XY circular motion

var tab = String.fromCharCode(9); // define the tabulator char

// user-defined properties
properties = {
  approachSpeed: {
    title: "Approach speed",
    description: "Default approach speed.",
    type: "number",
    value: 8000,
    scope: "post"
  },
  useFeeds: {
    title: "Use feedrates",
    description: "Output feedrates on moves.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  useSpeeds: {
    title: "Use spindle speeds",
    description: "Output spindle speeds on moves.",
    type: "boolean",
    value: true,
    scope: "post"
  },
  useRoutMacro: {
    title: "Use ROUT Macros",
    description: "Enable to use ROUT Macros, disable for GEO/ROUTG Macros.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  hoodPosition: {
    title: "Hood position (SHP) value",
    description: "The hood position mode output using the SHP parameter.",
    type: "number",
    value: 0,
    scope: "post"
  },
  useBGToolName: {
    title: "Output tool name for BG Macros",
    description: "Output the tool name in BG (boring) Macros, otherwise the control uses the tool diameter to select tool.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  useToolpath: {
    title: "Stock includes toolpath range",
    description: "Use the toolpath ranges in the stock size calculation.",
    type: "boolean",
    value: false,
    scope: "post"
  },
  ignoreSawLeadIn: {
    title:"Ignore saw lead-in/out moves",
    description:"Enable to ignore lead-in/out moves on saw cuts so simulation is consistent with machine movement.  If disabled, the lead-in/out moves must be tangent to the saw cut.",
    type:"boolean",
    value: true,
    scope: "post"
  },
  jigThickness: {
    title: "Jig thickness (JIGTH)",
    description: "Thickness of the jig.",
    type: "number",
    value: 0,
    scope: "post"
  },
  wcsOverride: {
    title: "WCS override (ORLST)",
    description:"Overrides the WCS used for the operations. Can be a single value or command separated list of values.",
    type:"string",
    value: "",
    scope: "post"
  },
  clampMethod: {
    title: "Clamping method",
    description: "Select the desired clamping method for the part, either using a vacuum or physical clamps.  Affects the output of the CUSTSTR block.",
    type: "enum",
    values: [
      {title:"Vacuum", id:"Vacuum"},
      {title:"Clamps", id:"Clamps"}
    ],
    value: "Vacuum",
    scope: "post"
  },
  maximumSawDepth: {
    title:"Maximum saw depth",
    description:"Saw cuts greater than this depth will use two passes.  A value of 0 output all saw cuts as a single pass.",
    type: "number",
    value: 0,
    scope: "post"
  }
};

var xyzFormat = createFormat({decimals:(unit == MM ? 5 : 5)});
var abcFormat = createFormat({decimals: 3, forceDecimal: true, scale: DEG});
var feedFormat = createFormat({decimals:(unit == MM ? 4 : 4)});
var toolDiaFormat = createFormat({decimals:3});

var xOutput = createVariable({prefix:tab + "PARAM,NAME=XE,VALUE=", force:true}, xyzFormat);
var yOutput = createVariable({prefix:tab + "PARAM,NAME=YE,VALUE=", force:true}, xyzFormat);
var zsOutput = createIncrementalVariable({prefix:tab + "PARAM,NAME=ZS,VALUE=", force:true}, xyzFormat);
var zOutput =  createIncrementalVariable({prefix:tab + "PARAM,NAME=ZE,VALUE=", force:true}, xyzFormat);
var initxOutput = createVariable({prefix:tab + "PARAM,NAME=X,VALUE=", force:true}, xyzFormat);
var inityOutput = createVariable({prefix:tab + "PARAM,NAME=Y,VALUE=", force:true}, xyzFormat);
var initzOutput = createVariable({prefix:tab + "PARAM,NAME=Z,VALUE=", force:true}, xyzFormat);

// circular output
var xcOutput = createVariable({prefix:tab + "PARAM,NAME=XC,VALUE=", force:true}, xyzFormat);
var ycOutput = createVariable({prefix:tab + "PARAM,NAME=YC,VALUE=", force:true}, xyzFormat);

// fixed state
var WARNING_WORK_OFFSET = 0;

// collected state
var operationId = 1001; // unique operation ID
var geometryId = 1001;
var side = 0;
var lineId;
var pointsCount = 0;
var firstMotion = false;
var workpiece;
var sawIsActive = false;
var sawZDepth;

/**
  Writes the specified block.
*/
function writeBlock() {
  writeWords(arguments);
}

function formatToolName(tool) {
  var permittedCommentChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
  var text = tool.productId;
  if (!text) {
    text = tool.description;
  }
  return filterText(String(text).toUpperCase(), permittedCommentChars).replace(/[()]/g, "");
}

function formatComment(text) {
  return "(" + String(text).replace(/[()]/g, "") + ")";
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

function writeDebug(_text) {
  writeComment("DEBUG - " + _text);
  log("DEBUG - " + _text);
}

function onOpen() {
  lineId = getProperty("useRoutMacro") ? 100000 : 100;
  hoodValue = getProperty("hoodPosition");
  if (programName) {
    operationId = programName;
  }
  
  // Calculate workpiece dimensions
  workpiece = getWorkpiece();
  workpiece.expandTo(new Vector(0, 0, 0)); // include origin of WCS, which is always 0,0,0
  if (getProperty("useToolpath")) {
    var numberOfSections = getNumberOfSections();
    for (var i = 0; i < numberOfSections; ++i) {
      var section = getSection(i);
      var box;
      var temp = section.getGlobalBoundingBox();
      var zAxis = section.workPlane.forward;
      if (isSameDirection(zAxis, new Vector(0, 0, 1)) || isSameDirection(zAxis, new Vector(0, 0, -1))) {
        box = new BoundingBox(new Vector(temp.lower.x, temp.lower.y, workpiece.lower.z), new Vector(temp.upper.x, temp.upper.y, workpiece.upper.z));
      } else if (isSameDirection(zAxis, new Vector(1, 0, 0)) || isSameDirection(zAxis, new Vector(-1, 0, 0))) {
        box = new BoundingBox(new Vector(workpiece.lower.x, temp.lower.y, temp.lower.z), new Vector(workpiece.upper.x, temp.upper.y, temp.upper.z));
      } else if (isSameDirection(zAxis, new Vector(0, 1, 0)) || isSameDirection(zAxis, new Vector(0, -1, 0))) {
        box = new BoundingBox(new Vector(temp.lower.x, workpiece.lower.y, temp.lower.z), new Vector(temp.upper.x, workpiece.upper.y, temp.upper.z));
      }
      workpiece.expandToBox(box);
    }
  }
  var delta = Vector.diff(workpiece.upper, workpiece.lower);

  // Get work coordinate system
  var section = getSection(0);
  var wcs = section.workOffset == 0 ? 1 : section.workOffset;
           
  // Start of program CIX pre-amble
  writeBlock("BEGIN ID CID3");
  writeBlock(tab + "REL= 5.0");
  writeBlock("END ID");
  writeBlock(" ");
  
  writeBlock("BEGIN MAINDATA");
  if (delta.isNonZero()) {
    writeBlock(tab + "LPX=" + xyzFormat.format(delta.x));
    writeBlock(tab + "LPY=" + xyzFormat.format(delta.y));
    writeBlock(tab + "LPZ=" + xyzFormat.format(delta.z));
  }
  writeBlock(tab + "ORLST=\"" + (getProperty("wcsOverride") ? getProperty("wcsOverride") : wcs) + "\"");
  writeBlock(tab + "SIMMETRY=1");
  writeBlock(tab + "TLCHK=0");
  writeBlock(tab + "TOOLING=\"\"");
  if (getProperty("clampMethod") == "Clamps") {
    writeBlock(tab + "CUSTSTR=\"2,0,0,1,1,0,0,0,0,,,0,0,0,0\"");
  } else {
    writeBlock(tab + "CUSTSTR=$B$KBsExportToNcRoverNET.XncExtraPanelData$V\"\"");
  }
    
  switch (unit) {
  case IN:
    writeBlock(tab + "FCN=25.400000");  // 25.4 = inches
    break;
  case MM:
    writeBlock(tab + "FCN=1.000000");  // 1 = MM
    break;
  }
  writeBlock(tab + "XCUT=0");  // Safety position along machine X-axis for automatic suspension of the machining operation.
  writeBlock(tab + "YCUT=0");  // Safety position along machine Y-axis for automatic suspension of the machining operation.
  writeBlock(tab + "JIGTH=" + xyzFormat.format(getProperty("jigThickness"))); // jig thickness
  writeBlock(tab + "CKOP=0");  // Origin movement
  writeBlock(tab + "UNIQUE=0");  // used to designation sole origin
  writeBlock(tab + "MATERIAL=\"wood\""); // the type of material to be cut
  writeBlock(tab + "PUTLST=\"\"");
  writeBlock(tab + "OPPWKRS=0"); // skipper machine only opposite machining
  writeBlock(tab + "UNICLAMP=0"); // 1 or 0 uniclamp field
  writeBlock(tab + "CHKCOLL=0"); // collision control
  writeBlock(tab + "WTPIANI=0");  // locking zone
  writeBlock(tab + "COLLTOOL=0"); // maching working dimension
  writeBlock(tab + "CALCEDTH=0"); //
  writeBlock(tab + "ENABLELABEL=0"); // allow ISO code for labels
  writeBlock(tab + "LOCKWASTE=0"); // waste blocking
  writeBlock(tab + "LOADEDGEOPT=0"); //
  writeBlock(tab + "ITLTYPE=0"); //
  writeBlock(tab + "RUNPAV=0"); // optimize suction cups
  writeBlock(tab + "FLIPEND=0"); //
  writeBlock("END MAINDATA");
  writeln("");
}

function onComment(message) {
  writeComment(message);
}

function writeGeoMacro() {
  writeBlock("BEGIN MACRO");
  writeBlock(tab + "NAME=GEO");
  writeBlock(tab + "PARAM,NAME=LAY,VALUE=" + "\"" + "Layer 0" + "\"");
  writeBlock(tab + "PARAM,NAME=ID,VALUE=" + "\"" + "G1003." + geometryId + "\"");
  writeBlock(tab + "PARAM,NAME=SIDE,VALUE=" + side);
  writeBlock(tab + "PARAM,NAME=CRN,VALUE=\"1\"");
  writeBlock(tab + "PARAM,NAME=DP,VALUE=0");
  writeBlock(tab + "PARAM,NAME=RTY,VALUE=rpNO");
  writeBlock(tab + "PARAM,NAME=NRP,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DX,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DY,VALUE=0");
  writeBlock(tab + "PARAM,NAME=RV,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=COW,VALUE=NO");
  if (hasParameter("operation:compensationType") && (getParameter("operation:compensationType") == "control")) {
    if (hasParameter("operation:compensation") && (getParameter("operation:compensation") == "left")) {
      writeBlock(tab + "PARAM,NAME=CRC,VALUE=2");
    }
    if  (hasParameter("operation:compensation") && (getParameter("operation:compensation") == "right")) {
      writeBlock(tab + "PARAM,NAME=CRC,VALUE=1");
    }
  } else {
    writeBlock(tab + "PARAM,NAME=CRC,VALUE=0");
  }
  writeBlock("END MACRO");
  writeln("");
  
  pointsCount = 0;
}

function writeStartPointMacro(startPoint) {
  var startZ = 0; // Biesse control ignores Z in startpoint always assumes top of part
  writeBlock("BEGIN MACRO");
  writeBlock(tab + "NAME=START_POINT");
  if (getProperty("useRoutMacro")) {
    writeBlock(tab + "PARAM,NAME=ID,VALUE=" + lineId++);
  } else {
    writeBlock(tab + "PARAM,NAME=LAY,VALUE=" + "\"" + "Layer 0" + "\"");
  }
  writeBlock(initxOutput.format(startPoint.x));
  writeBlock(inityOutput.format(startPoint.y));
  writeBlock(initzOutput.format(startZ));
  writeBlock("END MACRO");
  writeln("");

  xOutput.format(startPoint.x);
  yOutput.format(startPoint.y);
  zOutput.format(startZ);
  zOutput.format(startZ);
  zsOutput.format(startZ);
  zsOutput.format(startZ);
  previousZ = startZ;
}

function writeRoutGMacro() {
  writeBlock("BEGIN MACRO");
  writeBlock(tab + "NAME=ROUTG");
  writeBlock(tab + "PARAM,NAME=LAY,VALUE=" + "\"" + "Layer 0" + "\"");
  writeBlock(tab + "PARAM,NAME=ID,VALUE=" + "\"" + "P" + operationId + "\"");
  writeBlock(tab + "PARAM,NAME=GID,VALUE=" + "\"G1003." + geometryId + "\"");
  writeBlock(tab + "PARAM,NAME=SIL,VALUE=\"\"");
  writeBlock(tab + "PARAM,NAME=Z,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DP,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DIA,VALUE=" + toolDiaFormat.format(tool.diameter)); // Diameter of tool
  writeBlock(tab + "PARAM,NAME=THR,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=RV,VALUE=NO");
  if (hasParameter("operation:compensationType") && (getParameter("operation:compensationType") == "control")) {
    if (hasParameter("operation:compensation") && (getParameter("operation:compensation") == "left")) {
      writeBlock(tab + "PARAM,NAME=CRC,VALUE=2");
    }
    if (hasParameter("operation:compensation") && (getParameter("operation:compensation") == "right")) {
      writeBlock(tab + "PARAM,NAME=CRC,VALUE=1");
    }
  } else {
    writeBlock(tab + "PARAM,NAME=CRC,VALUE=0");
  }
  writeBlock(tab + "PARAM,NAME=CKA,VALUE=" + (isWorkingPlane ? "3" : "azrNO"));
  writeBlock(tab + "PARAM,NAME=AZ,VALUE=0");
  writeBlock(tab + "PARAM,NAME=AR,VALUE=0");
  writeBlock(tab + "PARAM,NAME=OPT,VALUE=YES");
  writeBlock(tab + "PARAM,NAME=RSP,VALUE=" +  (getProperty("useSpeeds") ? getParameter("operation:tool_spindleSpeed", 0) : 0));
  writeBlock(tab + "PARAM,NAME=IOS,VALUE=" + getProperty("approachSpeed"));
  if (hasParameter("operation:tool_feedCutting")) {
    var feed = (getParameter("operation:tool_feedCutting"));
    writeBlock(tab + "PARAM,NAME=WSP,VALUE=" +  getFeed(feed));
  }
  if (hasParameter("operation:tool_feedEntry")) { // Lead-in and lead-out speed
    var infeed = (getParameter("operation:tool_feedEntry"));
    writeBlock(tab + "PARAM,NAME=DSP,VALUE=" +  getFeed(infeed));
    // writeBlock(tab + "PARAM,NAME=IMS,VALUE=" +  infeed); // not documented
  }
  writeBlock(tab + "PARAM,NAME=VTR,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DVR,VALUE=0");
  writeBlock(tab + "PARAM,NAME=OTR,VALUE=0");
  writeBlock(tab + "PARAM,NAME=SVR,VALUE=0");
  writeBlock(tab + "PARAM,NAME=COF,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=DOF,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TIN,VALUE=0");
  writeBlock(tab + "PARAM,NAME=CIN,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=AIN,VALUE=45");
  writeBlock(tab + "PARAM,NAME=GIN,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TLI,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TQI,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TBI,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=DIN,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TOU,VALUE=0");
  writeBlock(tab + "PARAM,NAME=COU,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=AOU,VALUE=45");
  writeBlock(tab + "PARAM,NAME=GOU,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TBO,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=TLO,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TQO,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DOU,VALUE=0");
  writeBlock(tab + "PARAM,NAME=PRP,VALUE=100");
  writeBlock(tab + "PARAM,NAME=SDS,VALUE=0");
  // writeBlock(tab + "PARAM,NAME=SDSF,VALUE=2000"); // not documented
  writeBlock(tab + "PARAM,NAME=UDT,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=TDT,VALUE=\"\"");
  writeBlock(tab + "PARAM,NAME=DDT,VALUE=5");
  writeBlock(tab + "PARAM,NAME=SDT,VALUE=0");
  writeBlock(tab + "PARAM,NAME=IDT,VALUE=20");
  writeBlock(tab + "PARAM,NAME=FDT,VALUE=80");
  writeBlock(tab + "PARAM,NAME=RDT,VALUE=60");
  writeBlock(tab + "PARAM,NAME=CRR,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=GIP,VALUE=YES");
  writeBlock(tab + "PARAM,NAME=OVM,VALUE=0");
  writeBlock(tab + "PARAM,NAME=SWI,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=BLW,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=TOS,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=TNM,VALUE=" + "\"" + formatToolName(tool) + "\"");
  writeBlock(tab + "PARAM,NAME=TTP,VALUE=103"); // Tool Type ROUT1
  writeBlock(tab + "PARAM,NAME=SPI,VALUE=\"\"");
  writeBlock(tab + "PARAM,NAME=BFC,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=SHP,VALUE=" + hoodValue);
  writeBlock(tab + "PARAM,NAME=PRS,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=NEBS,VALUE=NO");
  // writeBlock(tab + "PARAM,NAME=ETB,VALUE=0"); // not documented
  // writeBlock(tab + "PARAM,NAME=FXD,VALUE=0"); // not documented
  // writeBlock(tab + "PARAM,NAME=FXDA,VALUE=0"); // not documented
  // writeBlock(tab + "PARAM,NAME=KDT,VALUE=0"); // not documented
  // writeBlock(tab + "PARAM,NAME=EML,VALUE=0"); // not documented
  writeBlock(tab + "PARAM,NAME=CKT,VALUE=NO");
  // writeBlock(tab + "PARAM,NAME=ETG,VALUE=0"); // not documented
  // writeBlock(tab + "PARAM,NAME=ETG,VALUE=0.1"); // not documented
  // writeBlock(tab + "PARAM,NAME=AJT,VALUE=0"); // not documented
  // writeBlock(tab + "PARAM,NAME=ION,VALUE=0"); // not documented
  // writeBlock(tab + "PARAM,NAME=LUBMNZ,VALUE=0"); // not documented
  // writeBlock(tab + "PARAM,NAME=SHT,VALUE=0"); // not documented
  // writeBlock(tab + "PARAM,NAME=SHD,VALUE=0"); // not documented
  // writeBlock(tab + "PARAM,NAME=LPR,VALUE=1"); // not needed
  // writeBlock(tab + "PARAM,NAME=LNG,VALUE=0"); // not needed
  writeBlock(tab + "PARAM,NAME=ZS,VALUE=0");
  writeBlock(tab + "PARAM,NAME=ZE,VALUE=0");
  // writeBlock(tab + "PARAM,NAME=RDIN,VALUE=0"); // not documented

  writeBlock("END MACRO");
  writeln("");
  ++geometryId;
}

function writeRoutMacro() {
  writeBlock("BEGIN VB");
  writeBlock(tab + "VBLINE=\"\"");
  writeBlock("END VB");
  writeln("");

  writeBlock("BEGIN MACRO");
  writeBlock(tab + "NAME=ROUT");
  writeBlock(tab + "PARAM,NAME=ID,VALUE=" + "\"" + "P" + operationId + "\"");
  writeBlock(tab + "PARAM,NAME=SIDE,VALUE=" + side);
  writeBlock(tab + "PARAM,NAME=CRN,VALUE=\"1\"");
  writeBlock(tab + "PARAM,NAME=Z,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DP,VALUE=0");
  writeBlock(tab + "PARAM,NAME=ISO,VALUE=\"\"");
  writeBlock(tab + "PARAM,NAME=OPT,VALUE=YES");
  writeBlock(tab + "PARAM,NAME=DIA,VALUE=" + toolDiaFormat.format(tool.diameter)); // Diameter of tool
  writeBlock(tab + "PARAM,NAME=RTY,VALUE=rpNO");
  writeBlock(tab + "PARAM,NAME=XRC,VALUE=0");
  writeBlock(tab + "PARAM,NAME=YRC,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DX,VALUE=32");
  writeBlock(tab + "PARAM,NAME=DY,VALUE=32");
  writeBlock(tab + "PARAM,NAME=R,VALUE=50");
  writeBlock(tab + "PARAM,NAME=A,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DA,VALUE=45");
  writeBlock(tab + "PARAM,NAME=RDL,VALUE=YES");
  writeBlock(tab + "PARAM,NAME=NRP,VALUE=0");
  writeBlock(tab + "PARAM,NAME=AZ,VALUE=0");
  writeBlock(tab + "PARAM,NAME=AR,VALUE=0");
  writeBlock(tab + "PARAM,NAME=ZS,VALUE=0");
  writeBlock(tab + "PARAM,NAME=ZE,VALUE=0");
  writeBlock(tab + "PARAM,NAME=CKA,VALUE=" + (isWorkingPlane ? "3" : "azrNO"));
  writeBlock(tab + "PARAM,NAME=THR,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=RV,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=CKT,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=ARP,VALUE=0");
  writeBlock(tab + "PARAM,NAME=LRP,VALUE=0");
  writeBlock(tab + "PARAM,NAME=ER,VALUE=YES");
  writeBlock(tab + "PARAM,NAME=COW,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=OVM,VALUE=0");
  writeBlock(tab + "PARAM,NAME=A21,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TOS,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=VTR,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DVR,VALUE=0");
  writeBlock(tab + "PARAM,NAME=OTR,VALUE=0");
  writeBlock(tab + "PARAM,NAME=SVR,VALUE=0");
  writeBlock(tab + "PARAM,NAME=COF,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=DOF,VALUE=0");
  writeBlock(tab + "PARAM,NAME=GIP,VALUE=YES");
  writeBlock(tab + "PARAM,NAME=LSV,VALUE=0");
  writeBlock(tab + "PARAM,NAME=S21,VALUE=-1");
  writeBlock(tab + "PARAM,NAME=AZS,VALUE=0");
  if (hasParameter("operation:tool_feedEntry")) { // Lead-in and lead-out speed
    var infeed = (getParameter("operation:tool_feedEntry"));
    writeBlock(tab + "PARAM,NAME=DSP,VALUE=" +  getFeed(infeed));
  }
  writeBlock(tab + "PARAM,NAME=RSP,VALUE=" +  (getProperty("useSpeeds") ? getParameter("operation:tool_spindleSpeed", 0) : 0));
  writeBlock(tab + "PARAM,NAME=IOS,VALUE=" + getProperty("approachSpeed"));
  if (hasParameter("operation:tool_feedCutting")) {
    var feed = (getParameter("operation:tool_feedCutting"));
    writeBlock(tab + "PARAM,NAME=WSP,VALUE=" +  getFeed(feed));
  }
  writeBlock(tab + "PARAM,NAME=TNM,VALUE=" + "\"" + formatToolName(tool) + "\"");
  writeBlock(tab + "PARAM,NAME=TTP,VALUE=103"); // Tool Type 102=ROUT0, 103=ROUT1
  writeBlock(tab + "PARAM,NAME=TCL,VALUE=1");
  if (hasParameter("operation:compensationType") && (getParameter("operation:compensationType") == "control")) {
    if (hasParameter("operation:compensation") && (getParameter("operation:compensation") == "left")) {
      writeBlock(tab + "PARAM,NAME=CRC,VALUE=2");
    }
    if (hasParameter("operation:compensation") && (getParameter("operation:compensation") == "right")) {
      writeBlock(tab + "PARAM,NAME=CRC,VALUE=1");
    }
  } else {
    writeBlock(tab + "PARAM,NAME=CRC,VALUE=0");
  }
  writeBlock(tab + "PARAM,NAME=TIN,VALUE=0");
  writeBlock(tab + "PARAM,NAME=AIN,VALUE=45");
  writeBlock(tab + "PARAM,NAME=CIN,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=GIN,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TBI,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=TLI,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TQI,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TOU,VALUE=0");
  writeBlock(tab + "PARAM,NAME=AOU,VALUE=45");
  writeBlock(tab + "PARAM,NAME=COU,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=GOU,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TBO,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=TLO,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TQO,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DIN,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DOU,VALUE=0");
  writeBlock(tab + "PARAM,NAME=SDS,VALUE=0");
  writeBlock(tab + "PARAM,NAME=PRP,VALUE=0");
  writeBlock(tab + "PARAM,NAME=BDR,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=SPI,VALUE=\"\"");
  writeBlock(tab + "PARAM,NAME=SC,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=SWI,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=BLW,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=PRS,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=BFC,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=SHP,VALUE=" + hoodValue);
  writeBlock(tab + "PARAM,NAME=SWP,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=CSP,VALUE=0");
  writeBlock(tab + "PARAM,NAME=UDT,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=TDT,VALUE=\"\"");
  writeBlock(tab + "PARAM,NAME=DDT,VALUE=5");
  writeBlock(tab + "PARAM,NAME=SDT,VALUE=0");
  writeBlock(tab + "PARAM,NAME=IDT,VALUE=20");
  writeBlock(tab + "PARAM,NAME=FDT,VALUE=80");
  writeBlock(tab + "PARAM,NAME=RDT,VALUE=60");
  writeBlock(tab + "PARAM,NAME=EA21,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=CEN,VALUE=\"\"");
  writeBlock(tab + "PARAM,NAME=AGG,VALUE=\"\"");
  writeBlock(tab + "PARAM,NAME=LAY,VALUE=\"ROUT\"");
  writeBlock(tab + "PARAM,NAME=EECS,VALUE=0");
  writeBlock(tab + "PARAM,NAME=PDIN,VALUE=1");
  writeBlock(tab + "PARAM,NAME=PDU,VALUE=1");
  writeBlock(tab + "PARAM,NAME=PCIN,VALUE=0");
  writeBlock(tab + "PARAM,NAME=PCU,VALUE=0");
  writeBlock(tab + "PARAM,NAME=PMOL,VALUE=0");
  writeBlock(tab + "PARAM,NAME=AUX,VALUE=0");
  writeBlock(tab + "PARAM,NAME=CRR,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=NEBS,VALUE=YES");
  writeBlock(tab + "PARAM,NAME=ETB,VALUE=0");
  writeBlock(tab + "PARAM,NAME=FXD,VALUE=0");
  writeBlock(tab + "PARAM,NAME=FXDA,VALUE=0");
  writeBlock(tab + "PARAM,NAME=KDT,VALUE=0");
  writeBlock(tab + "PARAM,NAME=EML,VALUE=0");
  writeBlock("END MACRO");
  writeln("");
}

function writeCutGeoMacro() {
  var nPasses = (getProperty("maximumSawDepth") != 0) && (sawZDepth > getProperty("maximumSawDepth")) ? 2 : 1;
  writeBlock("BEGIN MACRO");
  writeBlock(tab + "NAME=CUT_GEO");
  writeBlock(tab + "PARAM,NAME=LAY,VALUE=" + "\"" + "Layer 0" + "\"");
  writeBlock(tab + "PARAM,NAME=ID,VALUE=" + "\"" + "P" + operationId + "\"");
  writeBlock(tab + "PARAM,NAME=GID,VALUE=" + "\"G1003." + geometryId + "\"");
  writeBlock(tab + "PARAM,NAME=SIL,VALUE=\"\"");
  writeBlock(tab + "PARAM,NAME=Z,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DP,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TH,VALUE=" + toolDiaFormat.format(tool.diameter)); // Diameter of tool
  writeBlock(tab + "PARAM,NAME=THR,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TTK,VALUE=0");
  if (hasParameter("operation:compensationType") && (getParameter("operation:compensationType") == "control")) {
    if (hasParameter("operation:compensation") && (getParameter("operation:compensation") == "left")) {
      writeBlock(tab + "PARAM,NAME=CRC,VALUE=2");
    }
    if (hasParameter("operation:compensation") && (getParameter("operation:compensation") == "right")) {
      writeBlock(tab + "PARAM,NAME=CRC,VALUE=1");
    }
  } else {
    writeBlock(tab + "PARAM,NAME=CRC,VALUE=0");
  }
  writeBlock(tab + "PARAM,NAME=RV,VALUE=NO");
  writeBlock(tab + "PARAM,NAME=CKA,VALUE=" + (isWorkingPlane ? "3" : "azrNO"));
  writeBlock(tab + "PARAM,NAME=AZ,VALUE=0");
  writeBlock(tab + "PARAM,NAME=OPT,VALUE=1");
  writeBlock(tab + "PARAM,NAME=RSP,VALUE=" +  (getProperty("useSpeeds") ? getParameter("operation:tool_spindleSpeed", 0) : 0));
  writeBlock(tab + "PARAM,NAME=IOS,VALUE=0");
  writeBlock(tab + "PARAM,NAME=WSP,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DSP,VALUE=0");
  writeBlock(tab + "PARAM,NAME=OVM,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DIN,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DOU,VALUE=0");
  writeBlock(tab + "PARAM,NAME=TOS,VALUE=1");
  writeBlock(tab + "PARAM,NAME=VTR,VALUE=" + nPasses);
  writeBlock(tab + "PARAM,NAME=GIP,VALUE=1");
  writeBlock(tab + "PARAM,NAME=TNM,VALUE=" + "\"" + formatToolName(tool) + "\"");
  writeBlock(tab + "PARAM,NAME=SPI,VALUE=\"\"");
  writeBlock(tab + "PARAM,NAME=BFC,VALUE=0");
  writeBlock(tab + "PARAM,NAME=SHP,VALUE=0");
  writeBlock(tab + "PARAM,NAME=BRC,VALUE=0");
  writeBlock(tab + "PARAM,NAME=BDR,VALUE=1");
  writeBlock(tab + "PARAM,NAME=PRV,VALUE=1");
  writeBlock(tab + "PARAM,NAME=NRV,VALUE=0");
  writeBlock(tab + "PARAM,NAME=DVR,VALUE=0");
  writeBlock(tab + "PARAM,NAME=KDT,VALUE=0");
  
  writeBlock("END MACRO");
  writeln("");
  ++geometryId;
}

function writeEndPathMacro() {
  writeBlock("BEGIN MACRO");
  writeBlock(tab + "NAME=ENDPATH");
  if (getProperty("useRoutMacro")) {
    writeBlock(tab + "PARAM,NAME=ID,VALUE=" + lineId++);
  }
  writeBlock("END MACRO");
  writeln("");
  pointsCount = 0;
  if (!getProperty("useRoutMacro")) {
    lineId = 100;
  }
}

/** Buffer consecutive Z-moves. */
var zBuffer;
var previousZ;
var zIsBuffered = false;

function bufferZ(_x, _y, _z) {
  if (!getProperty("useRoutMacro")) {
    var start = getCurrentPosition();
    if (!xyzFormat.areDifferent(_x, start.x) &&
        !xyzFormat.areDifferent(_y, start.y) &&
        xyzFormat.areDifferent(_z, start.z)) {
      if (!zIsBuffered) {
        zBuffer = new Vector(_x, _y, _z);
      }
      zIsBuffered = true;
    } else {
      zIsBuffered = false;
    }
  }
  return (zIsBuffered);
}

function writeLineEpMacro(_x, _y, _z, sawStart) {
  var start = sawIsActive ? new Vector(sawStart.x, sawStart.y, sawStart.z) : getCurrentPosition();
  if (!xyzFormat.areDifferent(start.x, _x) &&
      !xyzFormat.areDifferent(start.y, _y) &&
      !xyzFormat.areDifferent(start.z, _z)) {
    return;
  }

  // start of geometry
  if (pointsCount == 0) {
    if (getProperty("useRoutMacro")) {
      writeRoutMacro();
    } else {
      writeGeoMacro();
    }
    writeStartPointMacro(start);
  }

  if (sawIsActive || !bufferZ(_x, _y, _z)) {
    writeBlock("BEGIN MACRO");
    writeBlock(tab + "NAME=LINE_EP");
    if (!getProperty("useRoutMacro")) {
      writeBlock(tab + "PARAM,NAME=LAY,VALUE=" + "\"" + "Layer 0" + "\"");
    }
    writeBlock(tab + "PARAM,NAME=ID,VALUE=" + lineId++);

    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var zs = zsOutput.format(previousZ);
    zs = zsOutput.format(start.z);
    zOutput.format(start.z);
    var z = zOutput.format(_z);
    writeBlock(x);
    writeBlock(y);
    writeBlock(zs); // start Z
    writeBlock(z); // ZE value

    writeBlock(tab + "PARAM,NAME=FD,VALUE=0");
    writeBlock(tab + "PARAM,NAME=SP,VALUE=0");
    writeBlock(tab + "PARAM,NAME=MVT,VALUE=NO");
    writeBlock("END MACRO");
    writeln("");
    previousZ = _z;
  }
  ++pointsCount;
}

function getWorkPlaneMachineABC(workPlane) {
  var W = workPlane; // map to global frame

  // Workplane angles are between -360 - 360 : Beta=A, Alpha=C
  var abc = W.getTurnAndTilt(X, Z);
  abc.setZ(-abc.z); // axis rotates in opposite direction, can't specify direction with Turn and Tilt
  if (abc.x < 0) {
    abc.setX(-abc.x);
    abc.setZ(abc.z + Math.PI);
  }
  if (abc.z < 0) {
    abc.setZ(abc.z + (Math.PI * 2));
  }
  if (abcFormat.format(abc.z) > 360) {
    abc.setZ(abc.z - (Math.PI * 2));
  }
  return abc;
}

/** create a custom 3+2 side */
var isWorkingPlane = false;
var workingPlaneABC = new Vector(0, 0, 0);
var workingPlanes = [];
var workingOrigins = [];
function getWorkingSide(workPlane, workOrigin) {
  var firstCustomSide = 6;
  var customSide;
  workingPlaneABC = getWorkPlaneMachineABC(currentSection.workPlane);
  
  // see if side already exists
  var operationType = "CUT"; //sawIsActive ? "SAW" : (isDrillingOperation() ? "DRILL" : "CUT");
  for (i = 0; i < workingPlanes.length; i++) {
    if (
      !abcFormat.areDifferent(workingPlaneABC.x, workingPlanes[i].abc.x) && !abcFormat.areDifferent(workingPlaneABC.y, workingPlanes[i].abc.y) &&
      !abcFormat.areDifferent(workingPlaneABC.z, workingPlanes[i].abc.z) && !xyzFormat.areDifferent(workOrigin.x, workingPlanes[i].origin.x) &&
      !xyzFormat.areDifferent(workOrigin.y, workingPlanes[i].origin.y) && !xyzFormat.areDifferent(workOrigin.z, workingPlanes[i].origin.z) &&
      operationType == workingPlanes[i].type
    ) {
      customSide = firstCustomSide + i;
      return customSide;
    }
  }

  // create new custom side
  customSide = firstCustomSide + workingPlanes.length;
  //workingPlanes.push(workingPlaneABC);
  //workingOrigins.push(workOrigin);
  workingPlanes.push({abc:workingPlaneABC, origin:workOrigin, type:operationType});
  writeBlock("BEGIN MACRO");
  writeBlock(tab + "NAME=WFL");
  writeBlock(tab + "PARAM,NAME=ID,VALUE=" + customSide);
  writeBlock(tab + "PARAM,NAME=X,VALUE=" + xyzFormat.format(-workpiece.lower.x + workOrigin.x)); // origin
  writeBlock(tab + "PARAM,NAME=Y,VALUE=" + xyzFormat.format(workpiece.upper.y - workOrigin.y));
  writeBlock(tab + "PARAM,NAME=Z,VALUE=" + xyzFormat.format(workpiece.upper.z - workOrigin.z));
  writeBlock(tab + "PARAM,NAME=AZ,VALUE=" + abcFormat.format(toRad(90) - workingPlaneABC.x)); // tilt from vertical plane (side of part)
  writeBlock(tab + "PARAM,NAME=AR,VALUE=" + abcFormat.format(workingPlaneABC.z)); // turn
  writeBlock(tab + "PARAM,NAME=L,VALUE=" + xyzFormat.format(0)); // length of side, use auto height
  writeBlock(tab + "PARAM,NAME=H,VALUE=" + xyzFormat.format(0)); // thickness of side, use auto length
  writeBlock(tab + "PARAM,NAME=VRT,VALUE=0"); // vertical
  writeBlock(tab + "PARAM,NAME=VF,VALUE=1"); // virtual face
  writeBlock(tab + "PARAM,NAME=AFL,VALUE=1"); // auto length
  writeBlock(tab + "PARAM,NAME=AFH,VALUE=1"); // auto height
  writeBlock(tab + "PARAM,NAME=UCS,VALUE=1"); // system, uses corner FRC for inclination
  writeBlock(tab + "PARAM,NAME=RV,VALUE=0"); // reverse
  writeBlock(tab + "PARAM,NAME=FRC,VALUE=1"); // corner for inclination
  writeBlock("END MACRO");
  return customSide;
}

function setWorkingSide(section) {
  cancelTransformation();
  isWorkingPlane = false;
  var W = section.workPlane;
  var zAxis = W.forward;
  var xAxis = new Vector(1, 0, 0);
  var origin = section.getWorkOrigin();
  leftHand = false;
  if (isSameDirection(zAxis, new Vector(0, 0, 1)) || sawIsActive) {
    side = 0;
    xAxis = new Vector(1, 0, 0);
    zAxis = new Vector(0, 0, -1);
    setTranslation(new Vector(-workpiece.lower.x + origin.x, workpiece.upper.y - origin.y, workpiece.upper.z - origin.z));
  } else if (isSameDirection(zAxis, new Vector(-1, 0, 0))) {
    side = 1;
    xAxis = new Vector(0, -1, 0);
    zAxis = new Vector(1, 0, 0);
    setTranslation(new Vector(workpiece.upper.y - origin.y, -workpiece.upper.z - origin.z, -workpiece.lower.x + origin.x));
    // leftHand = true; // yAxis has flipped sign - left hand
  } else if (isSameDirection(zAxis, new Vector(1, 0, 0))) {
    side = 3;
    xAxis = new Vector(0, 1, 0);
    zAxis = new Vector(-1, 0, 0);
    setTranslation(new Vector(-workpiece.lower.y + origin.y, workpiece.upper.z - origin.z, workpiece.upper.x - origin.x));
  } else if (isSameDirection(zAxis, new Vector(0, -1, 0))) {
    side = 2;
    xAxis = new Vector(1, 0, 0);
    zAxis = new Vector(0, 1, 0);
    setTranslation(new Vector(-workpiece.lower.x + origin.x, workpiece.upper.z - origin.z, -workpiece.lower.y + origin.y));
  } else if (isSameDirection(zAxis, new Vector(0, 1, 0))) {
    side = 4;
    xAxis = new Vector(-1, 0, 0);
    zAxis = new Vector(0, -1, 0);
    setTranslation(new Vector(workpiece.upper.x - origin.x, -workpiece.upper.z - origin.z, workpiece.upper.y - origin.y));
    // leftHand = true; // yAxis has flipped sign - left hand
  } else { // 3+2 operation outside of a predefined face
    side = getWorkingSide(W, origin);
    xAxis = new Vector(1, 0, 0);
    zAxis = new Vector(0, 0, -1);
    isWorkingPlane = true;
    // setTranslation(new Vector(-workpiece.lower.x, workpiece.upper.y, workpiece.upper.z));
  }
  var yAxis = leftHand ? Vector.cross(xAxis, zAxis) : Vector.cross(zAxis, xAxis);
  var O = new Matrix(xAxis, yAxis, zAxis);
  if (!isWorkingPlane) {
    var R = O.getTransposed().multiply(W);
    setRotation(R);
  } else {
    setRotation(O);
  }
}

function onSection() {
  sawIsActive = tool.type == TOOL_MILLING_SLOT;
  if (sawIsActive) {
    if (Vector.dot(currentSection.workPlane.forward, new Vector(0, 0, 1)) > 1.e-7) {
      error(localize("Only vertical saw cuts are currently supported."));
      return;
    }
  }

  setWorkingSide(currentSection);
  
  firstMotion = !isDrillingOperation();
}

function isDrillingOperation() {
  return hasParameter("operation-strategy") && (getParameter("operation-strategy") == "drill");
}

function getFeed(_feed) {
  return feedFormat.format(getProperty("useFeeds") ? _feed : 0);
}

function parseNumbers(_text, _max) {
  // extract values between commas
  var sText1 = _text;
  var sText2 = new Array();
  var retCoord = new Array();
  sText2 = sText1.split(",");

  // too many values, return 0
  if (sText2.length > _max) {
    return retCoord;
  }

  // parse numbers
  for (i = 0; i < sText2.length; i++) {
    retCoord[i] = parseFloat(sText2[i]);
    if (isNaN(retCoord[i])) {
      return new Array();
    }
  }

  // return number of values
  return retCoord;
}

function onParameter(name, value) {
  if (name == "action") {
    var sText1 = String(value).toUpperCase();
    var sText2 = new Array();
    sText2 = sText1.split(":");
    if (sText2.length != 2) {
      error(localize("Invalid action command") + ": " + value);
      return;
    }
    if (sText2[0] == "HOOD") {
      var num = parseNumbers(sText2[1], 1);
      if (num.length != 1) {
        error(localize("Invalid HOOD command" + ": " + value));
        return;
      }
      hoodValue = num[0];
    } else {
      error(localize("Unknown Action command") + ": " + value);
    }
  }
}

function onPassThrough(text) {
  var commands = String(text).split(";");
  for (text in commands) {
    writeBlock(commands[text]);
  }
}

function onCycle() {
  if (sawIsActive) {
    error(localize("Cycles are not allowed when using a saw blade."));
    return;
  }
}

var cyclePoints = new Array();
var cycleDelta = new Vector();

function flushCyclePoints() {
  if (cyclePoints.length == 0) {
    return;
  }
  var F = cycle.feedrate;
  var repeatType = "-1";
  var nrp = 0;
  if (cyclePoints.length > 1) {
    nrp = cyclePoints.length;
    if (cycleDelta.x != 0) {
      if (cycleDelta.y != 0) {
        repeatType = "2";
      } else {
        repeatType = "0";
      }
    } else if (cycleDelta.y != 0) {
      repeatType = "1";
    }
  }
  
  switch (cycleType) {
  case "drilling":
  case "chip-breaking":
  case "deep-drilling":
    var numberOfPecks = cycleType == "drilling" ? 0 : Math.ceil(cycle.depth / (cycle.incrementalDepth + 0.001));
    var retractType = cycleType == "chip-breaking" ? 2 : 1;
    // start boring data for one hole
    writeBlock("BEGIN MACRO");
    writeBlock(tab + "NAME=BG");
    writeBlock(tab + "PARAM,NAME=SIDE,VALUE=" + side);
    writeBlock(tab + "PARAM,NAME=CRN,VALUE=\"1\"");
    writeBlock(tab + "PARAM,NAME=X,VALUE=" + xyzFormat.format(cyclePoints[0].x));
    writeBlock(tab + "PARAM,NAME=Y,VALUE=" + xyzFormat.format(cyclePoints[0].y));
    writeBlock(tab + "PARAM,NAME=Z,VALUE=" + xyzFormat.format(cyclePoints[0].z - cycle.depth));
    writeBlock(tab + "PARAM,NAME=DP,VALUE=" + xyzFormat.format(cycle.depth));
    writeBlock(tab + "PARAM,NAME=DIA,VALUE=" + tool.diameter);
    writeBlock(tab + "PARAM,NAME=THR,VALUE=0"); // 1 = through bore
    writeBlock(tab + "PARAM,NAME=RTY,VALUE=" + repeatType);
    writeBlock(tab + "PARAM,NAME=DX,VALUE=" + xyzFormat.format(cycleDelta.x));
    writeBlock(tab + "PARAM,NAME=DY,VALUE=" + xyzFormat.format(cycleDelta.y));
    writeBlock(tab + "PARAM,NAME=R,VALUE=0");
    writeBlock(tab + "PARAM,NAME=A,VALUE=0");
    writeBlock(tab + "PARAM,NAME=DA,VALUE=0");
    writeBlock(tab + "PARAM,NAME=NRP,VALUE=" + nrp);
    writeBlock(tab + "PARAM,NAME=ISO,VALUE=\"\"");
    writeBlock(tab + "PARAM,NAME=OPT,VALUE=1");
    writeBlock(tab + "PARAM,NAME=AZ,VALUE=0");
    writeBlock(tab + "PARAM,NAME=AR,VALUE=0");
    writeBlock(tab + "PARAM,NAME=AP,VALUE=0");
    writeBlock(tab + "PARAM,NAME=CKA,VALUE=" + (isWorkingPlane ? "3" : "azrNO"));
    writeBlock(tab + "PARAM,NAME=XRC,VALUE=0");
    writeBlock(tab + "PARAM,NAME=YRC,VALUE=0");
    writeBlock(tab + "PARAM,NAME=ARP,VALUE=0");
    writeBlock(tab + "PARAM,NAME=LRP,VALUE=0");
    writeBlock(tab + "PARAM,NAME=ER,VALUE=YES");
    writeBlock(tab + "PARAM,NAME=MD,VALUE=0");
    writeBlock(tab + "PARAM,NAME=COW,VALUE=NO");
    writeBlock(tab + "PARAM,NAME=A21,VALUE=0");
    writeBlock(tab + "PARAM,NAME=TOS,VALUE=NO");
    writeBlock(tab + "PARAM,NAME=VTR,VALUE=" + numberOfPecks);
    writeBlock(tab + "PARAM,NAME=S21,VALUE=-1");
    writeBlock(tab + "PARAM,NAME=ID,VALUE=\"P" + operationId + "\""); // operation ID
    writeBlock(tab + "PARAM,NAME=AZS,VALUE=0");
    writeBlock(tab + "PARAM,NAME=MAC,VALUE=\"\"");
    if (getProperty("useBGToolName")) {
      writeBlock(tab + "PARAM,NAME=TNM,VALUE=" + "\"" + formatToolName(tool) + "\"");
    } else {
      writeBlock(tab + "PARAM,NAME=TNM,VALUE=\"\"");
    }
    writeBlock(tab + "PARAM,NAME=TTP,VALUE=" + ((tool.taperAngle == 0) || (tool.taperAngle == Math.PI) ? 0 : 1));
    writeBlock(tab + "PARAM,NAME=TCL,VALUE=0");
    writeBlock(tab + "PARAM,NAME=RSP,VALUE=" +  (getProperty("useSpeeds") ? getParameter("operation:tool_spindleSpeed", 0) : 0));
    writeBlock(tab + "PARAM,NAME=IOS,VALUE=0"); // leadin lead out speed
    writeBlock(tab + "PARAM,NAME=WSP,VALUE=" + getFeed(F)); // feedrate for drilling mm per min
    writeBlock(tab + "PARAM,NAME=SPI,VALUE=\"\"");
    writeBlock(tab + "PARAM,NAME=DDS,VALUE=0");
    writeBlock(tab + "PARAM,NAME=DSP,VALUE=0");
    writeBlock(tab + "PARAM,NAME=BFC,VALUE=0");
    writeBlock(tab + "PARAM,NAME=SHP,VALUE=0");
    writeBlock(tab + "PARAM,NAME=EA21,VALUE=NO");
    writeBlock(tab + "PARAM,NAME=CEN,VALUE=\"\"");
    writeBlock(tab + "PARAM,NAME=AGG,VALUE=\"\"");
    writeBlock(tab + "PARAM,NAME=LAY,VALUE=\"BG\"");
    writeBlock(tab + "PARAM,NAME=PRS,VALUE=0");
    writeBlock("END MACRO");
    writeBlock(" ");
    cyclePoints = new Array();
    cycleDelta = new Vector(0, 0, 0);
    break;
  }
}

function onCyclePoint(x, y, z) {
  var point = new Vector(x, y, z);

  switch (cycleType) {
  case "drilling":
  case "chip-breaking":
  case "deep-drilling":
    if (isFirstCyclePoint()) {
      cyclePoints.push(point);
      cycleDelta = new Vector(0, 0, 0);
    } else {
      var delta = Vector.diff(point, cyclePoints[cyclePoints.length - 1]);
      if (cyclePoints.length != 1) {
        if (xyzFormat.areDifferent(delta.x, cycleDelta.x) ||
            xyzFormat.areDifferent(delta.y, cycleDelta.y) ||
            xyzFormat.areDifferent(delta.z, cycleDelta.z)) {
          flushCyclePoints();
        }
      } else {
        cycleDelta = delta;
      }
      cyclePoints.push(new Vector(x, y, z));
    }
    if (isLastCyclePoint()) {
      flushCyclePoints();
    }
    break;
  default:
    error(localize("Unsupported cycle: ") + cycleType);
    break;
  }
}

function onCycleEnd() {
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

function onRapid(_x, _y, _z) {
  if (sawIsActive) {
    bufferSawMove(_x, _y, _z, 0);
    return;
  }

  if (!isDrillingOperation()) {
    if (firstMotion) {
      firstMotion = false;
      return;
    }
    var start = getCurrentPosition();

    // XY-only move signifies start of new profile
    if ((xyzFormat.areDifferent(_x, start.x) ||
        xyzFormat.areDifferent(_y, start.y)) &&
        !xyzFormat.areDifferent(_z, start.z)) {
      if (pointsCount != 0) {
        writeEndPathMacro();
        if (!getProperty("useRoutMacro")) { // using ROUTG Macro
          writeRoutGMacro();
          writeEndPathMacro();
        }
      }
    } else {
      writeLineEpMacro(_x, _y, _z);
    }
  }
}

function onLinear(_x, _y, _z, feed) {
  if (sawIsActive) {
    bufferSawMove(_x, _y, _z, feed);
    return;
  }
  if (firstMotion) {
    firstMotion = false;
    return;
  }
  writeLineEpMacro(_x, _y, _z);
}

var sawOffset = 1; // -1 = offset from saw to line, 0 = no offset, 1 = offset from line to saw
var sawPositions = new Array();

function bufferSawMove(x, y, z, feed) {
  if (sawPositions.length == 0 || xyzFormat.getResultingValue(Vector.diff(new Vector(x, y, z), sawPositions[sawPositions.length - 1].xyz).length)) {
    sawPositions.push({xyz:new Vector(x, y, z), feed:feed, movement:movement});
  }
}

function flushSawMove() {
  // break out saw moves
  var currentPosition = undefined;
  var sawMoves = new Array();
  for (var i = 0; i < sawPositions.length; ++i) {
    switch (sawPositions[i].movement) {
    case MOVEMENT_RAPID:
      currentPosition = sawPositions[i].xyz;
      break;
    case MOVEMENT_LEAD_IN:
    case MOVEMENT_LEAD_OUT:
      if (getProperty("ignoreSawLeadIn") || (currentPosition == undefined)) {
        currentPosition = sawPositions[i].xyz;
      } else {
        sawMoves.push({start:currentPosition, end:sawPositions[i].xyz, feed:feed});
      }
      break;
    case MOVEMENT_CUTTING:
    case MOVEMENT_FINISH_CUTTING:
    case MOVEMENT_REDUCED:
      if (currentPosition == undefined) {
        currentPosition = sawPositions[i].xyz;
      } else {
        sawMoves.push({start:currentPosition, end:sawPositions[i].xyz, feed:sawPositions[i].feed, used:true});
        currentPosition = sawPositions[i].xyz;
      }
      break;
    default:
      currentPosition = sawPositions[i].xyz;
      break;
    }
  }

  if (false) {
    for (var i = 0; i < sawMoves.length; ++i) {
      if (sawMoves.used) {
        writeDebug("");
        writeDebug("start = " + sawMoves[i].start);
        writeDebug("end = " + sawMoves[i].end);
      }
    }
  }

  // validate saw moves
  if (sawMoves.length > 1) {
    var sawDirection = Vector.diff(sawMoves[0].end, sawMoves[0].start).getNormalized();
    for (var i = 1; i < sawMoves.length; ++i) {
      var moveDirection = Vector.diff(sawMoves[i].end, sawMoves[i].start).getNormalized();
      if (xyzFormat.getResultingValue(Vector.diff(sawMoves[i - 1].end, sawMoves[i].start).length) <= toPreciseUnit(0.001, IN)) {
        if (Vector.diff(moveDirection, sawDirection).length > toPreciseUnit(0.001, IN)) { // saw direction changes
          error(localize("Saw move changes direction during cut."));
          return;
        } else { // remove saw cuts in same direction
          sawMoves[i - 1].used = false;
          sawMoves[i].start = sawMoves[i - 1].start;
        }
      }
    }
  }

  // output saw moves
  writeSawMoves(sawMoves);
}

function writeSawMoves(sawMoves) {
  for (var i = 0; i < sawMoves.length; ++i) {
    if (sawMoves[i].used) {
      var start = new Vector(sawMoves[i].start.x, sawMoves[i].start.y, sawMoves[i].start.z);
      var end = new Vector(sawMoves[i].end.x, sawMoves[i].end.y, sawMoves[i].end.z);
      var forward = getRotation().multiply(new Vector(0, 0, 1));

      // output points are along edge of cutter
      if (hasParameter("operation:compensationType") && hasParameter("operation:compensation")) {
        if (getParameter("operation:compensationType") != "control") {
          var offsetVector;
          var dir = getParameter("operation:compensation");
          var sawDirection = Vector.diff(sawMoves[i].end, sawMoves[i].start).getNormalized();
          if (dir == "right") {
            offsetVector = Vector.product(Vector.cross(forward, sawDirection).getNormalized(), (tool.diameter / 2));
          } else if (getParameter("operation:compensation") == "left") {
            offsetVector = Vector.product(Vector.cross(sawDirection, forward).getNormalized(), (tool.diameter / 2));
          }
          start = Vector.sum(start, offsetVector);
          end = Vector.sum(end, offsetVector);
        }
      }

      // output points are at center of blade
      start = Vector.sum(start, Vector.product(forward, (tool.fluteLength / 2)));
      end = Vector.sum(end, Vector.product(forward, (tool.fluteLength / 2)));

      sawZDepth = Math.min(start.z, end.z);

      // write out geometry
      writeLineEpMacro(end.x, end.y, end.z, start);
      writeEndPathMacro();

      // write out saw operation
      writeCutGeoMacro();
      writeEndPathMacro();
    }
  }
  sawPositions = new Array(); // zero out saw moves
}

/** Adjust final point to lie exactly on circle. */
function CircularData(_plane, _center, _end) {
  // use Output variables, since last point could have been adjusted if previous move was circular
  var start = new Vector(xOutput.getCurrent(), yOutput.getCurrent(), zOutput.getCurrent());
  var center = _center;
  var end = _end;
  switch (_plane) {
  case PLANE_XY:
    start.setZ(center.z);
    end.setZ(_center.z);
    break;
  case PLANE_ZX:
    start.y = _center.y;
    end.y = _center.y;
    break;
  case PLANE_YZ:
    start.x = _center.x;
    end.x = _center.x;
    break;
  default:
    this.center = new Vector(_center.x, _center.y, _center.z);
    this.start = new Vector(start.x, start.y, start.z);
    this.end = new Vector(_end.x, _end.y, _end.z);
    this.offset = Vector.diff(_center, start);
    this.radius = this.offset.length;
    return;
  }
  this.start = new Vector(
    xyzFormat.getResultingValue(start.x),
    xyzFormat.getResultingValue(start.y),
    xyzFormat.getResultingValue(start.z)
  );
  var temp = Vector.diff(_center, start);
  this.offset = new Vector(
    xyzFormat.getResultingValue(temp.x),
    xyzFormat.getResultingValue(temp.y),
    xyzFormat.getResultingValue(temp.z)
  );
  this.center = Vector.sum(this.start, this.offset);
  this.radius = this.offset.length;

  temp = Vector.diff(end, _center).normalized;
  this.end = new Vector(
    xyzFormat.getResultingValue(this.center.x + temp.x * radius),
    xyzFormat.getResultingValue(this.center.y + temp.y * radius),
    xyzFormat.getResultingValue(this.center.z + temp.z * radius)
  );

  switch (_plane) {
  case PLANE_XY:
    this.start.z = start.z;
    this.end.z = _end.z;
    this.offset.z = 0;
    break;
  case PLANE_ZX:
    this.start.y = start.y;
    this.end.y = _end.y;
    this.offset.y = 0;
    break;
  case PLANE_YZ:
    this.start.x = start.x;
    this.end.x = _end.x;
    this.offset.x = 0;
    break;
  }
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  if (sawIsActive) {
    linearize(tolerance);
    return;
  }

  var start = getCurrentPosition();
  var circle = new CircularData(getCircularPlane(), new Vector(cx, cy, cz), new Vector(x, y, z));

  switch (getCircularPlane()) {
  case PLANE_XY:
    writeBlock("BEGIN MACRO");
    writeBlock(tab + "NAME=ARC_EPCE");
    writeBlock(tab + "PARAM,NAME=ID,VALUE=" + lineId++);
    writeBlock(xOutput.format(circle.end.x));
    writeBlock(yOutput.format(circle.end.y));
    writeBlock(xcOutput.format(circle.center.x));
    writeBlock(ycOutput.format(circle.center.y));
    writeBlock(tab + "PARAM,NAME=DIR,VALUE=" + (clockwise ? "dirCCW" : "dirCW")); // Z-axis is reversed
    var zs = zsOutput.format(previousZ);
    zOutput.format(start.z);
    writeBlock(zsOutput.format(start.z)); // start Z
    writeBlock(zOutput.format(z)); // Z end
    writeBlock(tab + "PARAM,NAME=SC,VALUE=scOFF");
    writeBlock(tab + "PARAM,NAME=FD,VALUE=0");
    writeBlock(tab + "PARAM,NAME=SP,VALUE=0");
    writeBlock(tab + "PARAM,NAME=SOL,VALUE=0");
    previousZ = z;
    break;
  default:
    linearize(tolerance);
  }
  writeBlock("END MACRO");
  writeln("");
}

function onCommand(command) {
}

function onSectionEnd() {
  if (sawIsActive) {
    flushSawMove();
  } else if (!isDrillingOperation()) {
    if (pointsCount != 0) {
      writeEndPathMacro();
      if (!getProperty("useRoutMacro")) {
        writeRoutGMacro();
        writeEndPathMacro();
      }
    }
  }
  operationId++;
  hoodValue = getProperty("hoodPosition");
}

function onClose() {
}

function setProperty(property, value) {
  properties[property].current = value;
}
