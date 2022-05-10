/**
  Copyright (C) 2012-2020 by Autodesk, Inc.
  All rights reserved.

  NCSIMUL post processor configuration.

  $Revision: 42894 dd9c43a7c32e5cef37cde1beb3ef0e8d1799b6a3 $
  $Date: 2020-08-12 13:56:16 $
  
  FORKID {231621F3-F6FF-484F-B1F5-E35DD7220AB8}
*/

description = "NCSIMUL";
vendor = "Hexagon - NCSIMUL";
vendorUrl = "https://www.ncsimul.com";
legal = "Copyright (C) 2012-2020 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 41761;
capabilities = CAPABILITY_INTERMEDIATE | CAPABILITY_CASCADING;

longDescription = "Post integration with NCSIMUL. This is a cascading post to use for automatic simulation of generated NC programs in NCSIMUL.";

dependencies = "nc-simul.hta";

var action = "";
var user = ""; // specifies the user account for NCSIMUL
var machineName = ""; // Insert the exact name of the machine from NCSIMUL
var machinePath = "";
var tapesPath = "";
var exportToolLib = true;
var disableRadiusCompensation = false;

this.exportStock = true;
this.exportPart = true;
this.exportFixture = true;

var destPath = FileSystem.getFolderPath(getCascadingPath());
var projectPath;
var NXFfile;
var nxfFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var nxfAngleFormat = createFormat({decimals:(unit == MM ? 3 : 4), scale:DEG});

function onSection() {
  skipRemainingSection();
}

