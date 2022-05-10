/**
  Copyright (C) 2012-2021 by Autodesk, Inc.
  All rights reserved.

  VERICUT post processor configuration.

  $Revision: 43180 caabf52234c46abb01b73fb91f79162ddaaff381 $
  $Date: 2021-03-12 15:47:06 $

  FORKID {7B821814-D2EB-4DEE-84F2-FF4D3F28BEB1}
*/

description = "VERICUT";
vendor = "CGTech";
vendorUrl = "http://www.cgtech.com";
legal = "Copyright (C) 2012-2021 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;
capabilities = CAPABILITY_INTERMEDIATE | CAPABILITY_CASCADING;

longDescription = "Post integration with VERICUT. This is a cascading post to use for automatic simulation of generated NC programs in VERICUT.";

dependencies = "vericut.hta";

// user-defined properties
properties = {
  toolListOnly: {
    title: "Create tool database only",
    description: "Enable to create the tool database only, disable to run VERICUT.",
    group: 0,
    type: "boolean",
    value: false,
    scope: "post"
  }
};

function onSection() {
  if (currentSection.getType() != TYPE_MILLING) {
    error(localize("Unsupported operation type."));
    return;
  }
  skipRemainingSection();
}

function onClose() {
  showDialog();

  if (getProperty("toolListOnly")) {
    createToolDatabaseFile();
  } else {
    createVerificationJob();
    createProjectFile();
    createToolDatabaseFile();
    createOPSfile();
  }
}

this.exportStock = true;
this.exportPart = true;
this.exportFixture = true;

var destPath = FileSystem.getFolderPath(getCascadingPath());
var projectPath;
var vericutPath;

/* eslint-disable */
function showDialog() {
  if (!FileSystem.isFolder(FileSystem.getTemporaryFolder())) {
    FileSystem.makeFolder(FileSystem.getTemporaryFolder());
  }
  var path = FileSystem.getTemporaryFile("post");
  var exePath = getVericutPath();
  execute(findFile("vericut.hta"), "\"" + path + "\" " + "\"" + exePath + "\"", false, "");
  var result = {};
  try {
    var file = new TextFile(path, false, "utf-8");
    while (true) {
      var line = file.readln();
      var index = line.indexOf("=");
      if (index >= 0) {
        var name = line.substr(0, index);
        var value = line.substr(index + 1);
        result[name] = value;
      }
    }
    file.close();
  } catch (e) {
  }
  FileSystem.remove(path);

  var gotValues = false;
  for (var name in result) {
    gotValues = true;
    break;
  }
  if (!gotValues) {
    error(localize("Aborted by user."));
    return false;
  }

  var comment;
  for (var name in result) {
    var value = result[name];
    switch (name) {
    case "vericutPath":
      vericutPath = value;
      break;
    case "vcprojectPath":
      projectPath = value;
      break;
    case "baseToolNumber":
      baseToolNumber = parseInt(value);
      baseToolNumber = isNaN(baseToolNumber) ? 0 : baseToolNumber;
      break;
    }
  }
  return true;
}
/* eslint-enable */

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var spatialFormat = createFormat({decimals:4});

function createOPSfile() {
  var path = FileSystem.replaceExtension(getCascadingPath(), "ops");
  var file = new TextFile(path, true, "utf-8");

  file.writeln("PROJECT FILE=" + "\"" + projectPath + "\"");
  file.writeln("SETUP NAME=" + "\"" + programName + "\"" + " INDEX=1 SETUP=1 FILE=" + "\"" + projectPath + "\"");
  file.writeln("SETUP NAME=" + "\"" + programName + "\"" + " INDEX=1 SETUP=1 FILE=" + "\"" + FileSystem.replaceExtension(getCascadingPath(), "VcTemp") + "\"");
  file.close();
}

