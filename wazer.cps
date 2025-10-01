/**
  Copyright (C) 2012-2025 by Autodesk, Inc.
  All rights reserved.

  Wazer Waterjet post processor configuration.

  $Revision: 
  $Date: 2025-09-30 13:23:15 $

  FORKID {}
*/

/*
debugMode = true;
setWriteInvocations(true);
setWriteStack(true);
*/

description = "Wazer Waterjet";
vendor = "Wazer";
vendorUrl = "http://www.wazer.com";
legal = "Copyright (C) 2012-2025 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45702;

longDescription = "Generic post for Wazer waterjet.";

extension = "gcode";
setCodePage("ascii");

capabilities = CAPABILITY_JET;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = false;
allowedCircularPlanes = 0; // no arcs


// user-defined properties
properties = {
  writeMachine: {
    title      : "Write machine",
    description: "Output the machine settings in the header of the code.",
    group      : "formats",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  showSequenceNumbers: {
    title      : "Use sequence numbers",
    description: "Use sequence numbers for each block of outputted code.",
    group      : "formats",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  sequenceNumberStart: {
    title      : "Start sequence number",
    description: "The number at which to start the sequence numbers.",
    group      : "formats",
    type       : "integer",
    value      : 10,
    scope      : "post"
  },
  sequenceNumberIncrement: {
    title      : "Sequence number increment",
    description: "The amount by which the sequence number is incremented by in each block.",
    group      : "formats",
    type       : "integer",
    value      : 5,
    scope      : "post"
  },
  separateWordsWithSpace: {
    title      : "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    group      : "formats",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  softwareVersion: {
    title      : "Software Version",
    description: "Specifies the WAM software version.",
    group      : "preferences",
    type       : "number",
    value      : 1.3,
    scope      : "post"
  },
  material: {
    title      : "Material",
    description: "Specifies the material to make use of the feed/speed database. Choose -Custom- to use Pierce time and Feedrate Properties.",
    group      : "preferences",
    type       : "enum",
    values     : [
      {title:"Stainless Steel - 316",   id:"StainlessSteel316"},
      {title:"Stainless Steel - 440C",  id:"StainlessSteel440C"},
      {title:"Stainless Steel - 304",   id:"StainlessSteel304"},
      {title:"Steel - 1008",            id:"Steel1008"},
      {title:"Steel - 1018",            id:"Steel1018"},
      {title:"Steel - 4130",            id:"Steel4130"},
      {title:"Steel - O1",              id:"SteelO1"},
      {title:"Aluminum - 6061",         id:"Aluminum6061"},
      {title:"Aluminum - 7075",         id:"Aluminum7075"},
      {title:"Copper - 110",            id:"Copper110"},
      {title:"Titanium - Grade 5",      id:"TitaniumG5"},
      {title:"HDPE Plastic",            id:"HDPEPlastic"},
      {title:"Polyurathane - 60A",      id:"Polyurathane60"},
      {title:"Polycarbonate",           id:"Polycarbonate"},
      {title:"Acrylic",                 id:"Acrylic"},
      {title:"Silicone - 50A",          id:"Silicone50A"},
      {title:"Neoprene - 50A",          id:"Neoprene50A"},
      {title:"Glass - Soda Lime",       id:"GlassSodaLime"},
      {title:"Glass - Borosilicate",    id:"GlassBorosilicate"},
      {title:"Tile - Ceramic/Porcelain",id:"Tile"},
      {title:"Carbon Fiber",            id:"CarbonFiber"},
      {title:"Garolite - G-10/FR4",     id:"GaroliteG10FR4"},
      {title:"Brass",                   id:"Brass"},
      {title:"Custom",                  id:"custom"}
      // other possible options: stained glass, agate, gabbro, fused glass, granite, marble, memory foam
    ],
    value: "StainlessSteel316",
    scope: "post"
  },
  pierceTime: {
    title      : "Pierce time",
    description: "Specifies the pierce time if material type -Custom- is selected.",
    group      : "preferences",
    type       : "number",
    value      : 0,
    scope      : "post"
  },
  useFeeds: {
    title      : "Feedrate",
    description: "Specifies the feedrate if material type -Custom- is selected.",
    group      : "preferences",
    type       : "number",
    value      : 0,
    scope      : "post"
  },
  maximumLineLength: {
    title: "Maximum segment length for linear moves (mm)",
    description: "Specifies the maximum segment length to be used in linear cuts.",
    group      : "preferences",
    type: "number",
    //value: unit == MM ? 5 : 0.1968504 // FIXME not sure how to implement this so the user can choose in vs mm
    value: 5
  },
  minimumLineLengthForAngleMeasurement: {
    title: "Minimum segment length for corner compensation (mm)",
    description: "Specifies the minimum aggregate segment length to be used for computing angles of corner.",
    group      : "preferences",
    type: "number",
    //value: unit == MM ? 0.4 : 0.01574803 // FIXME not sure how to implement this so the user can choose in vs mm
    value: 0.4
  },
  IgnoreMaxThickness: {
    title      : "Ignore Max thickness",
    description: "Override failure",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  }
};


// max segment length based on WAM algo setting of 5mm
var maximumLineLength = toPreciseUnit(properties.maximumLineLength.value, MM); 
// min aggregate segments length to compute angles off of. 
// fusion will make some smaller segments 0.08 vs 0.2 and we want to be able to adjust for shorter corner segments 
// by computing corner angles of multiple segments that are at least minimumLineLengthForAngleMeasurement long
var minimumLineLengthForAngleMeasurement = toPreciseUnit(properties.minimumLineLengthForAngleMeasurement.value, MM); 


// TODO verify maxThicknessInMm for each of these materials
// formulas derived from data points found in https://wazer-pre-production-backend-a71598b05b9d.herokuapp.com/api/getMaterials?machineType=desktop
const materialFormulas = { 
  Sample: {
    pierceTimeFormula: "",            // Formula to compute the necessary pierce time for a given material thickness
    feedRate: {Fine: "", Rough: ""},  // Formulas to compute feedrates for a given material thickness at a given cut quality (FINE/ROUGH)
    maxThicknessInMm: 0,              // MAX material thickness for a given material
    minPierceTime: 0,                 // MIN pierce time for a given marital
    maxFeedRateInMMPM: {Fine: 1050, Rough: 1350} // MAX feedrate in mm/m for a given material at a given cut quality (optional)
  },
  Acrylic: {
    pierceTimeFormula: "0.6 * Math.pow(thicknessInMm - 0.3, 2) + 2.16",
    feedRate: {Fine: "391 * Math.pow(thicknessInMm, -1.34) + 2.2", Rough: "511 * Math.pow(thicknessInMm, -1.34) + 0.9"},
    maxThicknessInMm: 15.875,
    minPierceTime: 2.16
  },
  StainlessSteel316: {
    pierceTimeFormula: "6 * Math.pow(thicknessInMm - 0.5, 2) + 4.32",
    feedRate: {Fine: "30 * Math.pow(thicknessInMm, -0.7) + 0.1", Rough: "38 * Math.pow(thicknessInMm, -0.7) + 0.1"},
    maxThicknessInMm: 4.7752,
    minPierceTime: 4.32
  },
  Aluminum7075: {
    pierceTimeFormula: "2 * Math.pow(thicknessInMm, 2)",
    feedRate: {Fine: "90 * Math.pow(thicknessInMm, -0.75) + 0.1", Rough: "115 * Math.pow(thicknessInMm, -0.75) + 0.5"},
    maxThicknessInMm: 12.7,
    minPierceTime: 2.16
  },
  Aluminum6061: {
    pierceTimeFormula: "2.2 * Math.pow(thicknessInMm, 1.96) + 1.08",
    feedRate: {Fine: "89 * Math.pow(thicknessInMm, -0.88) + 0.3", Rough: "115 * Math.pow(thicknessInMm, -0.88) + 0.2"},
    maxThicknessInMm: 12.7,
    minPierceTime: 2.16
  },
  CarbonFiber: {
    pierceTimeFormula: "3.2 * Math.pow(thicknessInMm, 2.05) + 2.16",
    feedRate: {Fine: "81 * Math.pow(thicknessInMm, -1.1) + 2.6", Rough: "105 * Math.pow(thicknessInMm, -1.1) + 2.6"},
    maxThicknessInMm: 7.9502,
    minPierceTime: 2.16
  },
  Copper110: {
    pierceTimeFormula: "6 * Math.pow(thicknessInMm - 0.1, 2)",
    feedRate: {Fine: "31 * Math.pow(thicknessInMm, -0.8) + 0.5", Rough: "40 * Math.pow(thicknessInMm, -0.8) + 0.5"},
    maxThicknessInMm: 4.7752,
    minPierceTime: 2.16
  },
  GaroliteG10FR4: {
    pierceTimeFormula: "0.7 * Math.pow(thicknessInMm - 1.4, 1.96) + 0.9",
    feedRate: {Fine: "630 * Math.pow(thicknessInMm, -0.95) - 40", Rough: "760 * Math.pow(thicknessInMm, -0.95) - 40"},
    maxThicknessInMm: 6.35, // largest point in json
    minPierceTime: 0.87
  },
  GlassBorosilicate: { // fine and rough formulas could probably be improved for GlassBorosilicate
    pierceTimeFormula: "0.5 * Math.pow(thicknessInMm - 3, 1.96) + 3.24",
    feedRate: {Fine: "3400 * Math.pow(thicknessInMm, -2.44) + 1", Rough: "4800 * Math.pow(thicknessInMm, -2.44) + 1"},
    maxThicknessInMm: 19.05,
    minPierceTime: 3.24
  },
  GlassSodaLime: {
    pierceTimeFormula: "0.5 * Math.pow(thicknessInMm - 1.8, 1.96) + 2.16",
    feedRate: {Fine: "870 * Math.pow(thicknessInMm, -1.5) + 1", Rough: "1150 * Math.pow(thicknessInMm, -1.5) + 1"},
    maxThicknessInMm: 19.05,
    minPierceTime: 2.16
  },
  HDPEPlastic: {
    pierceTimeFormula: "0.5 * Math.pow(thicknessInMm - 1.8, 1.96) + 2.16",
    feedRate: {Fine: "290 * Math.pow(thicknessInMm, -1.2) + 2.2", Rough: "375 * Math.pow(thicknessInMm, -1.19) + 1.6"},
    maxThicknessInMm: 19.05,
    minPierceTime: 2.16
  },
  Neoprene50A: {
    pierceTimeFormula: "0.4 * Math.pow(thicknessInMm - 0.4, 1.96) + 1.08",
    feedRate: {Fine: "10800 * Math.pow(thicknessInMm, -2.42) - 5", Rough: "13800 * Math.pow(thicknessInMm, -2.42) + 5"},
    maxThicknessInMm: 15.875,
    minPierceTime: 1.08,
    maxFeedRateInMMPM: {Fine: 1050, Rough: 1350}
  },
  Polycarbonate: {
    pierceTimeFormula: "2 * Math.pow(thicknessInMm - 1, 2) + 2.16",
    feedRate: {Fine: "220 * Math.pow(thicknessInMm, -1.2) + 2.2", Rough: "320 * Math.pow(thicknessInMm, -1.2) + 2.2"},
    maxThicknessInMm: 12.7,
    minPierceTime: 1.08
  },
  Polyurathane60: {
    pierceTimeFormula: "0.66 * Math.pow(thicknessInMm + 1, 2)",
    feedRate: {Fine: "44500 * Math.pow(thicknessInMm, -3.6) + 0.1", Rough: "60500 * Math.pow(thicknessInMm, -3.6) + 1"},
    maxThicknessInMm: 12.7,
    minPierceTime: 2.16,
    maxFeedRateInMMPM: {Fine: 1050, Rough: 1350}
  },
  Silicone50A: {
    pierceTimeFormula: "0.31 * Math.pow(thicknessInMm - 1.1, 1.96) + 2.16",
    feedRate: {Fine: "158000 * Math.pow(thicknessInMm, -3.2) + 1", Rough: "200000 * Math.pow(thicknessInMm, -3.2) + 1"},
    maxThicknessInMm: 19.05,
    minPierceTime: 2.16,
    maxFeedRateInMMPM: {Fine: 1050, Rough: 1350}
  },
  StainlessSteel304: {
    pierceTimeFormula: "4.7 * Math.pow(thicknessInMm - 0.2, 2) + 1.08",
    feedRate: {Fine: "31 * Math.pow(thicknessInMm, -0.74) + 1", Rough: "40 * Math.pow(thicknessInMm, -0.74) + 1"},
    maxThicknessInMm: 4.7752,
    minPierceTime: 2.16
  },
  Steel1008: {
    pierceTimeFormula: "5.4 * Math.pow(thicknessInMm - 0.5, 1.96) + 3",
    feedRate: {Fine: "35 * Math.pow(thicknessInMm, -0.66) + 1", Rough: "45 * Math.pow(thicknessInMm, -0.66) + 1"},
    maxThicknessInMm: 3.175,
    minPierceTime: 2.16
  },
  Steel1018: {
    pierceTimeFormula: "6 * Math.pow(thicknessInMm - 0.5, 1.96) + 3",
    feedRate: {Fine: "32 * Math.pow(thicknessInMm, -0.8) - 1", Rough: "46 * Math.pow(thicknessInMm, -0.7) - 2"},
    maxThicknessInMm: 6.35, // from json, but this is thicker than machine is spec'd for (MAX: 0.188 in / 4.7752 mm)
    minPierceTime: 2.16
  },
  Steel4130: {
    pierceTimeFormula: "6.4 * Math.pow(thicknessInMm - 0.5, 1.96) + 3.4",
    feedRate: {Fine: "32.5 * Math.pow(thicknessInMm, -0.63) - 2", Rough: "41 * Math.pow(thicknessInMm, -0.63) - 2"},
    maxThicknessInMm: 3.175,
    minPierceTime: 3.24
  },
  SteelO1: {
    pierceTimeFormula: "8 * Math.pow(thicknessInMm - 0.5, 1.96) + 3.4",
    feedRate: {Fine: "29 * Math.pow(thicknessInMm, -0.77) - 1", Rough: "37 * Math.pow(thicknessInMm, -0.74) - 1"},
    maxThicknessInMm: 3.7,
    minPierceTime: 3.24
  },
  TitaniumG5: {
    pierceTimeFormula: "5.3 * Math.pow(thicknessInMm - 0.4, 1.96) + 2.4",
    feedRate: {Fine: "36 * Math.pow(thicknessInMm, -0.87) + 1", Rough: "47 * Math.pow(thicknessInMm, -0.87) + 1"},
    maxThicknessInMm: 4.7752,
    minPierceTime: 2.16
  },
  StainlessSteel440C: { // json only has two data point so used other SS plots to maintain a similar curve, shifted slightly
    pierceTimeFormula: "9.5 * Math.pow(thicknessInMm - 0.5, 1.96) + 4.32",
    feedRate: {Fine: "27 * Math.pow(thicknessInMm, -0.71) + 0.01", Rough: "34 * Math.pow(thicknessInMm, -0.7) + 0.1"},
    maxThicknessInMm: 4.7752,
    minPierceTime: 4.32
  },
  Tile: { // pulled rough cut quality and pierce time from entering 1mm increments into https://wazer.com/materials/materials-specs/#materials-table
    pierceTimeFormula: "1.2 * Math.pow(thicknessInMm - 4, 1.96) + 2",
    feedRate: {Fine: "160 * Math.pow(thicknessInMm, -0.77)", Rough: "190 * Math.pow(thicknessInMm, -0.77)"},
    maxThicknessInMm: 12.7,
    minPierceTime: 4.32
  },
  Brass: { // pulled rough cut quality and pierce time from entering 1mm increments into https://wazer.com/materials/materials-specs/#materials-table
    pierceTimeFormula: "3.1 * Math.pow(thicknessInMm, 1.96) + 4",
    feedRate: {Fine: "35 * Math.pow(thicknessInMm, -0.77) + 0.5", Rough: "50 * Math.pow(thicknessInMm, -0.77) + 0.5"},
    maxThicknessInMm: 6.35,
    minPierceTime: 2.16
  },
}

var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"M", decimals:0});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 3), forceDecimal:true, trim:false});
var abcFormat = createFormat({decimals:3, forceDecimal:true, scale:DEG});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-1000
var feedFormat = createFormat({decimals:(unit == MM ? 3 : 3), forceDecimal:true, trim:false});