function createNXF() {
  NXFfile.writeln("BEGIN_PARAMETERS");
  NXFfile.writeln("  |SOFTWARE|" + getGlobalParameter("product-id").toUpperCase() + "|");
  NXFfile.writeln("  |VERSION|" + getVersion() + "|");
  NXFfile.writeln("  |RELEASE|" + " " + "|");
  NXFfile.writeln("  |DATE|" + writeDate() + "|");
  NXFfile.writeln("END");

  var operationType = [];
  var ncFrame = new Array();
  var numberOfSections = getNumberOfSections();
  for (var i = 0; i < numberOfSections; ++i) {
    var found = false;
    var section = getSection(i);
    operationType[i] = section.getType() == TYPE_TURNING ? "TURNING" : "MILLING";
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

  NXFfile.writeln("BEGIN_NCSIMUL_SETTING");
  NXFfile.writeln(" |USER|" + user + "|");
  NXFfile.writeln("END");
  
  var machiningType;
  if ((operationType.indexOf("TURNING") > -1) && (operationType.indexOf("MILLING") == -1)) {
    machiningType = "TURNING";
  } else if ((operationType.indexOf("MILLING") > -1) && (operationType.indexOf("TURNING") == -1)) {
    machiningType = "MILLING";
  } else if ((operationType.indexOf("MILLING") > -1) && (operationType.indexOf("TURNING") > -1)) {
    machiningType = "MILLTURN";
  } else {
    error(localize("Machining type not supported."));
    return;
  }

  NXFfile.writeln("BEGIN_MACHINE");
  NXFfile.writeln("  |MACHINE|" + machiningType + "|" + machineName + "|");
  NXFfile.writeln("  |CHANNEL_NUMBER|" + " " + "|" + " " + "|");
  NXFfile.writeln("  |POST-PROCESSOR|" + " " + "|" + getCascadingPath() + "| |");
  // NXFfile.writeln("  |SUB-PRG|" + " " + "|");
  NXFfile.writeln("  |MACHINE-ELEMENT|" + " " + "|" + " " + "|" + " " + "|" + " " + "|");
  NXFfile.writeln("END");

  var workpiece = getWorkpiece();
  var delta = Vector.diff(workpiece.upper, workpiece.lower);

  if (hasGlobalParameter("autodeskcam:fixture-path")) {
    var x = nxfFormat.format(getSection(0).getFCSOrigin().x);
    var y = nxfFormat.format(getSection(0).getFCSOrigin().y);
    var z = nxfFormat.format(getSection(0).getFCSOrigin().z);
  } else {
    var x = nxfFormat.format(delta.x / 2 - workpiece.upper.x) * -1;
    var y = nxfFormat.format(delta.y / 2 - workpiece.upper.y) * -1;
    var z = nxfFormat.format(workpiece.lower.z);
  }
  NXFfile.writeln("BEGIN_NCFRAME");
  // NXFfile.writeln("   |ALL_FRAME|" + "0.0,0.0,-500,1.0,0.0,0.0,0.0,1.0,0.0" + "|");
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

    // note that NC FRAME has to be in MM always
    if (workOffset > 0) {
      var frame;
      if (workOffset > 6) {
        var code = workOffset - 6;
        frame = "  |FRAME|" + "G54.1 P" + (code) + "|";
      } else {
        frame = "  |FRAME|" + "G" + (53 + workOffset) + "|";
      }
      NXFfile.writeln(
        frame +
        nxfFormat.format((unit == IN ? (x * 25.4) : x) * (x < 0 ? -1 : 1)) + "," +
        nxfFormat.format((unit == IN ? (y * 25.4) : y) * (y < 0 ? -1 : 1)) + "," +
        nxfFormat.format((unit == IN ? (z * 25.4) : z) * (z < 0 ? -1 : 1)) +
        ",1.0,0.0,0.0,0.0,1.0,0.0" + "|"
      );
    }
  }

  NXFfile.writeln("END");
  
  var vxx = nxfFormat.format(getSection(0).getFCSPlane().getRight().x);
  var vxy = nxfFormat.format(getSection(0).getFCSPlane().getRight().y);
  var vxz = nxfFormat.format(getSection(0).getFCSPlane().getRight().z);
  var vyx = nxfFormat.format(getSection(0).getFCSPlane().getUp().x);
  var vyy = nxfFormat.format(getSection(0).getFCSPlane().getUp().y);
  var vyz = nxfFormat.format(getSection(0).getFCSPlane().getUp().z);

  if (hasGlobalParameter("autodeskcam:part-path")) {
    NXFfile.writeln("BEGIN_MODEL");
    NXFfile.writeln("  |ELEMENT_NAME|" + programName + "_PART" + "|");
    NXFfile.writeln("  |UNITS|" + ((unit == IN) ? "INCH" : "MM") + "|");
    // NXFfile.writeln("  |MATRICE_OXY|" + x + "," + y + "," + z + ",1.0,0.0,0.0,0.0,1.0,0.0" + "|");
    NXFfile.writeln("  |MATRICE_OXY|" + x + "," + y + "," + z + "," + vxx + "," + vxy + "," + vxz + "," + vyx + "," + vyy + "," + vyz + "|");
    NXFfile.writeln("  |PART|" + "STL|" + programName + "_PART.stl|" + " |");
    NXFfile.writeln("END");
  }

  if (hasGlobalParameter("autodeskcam:stock-path")) {
    NXFfile.writeln("BEGIN_MODEL");
    NXFfile.writeln("  |ELEMENT_NAME|" + programName + "_STOCK" + "|");
    NXFfile.writeln("  |UNITS|" + ((unit == IN) ? "INCH" : "MM") + "|");
    // NXFfile.writeln("  |MATRICE_OXY|" +  x + "," + y + "," + z + ",1.0,0.0,0.0,0.0,1.0,0.0" + "|");
    NXFfile.writeln("  |MATRICE_OXY|" + x + "," + y + "," + z + "," + vxx + "," + vxy + "," + vxz + "," + vyx + "," + vyy + "," + vyz + "|");
    NXFfile.writeln("  |STOCK|" + "STL|" + programName + "_STOCK.stl|" + " |");
    NXFfile.writeln("END");
  }

  if (hasGlobalParameter("autodeskcam:fixture-path")) {
    NXFfile.writeln("BEGIN_MODEL");
    NXFfile.writeln("  |ELEMENT_NAME|" + programName + "_FIXTURE" + "|");
    NXFfile.writeln("  |UNITS|" + ((unit == IN) ? "INCH" : "MM") + "|");
    // NXFfile.writeln("  |MATRICE_OXY|" +  x + "," + y + "," + z + ",1.0,0.0,0.0,0.0,1.0,0.0" + "|");
    NXFfile.writeln("  |MATRICE_OXY|" + x + "," + y + "," + z + "," + vxx + "," + vxy + "," + vxz + "," + vyx + "," + vyy + "," + vyz + "|");
    NXFfile.writeln("  |CLAMP|" + "STL|" + programName + "_FIXTURE.stl|" + " |");
    NXFfile.writeln("END");
  }

  // Tool library export
  if (exportToolLib == "true") {
    toolDatabase();
  }
  
  NXFfile.close();
}

