# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules

# this class defines the package Calculator for the ECAP Package.
class PackageCalculatorDpak(pkg_calculator.PackageCalculator):
	
	# initialize the data members
	def __init__(self, pkg_type: str):
		super().__init__(pkg_type)

	def get_general_footprint(self):
		pass

	def get_3d_model_data(self):
		pass

	# process the data for 3d model generator	
	def get_ipc_3d_model_data(self):
		model_data = {}
		model_data['type'] = self.pkg_type
		model_data['A'] = self.ui_data['bodyHeightMax']
		model_data['E'] = self.ui_data['horizontalLeadToLeadSpanMax']
		model_data['L'] = self.ui_data['padWidthMax']
		model_data['L1'] = self.ui_data['extendedEdgeWidth']
		model_data['b'] = self.ui_data['padHeightMax']
		model_data['b1'] = self.ui_data['oddPadHeightMax']
		model_data['E1'] = self.ui_data['bodyWidthMax']
		model_data['E2'] = self.ui_data['oddPadWidthMax']
		model_data['D'] = self.ui_data['bodyLengthMax']
		model_data['e'] = self.ui_data['verticalPinPitch']
		model_data['DPins'] = self.ui_data['horizontalPadCount']

		if self.ui_data['hasTruncatedPin'] == True:
			model_data['truncatedFlag'] = 1
		else:
			model_data['truncatedFlag'] = 0
		return model_data

	def get_footprint_smd_data(self, pad_width_max, pad_width_min, pad_height_max, pad_height_min, toe_goal, heel_goal, side_goal):

		fab_tol = self.ui_data['fabricationTolerance']
		place_tol = self.ui_data['placementTolerance']

		s_max = self.ui_data['horizontalLeadToLeadSpanMax'] - pad_width_min*2
		s_min = self.ui_data['horizontalLeadToLeadSpanMin'] - pad_width_max*2
		s_tol = s_max - s_min
		t_tol = pad_width_max - pad_width_min

		l_range = self.ui_data['horizontalLeadToLeadSpanMax'] - self.ui_data['horizontalLeadToLeadSpanMin']
		t_range = pad_width_max - pad_width_min
		w_range = pad_height_max - pad_height_min
		s_tol_rms = math.sqrt(l_range * l_range + t_range * t_range*2)
		s_diff = s_tol - s_tol_rms

		s_max_actual = s_max - s_diff/2
		s_min_actual = s_min + s_diff/2
		s_diff_actual = s_max_actual - s_min_actual		
		
		toe_tol = math.sqrt((l_range * l_range) + 4 * (fab_tol * fab_tol) + 4 * (place_tol * place_tol))
		Z_max = self.ui_data['horizontalLeadToLeadSpanMin'] + toe_tol + (2 * toe_goal)
		heel_tol = math.sqrt((s_diff_actual * s_diff_actual) + 4 * (fab_tol*fab_tol) + 4 * (place_tol*place_tol))

		#update heel goal based on pad
		if pad_width_max == self.ui_data['oddPadWidthMax']: #update only for odd pad
			update_heel_goal = False
		else:
			update_heel_goal = True

		# update heel goal depends on Smin, tTol, bodyWidthMax
		if update_heel_goal and t_tol <= 0.0500:
			if s_min <= self.ui_data['bodyWidthMax']:
				updatedGullWingHeelFilletMaxMedMinGT = [0.0250, 0.0150, 0.0050]
				heel_goal = updatedGullWingHeelFilletMaxMedMinGT[self.ui_data['densityLevel']]
			else:
				heel_goal = ipc_rules.PAD_GOAL_GULLWING['heelFilletMaxMedMinGT'][self.ui_data['densityLevel']]
		else:
			heel_goal = side_goal

		g_min = s_max_actual - (2 * heel_goal) - heel_tol 
		side_tol = math.sqrt((w_range * w_range) + 4 * (fab_tol * fab_tol) + 4 * (place_tol * place_tol))
		y_ref = pad_height_min + 2 * side_goal + side_tol

		C = (Z_max + g_min)/2
		X = (Z_max - g_min)/2
		Y = y_ref

		return X, Y, C

	def build_silkscreen_pin_one_marker(self, footprint_data, pin_one_x, pin_one_y, at_left):
		pin_marker_size = ipc_rules.SILKSCREEN_ATTRIBUTES['dotPinMarkerSize']
		clearance = ipc_rules.SILKSCREEN_ATTRIBUTES['PinMarkerDotClearance'] + pin_marker_size/2
		
		pin_marker_x = pin_one_x

		if at_left :
			pin_marker_y = pin_one_y
		else:
			pin_marker_y = pin_one_y + clearance

		pin_marker = footprint.FootprintCircle(pin_marker_x, pin_marker_y, 0, pin_marker_size/2)
		footprint_data.append(pin_marker)

	def build_assembly_body_outline(self, footprint_data, body_width, body_length, offset_x, offset_y, stroke_width):
		line_left = footprint.FootprintWire(-body_width /2 + offset_x, -body_length/2 + offset_y, -body_width/2 + offset_x, body_length/2 + offset_y, stroke_width)
		line_left.layer = 51
		footprint_data.append(line_left)
		line_top = footprint.FootprintWire(-body_width/2 + offset_x, body_length/2 + offset_y, body_width/2 + offset_x, body_length/2 + offset_y, stroke_width)
		line_top.layer = 51
		footprint_data.append(line_top)
		line_right = footprint.FootprintWire(body_width/2 + offset_x, body_length/2 + offset_y, body_width/2 + offset_x, -body_length/2 + offset_y, stroke_width)
		line_right.layer = 51
		footprint_data.append(line_right)
		line_bottom = footprint.FootprintWire(body_width/2 + offset_x, -body_length/2 + offset_y, -body_width/2 + offset_x, -body_length/2 + offset_y, stroke_width)
		line_bottom.layer = 51
		footprint_data.append(line_bottom)

	def get_footprint(self):
		
		footprint_data = []

		if self.ui_data['verticalPinPitch'] > ipc_rules.PAD_GOAL_GULLWING['pitchTh']:
			toe_goal = ipc_rules.PAD_GOAL_GULLWING['toeFilletMaxMedMinGT'][self.ui_data['densityLevel']]
			heel_goal = ipc_rules.PAD_GOAL_GULLWING['heelFilletMaxMedMinGT'][self.ui_data['densityLevel']]
			side_goal = ipc_rules.PAD_GOAL_GULLWING['sideFilletMaxMedMinGT'][self.ui_data['densityLevel']]
		else:
			toe_goal = ipc_rules.PAD_GOAL_GULLWING['toeFilletMaxMedMinLTE'][self.ui_data['densityLevel']]
			heel_goal = ipc_rules.PAD_GOAL_GULLWING['heelFilletMaxMedMinLTE'][self.ui_data['densityLevel']]
			side_goal = ipc_rules.PAD_GOAL_GULLWING['sideFilletMaxMedMinLTE'][self.ui_data['densityLevel']]

		#calculate the smd data for regular pins and odd pin
		if self.ui_data['hasCustomFootprint'] :
			#for custom footprint
			pad_width = self.ui_data['customPadWidth']
			pad_height = self.ui_data['customPadLength']
			pin_pitch = self.ui_data['customPadSpan1']  - self.ui_data['customPadWidth']
			odd_pad_width = self.ui_data['customOddPadWidth']
			odd_pad_height = self.ui_data['customOddPadLength']
			odd_pin_pitch = self.ui_data['customPadSpan1']  - self.ui_data['customOddPadWidth']
		else:
			pad_width, pad_height, pin_pitch = self.get_footprint_smd_data(self.ui_data['padWidthMax'], self.ui_data['padWidthMin'], self.ui_data['padHeightMax'], self.ui_data['padHeightMin'], toe_goal, heel_goal, side_goal)	
			odd_pad_width, odd_pad_height, odd_pin_pitch = self.get_footprint_smd_data(self.ui_data['oddPadWidthMax'], self.ui_data['oddPadWidthMin'], self.ui_data['oddPadHeightMax'], self.ui_data['oddPadHeightMin'],toe_goal, heel_goal, side_goal) 	 
		
		# build the left side smd 
		left_smd_count = self.ui_data['horizontalPadCount'] - 1
		pad_id = 1
		for i in range(0, self.ui_data['horizontalPadCount'] - 1):
			row_index = i % left_smd_count
			smd_pos_y = ((left_smd_count - 1)/2 - row_index) * self.ui_data['verticalPinPitch']

			if self.ui_data['hasTruncatedPin'] == True and i == math.floor(left_smd_count/2): 
				# skip the truncated pin
				continue
			
			left_pad = footprint.FootprintSmd(-pin_pitch/2, smd_pos_y, pad_width, pad_height)
			left_pad.name = str(pad_id)
			pad_id = pad_id + 1
			left_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(left_pad)

		# build the right side smd
		odd_pad = footprint.FootprintSmd(odd_pin_pitch/2 , 0, odd_pad_width, odd_pad_height)
		odd_pad.name = str(pad_id)
		odd_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(odd_pad)

		#build the silkscreen 
		stroke_width = ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'] #silkscreen width
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])
		bodyline_offset_x = (self.ui_data['horizontalLeadToLeadSpanMax'] + self.ui_data['horizontalLeadToLeadSpanMin'])/4 - body_width/2 - (self.ui_data['extendedEdgeWidth']- ipc_rules.PACKAGE_ATTRIBUTES['extendedEdgeTol'])
		body_right_line_offset = odd_pad.center_point_y + odd_pad.height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] 

		#top side silkscreen
		line_left = footprint.FootprintWire(- body_width/2 + bodyline_offset_x, body_length/2 , - body_width/2 + bodyline_offset_x, - body_length/2, stroke_width)
		footprint_data.append(line_left)
		line_top = footprint.FootprintWire(- body_width/2 + bodyline_offset_x, body_length/2, body_width/2 + bodyline_offset_x, body_length/2, stroke_width)
		footprint_data.append(line_top)
		line_top_right = footprint.FootprintWire(body_width/2 + bodyline_offset_x, body_length/2, body_width/2 + bodyline_offset_x, body_right_line_offset, stroke_width)
		footprint_data.append(line_top_right)
		line_bottom = footprint.FootprintWire(- body_width/2 + bodyline_offset_x, -body_length/2, body_width/2 + bodyline_offset_x, -body_length/2, stroke_width)
		footprint_data.append(line_bottom)
		line_bottom_right = footprint.FootprintWire(body_width/2 + bodyline_offset_x, -body_length/2, body_width/2 + bodyline_offset_x, -body_right_line_offset, stroke_width)
		footprint_data.append(line_bottom_right)

		# build the assembly body outline
		assembly_bodyline_offset_x = (self.ui_data['horizontalLeadToLeadSpanMax'] + self.ui_data['horizontalLeadToLeadSpanMin'])/4 - self.ui_data['bodyWidthMax']/2 - (self.ui_data['extendedEdgeWidth']- ipc_rules.PACKAGE_ATTRIBUTES['extendedEdgeTol'])
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], assembly_bodyline_offset_x, 0, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		first_left_pad = footprint_data[0]
		# pin one marker
		pin_one_x = first_left_pad.center_point_x
		pin_one_y = first_left_pad.center_point_y + first_left_pad.height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['PinMarkerDotClearance'] + ipc_rules.SILKSCREEN_ATTRIBUTES['dotPinMarkerSize']/2
		self.build_silkscreen_pin_one_marker(footprint_data, pin_one_x, pin_one_y, True)
		
		#build the text
		self.build_footprint_text(footprint_data)

		return footprint_data

	def get_ipc_package_name(self):

		#Name + Pitch + P + Lead Span Nominal + X + Height Max - Pin Qty density level
		pin_count = self.ui_data['horizontalPadCount'] 
		if self.ui_data['hasTruncatedPin'] == True: pin_count = pin_count - 1
		
		pkg_name = 'TO'  
		pkg_name += str(int((self.ui_data['verticalPinPitch']*1000))) + 'P'
		pkg_name += str(int(((self.ui_data['horizontalLeadToLeadSpanMax']*1000 + self.ui_data['horizontalLeadToLeadSpanMin']*1000)/2))) + 'X' #rounding issue 1053.9999999999998 => 1053 so multiply by 1000 first.
		pkg_name += str(int((self.ui_data['bodyHeightMax']*1000))) + '-'
		pkg_name += str(pin_count)
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_density_level_for_smd(self.ui_data['densityLevel'])	
		return pkg_name

	def get_ipc_package_description(self):
	
		ao = addin_utility.AppObjects()
		unit = 'mm'	

		pin_count = self.ui_data['horizontalPadCount'] 
		if self.ui_data['hasTruncatedPin'] == True: pin_count = pin_count - 1
		lead_span = ao.units_manager.convert((self.ui_data['horizontalLeadToLeadSpanMax']+self.ui_data['horizontalLeadToLeadSpanMin'])/2, 'cm', unit)
		pin_pitch = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', unit)

		short_description = str(pin_count) + '-TO, DPAK, '
		short_description += str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch, '
		short_description += str('{:.2f}'.format(round(lead_span,2))) + ' ' + unit + ' span, '
		short_description += self.get_body_description(True,True) + unit + ' body'
			
		full_description = str(pin_count) + '-pin TO, DPAK package with '
		full_description += str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch, '
		full_description += str('{:.2f}'.format(round(lead_span,2))) + ' ' + unit + ' span'
		full_description += self.get_body_description(False,True) + unit

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		super().get_ipc_package_metadata()
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "DPAK"
		self.metadata["pitch"] = str(round(ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm'),4))
		self.metadata['leadSpan'] = str(round(ao.units_manager.convert((self.ui_data['horizontalLeadToLeadSpanMax']+self.ui_data['horizontalLeadToLeadSpanMin'])/2, 'cm', 'mm'), 4))
		if self.ui_data['hasTruncatedPin']:
			self.metadata["pins"] = str(self.ui_data['horizontalPadCount']-1)
		else:	
			self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
			
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_DPAK, PackageCalculatorDpak) 