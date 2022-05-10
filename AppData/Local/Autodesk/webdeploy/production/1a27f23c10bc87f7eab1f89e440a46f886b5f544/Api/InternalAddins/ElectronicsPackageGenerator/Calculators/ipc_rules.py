# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

"""
IPC rules containing density tables for different component, silkscreen and assembly outline properties, package specific properties etc. Note: All values are in um.
"""
 
"""
	////////////////////
	// Density Tables //
	////////////////////
"""
PAD_GOAL_GULLWING = {}
#gullwing components with greater than 0.625mm pitch
PAD_GOAL_GULLWING['toeFilletMaxMedMinGT'] = [0.0550, 0.0350, 0.0150]
PAD_GOAL_GULLWING['heelFilletMaxMedMinGT'] = [0.0450, 0.0350, 0.0250] 
PAD_GOAL_GULLWING['sideFilletMaxMedMinGT'] = [0.0050, 0.0030, 0.0010] 
#gullwing components with smaller than or equal to 0.625mm pitch
PAD_GOAL_GULLWING['toeFilletMaxMedMinLTE'] = [0.0550, 0.0350, 0.0150]
PAD_GOAL_GULLWING['heelFilletMaxMedMinLTE'] = [0.0450, 0.0350, 0.0250]
PAD_GOAL_GULLWING['sideFilletMaxMedMinLTE'] = [0.0010, -0.0020, -0.0040] 
PAD_GOAL_GULLWING['curtyardExcessMaxMedMin'] = [0.0500, 0.0250, 0.0100]
PAD_GOAL_GULLWING['pitchTh'] = 0.0625

PAD_GOAL_NOLEAD = {}
PAD_GOAL_NOLEAD['toeFilletMaxMedMin'] =  [0.0400, 0.0300, 0.0200]
PAD_GOAL_NOLEAD['heelFilletMaxMedMin'] =  [0.0, 0.0, 0.0]
PAD_GOAL_NOLEAD['sideFilletMaxMedMin'] =  [-0.0040, -0.0040, -0.0040]
PAD_GOAL_NOLEAD['curtyardExcessMaxMedMin'] =  [0.0500, 0.0250, 0.0100]

PAD_GOAL_CHIP = {}
#Rectangular or Square-End Components (Capacitors and Resistors) Equal to or Larger than 1608 (0603) (unit: mm)
PAD_GOAL_CHIP['toeFilletMaxMedMinGTE'] = [0.0550, 0.0350, 0.0150]
PAD_GOAL_CHIP['heelFilletMaxMedMinGTE'] = [0.0, 0.0, 0.0]
PAD_GOAL_CHIP['sideFilletMaxMedMinGTE'] = [0.0050, 0.0, -0.0050]
PAD_GOAL_CHIP['curtyardExcessMaxMedMinGTE'] = [0.0500, 0.0250, 0.0100]
PAD_GOAL_CHIP['toeFilletMaxMedMinLT'] = [0.0300, 0.0200, 0.0100]
PAD_GOAL_CHIP['heelFilletMaxMedMinLT'] = [0.0, 0.0, 0.0]
PAD_GOAL_CHIP['sideFilletMaxMedMinLT'] = [0.0050, 0.0, -0.0050]
PAD_GOAL_CHIP['curtyardExcessMaxMedMinLT'] = [0.0200, 0.0150, 0.0100]
PAD_GOAL_CHIP['bodyLengthTh'] = 0.1608

PAD_GOAL_CHIPARRAY = {}
# In 7351C proposed densities depends in pitch. Our calculator follows IPC7351B standard.
PAD_GOAL_CHIPARRAY['toeFilletMaxMedMin'] = [0.055, 0.045, 0.035]
PAD_GOAL_CHIPARRAY['heelFilletMaxMedMin'] = [-0.005, -0.007, -0.01]
PAD_GOAL_CHIPARRAY['sideFilletMaxMedMin'] = [-0.005, -0.007, -0.01]
PAD_GOAL_CHIPARRAY['curtyardExcessMaxMedMin'] = [0.05, 0.025, 0.01]

PAD_GOAL_MOLDEDBODY = {}
#Note: toe and heel goals are swapped for this component
PAD_GOAL_MOLDEDBODY['toeFilletMaxMedMin'] = [0.0800, 0.0500, 0.0200]
PAD_GOAL_MOLDEDBODY['heelFilletMaxMedMin'] = [0.0250, 0.0150, 0.0070]
PAD_GOAL_MOLDEDBODY['sideFilletMaxMedMin'] = [0.0010, -0.0050, -0.0100]
PAD_GOAL_MOLDEDBODY['curtyardExcessMaxMedMin'] = [0.0500, 0.0250, 0.0100]