function toolDatabase() {
  var tools = getToolTable();
  if (tools.getNumberOfTools() > 0) {
    for (var i = 0; i < tools.getNumberOfTools(); ++i) {
      var tool = tools.getTool(i);
      var holder = tool.holder;

      NXFfile.writeln("BEGIN_TOOL");
      NXFfile.writeln("  |TOOL|" + nxfFormat.format(5) + "|" + (tool.description ? tool.description : getToolTypeName(tool.type)) + "|" + " " + "|" + tool.number + "|");
      NXFfile.writeln("  |MATRICE_OXY|" + "0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0,0.0" + "|"); // Matrix definition for the element position on the machine table.
      NXFfile.writeln("  |UNITS|" + ((unit == IN) ? "INCH" : "MM") + "|");
      NXFfile.writeln("  |GAUGE|" + nxfFormat.format(tool.bodyLength + tool.holderLength) + "|"); // Length under spindle.
      NXFfile.writeln("  |PARAMETER|" + nxfFormat.format(tool.diameter) + "|" + nxfFormat.format(tool.bodyLength) + "|");
      NXFfile.writeln("  BEGIN_PROFILE");
      
      if (revision < 41761) {
        var cutter = tool.getCutterProfileAsSVGPath();
        cutter = cutter.slice(0, ((cutter.length / 2) + 1));
        var cutterProfile = new Array();
        for (var j = 0; j < cutter.length; ++j) {
          var letterIndex = cutter.search(/[A-Z]/);
          var letter = cutter.charAt(letterIndex);
          cutter = cutter.substr(letterIndex + 1);
          letterIndex = cutter.search(/[A-Z]/);
          var _coordinates = cutter.slice(0, letterIndex - 1);
          cutterProfile.push({
            letter: letter,
            coordinates: _coordinates.split(" ")
          });
        }
        for (var k = 1; k < cutterProfile.length; ++k) {
          var cut = "|CUT|";
          var startX = parseFloat(cutterProfile[k - 1].coordinates[0]);
          var startY = parseFloat(cutterProfile[k - 1].coordinates[1]);
          switch (cutterProfile[k].letter) {
          case "M":
          case "L":
            var type = "    |LINE";
            var endX = parseFloat(cutterProfile[k].coordinates[0]);
            var endY = parseFloat(cutterProfile[k].coordinates[1]);
            if (endY > tool.fluteLength) {
              cut = "|NOCUT|";
            }
            NXFfile.writeln(type + cut + nxfFormat.format(startX) + "," + nxfFormat.format(startY) + "," + nxfFormat.format(endX) + "," + nxfFormat.format(endY) + "|");
            break;
          case "A":
            var type = "    |ARC";
            var endX = parseFloat(cutterProfile[k].coordinates[5]);
            var endY = parseFloat(cutterProfile[k].coordinates[6]);
            var radius = parseFloat(cutterProfile[k].coordinates[0]);
            var arcDir = parseFloat(cutterProfile[k].coordinates[4]);
            if (endY > tool.fluteLength) {
              cut = "|NOCUT|";
            }
            if (arcDir == 1) {
              if (startX < endX) {
                var centerX = startX;
                var centerY = startY + radius;
              } else {
                var centerX = startX - radius;
                var centerY = startY;
              }
            } else {
              if (startY < endY) {
                var centerX = startX + radius;
                var centerY = startY;
              } else {
                var centerX = startX;
                var centerY = startY - radius;
              }
            }
            NXFfile.writeln(type + cut + nxfFormat.format(startX) + "," + nxfFormat.format(startY) + "," + nxfFormat.format(endX) + "," + nxfFormat.format(endY) + "," + nxfFormat.format(centerX) + "," + nxfFormat.format(centerY) + "|" + (arcDir == 1 ? "CCW" : "CW") + "|");
            break;
          }
        }
      } else {
        var cutter = tool.getCutterProfile();
        for (var k = 0; k < cutter.getNumberOfEntities() / 2; ++k) {
          var arc = ((cutter.getEntity(k).clockwise == true) || cutter.getEntity(k).center.length > 1e-4);
          var cut = "|CUT|";
          var type = arc ? "    |ARC" : "    |LINE";
          var startX = cutter.getEntity(k).start.x;
          var startY = cutter.getEntity(k).start.y;
          var endX = cutter.getEntity(k).end.x;
          var endY = cutter.getEntity(k).end.y;
          var centerX = cutter.getEntity(k).center.x;
          var centerY = cutter.getEntity(k).center.y;
          var arcDir = cutter.getEntity(k).clockwise ? "CW" : "CCW";

          if (endY > tool.fluteLength) { // split a single arc segment if the fluteLength is smaller than the endY position
            if (arc) {
              var radius = Vector.diff(cutter.getEntity(k).start, cutter.getEntity(k).center).length;
              var p = cutter.getEntity(k).clockwise ? (radius - tool.fluteLength) : tool.fluteLength;
              var q = (2 * Math.sqrt(p * ((radius * 2) - p))) / 2;
              if (cutter.getEntity(k).clockwise) {
                q = startX + radius - q;
              } else {
                q = startX + q;
              }
              NXFfile.writeln(type + cut + nxfFormat.format(startX) + "," + nxfFormat.format(startY) + "," + nxfFormat.format(q) + "," + nxfFormat.format(tool.fluteLength) + conditional(arc, "," + nxfFormat.format(centerX) + "," + nxfFormat.format(centerY) + "|" + arcDir) + "|");
              cut = "|NOCUT|";
              startX = q;
              startY = tool.fluteLength;
            } else { // split a single line segment for eg drills, chamfer tools
              if (k == 0) {
                endX = tool.fluteLength * (Math.tan(tool.taperAngle / 2));
                endY = tool.fluteLength;
                NXFfile.writeln(type + cut + nxfFormat.format(startX) + "," + nxfFormat.format(startY) + "," + nxfFormat.format(endX) + "," + nxfFormat.format(endY) + conditional(arc, "," + nxfFormat.format(centerX) + "," + nxfFormat.format(centerY) + "|" + arcDir) + "|");
                startY = endY;
                startX = endX;
              }
              cut = "|NOCUT|";
            }
          }
          NXFfile.writeln(type + cut + nxfFormat.format(startX) + "," + nxfFormat.format(startY) + "," + nxfFormat.format(endX) + "," + nxfFormat.format(endY) + conditional(arc, "," + nxfFormat.format(centerX) + "," + nxfFormat.format(centerY) + "|" + arcDir) + "|");
        }
      }
      NXFfile.writeln("  END");
      NXFfile.writeln("  |CUTTING_PARAMETER|" + nxfFormat.format(tool.numberOfFlutes) + "|" + " " + "|" + " " + "|");
      NXFfile.writeln("  |LENGTH_COMPENSATION|" + "TOOL_TIP" + "|");
      NXFfile.writeln("  |RADIUS_COMPENSATION|" + (disableRadiusCompensation ? "0" : "RADIUS") + "|");

      if (holder) {
        var hCurrent = 0;
        if (holder && holder.hasSections()) {
          var n = holder.getNumberOfSections();
          for (var j = 0; j < n; ++j) {
            if (j == 0) {
              NXFfile.writeln("  BEGIN_TOOLHOLDERS");
              NXFfile.writeln("    |VECTOR|0.0,0.0," + nxfFormat.format(tool.bodyLength) + "|");
              NXFfile.writeln("    BEGIN_PROFILE");
              NXFfile.writeln("      |LINE|NOCUT|" + "0,0," + nxfFormat.format(holder.getDiameter(j) / 2) + "," + nxfFormat.format(holder.getLength(j)) + "|");
            } else {
              hCurrent += holder.getLength(j - 1);
              NXFfile.writeln("      |LINE|NOCUT|" + nxfFormat.format(holder.getDiameter(j - 1) / 2) + "," + nxfFormat.format(hCurrent) + "," + nxfFormat.format(holder.getDiameter(j) / 2) + "," + nxfFormat.format(holder.getLength(j) + hCurrent) + "|");
            }
          }
          NXFfile.writeln("    END");
          NXFfile.writeln("  END");
        }
      }
      NXFfile.writeln("END");
    }
  }
}