var xOutput = createVariable({prefix:"X", force:true}, xyzFormat);
var yOutput = createVariable({prefix:"Y", force:true}, xyzFormat);
var zOutput = createVariable({prefix:"Z"}, xyzFormat);
var aOutput = createVariable({prefix:"A"}, abcFormat);
var bOutput = createVariable({prefix:"B"}, abcFormat);
var cOutput = createVariable({prefix:"C"}, abcFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);

// circular output
var iOutput = createReferenceVariable({prefix:"I", force:true}, xyzFormat);
var jOutput = createReferenceVariable({prefix:"J", force:true}, xyzFormat);
var kOutput = createReferenceVariable({prefix:"K", force:true}, xyzFormat);

var gMotionModal = createModal({force:true}, gFormat); // modal group 1 // G0-G3, ...
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-22

// collected state
var sequenceNumber;

var totalTime = 0;

// globals for buffering of linear and rapid moves to be used in post processor based corner compensation
// do not use feed optimization as that does not progressively adjust feedrate into and out of corners
var sectionMoves = []; // Buffer for linear cutting moves {x, y, z, feed}
var feedRateFactor = 1.0; // Dynamic feed rate adjustment factor
var lastFeedRate = 0; // Track last set feed rate for feed=0 cases - should we use table feed rate instead?
var powerEvents = {}; // buffer onPower events (on / off power) to be reconstructed during corner compensation