PAD_GOAL_MELF = {}
PAD_GOAL_MELF['toeFilletMaxMedMin'] = [0.0600, 0.0400, 0.0200]
PAD_GOAL_MELF['heelFilletMaxMedMin'] = [0.0200, 0.0100, 0.0020]
PAD_GOAL_MELF['sideFilletMaxMedMin'] = [0.0100, 0.0050, 0.0010]
PAD_GOAL_MELF['curtyardExcessMaxMedMin'] = [0.0500, 0.0250, 0.0100]

PAD_GOAL_PLCC = {}
#Note: toe and heel goals are swapped for this component because of J-Lead
PAD_GOAL_PLCC['toeFilletMaxMedMin'] = [0.0550, 0.0350, 0.0150]
PAD_GOAL_PLCC['heelFilletMaxMedMin'] = [0.0100, 0, -0.0100]
PAD_GOAL_PLCC['sideFilletMaxMedMin'] = [0.0050, 0.0030, 0.0010]
PAD_GOAL_PLCC['curtyardExcessMaxMedMin'] = [0.0500, 0.0250, 0.0100]

PAD_GOAL_SMALLOUTLINEFLATLEAD = {}
PAD_GOAL_SMALLOUTLINEFLATLEAD['toeFilletMaxMedMin'] = [0.0300, 0.0200, 0.0100]
PAD_GOAL_SMALLOUTLINEFLATLEAD['heelFilletMaxMedMin'] = [0.0, 0.0, 0.0]
PAD_GOAL_SMALLOUTLINEFLATLEAD['sideFilletMaxMedMin'] = [0.0050, 0.0, -0.0050]
PAD_GOAL_SMALLOUTLINEFLATLEAD['curtyardExcessMaxMedMin'] = [0.0200, 0.0150, 0.0100]

PAD_GOAL_DFN = {}
PAD_GOAL_DFN['periphery'] = [0.005, 0, -0.005]
PAD_GOAL_DFN['curtyardExcessMaxMedMin'] = [0.05, 0.025, 0.01]

PAD_GOAL_ALUMI_ELECTROLYTIC = {}
PAD_GOAL_ALUMI_ELECTROLYTIC['toeFilletMaxMedMinGTE'] = [0.1000, 0.0700, 0.0400]
PAD_GOAL_ALUMI_ELECTROLYTIC['heelFilletMaxMedMinGTE'] = [0.0, -0.0050, -0.0100]
PAD_GOAL_ALUMI_ELECTROLYTIC['sideFilletMaxMedMinGTE'] = [0.0600, 0.0500, 0.0400]
PAD_GOAL_ALUMI_ELECTROLYTIC['toeFilletMaxMedMinLT'] = [0.0700, 0.0500, 0.0300]
PAD_GOAL_ALUMI_ELECTROLYTIC['heelFilletMaxMedMinLT'] = [0.0, -0.0100, -0.0200]
PAD_GOAL_ALUMI_ELECTROLYTIC['sideFilletMaxMedMinLT'] = [0.0500, 0.0400, 0.0300]
PAD_GOAL_ALUMI_ELECTROLYTIC['curtyardExcessMaxMedMin'] = [0.1000, 0.0500, 0.0250]
PAD_GOAL_ALUMI_ELECTROLYTIC['bodyHeightTh'] = 1.0000

PAD_GOAL_OSCILLATOR_CORNERCONCAVE = {}
PAD_GOAL_OSCILLATOR_CORNERCONCAVE['toeFilletMaxMedMin'] = [0.035, 0.025, 0.015]
PAD_GOAL_OSCILLATOR_CORNERCONCAVE['heelFilletMaxMedMin'] = [0.01, 0.0, -0.005]
PAD_GOAL_OSCILLATOR_CORNERCONCAVE['sideFilletMaxMedMin'] = [0.0, 0.0, 0.0]
PAD_GOAL_OSCILLATOR_CORNERCONCAVE['curtyardExcessMaxMedMin'] = [0.05, 0.025, 0.01]
		