function writeDate() {
  var months = new Array("JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC");
  var timeFormat = createFormat({decimals:0, width:2, zeropad:true});
  var now = new Date();
  var nowDay = now.getDate();
  var nowMonth = now.getMonth();
  var nowHour = now.getHours();
  var nowMin = now.getMinutes();
  var sDate =  timeFormat.format(nowDay) + "." + months[nowMonth] + "." + now.getFullYear();
  var sTime = timeFormat.format(nowHour) + ":" + timeFormat.format(nowMin);
  return sDate + " - " + sTime;
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

  if (!FileSystem.isFolder(destFolderPath)) {
    error(subst(localize("NC verification job folder '%1' does not exist."), destFolderPath));
    return;
  }

  if (!programName) {
    error(localize("Program name is not specified."));
    return;
  }

  if (FileSystem.isFile(stockPath)) {
    destStockPath = FileSystem.getCombinedPath(destFolderPath, programName + "_STOCK.stl");
    FileSystem.copyFile(stockPath, destStockPath);
  }

  if (FileSystem.isFile(partPath)) {
    destPartPath = FileSystem.getCombinedPath(destFolderPath, programName + "_PART.stl");
    FileSystem.copyFile(partPath, destPartPath);
  }

  if (FileSystem.isFile(fixturePath)) {
    destFixturePath = FileSystem.getCombinedPath(destFolderPath, programName + "_FIXTURE.stl");
    FileSystem.copyFile(fixturePath, destFixturePath);
  }
}