var currentPosition = new Vector(0, 0, 0);

// Helper function: Returns a new normalized vector (non-mutating)
// NOTE: not currently in use. was relevant for a previous implemenation attempt
function normalizeVector(vec) {
  var len = vec.length;
  if (len === 0) {
    return new Vector(0, 0, 0);  // Avoid division by zero
  }
  return new Vector(vec.x / len, vec.y / len, vec.z / len);
}

/**
  Writes the specified block.
*/
function writeBlock() {
  if (getProperty("showSequenceNumbers")) {
    writeWords2("N" + sequenceNumber, arguments);
    sequenceNumber += getProperty("sequenceNumberIncrement");
  } else {
    writeWords(arguments);
  }
}

function formatComment(text) {
  return ";" + String(text).replace(/[()]/g, "");
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

var pierceTime;
var tableFeedrate;
var materialThickness = undefined;
var quality = undefined;

function getMaterialThickness (section) {
  if (hasGlobalParameter("stock-lower-z") && hasGlobalParameter("stock-upper-z")) {
    materialThickness = xyzFormat.format(Math.abs(getGlobalParameter("stock-lower-z") - getGlobalParameter("stock-upper-z")));
  } else {
    error(localize("Stock is not defined into your setup."));
    return undefined;
  }
  return materialThickness;
}

function getCuttingData(section) {
  var materialId = getProperty("material");
  var materialThickness = getMaterialThickness(section);
  // thicknessInMm is materialThickness in mm. used in computing table feed and pierce time
  var thicknessInMm = (unit == MM ? materialThickness : materialThickness * 25.4);

  // Throw error if thickness of material exceeds max thickness defined by materialFormulas
  // is there a more graceful way to notify? in GUI perhaps, instead of failing and dumping an error to log?
  if (thicknessInMm > materialFormulas[materialId].maxThicknessInMm && !getProperty("IgnoreMaxThickness")) {
    var thicknessInIn = thicknessInMm / 25.4;
    var maxThicknessInIn = materialFormulas[materialId].maxThicknessInMm / 25.4;
    var tooThickErr = "material to be cut is too thick for wazer desktop: " +  thicknessInMm + "mm. (" + thicknessInIn + " in.)"
      + "Max thickness for " + materialId + " is: " + materialFormulas[materialId].maxThicknessInMm + "mm. (" 
      + maxThicknessInIn + " in.) Adjust material thickness or material.\n"
      + "If you wish to override this check select Ignore Max Thickness from the Post Preferences dialog.";
    error(localize(tooThickErr));
  }

  switch (section.quality) {
  case 1: // fine
    quality = "Fine";
    break;
  case 2: // medium
    quality = "Medium";
    break;
  case 3: // rough
    quality = "Rough";
    break;
  default:
    // medium quality as default
    quality = "Medium";
  }

  if (materialId == "custom") {
    pierceTime = getProperty("pierceTime");
    tableFeedrate = getProperty("useFeeds");
    quality = "Custom";
  } else {
    getTableFeedrateAndPierceTimeFromFormula(materialId, thicknessInMm, quality); 
  }
}

function getTableFeedrateAndPierceTimeFromFormula(materialId, thicknessInMm, quality) {
  //writeComment("getTableFeedrateAndPierceTimeFromFormula - quality: " + quality);
  pierceTime = eval(materialFormulas[materialId].pierceTimeFormula);
  if (isNaN(pierceTime) || pierceTime < materialFormulas[materialId].minPierceTime) {
    /* 
    pierceTimeFormula should have a floor equal to minimum pierce time but in the event 
    that it does not we can raise it to the min here.

    additionally, some pierce time formulas will purposely generate NaN results for very small thicknesses. 
    this is because of fractional exponents are sometimes used to prevent a right-shifted 
    parabola that would generate increasingly positive values as thickness gets smaller
    e.g. .5 * (x-3)^1.96 + 3.24 where x = 0.1
    */
    pierceTime = materialFormulas[materialId].minPierceTime;
  }
  pierceTime = Math.round(pierceTime*100)/100;
  tableFeedrate = getTableFeedrateFromFormula(materialId, thicknessInMm, quality);
}

function getTableFeedrateFromFormula(materialId, thicknessInMm, quality) {
  //writeComment("getTableFeedrateFromFormula - quality: " + quality);
  switch (quality) {
    case "Fine":
      //writeComment("Quality Fine selected");
      tableFeedrate = eval(materialFormulas[materialId].feedRate.Fine);
      break;
    case "Medium": // medium is derived as a value between fine and rough formula
      //writeComment("Quality Medium selected");
      tableFeedrate = (eval(materialFormulas[materialId].feedRate.Rough) + eval(materialFormulas[materialId].feedRate.Fine)) / 2;
      break;
    case "Rough":
      //writeComment("Quality Rough selected");
      tableFeedrate = eval(materialFormulas[materialId].feedRate.Rough);
      break;
    default:
      // default to medium cut quality
      //writeComment("Quality default selected");
      tableFeedrate = (eval(materialFormulas[materialId].feedRate.Rough) + eval(materialFormulas[materialId].feedRate.Fine)) / 2;
  }
  /*
  some materials (e.g. Silicone, Polyurethane, Neoprene) have a max
  feedrate defined to maintain a particular cut quality for thiner materials. 
  our formula may exceed that feedrate for thiner materials so we set a ceiling to our feedrate 
  */
  if (materialFormulas[materialId].hasOwnProperty('maxFeedRateInMMPM')){
    if (quality == "Fine" && tableFeedrate > materialFormulas[materialId].maxFeedRateInMMPM.Fine) {
      //writeComment("Quality Fine corrected");
      tableFeedrate = materialFormulas[materialId].maxFeedRateInMMPM.Fine;
    }
    else if (quality ==  "Medium" && tableFeedrate > (materialFormulas[materialId].maxFeedRateInMMPM.Fine + materialFormulas[materialId].maxFeedRateInMMPM.Rough)/2) {
      //writeComment("Quality Medium corrected");
      tableFeedrate = (materialFormulas[materialId].maxFeedRateInMMPM.Fine + materialFormulas[materialId].maxFeedRateInMMPM.Rough)/2;
    }
    else if (quality == "Rough" && tableFeedrate > materialFormulas[materialId].maxFeedRateInMMPM.Rough) {
      //writeComment("Quality Rough corrected");
      tableFeedrate = materialFormulas[materialId].maxFeedRateInMMPM.Rough;
    }
  }
  // do not exceed machine's stated max rapids of 59IPM (~1500MMPM)
  if (tableFeedrate > 1500) {
    tableFeedrate = 1500;
  }
  return tableFeedrate;
}

function getMaterialTitle() {
  for (var i = 0; i < properties.material.values.length; i++) {
    if (properties.material.values[i].id == properties.material.current) {
     return properties.material.values[i].title;
    }
  }
}

function onOpen() {
  // update globals based on user selected values for these properties
  maximumLineLength = toPreciseUnit(properties.maximumLineLength.current, MM); // max segment length based on WAM algo
  minimumLineLengthForAngleMeasurement = toPreciseUnit(properties.minimumLineLengthForAngleMeasurement.current, MM); // min segment length to comput angles off of. fusion will make some smaller segments 0.08 vs 0.2

  if (getProperty("material") != "custom" && (getProperty("pierceTime") != 0 || getProperty("useFeeds") != 0)) {
    writeComment("Warning: The properties -Pierce Time- and / or -Feedrate- are only used if the property -material- is set to -Custom-.");
  }
  getCuttingData(getSection(0));
  zOutput.disable();

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  sequenceNumber = getProperty("sequenceNumberStart");

  /*
  if (programName) {
    writeComment(programName);
  }
*/
  if (programComment) {
    writeComment(programComment);
  }

  var cuttingTime = 0;
  var rapidTime = 0;
  //var totalTime = 0;
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    var rapidFeedrate = (unit == MM ? 1905 : 75); // FIXME where is unit set?
    var cuttingDistance = section.getCuttingDistance();
    var rapidDistance = section.getRapidDistance();
    cuttingTime += (cuttingDistance / tableFeedrate * 60);
    rapidTime += (rapidDistance / rapidFeedrate * 60);
  }
  totalTime = (cuttingTime + rapidTime);

  if (hasGlobalParameter("document-path")) {
    var documentPath = getGlobalParameter("document-path");
  }

  writeComment("-------------------------------Cut file parameters------------------------");
  writeComment("Input file name : " + documentPath);
  writeComment("Material name : " + getProperty("material"));
  writeComment("Material thickness : " + getMaterialThickness(getSection(0)) + (unit == MM ? "MM" : "IN"));
  writeComment("Cut Time: " + formatCycleTime(totalTime));
  //writeComment("-------------------------------Do not modify the Gcode file---------------");

  // dump machine configuration
  var vendor = machineConfiguration.getVendor();
  var model = machineConfiguration.getModel();
  var description = machineConfiguration.getDescription();

  if (getProperty("writeMachine") && (vendor || model || description)) {
    writeComment(localize("Machine"));
    if (vendor) {
      writeComment("  " + localize("vendor") + ": " + vendor);
    }
    if (model) {
      writeComment("  " + localize("model") + ": " + model);
    }
    if (description) {
      writeComment("  " + localize("description") + ": " + description);
    }
  }

  writeComment("-------------------------------Do not modify the Gcode file---------------");

  // absolute coordinates and feed per min
  writeBlock(gAbsIncModal.format(90));

  switch (unit) {
  case IN:
    writeBlock(gUnitModal.format(20));
    break;
  case MM:
    writeBlock(gUnitModal.format(21));
    break;
  }

  var stock = getWorkpiece();
  writeBlock(mFormat.format(1403)); // initialize pumps
  writeBlock(mFormat.format(1405), "X" + xyzFormat.format(stock.lower.x), "Y" + xyzFormat.format((stock.upper.y))); // get job top left corner points
  writeBlock(mFormat.format(1406), "X" + xyzFormat.format(stock.upper.x), "Y" + xyzFormat.format((stock.lower.y)));  // get bottom right corner points
  writeBlock(mFormat.format(1407), "S" + pierceTime); // pierce time-based on the selected material
  writeBlock(mFormat.format(1410), getProperty("softwareVersion")); // software version number
  
  // write material M1411
  writeBlock(mFormat.format(1411), getMaterialTitle());
  // write material thickness M1412
  writeBlock(mFormat.format(1412), materialThickness + (unit == MM ? " mm" : " in"));

  sectionMoves = [];
  lastFeedRate = 0;
}