PAD_GOAL_OSCILLATOR_JLEAD = {}
#Note: toe and heel goals are swapped for this component because of J-Lead
PAD_GOAL_OSCILLATOR_JLEAD['toeFilletMaxMedMin'] = [0.0550, 0.0350, 0.0150]
PAD_GOAL_OSCILLATOR_JLEAD['heelFilletMaxMedMin'] = [0.0100, 0.0, -0.0100]
PAD_GOAL_OSCILLATOR_JLEAD['sideFilletMaxMedMin'] = [0.0050, 0.0030, 0.0010]
PAD_GOAL_OSCILLATOR_JLEAD['curtyardExcessMaxMedMin'] = [0.0500, 0.0250, 0.0100]

PAD_GOAL_OSCILLATOR_LBEND = {}
#Note: toe and heel goals are swapped for this component because of L-Bend
PAD_GOAL_OSCILLATOR_LBEND['toeFilletMaxMedMin'] = [0.0100, 0.0, -0.0100]
PAD_GOAL_OSCILLATOR_LBEND['heelFilletMaxMedMin'] = [0.0550, 0.0350, 0.0150]
PAD_GOAL_OSCILLATOR_LBEND['sideFilletMaxMedMin'] = [0.0010, -0.0020, -0.0040]
PAD_GOAL_OSCILLATOR_LBEND['curtyardExcessMaxMedMin'] = [0.0500, 0.0250, 0.0100]

PAD_GOAL_SOJ = {}
#Note: toe and heel goals are swapped for this component because of Soj
PAD_GOAL_SOJ['toeFilletMaxMedMin'] = [0.0550, 0.0350, 0.0150]
PAD_GOAL_SOJ['heelFilletMaxMedMin'] = [0.0100, 0.0, -0.0100]
PAD_GOAL_SOJ['sideFilletMaxMedMin'] = [0.0050, 0.0030, 0.0010]
PAD_GOAL_SOJ['curtyardExcessMaxMedMin'] = [0.0500, 0.0250, 0.0100]

PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE = {}
#percentage decrease from nominal ball diameter
#table key is the nominal ball diameter and value is an array contains percentage adjustment (from nominal ball diameter), variation (+), ball size increment (round off to specific increment)
PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE['150'] = [-0.15, 20, 10]
PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE['170'] = [-0.15, 30, 50]
PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE['200'] = [-0.15, 30, 10]
PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE['250'] = [-0.2, 0, 10]
PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE['300'] = [-0.2, 0, 50]
PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE['350'] = [-0.2, 50, 10]
PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE['400'] = [-0.2, 50, 50]
PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE['450'] = [-0.2, 50, 50]
PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE['500'] = [-0.2, 50, 50]
PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE['550'] = [-0.25, 100, 50]
PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE['600'] = [-0.25, 50, 50]
PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE['650'] = [-0.25, 50, 50]
PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE['750'] = [-0.25, 50, 50]
"""
nominal ball diameter range. It is used to find exact key to be used in lookup table if nominal ball diameter input does not match any of the keys.
find range for calculated nominal ball diamter (average of min and max) and use the range minimum as the key.
e.g., if nominal ball diameter is 470, key to be used should be 450.
Note: If the input is greater than max key use max index and if it is smaller than min use min index.
"""
PAD_GOAL_BGA_COLLAPSIBLE_RANGE = [[150, 170], [170, 200], [200, 250], [250, 300], [300, 350], [350, 400], [400, 450], [450, 500], [500, 550], [550, 600], [600, 650], [650, 750]]

PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE = {}
#percentage decrease from nominal ball diameter
#table key is the nominal ball diameter and value is an array contains percentage adjustment (from nominal ball diameter), variation (+), ball size increment (round off to specific increment)
PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE['150'] = [0.05, 30, 10]
PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE['170'] = [0.05, 30, 10]
PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE['200'] = [0.05, 30, 10]
PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE['250'] = [0.1, 50, 10]
PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE['300'] = [0.1, 50, 10]
PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE['400'] = [0.1, 50, 50]
PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE['450'] = [0.1, 50, 50]
PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE['500'] = [0.1, 50, 50]
PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE['550'] = [0.15, 50, 50]
PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE['600'] = [0.15, 50, 50]
PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE['750'] = [0.15, 50, 50]

PAD_GOAL_BGA_NONCOLLAPSIBLE_RANGE = [[150, 170], [170, 200], [200, 250], [250, 300], [300, 400], [400, 450], [450, 500], [500, 550], [550, 600], [600, 750]]
			
PAD_GOAL_BGA_NONCOLLAPSIBLE = {}
PAD_GOAL_BGA_NONCOLLAPSIBLE['curtyardExcessMaxMedMin'] = [2000, 1000, 500]

