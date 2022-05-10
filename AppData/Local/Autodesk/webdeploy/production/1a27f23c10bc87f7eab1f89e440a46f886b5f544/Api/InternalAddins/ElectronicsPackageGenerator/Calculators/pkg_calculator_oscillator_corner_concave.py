# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules
from ..Utilities.localization import _LCLZ

class PackageCalculatorCornerConcave(pkg_calculator.PackageCalculator):
	
	# initialize the data members
	def __init__(self, pkg_type: str):
		super().__init__(pkg_type)
		#self.pkg_type = constant.PKG_TYPE_CHIP

	def get_general_footprint(self):
		pass

	def get_3d_model_data(self):
		pass

	# process the data for 3d model generator	
	def get_ipc_3d_model_data(self):
		model_data = {}
		model_data['type'] = self.pkg_type
		model_data['A'] = self.ui_data['bodyHeightMax']
		model_data['D'] = self.ui_data['bodyWidthMax']
		model_data['E'] = self.ui_data['bodyLengthMax']	
		model_data['D1'] = self.ui_data['horizontalTerminalGapMax']	
		model_data['E1'] = self.ui_data['verticalTerminalGapMax']

		return model_data

	def get_footprint_smd_data(self, s_min, s_max, pad_width_min, pad_width_max, pad_height_min, pad_height_max, toe_goal, heel_goal, side_goal, lead_to_lead_span_min):

		fab_tol = self.ui_data['fabricationTolerance']
		place_tol = self.ui_data['placementTolerance']

		s_tol = s_max - s_min
		t_tol = pad_width_max - pad_width_min

		l_range = 0 #considered 0 for corner concave
		t_range = pad_width_max - pad_width_min
		w_range = pad_height_max - pad_height_min
		s_tol_rms = math.sqrt(l_range * l_range + t_range * t_range*2)
		s_diff = s_tol - s_tol_rms

		s_max_actual = s_max
		s_min_actual = s_min
		s_diff_actual = s_max_actual - s_min_actual		
		
		toe_tol = math.sqrt((l_range * l_range) + 4 * (fab_tol * fab_tol) + 4 * (place_tol * place_tol))
		Z_max = lead_to_lead_span_min + toe_tol + (2 * toe_goal)
		heel_tol = math.sqrt((s_diff_actual * s_diff_actual) + 4 * (fab_tol*fab_tol) + 4 * (place_tol*place_tol))

		g_min = s_max_actual - (2 * heel_goal) - heel_tol 
		side_tol = math.sqrt((w_range * w_range) + 4 * (fab_tol * fab_tol) + 4 * (place_tol * place_tol))
		y_ref = pad_height_min + 2 * side_goal + side_tol

		C = (Z_max + g_min)/2
		X = (Z_max - g_min)/2
		Y = y_ref

		return X, Y, C
		
	def get_footprint(self):

		footprint_data = []

		toe_goal = ipc_rules.PAD_GOAL_OSCILLATOR_CORNERCONCAVE['toeFilletMaxMedMin'][self.ui_data['densityLevel']]
		heel_goal = ipc_rules.PAD_GOAL_OSCILLATOR_CORNERCONCAVE['heelFilletMaxMedMin'][self.ui_data['densityLevel']]
		side_goal = ipc_rules.PAD_GOAL_OSCILLATOR_CORNERCONCAVE['sideFilletMaxMedMin'][self.ui_data['densityLevel']]

		horizontal_lead_to_lead_span_avg = 	(self.ui_data['bodyWidthMax'] + self.ui_data['bodyWidthMin']) / 2
		vertical_lead_to_lead_span_avg = 	(self.ui_data['bodyLengthMax'] + self.ui_data['bodyLengthMin']) / 2

		pad_width_min = (self.ui_data['bodyWidthMin'] - self.ui_data['horizontalTerminalGapMin'])/2	
		pad_width_max = (self.ui_data['bodyWidthMax'] - self.ui_data['horizontalTerminalGapMax'])/2	
		pad_height_min = (self.ui_data['bodyLengthMin'] - self.ui_data['verticalTerminalGapMin'])/2
		pad_height_max = (self.ui_data['bodyLengthMax'] - self.ui_data['verticalTerminalGapMax'])/2

		if self.ui_data['hasCustomFootprint'] :
			horizontal_pitch = self.ui_data['customPadToPadGap'] + self.ui_data['customPadLength']
			vertical_pitch = self.ui_data['customPadToPadGap1'] + self.ui_data['customPadWidth']
			pad_width = self.ui_data['customPadLength']
			pad_height = self.ui_data['customPadWidth']

		else :
			if vertical_lead_to_lead_span_avg < horizontal_lead_to_lead_span_avg:

				terminal_gap_min = self.ui_data['verticalTerminalGapMin']
				terminal_gap_max = self.ui_data['verticalTerminalGapMax']

				X, Y, C = self.get_footprint_smd_data(terminal_gap_min, terminal_gap_max, pad_width_min, 
    					pad_width_max, pad_height_min, pad_height_max, toe_goal, heel_goal, side_goal, self.ui_data['bodyLengthMin'])

				pad_height = X
				vertical_pitch = C

			else :

				terminal_gap_min = self.ui_data['horizontalTerminalGapMin']
				terminal_gap_max = self.ui_data['horizontalTerminalGapMax']

				X, Y, C = self.get_footprint_smd_data(terminal_gap_min, terminal_gap_max, pad_width_min, 
    					pad_width_max, pad_height_min, pad_height_max, toe_goal, heel_goal, side_goal, self.ui_data['bodyWidthMin'])

				pad_width = X
				horizontal_pitch = C

			#update terminal gap for other dimension (derived from other dimension's terminal gap)
			if vertical_lead_to_lead_span_avg < horizontal_lead_to_lead_span_avg : 
				terminal_gap_max = self.ui_data['horizontalTerminalGapMax']
				terminal_gap_min = self.ui_data['horizontalTerminalGapMax']	- (self.ui_data['verticalTerminalGapMax'] - self.ui_data['verticalTerminalGapMin'])

				X, Y, C = self.get_footprint_smd_data(terminal_gap_min, terminal_gap_max, pad_width_min, 
    					pad_width_max, pad_height_min, pad_height_max, toe_goal, heel_goal, side_goal, self.ui_data['bodyWidthMin'])

				pad_width = X
				horizontal_pitch = C

			else:

				terminal_gap_max = self.ui_data['verticalTerminalGapMax']
				terminal_gap_min = self.ui_data['verticalTerminalGapMax']	- (self.ui_data['horizontalTerminalGapMax'] - self.ui_data['horizontalTerminalGapMin'])

				X, Y, C = self.get_footprint_smd_data(terminal_gap_min, terminal_gap_max, pad_width_min, 
    					pad_width_max, pad_height_min, pad_height_max, toe_goal, heel_goal, side_goal, self.ui_data['bodyLengthMin'])

				pad_height = X
				vertical_pitch = C

		#pad1
		bottom_left_pad = footprint.FootprintSmd(-horizontal_pitch/2, -vertical_pitch/2, pad_width, pad_height)
		bottom_left_pad.name = '1'
		bottom_left_pad .roundness= footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(bottom_left_pad)

		#pad2
		bottom_right_pad = footprint.FootprintSmd(horizontal_pitch/2, -vertical_pitch/2, pad_width, pad_height)
		bottom_right_pad.name = '2'
		bottom_right_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(bottom_right_pad)

		#pad3
		top_right_pad = footprint.FootprintSmd(horizontal_pitch/2, vertical_pitch/2, pad_width, pad_height)
		top_right_pad.name = '3'
		top_right_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(top_right_pad)

		#pad4
		top_left_pad = footprint.FootprintSmd(-horizontal_pitch/2, vertical_pitch/2, pad_width, pad_height)
		top_left_pad.name = '4'
		top_left_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(top_left_pad)

		#build the silkscreen
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])	

		last_pad = footprint_data[3]
		first_pad = footprint_data[0]
		third_pad = footprint_data[2]
		
		last_pad_left_x = last_pad.center_point_x - last_pad.width/2
		last_pad_left_y = last_pad.center_point_y - last_pad.height/2

		last_pad_right_x = last_pad.center_point_x + last_pad.width/2
		last_pad_right_y = last_pad.center_point_y + last_pad.height/2

		first_pad_left_x = first_pad.center_point_x - last_pad.width/2
		first_pad_left_y = first_pad.center_point_y - last_pad.height/2

		first_pad_right_x = first_pad.center_point_x + last_pad.width/2
		first_pad_right_y = first_pad.center_point_y + last_pad.height/2

		third_pad_x = third_pad.center_point_x - third_pad.width/2
		third_pad_y = third_pad.center_point_y + third_pad.height/2

		#left 
		line_left = footprint.FootprintWire( last_pad_left_x - ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2, last_pad_left_y - ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'],
								 first_pad_left_x - ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2, first_pad_right_y + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'], ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		footprint_data.append(line_left)

		#right
		line_right = line_left = footprint.FootprintWire( -last_pad_left_x + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2, -last_pad_left_y + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'],
								 -first_pad_left_x + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2, -first_pad_right_y - ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'], ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		
		footprint_data.append(line_right)

		#top
		line_top = footprint.FootprintWire( last_pad_right_x + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'], last_pad_right_y + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2,
								 third_pad_x - ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'], third_pad_y + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		footprint_data.append(line_top)

		#bottom
		line_bottom = footprint.FootprintWire( -last_pad_right_x - ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'], -last_pad_right_y - ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2,
								 -third_pad_x + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'], -third_pad_y - ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		footprint_data.append(line_bottom)

		#create pin one marker
		self.build_silkscreen_pin_one_marker(footprint_data, first_pad.center_point_x, first_pad.center_point_y, pad_width, pad_height, body_width, True)

		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		#build the textbody_length
		self.build_footprint_text(footprint_data,0)

		return footprint_data

	def get_ipc_package_name(self):

		# Name + Body Length X Body Width X Height + density level
		pkg_name = 'OSCCC'  
		pkg_name += str(int(((self.ui_data['bodyWidthMax'] * 1000 +self.ui_data['bodyWidthMin'] * 1000)/2))) 
		pkg_name += 'X' + str(int(((self.ui_data['bodyLengthMax'] * 1000 +self.ui_data['bodyLengthMin']* 1000 )/2)))
		pkg_name += 'X' + str(int((self.ui_data['bodyHeightMax']*1000))) 
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_density_level_for_smd(self.ui_data['densityLevel'])		
		return pkg_name

	def get_ipc_package_description(self):
	
		ao = addin_utility.AppObjects()
		unit = 'mm'	

		short_description = 'Oscillator Corner Concave, '
		short_description += self.get_body_description(True, False) + unit + ' body'

		full_description = 'Oscillator Corner Concave package'
		full_description += self.get_body_description(False, False) + unit

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		isPackageRotated = True
		super().get_ipc_package_metadata(isPackageRotated)
		self.metadata['ipcFamily'] = "OSCIL"
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_CORNERCONCAVE, PackageCalculatorCornerConcave) 