function onComment(message) {
  writeComment(message);
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

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
  forceXYZ();
  forceABC();
}

function onParameter(name, value) {
}

var currentWorkPlaneABC = undefined;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

var closestABC = false; // choose closest machine angles
var currentMachineABC;

function getWorkPlaneMachineABC(workPlane) {
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
    return new Vector();
  }

  if (!machineConfiguration.isABCSupported(abc)) {
    error(
      localize("Work plane is not supported") + ":"
      + conditional(machineConfiguration.isMachineCoordinate(0), " A" + abcFormat.format(abc.x))
      + conditional(machineConfiguration.isMachineCoordinate(1), " B" + abcFormat.format(abc.y))
      + conditional(machineConfiguration.isMachineCoordinate(2), " C" + abcFormat.format(abc.z))
    );
  }

  var tcp = false;
  if (tcp) {
    setRotation(W); // TCP mode
  } else {
    var O = machineConfiguration.getOrientation(abc);
    var R = machineConfiguration.getRemainingOrientation(abc, W);
    setRotation(R);
  }

  return abc;
}

function formatCycleTime(cycleTime) {
  cycleTime += 0.5; // round up
  var seconds = (cycleTime % 60 | 0).toString();
  var minutes = (((cycleTime - seconds) / 60 | 0) % 60).toString();
  var hours = ((cycleTime - minutes * 60 - seconds) / (60 * 60) | 0).toString();
  if (hours != "0") {
    return subst(localize("%1:%2:%3"), hours, minutes, seconds);
  } else if (minutes != "0") {
    return subst(localize("00:%1:%2"), minutes.padStart(2,"0"), seconds.padStart(2,"0"));
  } else {
    return subst(localize("00:00:%1"), seconds);
  }
}