function showDialog(ncSimulVersion) {
  if (!FileSystem.isFolder(FileSystem.getTemporaryFolder())) {
    FileSystem.makeFolder(FileSystem.getTemporaryFolder());
  }
  var path = FileSystem.getTemporaryFile("post");
  execute(findFile("nc-simul.hta"), "\"" + path + "\"" + "\"" + ncSimulVersion + "\"", false, "");
  
  // if result of dialog is different than OK, cancel the process
  try {
    var file = new TextFile(path, false, "utf-8");
    if (file.readln() == "OK") {
      file.close();
    }
  } catch (e) {
    error("Aborted by user.");
  }
  FileSystem.remove(path);

  var result = {};
  try {
    var file = new TextFile(FileSystem.getTemporaryFolder() + "\\ncsimul.txt", false, "utf-8");
    while (true) {
      var line = file.readln();
      var index = line.indexOf(":");
      if (index >= 0) {
        var name = line.substr(0, index);
        var value = line.substr(index + 1);
        result[name] = value;
      }
    }
  } catch (e) {
    file.close();
  }

  var gotValues = false;
  for (var name in result) {
    gotValues = true;
    break;
  }
  if (!gotValues) {
    error(localize("Aborted by user."));
    return false;
  }

  for (var name in result) {
    var value = result[name];
    switch (name) {
    case "action":
      action = value;
      break;
    case "user":
      user = value;
      break;
    case "machine":
      machineName = value;
      break;
    case "machinePath":
      machinePath = value;
      break;
    case "tapesPath":
      tapesPath = value;
      break;
    case "exportToolLib":
      exportToolLib = value;
      break;
    case "disableRadiusCompensation":
      disableRadiusCompensation = value;
      break;
    }
  }
  return true;
}

function onOpen() {

}

function onTerminate() {

  var exePath;
  var ncSimulVersion;
  try {
    if (hasRegistryValue("HKEY_LOCAL_MACHINE\\SOFTWARE\\Hexagon\\NCSIMUL Interfaces\\", "Path")) { // V11
      exePath = FileSystem.getCombinedPath(getRegistryString("HKEY_LOCAL_MACHINE\\SOFTWARE\\Hexagon\\NCSIMUL Interfaces\\", "Path"), "\\Connector_AutoDesk\\ConnectorFromNXF.exe");
      ncSimulVersion = 11;
    } else if (hasRegistryValue("HKEY_LOCAL_MACHINE\\SOFTWARE\\Spring Technologies\\NCSIMUL SOLUTIONS Interfaces\\", "Path")) { // V10
      exePath = FileSystem.getCombinedPath(getRegistryString("HKEY_LOCAL_MACHINE\\SOFTWARE\\Spring Technologies\\NCSIMUL SOLUTIONS Interfaces\\", "Path"), "\\Connector_AutoDesk\\ConnectorFromNXF.exe");
      ncSimulVersion = 10;
    } else {
      error(localize("No supported version of the NCSIMUL Interface was found on your machine."));
      return;
    }
  } catch (e) {
    if (!FileSystem.isFile(exePath)) {
      error(localize("NCSIMUL Interface was not found on your machine."));
      return;
    }
  }
  
  if (!FileSystem.isFile(exePath)) {
    error(localize("The interface path " + exePath + " is not valid or does not exist. Please make sure that the NCSimul Interface is installed on your system."));
    return;
  }

  showDialog(ncSimulVersion);

  if (action == "create") {
    FileSystem.makeFolder(FileSystem.getCombinedPath(FileSystem.getFolderPath(getCascadingPath()), programName));
    destFolderPath = FileSystem.getCombinedPath(destPath, programName);
    destPath = FileSystem.getCombinedPath(destFolderPath, (programName ? programName + ".nxf" : "export.nxf")); // file
    NXFfile = new TextFile(destPath, true, "utf-8");
    createVerificationJob();
    createNXF();
    execute(exePath, "\"" + destPath + "\"", false, "");
  } else if (action == "update") { // update nc program of an existing project
    var destination = FileSystem.getCombinedPath(FileSystem.getFolderPath(tapesPath), FileSystem.getFilename(getCascadingPath()));
    FileSystem.copyFile(getCascadingPath(), destination);
  }
}