PTH_PAD_GOAL={}
# //same for all Plated Through Hole packages
PTH_PAD_GOAL['holeDiameterFactor'] = [0.0250, 0.0200, 0.0150]


"""
	///////////////////////////
	// Axial lead attributes //
	///////////////////////////
	//Ref: Table 3-1 in IPC7251 doc
"""
AXIAL_LEAD_GOAL = {}
AXIAL_LEAD_GOAL['thresholds'] = [0.0800, 0.1200]
#first 3 elements are lead extensions for different densities and last element is lead bend radius multiplication factor (bend radius = factor * lead diameter)
AXIAL_LEAD_GOAL['range1'] = [0.1200, 0.1000, 0.0800, 1.0] #<=0.8mm
AXIAL_LEAD_GOAL['range2'] = [0.2200, 0.1800, 0.1500, 1.5] #>0.8mm and <=1.2mm
AXIAL_LEAD_GOAL['range3'] = [0.2800, 0.2400, 0.2000, 2.0] #>1.2mm

"""
	////////////////////
	// Pad attributes //
	////////////////////
"""
PAD_ATTRIBUTES = {}
PAD_ATTRIBUTES['oblongPadCornerRadiusSize'] = 0.5 #50% of min(pad width, pad height)
PAD_ATTRIBUTES['roundedPadCornerRadiusSizeLimit'] = 250

"""
	/////////////////////////////////
	// Assembly outline attributes //
	/////////////////////////////////
"""
ASSEMBLY_OUTLINE_ATTRIBUTES = {}
ASSEMBLY_OUTLINE_ATTRIBUTES['StrokeWidth'] = 120
ASSEMBLY_OUTLINE_ATTRIBUTES['MappingTypeToBodyMax'] = 'Maximum'
ASSEMBLY_OUTLINE_ATTRIBUTES['MappingTypeToBodyNom'] = 'Nominal'
ASSEMBLY_OUTLINE_ATTRIBUTES['MappingTypeToBodyMin'] = 'Minimum'
	
"""
	///////////////////////////
	// Silkscreen attributes //
	///////////////////////////
"""
SILKSCREEN_ATTRIBUTES = {}
SILKSCREEN_ATTRIBUTES['MappingTypeToBodyMax'] = 'Maximum'
SILKSCREEN_ATTRIBUTES['MappingTypeToBodyNom'] = 'Nominal'
SILKSCREEN_ATTRIBUTES['MappingTypeToBodyMin'] = 'Minimum'
SILKSCREEN_ATTRIBUTES['StrokeWidth'] = 0.0120
SILKSCREEN_ATTRIBUTES['Clearance'] = 0.0254  #gap between silkscreen and pad edge (10 mil)
SILKSCREEN_ATTRIBUTES['PinMarkerDotClearance'] = 0.0254 #gap between dot and pad edge (10 mil)
SILKSCREEN_ATTRIBUTES['dotPinMarkerSize'] = 0.0500
#silkscreen corner clip - percentage of body length or width used for aluminum electrolytic
#percentage of minimum of body length and width for BGA
SILKSCREEN_ATTRIBUTES['CornerClipPercentage'] = 0.25


"""
	/////////////////////////////////
	// Package specific attributes //
	/////////////////////////////////
"""
PACKAGE_ATTRIBUTES = {}
PACKAGE_ATTRIBUTES['cornerClipAmount'] = 0.3  	#for DFN (% of body height)
PACKAGE_ATTRIBUTES['extendedEdgeTol'] = 0.0165 	#for TO,DPAK package extended edge tolerence

"""
	///////////////////////////
	// Property attributes   //
	///////////////////////////
"""
PROPERTY_ATTRIBUTES = {}
PROPERTY_ATTRIBUTES['font'] = "proportional"
PROPERTY_ATTRIBUTES['fontSize'] = 0.1270
PROPERTY_ATTRIBUTES['fontUnit'] = 'μm'
PROPERTY_ATTRIBUTES['alignment'] = 'middle'
PROPERTY_ATTRIBUTES['clearance'] = 0.0635

"""
	//////////////////////////////
	// Fabrication attributes   //
	//////////////////////////////
"""

FABRICATION_ATTRIBUTES = {}
FABRICATION_ATTRIBUTES['minAnnularRingWidth'] = 0.0050
FABRICATION_ATTRIBUTES['allowance'] = [0.0600, 0.0500, 0.0400] #TODO: Validate. Is taken from IPC7351C?