function onSection() {
  getCuttingData(currentSection);
  writeln("");

  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment(comment);
    }
  }

  if (hasParameter("operation:compensation")) {
    writeComment("Cut path : " + getParameter("operation:compensation"));
  }

  if (quality) {
    writeComment("Cut quality : " + quality);
  }

  switch (tool.type) {
  case TOOL_WATER_JET:
    break;
  default:
    error(localize("The CNC does not support the required tool/process. Only water jet cutting is supported."));
    return;
  }

  switch (currentSection.jetMode) {
  case JET_MODE_THROUGH:
    break;
  case JET_MODE_ETCHING:
    error(localize("Etch cutting mode is not supported."));
    break;
  case JET_MODE_VAPORIZE:
    error(localize("Vaporize cutting mode is not supported."));
    break;
  default:
    error(localize("Unsupported cutting mode."));
    return;
  }

  { // pure 3D
    var remaining = currentSection.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported."));
      return;
    }
    setRotation(remaining);
  }

  forceAny();

  // var initialPosition = getFramePosition(currentSection.getInitialPosition());
  // writeBlock(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y));

  // Reset for buffering
  currentPosition = getFramePosition(currentSection.getInitialPosition());
  sectionMoves = [];
  powerEvents = {};
  lastFeedRate = tableFeedrate ? tableFeedrate : 0; // Initialize with section's base feed rate
}

function onDwell(seconds) {
  writeComment("onDwell - " + seconds);
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.001, seconds, 99999.999);
  writeBlock(gFormat.format(4), "S" + secFormat.format(seconds));
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
  error(localize("Radius compensation is not supported."));
  return;
}

// old onPower - moved logic to write these into processAndWriteSection()
/*function onPower(power) {
  writeComment("onPower - " + power);
  if (power) {
    writeBlock(mFormat.format(3));
    writeBlock(mFormat.format(8));
    writeBlock(gFormat.format(4), "S" + secFormat.format(pierceTime));
  } else {
    var endPauseScaleVariable = 0.15;
    writeBlock(gFormat.format(4), "S" + secFormat.format(endPauseScaleVariable * pierceTime));
    writeBlock(mFormat.format(9));
    writeBlock(gFormat.format(4), "S" + secFormat.format(1));
    writeBlock(mFormat.format(5));
    writeBlock(gFormat.format(4), "S" + secFormat.format(1));
    writeln("");
  }
}*/

function onPower(power) {
  // buffer onPower events into powerEvents for later writing in processAndWriteSection() 
  // once corner compensation of feedrate has been performed
  powerEvents[sectionMoves.length] = {power: power};
}

function onRapid(_x, _y, _z) {
  // buffer onRapid moves into sectionMoves for later writing in processAndWriteSection()
  sectionMoves.push({ x: _x, y: _y, z: _z, feed: 0, type: "rapid" });
}