function createToolDatabaseFile() {
  var path = FileSystem.replaceExtension(getCascadingPath(), "tls");
  var file = new TextFile(path, true, "ansi");

  if (revision < 41761) {
    error(localize("Your version of CAM does not support the use of the Vericut interface. Please update to the latest version."));
    return;
  }
  
  file.writeln("<?xml version=" + "\"" + "1.0" + "\"" + "?>");
  file.writeln("<CGTechToolLibrary Version=" + "\"" + "8.1" + "\"" + ">");
  file.writeln("<Tools>");

  var tools = getToolTable();
  if (tools.getNumberOfTools() > 0) {
    for (var i = 0; i < tools.getNumberOfTools(); ++i) {
      var tool = tools.getTool(i);
      var toolType = tool.getType();
      var holder = tool.holder;
      
      switch (toolType) {
      case TOOL_DRILL:
      case TOOL_DRILL_CENTER:
      case TOOL_DRILL_SPOT:
      case TOOL_DRILL_BLOCK:
      case TOOL_REAMER:
      case TOOL_BORING_BAR:
      case TOOL_COUNTER_BORE:
      case TOOL_COUNTER_SINK:
        cutterType = "HoleMaking";
        break;
      case TOOL_TAP_RIGHT_HAND:
      case TOOL_TAP_LEFT_HAND:
        cutterType = "Tap";
        break;
      case TOOL_PROBE:
        cutterType = "Probing";
        break;
      default:
        cutterType = "Milling";
        break;
      }

      var toolNumber = tool.type == TOOL_PROBE ? tool.number : baseToolNumber + tool.number;
      file.writeln("<Tool ID=" + "\"" + toolNumber + "\"" + " Units=" + "\"" + ((unit == IN) ? "Inch" : "Millimeter") + "\"" + ">");
      file.writeln("<Description>" + getToolTypeName(tool.type) + "</Description>");
      file.writeln("<Teeth>" + tool.numberOfFlutes + "</Teeth>");
      file.writeln("<SpinAxis>SpindleAxis</SpinAxis>");
      file.writeln("<Type>" + cutterType + "</Type>");
      file.writeln("<Cutter>");

      if (cutterType == "Tap") {
        file.writeln("<Tap ID=\"Cutter\" ParentID=\"Holder1\">");
        file.writeln("<MajorDiameter>" + spatialFormat.format(tool.diameter) + "</MajorDiameter>");
        file.writeln("<ThreadPerUnit>" + spatialFormat.format(1 / tool.threadPitch) + "</ThreadPerUnit>");
        file.writeln("<ThreadLength>" + spatialFormat.format(tool.fluteLength) + "</ThreadLength>");
        file.writeln("<OverallLength>" + spatialFormat.format(tool.bodyLength + ((unit == IN ? 0.5 : 12))) + "</OverallLength>");
        file.writeln("<MinorDiameter>" + spatialFormat.format(tool.diameter * 0.9) + "</MinorDiameter>");
        file.writeln("<NeckDiameter>" + spatialFormat.format(tool.shaftDiameter) + "</NeckDiameter>");
        file.writeln("<NeckLength>" + spatialFormat.format(tool.shoulderLength) + "</NeckLength>");
        file.writeln("<ShankDiameter>" + spatialFormat.format(tool.shaftDiameter) + "</ShankDiameter>");
        file.writeln("<TipDiameter>" + spatialFormat.format(tool.diameter * 0.9) + "</TipDiameter>");
        file.writeln("<LeadTolerance>" + spatialFormat.format(0.0) + "</LeadTolerance>");
        file.writeln("<Style>" + "Bottom" + "</Style>");
        file.writeln("<Direction>" + (toolType == TOOL_TAP_LEFT_HAND ? "Left" : "Right") + "</Direction>");
        file.writeln("<SpindleDirection>" + (tool.clockwise ? "CW" : "CCW") + "</SpindleDirection>");
        file.writeln("<Forms>Unified (" + ((unit == IN) ? "Inch" : "Millimeter") + ")</Forms>");
        file.writeln("<StockMaterialRecords>");
        file.writeln("</StockMaterialRecords>");
        file.writeln("<Origin> <X>0</X> <Y>0</Y> <Z>" + spatialFormat.format(0) + "</Z> </Origin>");
        file.writeln("<Alternate>off</Alternate>");
        file.writeln("</Tap>");
      } else if (cutterType == "Probing") {
        file.writeln("<Probe ID=\"Probe\" ParentID=\"Holder1\" Type=\"Standard\" >");
        file.writeln("<SphereDiameter>" + spatialFormat.format(tool.diameter) + "</SphereDiameter>");
        file.writeln("<Height>" + spatialFormat.format(tool.bodyLength) + "</Height>");
        file.writeln("<StemDiameter>" + spatialFormat.format(tool.shaftDiameter) + "</StemDiameter>");
        file.writeln("<Length>" + spatialFormat.format(tool.bodyLength * 1.1) + "</Length>");
        file.writeln("<MaxRPM>" + spatialFormat.format(tool.spindleRPM) + "</MaxRPM>");
        file.writeln("<Origin> <X>0</X> <Y>0</Y> <Z>" + spatialFormat.format(0) + "</Z> </Origin>");
        file.writeln("<Alternate>off</Alternate>");
        file.writeln("</Probe>");
      } else {

        /*
        file.writeln("<Apt ID=" + "\"" + getToolTypeName(tool.type) + "\"" + "> Type=" + "\"" + "Apt 7" + "\"");
        file.writeln("<D>" + xyzFormat.format(tool.diameter) + "</D>");
        file.writeln("<R>" + xyzFormat.format(tool.cornerRadius) + "</R>");
        file.writeln("<E>0</E>");
        file.writeln("<F>0</F>");
        file.writeln("<A>0</A>");
        file.writeln("<B>0</B>");
        file.writeln("<H>" + tool.bodyLength + "</H>");
        file.writeln("<StickoutLength>" + tool.bodyLength + "</StickoutLength>");
        file.writeln("<ShankDiameter>" + tool.shaftDiameter + "</ShankDiameter>");
        file.writeln("<FluteLength>" + tool.fluteLength + "</FluteLength>");
        file.writeln("</Apt>");
        */

        file.writeln("<SOR ID=" + "\"" + getToolTypeName(tool.type) + "\"" + ">");
        file.writeln("<Pt><X>0</X><Z>0</Z></Pt>");
        var cutter = tool.getCutterProfile();
        for (var k = 0; k < cutter.getNumberOfEntities() / 2; ++k) {
          var arc = ((cutter.getEntity(k).clockwise == true) || cutter.getEntity(k).center.length > 1e-4);
          var endX = xyzFormat.format(cutter.getEntity(k).end.x);
          var endY = xyzFormat.format(cutter.getEntity(k).end.y);
          var centerX = xyzFormat.format(cutter.getEntity(k).center.x);
          var centerY = xyzFormat.format(cutter.getEntity(k).center.y);
          var arcDir = cutter.getEntity(k).clockwise ? "CW" : "CCW";
          var radius = xyzFormat.format(Vector.diff(cutter.getEntity(k).start, cutter.getEntity(k).center).length);
        
          if (arc) {
            file.writeln("<Arc><X>" + centerX + "</X><Z>" + centerY + "</Z><Radius>" + radius + "</Radius><Direction>" + arcDir + "</Direction></Arc>");
          }
          file.writeln("<Pt><X>" + endX + "</X><Z>" + endY + "</Z></Pt>");
        }
        file.writeln("<FluteLength>" + spatialFormat.format(tool.fluteLength) + "</FluteLength>");
        file.writeln("</SOR>");
      }
      file.writeln("</Cutter>");
      
      if (holder && holder.hasSections()) {
        file.writeln("<Holder>");
        file.writeln("<SOR ID=" + "\"" + "Holder1" + "\"" + ">");
        file.writeln("<Pt> <X>0</X> <Z>0</Z> </Pt>");
        var hCurrent = 0;
        if (holder && holder.hasSections()) {
          var n = holder.getNumberOfSections();
          for (var j = 0; j < n; ++j) {
            if (j == 0) {
              //file.writeln("        <Pt><X>" + tool.shaftDiameter + "</X> <Z>0</Z> <Pt>" + (tool.shaftDiameter/2) + " 0</END></Pt>");
            } else {
              hCurrent += holder.getLength(j - 1);
              file.writeln("<Pt><X>" + xyzFormat.format(holder.getDiameter(j - 1) / 2) + "</X>" + " <Z>" + xyzFormat.format(hCurrent) + "</Z> </Pt>");
            }
          }
        }
        file.writeln("<Origin> <X>0</X> <Y>0</Y> <Z>" + xyzFormat.format(tool.bodyLength) + "</Z> </Origin>");
        file.writeln("</SOR>");
        file.writeln("</Holder>");
      }
      file.writeln("<GagePoint>");
      file.writeln("<X>0</X>");
      file.writeln("<Y>0</Y>");
      file.writeln("<Z>" + (tool.bodyLength + tool.holderLength) + "</Z>");
      file.writeln("</GagePoint>");
      file.writeln("</Tool>");
    }
  }
  file.writeln("</Tools>");
  file.writeln("</CGTechToolLibrary>");
  file.close();
}

