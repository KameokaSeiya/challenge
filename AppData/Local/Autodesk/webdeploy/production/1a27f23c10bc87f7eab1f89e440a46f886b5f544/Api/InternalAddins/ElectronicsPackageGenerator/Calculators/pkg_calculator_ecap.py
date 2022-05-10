# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules

# this class defines the package Calculator for the ECAP Package.
class PackageCalculatorEcap(pkg_calculator.PackageCalculator):
	
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
		model_data['b'] = self.ui_data['padHeightMax']
		model_data['D1'] = self.ui_data['bodyWidthMax']	

        #optional params send only D2 and L for 3D model
		if self.ui_data['optionalDimension'] == constant.DIMENSION_OPTIONS_LEAD_SPAN:
			model_data['L'] = self.ui_data['padWidthMax']
			model_data['D2'] = self.ui_data['terminalGapMax']
		elif self.ui_data['optionalDimension'] == constant.DIMENSION_OPTIONS_TERMINAL_GAP:
			model_data['L'] = self.ui_data['padWidthMax']
			model_data['D2'] = self.ui_data['horizontalLeadToLeadSpanMax'] - self.ui_data['padWidthMax']*2
		elif self.ui_data['optionalDimension'] == constant.DIMENSION_OPTIONS_TERMINAL_LEN:
			model_data['D2'] = self.ui_data['terminalGapMax']
			model_data['L'] = self.ui_data['horizontalLeadToLeadSpanMax'] - self.ui_data['terminalGapMax']*2

		return model_data

	# overwrite the smd alorithm for this package only.
	def get_footprint_smd_data(self, toe_goal, heel_goal, side_goal):


		fab_tol = self.ui_data['fabricationTolerance']
		place_tol = self.ui_data['placementTolerance']

		if self.ui_data['optionalDimension'] == constant.DIMENSION_OPTIONS_LEAD_SPAN:
			s_max = self.ui_data['terminalGapMax']
			s_min = self.ui_data['terminalGapMin']
			
			lead_span_max = s_max + self.ui_data['padWidthMax']*2
			lead_span_min = s_min + self.ui_data['padWidthMin']*2
			lead_span_mean = (lead_span_max+lead_span_min)/2

			s_tol = s_max - s_min
			t_tol = self.ui_data['padWidthMax'] - self.ui_data['padWidthMin']
			l_tol = math.sqrt(s_tol * s_tol + 2 * t_tol * t_tol) / 2
			#update leadspan 
			lead_span_max = lead_span_mean + l_tol/2
			lead_span_min = lead_span_mean - l_tol/2

			l_range = lead_span_max - lead_span_min
			t_range = t_tol

		elif self.ui_data['optionalDimension'] == constant.DIMENSION_OPTIONS_TERMINAL_GAP:
			s_max = self.ui_data['horizontalLeadToLeadSpanMax'] - self.ui_data['padWidthMin']*2
			s_min = self.ui_data['horizontalLeadToLeadSpanMin'] - self.ui_data['padWidthMax']*2
			s_tol = s_max - s_min
			t_tol = self.ui_data['padWidthMax'] - self.ui_data['padWidthMin']
			l_tol = self.ui_data['horizontalLeadToLeadSpanMax'] - self.ui_data['horizontalLeadToLeadSpanMin']

			l_range = l_tol
			t_range = t_tol

			lead_span_max = self.ui_data['horizontalLeadToLeadSpanMax']
			lead_span_min = self.ui_data['horizontalLeadToLeadSpanMin']

		elif self.ui_data['optionalDimension'] == constant.DIMENSION_OPTIONS_TERMINAL_LEN:
			pad_width_max = self.ui_data['horizontalLeadToLeadSpanMax'] - self.ui_data['terminalGapMin']
			pad_width_min = self.ui_data['horizontalLeadToLeadSpanMin'] - self.ui_data['terminalGapMax']
			pad_width_mean = (pad_width_max + pad_width_min)/2

			s_max = self.ui_data['terminalGapMax']
			s_min = self.ui_data['terminalGapMin']
			s_tol = s_max - s_min
			l_tol = self.ui_data['horizontalLeadToLeadSpanMax'] - self.ui_data['horizontalLeadToLeadSpanMin']
			t_tol = math.sqrt(s_tol * s_tol + l_tol * l_tol) / 2
			pad_width_min = pad_width_mean - l_tol/2
			pad_width_max = pad_width_mean + l_tol/2

			l_range = l_tol
			t_range = pad_width_max - pad_width_min

			lead_span_max = self.ui_data['horizontalLeadToLeadSpanMax']
			lead_span_min = self.ui_data['horizontalLeadToLeadSpanMin']

		w_range = self.ui_data['padHeightMax'] - self.ui_data['padHeightMin']
		s_tol_rms = math.sqrt(l_range * l_range + t_range * t_range*2)
		s_diff = s_tol - s_tol_rms

		# check the terminalGapMax
		if self.ui_data['terminalGapMax'] == 0:
			s_max_actual = s_max - s_diff/2
			s_min_actual = s_min + s_diff/2
		else:
			s_max_actual = s_max
			s_min_actual = s_min

		s_diff_actual = s_max_actual - s_min_actual		
		
		toe_tol = math.sqrt((l_range * l_range) + 4 * (fab_tol * fab_tol) + 4 * (place_tol * place_tol))
		Z_max = lead_span_min + toe_tol + (2 * toe_goal)
		heel_tol = math.sqrt((s_diff_actual * s_diff_actual) + 4 * (fab_tol*fab_tol) + 4 * (place_tol*place_tol))
		g_min = s_max_actual - (2 * heel_goal) - heel_tol 
		side_tol = math.sqrt((w_range * w_range) + 4 * (fab_tol * fab_tol) + 4 * (place_tol * place_tol))
		y_ref = self.ui_data['padHeightMin'] + 2 * side_goal + side_tol

		C = (Z_max + g_min)/2
		X = (Z_max - g_min)/2
		Y = y_ref

		return X, Y, C

	def get_footprint(self):
		
		footprint_data = []

		if self.ui_data['bodyHeightMax'] >= ipc_rules.PAD_GOAL_ALUMI_ELECTROLYTIC['bodyHeightTh']:
			toe_goal = ipc_rules.PAD_GOAL_ALUMI_ELECTROLYTIC['toeFilletMaxMedMinGTE'][self.ui_data['densityLevel']]
			heel_goal = ipc_rules.PAD_GOAL_ALUMI_ELECTROLYTIC['heelFilletMaxMedMinGTE'][self.ui_data['densityLevel']]
			side_goal = ipc_rules.PAD_GOAL_ALUMI_ELECTROLYTIC['sideFilletMaxMedMinGTE'][self.ui_data['densityLevel']]
		else:
			toe_goal = ipc_rules.PAD_GOAL_ALUMI_ELECTROLYTIC['toeFilletMaxMedMinLT'][self.ui_data['densityLevel']]
			heel_goal = ipc_rules.PAD_GOAL_ALUMI_ELECTROLYTIC['heelFilletMaxMedMinLT'][self.ui_data['densityLevel']]
			side_goal = ipc_rules.PAD_GOAL_ALUMI_ELECTROLYTIC['sideFilletMaxMedMinLT'][self.ui_data['densityLevel']]

		#calculate the smd data. 
		if self.ui_data['hasCustomFootprint'] :
			pad_width = self.ui_data['customPadLength']
			pad_height = self.ui_data['customPadWidth']
			pin_pitch = self.ui_data['customPadToPadGap'] + self.ui_data['customPadLength']
		else:
			pad_width, pad_height, pin_pitch = self.get_footprint_smd_data(toe_goal, heel_goal, side_goal) 	

		# initiate the left pad data 
		left_pad = footprint.FootprintSmd(-pin_pitch/2, 0, pad_width, pad_height)
		left_pad.name = '1'
		left_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(left_pad)

		# initiate the right pad data 
		right_pad = footprint.FootprintSmd(pin_pitch/2, 0, pad_width, pad_height)
		right_pad.name = '2'
		right_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(right_pad)
		

		#build the silkscreen 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])
		intersect_y = pad_height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']
		intersect_x = body_width/4

		clearance = ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']
		top_edge_y = left_pad.center_point_y + pad_height/2 + clearance

		y2 = body_length/2 - ipc_rules.SILKSCREEN_ATTRIBUTES['CornerClipPercentage'] * (body_length - pad_height)
		x3 = -body_width/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['CornerClipPercentage'] * (body_width - pad_height)

		# top side silkscreen. need consider the clearance with the smd pads
		line_top_1 = footprint.FootprintWire(-body_width/2, top_edge_y, -body_width/2 , y2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_top_1)		

		line_top_2 = footprint.FootprintWire(-body_width/2, y2, x3, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_top_2)

		line_top_3 = footprint.FootprintWire(x3, body_length/2, body_width/2, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_top_3)	

		line_top_4 = footprint.FootprintWire(body_width/2, body_length/2, body_width/2, top_edge_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_top_4)	

		line_bottom_4 = footprint.FootprintWire(body_width/2, -body_length/2, body_width/2, -top_edge_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_bottom_4)

		line_bottom_3 = footprint.FootprintWire(x3, -body_length/2, body_width/2, -body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_bottom_3)	

		line_bottom_2 = footprint.FootprintWire(-body_width/2, -y2, x3, -body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_bottom_2)	

		line_bottom_1 = footprint.FootprintWire(-body_width/2, -top_edge_y, -body_width/2 , -y2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_bottom_1)	

		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyWidthMax'], ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		#build the text
		self.build_footprint_text(footprint_data)

		return footprint_data

	def get_ipc_package_name(self):
		#family name + Base Body Size X Height + density level
		pkg_name = 'CAPAE'  
		pkg_name += str(int(((self.ui_data['bodyWidthMax'] * 1000 +self.ui_data['bodyWidthMin'] * 1000 )/2))) 
		pkg_name += 'X' + str(int((self.ui_data['bodyHeightMax']*1000))) 
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_density_level_for_smd(self.ui_data['densityLevel'])		
		return pkg_name

	def get_ipc_package_description(self):
	
		ao = addin_utility.AppObjects()
		unit = 'mm'	

		body_width = ao.units_manager.convert((self.ui_data['bodyWidthMax']+self.ui_data['bodyWidthMin'])/2, 'cm', unit)
		body_height = ao.units_manager.convert(self.ui_data['bodyHeightMax'], 'cm', unit)

		short_description = 'ECAP (Aluminum Electrolytic Capacitor), '
		short_description += str('{:.2f}'.format(round(body_width,2))) + ' X ' + str('{:.2f}'.format(round(body_height,2))) + ' ' + unit + ' body'
			
		full_description = 'ECAP (Aluminum Electrolytic Capacitor) package'
		full_description += ' with body size ' + str('{:.2f}'.format(round(body_width,2))) + ' X ' + str('{:.2f}'.format(round(body_height,2))) + ' ' + unit
           
		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		super().get_ipc_package_metadata()
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "ECAP"
		if self.ui_data["optionalDimension"] == "Optional_D":
			self.metadata['leadSpan'] = str(round(ao.units_manager.convert((self.ui_data['terminalGapMin']+self.ui_data['terminalGapMax'])/2 + self.ui_data['padWidthMin']+ self.ui_data['padWidthMax'], 'cm', 'mm'), 4))
		else:
			self.metadata['leadSpan'] = str(round(ao.units_manager.convert((self.ui_data['horizontalLeadToLeadSpanMax']+self.ui_data['horizontalLeadToLeadSpanMin'])/2, 'cm', 'mm'), 4))		
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])

		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_ECAP, PackageCalculatorEcap) 