function onLinear(_x, _y, _z, feed) {

  if (pendingRadiusCompensation >= 0) {
    // ensure that we end at desired position when compensation is turned off
    xOutput.reset();
    yOutput.reset();
  }

  // Use last feed rate if feed is 0
  var effectiveFeed = (feed == 0 && lastFeedRate > 0) ? lastFeedRate : (tableFeedrate ? tableFeedrate : feed);
  // overide effectiveFeed (for now)
  effectiveFeed = feed ? feed : tableFeedrate;
  if (effectiveFeed > 0) {
    lastFeedRate = effectiveFeed; // Update last known feed rate
  }

  //writeComment("onLinear: feed: " + feed);

  var end = new Vector(_x, _y, _z);
  var direction = Vector.diff(end, currentPosition);
  //writeComment("onLinear - segment length: " + direction.length);

  /*
    split linear moves into to lengths of maximumLineLength (default 5mm)
    this ensures our corner compensations will have enough lead in/out to 
    progressively slow feedrate into corners and ramp back up to speed 
    when leaving them. 
  */
  if (direction.length > maximumLineLength) {
    // segment length too long, split the segment, then push the smaller segments onto sectionMoves array
    var numberOfSegments = Math.max(Math.ceil(direction.length / maximumLineLength), 1);
    //writeComment("onLinear - direction.legth TOO LONG: " + direction.length + " split into: " + numberOfSegments + " segments");

    var startXYZ = getCurrentPosition();
    var endXYZ = new Vector(_x, _y, _z);

    for (var i = 1; i <= numberOfSegments; ++i) {
      //var p = Vector.lerp(getCurrentPosition(), end, i * 1.0 / numberOfSegments);
      var p = Vector.lerp(startXYZ, endXYZ, i * 1.0 / numberOfSegments);
      //var intermediateEnd = new Vector(p.x, p.y, p.z);
      sectionMoves.push({ x: p.x, y: p.y, z: p.z, feed: effectiveFeed, type: "linear" });
      //setCurrentPosition(intermediateEnd); // added inside loop to update getCurrentPosition()
    }
  }
  else {
    // segment length OK, just push the coordinates onto the sectionMoves array
    sectionMoves.push({ x: _x, y: _y, z: _z, feed: effectiveFeed, type: "linear" });
  }

  currentPosition = end;
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  
  writeComment("onCircular called"); // should not be called

  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }

  var start = getCurrentPosition();

  if (isFullCircle()) {
    if (isHelical()) {
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

var mapCommand = {
  COMMAND_STOP         : 0,
  COMMAND_OPTIONAL_STOP: 1
};

function onCommand(command) {
  //writeComment("command "+command);
  switch (command) {
  case COMMAND_POWER_ON:
    return;
  case COMMAND_POWER_OFF:
    return;
  case COMMAND_LOCK_MULTI_AXIS:
    return;
  case COMMAND_UNLOCK_MULTI_AXIS:
    return;
  case COMMAND_BREAK_CONTROL:
    return;
  case COMMAND_TOOL_MEASURE:
    return;
  }

  var stringId = getCommandStringId(command);
  var mcode = mapCommand[stringId];
  if (mcode != undefined) {
    writeBlock(mFormat.format(mcode));
  } else {
    onUnsupportedCommand(command);
  }
}

function onSectionEnd() {
  //writeComment("calling processAndWriteSection();");
  processAndWriteSection();
  //writeComment("called processAndWriteSection();");

  forceAny();
  feedOutput.reset();
}

function processAndWriteSection() {
  // FIXME this should be updated but retain the logic around min section moves length
  if (sectionMoves.length < 2) {
    // Not enough moves for compensation: write original moves
    for (var i = 0; i < sectionMoves.length; i++) {
      var move = sectionMoves[i];
      var x = xOutput.format(move.x);
      var y = yOutput.format(move.y);
      var f = feedOutput.format(move.feed);
      writeBlock(gMotionModal.format(1), x, y, f);
      lastFeedRate = move.feed; // Update last feed rate
    }
    return;
  }

  // Compute segment lengths (2D XY distance, as Wazer is 2.5D)
  var segmentLengths = [];
  for (var i = 1; i < sectionMoves.length; i++) { // starting at index 1: segmentLengths.length will be sectionMoves.length - 1
    var dx = sectionMoves[i].x - sectionMoves[i - 1].x;
    var dy = sectionMoves[i].y - sectionMoves[i - 1].y;
    var length = Math.sqrt(dx * dx + dy * dy);
    segmentLengths.push(length);
  }

  /*
  step through segmentLengths array to build segmentPositionsForAngles array which we'll in 
  conjunction with sectionMoves to determine corner angles.

  we're doing this because we want to measure the angle of a corner over a distances that is 
  long enough to give us an accurate picture of how tight a corner is. this is particularly 
  helpful when corners are split into many smaller segments because comparing contigous vectors 
  over very small segments tends to underestimate the angle of the geometry. 
  */
  var segmentPositionsForAngles = [];
  for (var i = 0; i < segmentLengths.length; i++) {
    var segmentLengthAccumulator = 0;
    var segmentStartIndex = i;
    var segmentEndIndex = 0;
    //writeComment("i:" + i);
    for (var j = i; j < segmentLengths.length; j++) {
      //writeComment("\tj: " + j);
      segmentLengthAccumulator += segmentLengths[j];
      if (segmentLengthAccumulator > minimumLineLengthForAngleMeasurement || j == segmentLengths.length-1) {
        // we have a segment that is long enough, or we've hit the end of the array of segments, store the end position
        segmentEndIndex = j;
        segmentPositionsForAngles.push([segmentStartIndex,segmentEndIndex]);
        break;
      }
    }
  }
  //writeComment(JSON.stringify(segmentPositionsForAngles, null, 2));

  /*
  same as above but in reverse order. by looking back from the end of array to the beginning 
  we can better see what the angle is leaving the corner and adjust feedrate accordingly
  */
  var segmentPositionsForAnglesLookBack = [];
  for (var i = segmentLengths.length - 1; i >= 0; i--) {
    var segmentLengthAccumulator = 0;
    var segmentStartIndex = i;
    var segmentEndIndex = 0;
    //writeComment("i:" + i);
    //writeComment("[" + i + "]");//" segmentLengthAccumulator: " + segmentLengthAccumulator + " segmentEndIndex: " + segmentEndIndex);
    for (var j = i; j >= 0; j--) {
      //writeComment("\tj: " + j);
      segmentLengthAccumulator += segmentLengths[j];
      //writeComment("\t[" + j + "] segmentLengthAccumulator: " + segmentLengthAccumulator + " segmentEndIndex: " + segmentEndIndex);
      if (segmentLengthAccumulator > minimumLineLengthForAngleMeasurement || j == 0) {
        // we have a segment that is long enough, or we've hit the beginning of the array of segments, store the end position
        segmentEndIndex = j;
        segmentPositionsForAnglesLookBack.push([segmentStartIndex,segmentEndIndex]);
        //writeComment("\t[" + j + "] segmentLengthAccumulator: " + segmentLengthAccumulator + " segmentEndIndex: " + segmentEndIndex);
        break;
      }
    }
  }
  //writeComment(JSON.stringify(segmentPositionsForAnglesLookBack, null, 2));


  // Initialize arrays for feed rate adjustments
  var feedRateMultipliers = Array(segmentLengths.length).fill(1.0); // Segment-based
  var cornerFeedRates = Array(sectionMoves.length).fill(1.0); // Point-based
  feedRateFactor = 1.0; // Reset dynamic factor

  var angles = [];
  var debug = [];
  const PRINTDEBUG = false;

  //writeComment("number of segments in sectionMoves: " + sectionMoves.length);
  
  /// iterate over points taking current segment plus next into account for the angle / feedrate reduction factor
  var lastPointIndex = sectionMoves.length - 1;
  for (var pointIndex = 1; pointIndex <= lastPointIndex; pointIndex++) { // should start at 1?

    var forwardAngleAndMagnitude = getAngleAndMagnitudeFromSegmentPositionsForAngles(segmentPositionsForAngles, sectionMoves, pointIndex, "F");
    var lookBackAngleAndMagnitude = getAngleAndMagnitudeFromSegmentPositionsForAngles(segmentPositionsForAnglesLookBack, sectionMoves, pointIndex, "R");

    /*
     select the larger of the two angles computed by getAngleAndMagnitudeFromSegmentPositionsForAngles.
     our forwardAngleAndMagnitude will be larger when entering a corner since it's looking ahead.
     our lookBackAngleAndMagnitude will be larger when exiting a corner since it's looking behind
    */
    var angleDegrees = (forwardAngleAndMagnitude.angle > lookBackAngleAndMagnitude.angle) ? forwardAngleAndMagnitude.angle : lookBackAngleAndMagnitude.angle;
    var magnitudeStart = (forwardAngleAndMagnitude.angle > lookBackAngleAndMagnitude.angle) ? forwardAngleAndMagnitude.magnitude : lookBackAngleAndMagnitude.magnitude;
    //writeComment("[" + pointIndex + "] forward angle: " + forwardAngleAndMagnitude.angle + " lookback angle: " + lookBackAngleAndMagnitude.angle);

    /* 
      we'll want to collapse the shorter maximumLineLength segments we created in onLinear
      to do so we want to know when we are travelling in a straight line (angleDegrees==0)
      store angleDegrees in angles array for user during the gcode printing
    */
    angles.push(angleDegrees);

    // debug lets us know what each part of the WAM corner compensation algorithm is doing
    debug[pointIndex] = { A: angleDegrees, C: "" };

    // Adjust feed rate for short segments (< 0.05 mm)
    if (magnitudeStart < 0.05) {
      if (pointIndex < lastPointIndex - 1) {
        if (feedRateFactor > 0.7) {
          feedRateFactor = parseFloat((feedRateFactor - 0.05).toFixed(2));
          feedRateMultipliers[pointIndex - 1] = feedRateFactor;
          debug[pointIndex] = { A: debug[pointIndex].A, C: debug[pointIndex].C + " F1 (-1-=.05)" };
          // writeComment("Short segment adjust: F" + (sectionMoves[pointIndex].feed * feedRateMultipliers[pointIndex-1]).toFixed(2));
        } else if (feedRateFactor == 0.7) {
          feedRateMultipliers[pointIndex - 1] = feedRateFactor;
          debug[pointIndex] = { A: debug[pointIndex].A, C: debug[pointIndex].C + " F2 (-1=.7)" };
          // writeComment("Short segment hold: F" + (sectionMoves[pointIndex].feed * feedRateMultipliers[pointIndex-1]).toFixed(2));
        }
      } else {
        feedRateFactor = 0.75;
        feedRateMultipliers[pointIndex - 1] = feedRateFactor;
        debug[pointIndex] = { A: debug[pointIndex].A, C: debug[pointIndex].C + " F3 (-1=.75)" };
        // writeComment("Short segment end: F" + (sectionMoves[pointIndex].feed * feedRateMultipliers[pointIndex-1]).toFixed(2));
      }
    } else {
      if (pointIndex < lastPointIndex - 2) {
        if (feedRateFactor < 1.0) {
          feedRateFactor = parseFloat((feedRateFactor + 0.1).toFixed(2));
          feedRateMultipliers[pointIndex - 1] = feedRateFactor;
          debug[pointIndex] = { A: debug[pointIndex].A, C: debug[pointIndex].C + " F4 (-1+=.1)" };
          // writeComment("Long segment adjust: F" + (sectionMoves[pointIndex].feed * feedRateMultipliers[pointIndex-1]).toFixed(2));
        }
      } else {
        feedRateFactor = 0.75;
        feedRateMultipliers[pointIndex - 1] = feedRateFactor;
        debug[pointIndex] = { A: debug[pointIndex].A, C: debug[pointIndex].C + " F5 (-1=.75)" };
        // writeComment("Long segment end: F" + (sectionMoves[pointIndex].feed * feedRateMultipliers[pointIndex-1]).toFixed(2));
      }
    } /// end

    // Adjust feed rate for corners based on angle
    if (angleDegrees > 20 && angleDegrees < 60) {
      if (cornerFeedRates[pointIndex - 1] > 0.85) {
        cornerFeedRates[pointIndex - 1] = 0.85;
        debug[pointIndex] = { A: debug[pointIndex].A, C: debug[pointIndex].C + " C1 (-1=.85)" };
      }
      cornerFeedRates[pointIndex] = 0.7;
      cornerFeedRates[pointIndex + 1] = 0.85;
      debug[pointIndex] = { A: debug[pointIndex].A, C: debug[pointIndex].C + " C2 (0=.7 +1=.85)" };
      /*
      // could expand further to another point after corner exit, e.g. 
      if (pointIndex + 2 < sectionMoves.length) {
        cornerFeedRates[pointIndex + 2] = 0.9;
      }
      */
      // writeComment("Moderate corner (" + angleDegrees.toFixed(1) + "°): F" + (sectionMoves[pointIndex].feed * cornerFeedRates[pointIndex]).toFixed(2));
    } else if (angleDegrees >= 60) {
      if (pointIndex - 2 >= 0 && cornerFeedRates[pointIndex - 2] > 0.85) {
        cornerFeedRates[pointIndex - 2] = 0.85;
        debug[pointIndex] = { A: debug[pointIndex].A, C: debug[pointIndex].C + " C3 (-2=.85)" };
      }
      if (cornerFeedRates[pointIndex - 1] > 0.65) {
        cornerFeedRates[pointIndex - 1] = 0.65;
        debug[pointIndex] = { A: debug[pointIndex].A, C: debug[pointIndex].C + " C4 (-1=.65)" };
      }
      if (pointIndex < lastPointIndex - 2) {
        cornerFeedRates[pointIndex] = 0.45;
        debug[pointIndex] = { A: debug[pointIndex].A, C: debug[pointIndex].C + " C5 (0=.45)" };
      }
      cornerFeedRates[pointIndex + 1] = 0.65;
      debug[pointIndex] = { A: debug[pointIndex].A, C: debug[pointIndex].C + " C6 (+1=.65)" };
      if (pointIndex + 2 < sectionMoves.length) {
        cornerFeedRates[pointIndex + 2] = 0.85;
        debug[pointIndex] = { A: debug[pointIndex].A, C: debug[pointIndex].C + " C7 (+2=.85)" };
      }
      // writeComment("Sharp corner (" + angleDegrees.toFixed(1) + "°): F" + (sectionMoves[pointIndex].feed * cornerFeedRates[pointIndex]).toFixed(2));
    } // end adjust feed rate for corners
  } // end for loop pointIndex

  // variable userd in collapsing straight G1 movements that are of the same feedrate
  var onStraight = false;
  var lastFeed = 0;
  var lastF = "";
  var lastX = undefined;
  var lastY = undefined;

  // output gcode
  for (var i = 0; i < sectionMoves.length; i++) {
    var adjustedFeed = sectionMoves[i].feed;
    if (i > 0) {
      var segIndex = i - 1;
      adjustedFeed *= feedRateMultipliers[segIndex];
      adjustedFeed *= cornerFeedRates[i];
      // this was in the WAM code but since we're calculating angles differently we don't need to take the min over two positions
      //adjustedFeed *= Math.min(cornerFeedRates[i - 1], cornerFeedRates[i]); // original
    }
    var x = xOutput.format(sectionMoves[i].x);
    var y = yOutput.format(sectionMoves[i].y);
    var f = feedOutput.format(adjustedFeed);

    // look for onPower events in powerEvents
    // if we have one at this index we should either enable or disable the cutter
    if (!(powerEvents[i] === undefined)) {
      onStraight = false;
      if (powerEvents[i].power) {
        //writeComment("power == true - turn on cutter");
        writeBlock(mFormat.format(3));
        writeBlock(mFormat.format(8));
        writeBlock(gFormat.format(4), "S" + secFormat.format(pierceTime));
      } else {
        //writeComment("power == false - turn off cutter");
        var endPauseScaleVariable = 0.15;
        writeBlock(gFormat.format(4), "S" + secFormat.format(endPauseScaleVariable * pierceTime));
        writeBlock(mFormat.format(9));
        writeBlock(gFormat.format(4), "S" + secFormat.format(1));
        writeBlock(mFormat.format(5));
        writeBlock(gFormat.format(4), "S" + secFormat.format(1));
        writeln("");
      }
    }

    if (sectionMoves[i].type == "linear") {
      onStraight = (angles[i-1] == 0) ? true : false;
      if (onStraight && lastFeed == adjustedFeed)
      {
        //writeComment("would have DELETE");
        //writeBlock(gMotionModal.format(1), x, y, f);
        lastX = x;
        lastY = y;
      } else {
        if (!(lastX === undefined & lastY === undefined)){
          //writeComment("UNDELETING LAST");
          //f = feedOutput.format(lastFeed);
          //writeBlock(gMotionModal.format(1), lastX, lastY, feedOutput.format(lastFeed));
          //writeBlock(gMotionModal.format(1), lastX, lastY, lastF); 
          if (PRINTDEBUG) {
            var tabs = (lastF == "") ? "\t\t\t" : "\t";
            writeBlock(gMotionModal.format(1), lastX, lastY, lastF, tabs+";"+JSON.stringify(debug[i])+" "+onStraight+" feed: "+adjustedFeed+" lastfeed: "+lastFeed ); 
          } else {
            writeBlock(gMotionModal.format(1), lastX, lastY, lastF);
          }
          lastX = undefined;
          lastY = undefined;
        }

        if (PRINTDEBUG) {
          var tabs = (f == "") ? "\t\t\t" : "\t";
          writeBlock(gMotionModal.format(1), x, y, f, tabs+";"+JSON.stringify(debug[i])+" "+onStraight+" feed: "+adjustedFeed+" lastfeed: "+lastFeed ); 
        } else {
          writeBlock(gMotionModal.format(1), x, y, f);
        }

      }
      lastFeed = adjustedFeed;
      lastF = f;

    } else if (sectionMoves[i].type == "rapid") {
      onStraight = false;
      writeBlock(gMotionModal.format(0), x, y);
    } else {
      // this comment shouldn't ever appear as we only current have linear and rapid events in sectionMoves array
      writeComment("DIDNT WRITE type: " + sectionMoves[i].type);
    }
    lastFeedRate = f; // Update last feed rate
  }
}

function getAngleAndMagnitudeFromSegmentPositionsForAngles(segmentPositionsForAngles, sectionMoves, pointIndex, ArrayDirection){

  var startPointIndexArray = segmentPositionsForAngles[pointIndex - 1];
  var intermediatePointIndexArray = segmentPositionsForAngles[pointIndex]; 
  var endPointIndexArray = segmentPositionsForAngles[pointIndex + 1]; // this will overflow, endPointIndex undefined

  if (ArrayDirection == "R") {
    // need to approach the array from the end since it is reversed..
    var reversedPointIndex = segmentPositionsForAngles.length - pointIndex - 1;
    startPointIndexArray = segmentPositionsForAngles[reversedPointIndex - 1];
    intermediatePointIndexArray = segmentPositionsForAngles[reversedPointIndex]; 
    endPointIndexArray = segmentPositionsForAngles[reversedPointIndex + 1];
  }

  // clamp values to end, or start, of array if we exceed start or end index of array
  if (endPointIndexArray === undefined) {
    endPointIndexArray = [sectionMoves.length - 1,sectionMoves.length - 1];
  }
  if (intermediatePointIndexArray === undefined) {
    intermediatePointIndexArray = [sectionMoves.length - 1,sectionMoves.length - 1];
  }
  if (startPointIndexArray === undefined) {
    //startPointIndexArray = [sectionMoves.length - 1,sectionMoves.length - 1];
    startPointIndexArray = [0,0];
  }

  var startPointIndex = startPointIndexArray[0];
  var intermediatePointIndex = intermediatePointIndexArray[0];
  var endPointIndex = endPointIndexArray[1];

  // these are positions
  var startPosition = new Vector(sectionMoves[startPointIndex].x, sectionMoves[startPointIndex].y, 0);
  var intermediatePosition = new Vector(sectionMoves[intermediatePointIndex].x, sectionMoves[intermediatePointIndex].y, 0);
  var endPosition = new Vector(sectionMoves[endPointIndex].x, sectionMoves[endPointIndex].y, 0);

  // these are vectors
  var startDirection = Vector.diff(intermediatePosition,startPosition);
  var endDirection = Vector.diff(endPosition,intermediatePosition);

  var dotProduct = Vector.dot(endDirection,startDirection);
  var magnitudeStart = Math.hypot(startDirection.getX(), startDirection.getY());
  var magnitudeEnd = Math.hypot(endDirection.getX(), endDirection.getY());
  var angleDegrees = (180 / Math.PI * (Math.acos(dotProduct / (magnitudeStart * magnitudeEnd))));

  return { angle: angleDegrees, magnitude: magnitudeStart };
}

function onClose() {
  writeBlock(mFormat.format(1413), formatCycleTime(totalTime));
  writeBlock(mFormat.format(1404));
}

function setProperty(property, value) {
  properties[property].current = value;
}