function createProjectFile() {
  var path = FileSystem.replaceExtension(getCascadingPath(), "VcTemp");
  var file = new TextFile(path, true, "ansi");
  
  if (!programName) {
    error(localize("Program name is not specified."));
    return;
  }

  file.writeln("<?xml version=" + "\"" + "1.0" + "\"" + " encoding=" + "\"" + "UTF-8" + "\"" + "?>");
  file.writeln("<VcProject Version=" + "\"" + "8.1" + "\"" + " Unit=" + "\"" + ((unit == IN) ? "Inch" : "Millimeter") + "\"" + ">");
  file.writeln("<Setup Name=" + "\"" + programName + "\"" + " Active=" + "\"" + "on" + "\"" + ">");
  file.writeln("    <NCPrograms Selected=" + "\"" + "on" + "\"" + " Type=" + "\"" + "gcode" + "\"" + " Change=" + "\"" + "list" + "\"" + " List=" + "\"" + "tool_num" + "\"" + ">");
  file.writeln("    <NCProgram Use=" + "\"" + "on" + "\"" + " Filter=" + "\"" + "off" + "\"" + ">");
  // path to NC PGM
  file.writeln("    <File>" + getCascadingPath() + "</File>");
  file.writeln("    </NCProgram>");
  file.writeln("    </NCPrograms>");
  file.writeln("<ToolMan>");
  file.writeln("<Library>" + FileSystem.replaceExtension(getCascadingPath(), "tls") + "</Library>");
  file.writeln("</ToolMan>");
  file.writeln("    <ToolChange List=\"tool_num\">");
  var tools = getToolTable();
  if (tools.getNumberOfTools() > 0) {
    for (var i = 0; i < tools.getNumberOfTools(); ++i) {
      var tool = tools.getTool(i);
      var toolNumber = tool.type == TOOL_PROBE ? tool.number : baseToolNumber + tool.number;
      file.writeln("      <Event Init=\"" + tool.number + "\">");
      file.writeln("        <Cutter Ident=\"" + toolNumber + "\">" + tool.number + "</Cutter>");
      file.writeln("      </Event>");
    }
  }
  file.writeln("    </ToolChange>");
  /* Not recommended by CGTech
  file.writeln("<AutoDiff>");
  file.writeln("<Constant Gouge=" + "\"" + "off" + "\"" + "/>");
  file.writeln("</AutoDiff>");
  */
  file.writeln("<Build>");
  
  var workpiece = getWorkpiece();
  var delta = Vector.diff(workpiece.upper, workpiece.lower);

  if (hasGlobalParameter("autodeskcam:fixture-path")) {
    var x = xyzFormat.format(getSection(0).getFCSOrigin().x);
    var y = xyzFormat.format(getSection(0).getFCSOrigin().y);
    var z = xyzFormat.format(getSection(0).getFCSOrigin().z);
  } else {
    var x = xyzFormat.format(delta.x / 2 - workpiece.upper.x);
    var y = xyzFormat.format(delta.y / 2 - workpiece.upper.y);
    var z = xyzFormat.format(workpiece.lower.z);
  }
  /*
  var vxx = xyzFormat.format(getSection(0).getFCSPlane().getRight().x);
  var vxy = xyzFormat.format(getSection(0).getFCSPlane().getRight().y);
  var vxz = xyzFormat.format(getSection(0).getFCSPlane().getRight().z);
  var vyx = xyzFormat.format(getSection(0).getFCSPlane().getUp().x);
  var vyy = xyzFormat.format(getSection(0).getFCSPlane().getUp().y);
  var vyz = xyzFormat.format(getSection(0).getFCSPlane().getUp().z);
*/
  if (destFixturePath) {
    file.writeln("<Component Name=" + "\"" + "Fixture" + "\"" + " Type=" + "\"" + "fixture" + "\"" + " Visible=" + "\"" + "all" + "\"" + " Draw=" + "\"" + "shaded" + "\"" + " XRGB=" + "\"" + "0x00696969" + "\"" + " Select=" + "\"" + "off" + "\"" + ">");
    file.writeln("  <Attach>Fixture</Attach>");
    file.writeln("    <Position X=" + "\"" + -x + "\"" + " Y=" + "\"" + -y + "\"" + " Z=" + "\"" + -z + "\"" + "/>");
    file.writeln("    <Rotation I=" + "\"" + "0" + "\"" + " J=" + "\"" + "0" + "\"" + " K=" + "\"" + "0" + "\"" + "/>");
    file.writeln("    <STL Unit=" + "\"" + ((unit == IN) ? "Inch" : "Millimeter") + "\"" + " Normal=" + "\"" + "outward" + "\"" + " Visible=" + "\"" + "on" + "\"" + " XRGB=" + "\"" + "0x80000000" + "\"" + " Select=" + "\"" + "off" + "\"" + ">");
    file.writeln("      <File>" + destFixturePath + "</File>");
    file.writeln("          <ModelMatrix>");
    file.writeln("            <MatrixXAxis X=" + "\"" + "1" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "0" + "\"" + "/>");
    file.writeln("            <MatrixYAxis X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "1" + "\"" + " Z=" + "\"" + "0" + "\"" + "/>");
    file.writeln("            <MatrixZAxis X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "1" + "\"" + "/>");
    file.writeln("            <MatrixOrigin X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "0" + "\"" + "/>");
    file.writeln("          </ModelMatrix>");
    file.writeln("      </STL>");
    file.writeln("    </Component>");
  }
  file.writeln("<Component Name=" + "\"" + "Stock" + "\"" + " Type=" + "\"" + "stock" + "\"" + " Visible=" + "\"" + "all" + "\"" + " Draw=" + "\"" + "shaded" + "\"" +  " XRGB=" + "\"" + "0x00FFD700" + "\"" + " Select=" + "\"" + "off" + "\"" + ">");
  file.writeln("  <Attach>Fixture</Attach>");
  if (destFixturePath) {
    file.writeln("    <Position X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "0" + "\"" + "/>");
  } else {
    file.writeln("    <Position X=" + "\"" + x + "\"" + " Y=" + "\"" + y + "\"" + " Z=" + "\"" + -z + "\"" + "/>");
  }
  file.writeln("    <Rotation I=" + "\"" + "0" + "\"" + " J=" + "\"" + "0" + "\"" + " K=" + "\"" + "0" + "\"" + "/>");
  file.writeln("    <STL Unit=" + "\"" + ((unit == IN) ? "Inch" : "Millimeter") + "\"" + " Normal=" + "\"" + "outward" + "\"" + " Visible=" + "\"" + "on" + "\"" + " XRGB=" + "\"" + "0x80000000" + "\"" + " Select=" + "\"" + "off" + "\"" + ">");
  file.writeln("      <File>" + destStockPath + "</File>");
  file.writeln("          <ModelMatrix>");
  file.writeln("            <MatrixXAxis X=" + "\"" + "1" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "0" + "\"" + "/>");
  file.writeln("            <MatrixYAxis X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "1" + "\"" + " Z=" + "\"" + "0" + "\"" + "/>");
  file.writeln("            <MatrixZAxis X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "1" + "\"" + "/>");
  file.writeln("            <MatrixOrigin X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "0" + "\"" + "/>");
  file.writeln("          </ModelMatrix>");
  file.writeln("      </STL>");
  file.writeln("    </Component>");
  file.writeln("<Component Name=" + "\"" + "Design" + "\"" + " Type=" + "\"" + "design" + "\"" + " Visible=" + "\"" + "none" + "\"" + " Draw=" + "\"" + "shaded" + "\"" + " XRGB=" + "\"" + "0x007D7D7D " + "\"" + " Select=" + "\"" + "off" + "\"" + ">");
  file.writeln("  <Attach>Stock</Attach>");
  file.writeln("    <Position X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "0" + "\"" + "/>");
  file.writeln("    <Rotation I=" + "\"" + "0" + "\"" + " J=" + "\"" + "0" + "\"" + " K=" + "\"" + "0" + "\"" + "/>");
  file.writeln("    <STL Unit=" + "\"" + ((unit == IN) ? "Inch" : "Millimeter") + "\"" + " Normal=" + "\"" + "outward" + "\"" + " Visible=" + "\"" + "off" + "\"" + " XRGB=" + "\"" + "0x80000000" + "\"" + " Select=" + "\"" + "off" + "\"" + ">");
  file.writeln("      <File>" + destPartPath + "</File>");
  file.writeln("          <ModelMatrix>");
  file.writeln("            <MatrixXAxis X=" + "\"" + "1" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "0" + "\"" + "/>");
  file.writeln("            <MatrixYAxis X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "1" + "\"" + " Z=" + "\"" + "0" + "\"" + "/>");
  file.writeln("            <MatrixZAxis X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "1" + "\"" + "/>");
  file.writeln("            <MatrixOrigin X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "0" + "\"" + "/>");
  file.writeln("          </ModelMatrix>");
  file.writeln("      </STL>");
  file.writeln("    </Component>");
  file.writeln("</Build>");

  file.writeln("<GCode>");
  /* Not used
  file.writeln("  <Table Name=" + "\"" + "Machine Zero" + "\"" + ">");
  file.writeln("    <Row Index=" + "\"" + "1" + "\"" + " SubIndex=" + "\"" + "1" + "\"" + " Auto=" + "\"" + "auto" + "\"" + ">");
  file.writeln("      <System>1</System>");
  file.writeln("      <From CSystem=" + "\"" + "off" + "\"" + " X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "0" + "\"" + ">Spindle</From>");
  file.writeln("      <To CSystem=" + "\"" + "on" + "\"" + " X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "0" + "\"" + ">Program_Zero</To>");
  file.writeln("    </Row>");
  file.writeln("  </Table>");
  */

  var ncFrame = new Array();
  var numberOfSections = getNumberOfSections();
  for (var i = 0; i < numberOfSections; ++i) {
    var found = false;
    var section = getSection(i);
    for (var j = 0; j < ncFrame.length; ++j) {
      if (ncFrame[j].workOffsetNumber == section.workOffset) {
        found = true;
        break;
      }
    }
    if (!found) {
      ncFrame.push({workOffsetNumber: section.workOffset, fcsPlane: section.getFCSPlane()});
    }
  }

  file.writeln("<Table Name=" + quote("Work Offsets") + ">");

  for (var i = 0; i < ncFrame.length; ++i) {
    var workOffset = ncFrame[i].workOffsetNumber;
    if ((getNumberOfSections() > 0) && (getSection(0).workOffset == 0)) {
      for (var j = 0; j < getNumberOfSections(); ++j) {
        if (getSection(j).workOffset > 0) {
          error(localize("Using multiple work offsets is not possible if the initial work offset is 0."));
          return;
        }
      }
    }
    if (workOffset == 0) {
      workOffset = 1;
    }
    var wcs;
    if (workOffset > 0) {
      if (workOffset > 6) {
        var code = workOffset - 6;
        wcs = code;
      } else {
        wcs = 53 + workOffset;
      }
    }
    file.writeln("        <Row Index=" + "\"" + wcs + "\"" + " SubIndex=" + quote("1") + " Auto=" + quote("auto") + ">");
    file.writeln("          <System>1</System>");
    file.writeln("          <From CSystem=" + quote("off") + " X=" + quote("0") + " Y=" + quote("0") + " Z=" + quote("0") + ">Spindle</From>");
    file.writeln("          <To CSystem=" + quote("on") + " X=" + quote("0") + " Y=" + quote("0") + " Z=" + quote("0") + ">Program_Zero</To>");
    // file.writeln("          <AddOffset X="0" Y="0" Z="0" A="0" B="0" C="0" U="0" V="0" W="0" A2="0" B2="0" C2="0" />");
    // file.writeln("          <RelPosition X="0" Y="0" Z="0" A="0" B="0" C="0" U="0" V="0" W="0" A2="0" B2="0" C2="0" />");                                                                                                                                              ");
    file.writeln("        </Row>");
  }
  file.writeln("      </Table>");
  file.writeln("</GCode>");

  file.writeln("<CSystems>");
  file.writeln("  <CSystem Name=" + "\"" + "Program_Zero" + "\"" + " Type=" + "\"" + "component" + "\"" + " Visible=" + "\"" + "all" + "\"" + " Transition=" + "\"" + "on" + "\"" + ">");
  file.writeln("<Attach>Stock</Attach>");
  file.writeln("<Position X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "0" + "\"" + "/>");
  file.writeln("<Rotation I=" + "\"" + "0" + "\"" + " J=" + "\"" + "0" + "\"" + " K=" + "\"" + "0" + "\"" + "/>");
  file.writeln("</CSystem>");

  // file.writeln("<CSystem Name=" + "\"" + "*Stock*" + "\"" + " Type=" + "\"" + "component" + "\"" + " Visible=" + "\"" + "none" + "\"" + " Transition=" + "\"" + "off" + "\"" + ">");
  // file.writeln("<Attach>Stock</Attach>");
  // file.writeln("<Position X=" + "\"" + "0" + "\"" + " Y=" + "\"" + "0" + "\"" + " Z=" + "\"" + "0" + "\"" + "/>");
  // file.writeln("<Rotation I=" + "\"" + "0" + "\"" + " J=" + "\"" + "0" + "\"" + " K=" + "\"" + "0" + "\"" + "/>");
  // file.writeln("</CSystems>");
  file.writeln("</Setup>");
  file.writeln("</VcProject>");
  file.close();
}

function quote(text) {
  var result = "";
  for (var i = 0; i < text.length; ++i) {
    var ch = text.charAt(i);
    switch (ch) {
    case "\\":
    case "\"":
      result += "\\";
    }
    result += ch;
  }
  return "\"" + result + "\"";
}

var destStockPath = "";
var destPartPath = "";
var destFixturePath = "";

function createVerificationJob() {
  var stockPath;
  if (hasGlobalParameter("autodeskcam:stock-path")) {
    stockPath = getGlobalParameter("autodeskcam:stock-path");
  }
  var partPath;
  if (hasGlobalParameter("autodeskcam:part-path")) {
    partPath = getGlobalParameter("autodeskcam:part-path");
  }
  var fixturePath;
  if (hasGlobalParameter("autodeskcam:fixture-path")) {
    fixturePath = getGlobalParameter("autodeskcam:fixture-path");
  }

  if (!FileSystem.isFolder(destPath)) {
    error(subst(localize("NC verification job folder '%1' does not exist."), destPath));
    return;
  }

  if (!programName) {
    error(localize("Program name is not specified."));
    return;
  }

  if (FileSystem.isFile(stockPath)) {
    destStockPath = FileSystem.getCombinedPath(destPath, programName + "_STOCK.stl");
    FileSystem.copyFile(stockPath, destStockPath);
  }

  if (FileSystem.isFile(partPath)) {
    destPartPath = FileSystem.getCombinedPath(destPath, programName + "_PART.stl");
    FileSystem.copyFile(partPath, destPartPath);
  }

  if (FileSystem.isFile(fixturePath)) {
    destFixturePath = FileSystem.getCombinedPath(destPath, programName + "_FIXTURE.stl");
    FileSystem.copyFile(fixturePath, destFixturePath);
  }
}

function getVericutPath() {
  var exePath = "";
  var vericutVersion = ["9.2", "9.1.2", "9.1", "9.0", "8.1.1", "8.0"];
  for (var version in vericutVersion) {
    try {
      if (hasRegistryValue("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\CGTech VERICUT " + vericutVersion[version] + "\\", "InstallLocation")) {
        vericutPath = getRegistryString("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\CGTech VERICUT " + vericutVersion[version] + "\\", "InstallLocation");
        //exePath = FileSystem.getCombinedPath(vericutPath, "\\windows64\\commands\\vericut.bat");
        if (FileSystem.isFolder(vericutPath)) {
          return vericutPath;
        }
      }
    } catch (e) {
      // ignore
    }
  }
  return exePath;
}

function onTerminate() {
  var exePath = FileSystem.getCombinedPath(vericutPath, "\\windows64\\commands\\vericut.bat");
  if (!FileSystem.isFile(exePath)) {
    error(localize("VERICUT was not found on your machine. Be sure to specify a valid VERICUT installation folder."));
    return;
  }

  var vericutOpsPath = "\"" + "ops=" + FileSystem.replaceExtension(getCascadingPath(), "ops") + "\"";
  execute(exePath, vericutOpsPath, false, "");
}

function setProperty(property, value) {
  properties[property].current = value;
}
