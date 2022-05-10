# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules

# this class defines the package Calculator for the ECAP Package.
class PackageCalculatorSotfl(pkg_calculator.PackageCalculator):
	
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
		model_data['E1'] = self.ui_data['bodyWidthMax']
		model_data['D'] = self.ui_data['bodyLengthMax']
		model_data['b'] = self.ui_data['padHeightMax']
		model_data['E'] = self.ui_data['horizontalLeadToLeadSpanMax']
		model_data['e'] = self.ui_data['verticalPinPitch']
		model_data['L'] = (self.ui_data['padWidthMax'] + self.ui_data['padWidthMin'])/2
		model_data['DPins'] = self.ui_data['horizontalPadCount']
		return model_data
		
	def get_footprint(self):
		
		footprint_data = []

		toe_goal = ipc_rules.PAD_GOAL_SMALLOUTLINEFLATLEAD['toeFilletMaxMedMin'][self.ui_data['densityLevel']]
		heel_goal = ipc_rules.PAD_GOAL_SMALLOUTLINEFLATLEAD['heelFilletMaxMedMin'][self.ui_data['densityLevel']]
		side_goal = ipc_rules.PAD_GOAL_SMALLOUTLINEFLATLEAD['sideFilletMaxMedMin'][self.ui_data['densityLevel']]


		W_min = self.ui_data['padHeightMin']
		W_max = self.ui_data['padHeightMax']
		L_min = self.ui_data['horizontalLeadToLeadSpanMin']
		L_max = self.ui_data['horizontalLeadToLeadSpanMax']		
		T_min = self.ui_data['padWidthMin']
		T_max = self.ui_data['padWidthMax']

		#calculate the smd data. 
		if self.ui_data['hasCustomFootprint'] :
			#for custom footprint
			pad_width = self.ui_data['customPadWidth']
			pad_height = self.ui_data['customPadLength']
			pin_pitch = self.ui_data['customPadPitch']
		else :
			pad_width, pad_height, pin_pitch = self.get_footprint_smd_data(L_min, L_max, T_min, T_max, W_min, W_max, toe_goal, heel_goal, side_goal) 		

		left_smd_count = math.ceil(self.ui_data['horizontalPadCount'] / 2)
		right_smd_count = self.ui_data['horizontalPadCount'] - left_smd_count
		# build the left side smd 
		for i in range(0, left_smd_count):
			row_index = i % left_smd_count
			if self.ui_data['horizontalPadCount']==3 or self.ui_data['horizontalPadCount'] == 4:
				smd_pos_y = ((left_smd_count - 1)/2 - row_index) *2 * self.ui_data['verticalPinPitch']
			else:
				smd_pos_y = ((left_smd_count - 1)/2 - row_index) * self.ui_data['verticalPinPitch']

			left_pad = footprint.FootprintSmd(-pin_pitch/2, smd_pos_y, pad_width, pad_height)
			left_pad.name = str(i + 1)
			left_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(left_pad)

		# build the right side smd
		for i in range(0, right_smd_count):
			row_index = right_smd_count - 1 - i % right_smd_count
			if self.ui_data['horizontalPadCount']==5 or self.ui_data['horizontalPadCount'] == 4:
				smd_pos_y = ((right_smd_count - 1)/2 - row_index) *2 * self.ui_data['verticalPinPitch']
			else:
				smd_pos_y = ((right_smd_count - 1)/2 - row_index) * self.ui_data['verticalPinPitch']
			
			right_pad = footprint.FootprintSmd(pin_pitch/2, smd_pos_y, pad_width, pad_height)
			right_pad.name = str (left_smd_count + i + 1)
			right_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(right_pad)

		#build the silkscreen 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])
		first_left_pad = footprint_data[0]

		# pin one marker
		self.build_silkscreen_pin_one_marker(footprint_data, first_left_pad.center_point_x, first_left_pad.center_point_y, first_left_pad.width, first_left_pad.height, body_width, False)

		top_edge_y = first_left_pad.center_point_y + first_left_pad.height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']
		stroke_width = ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']
		#top side silkscreen
		if top_edge_y + stroke_width/2 > body_length/2:
			bbox_y_max = top_edge_y + stroke_width/2
			bbox_y_min = -bbox_y_max

			line_top = footprint.FootprintWire(-body_width/2, top_edge_y + stroke_width/2, body_width/2, top_edge_y + stroke_width/2, stroke_width)
			footprint_data.append(line_top)
			line_bottom = footprint.FootprintWire(-body_width/2, -top_edge_y - stroke_width/2, body_width/2, -top_edge_y - stroke_width/2, stroke_width)
			footprint_data.append(line_bottom)
		else:
			bbox_y_max = body_length/2
			bbox_y_min = -bbox_y_max

			line_top_left = footprint.FootprintWire(-body_width/2, top_edge_y, -body_width/2, body_length/2, stroke_width)
			footprint_data.append(line_top_left)
			line_top = footprint.FootprintWire(-body_width/2, body_length/2, body_width/2, body_length/2, stroke_width)
			footprint_data.append(line_top)
			line_top_right = footprint.FootprintWire(body_width/2, body_length/2, body_width/2, top_edge_y, stroke_width)
			footprint_data.append(line_top_right)

			line_bottom_left = footprint.FootprintWire(-body_width/2, -top_edge_y, -body_width/2, -body_length/2, stroke_width)
			footprint_data.append(line_bottom_left)
			line_bottom = footprint.FootprintWire(-body_width/2, -body_length/2, body_width/2, -body_length/2, stroke_width)
			footprint_data.append(line_bottom)
			line_bottom_right = footprint.FootprintWire(body_width/2, -body_length/2, body_width/2, - top_edge_y, stroke_width)
			footprint_data.append(line_bottom_right)

		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], stroke_width)

		#build the text
		self.build_footprint_text(footprint_data)

		return footprint_data

	def get_ipc_package_name(self):
		#Name + Pitch + P + Lead Span Nominal + X + Height Max - Pin Qty
		pkg_name = 'SOTFL'  
		pkg_name += str(int((self.ui_data['verticalPinPitch']*1000))) + 'P'
		pkg_name += str(int(((self.ui_data['horizontalLeadToLeadSpanMax'] * 1000 + self.ui_data['horizontalLeadToLeadSpanMin'] * 1000 )/2))) + 'X'
		pkg_name += str(int((self.ui_data['bodyHeightMax']*1000))) + '-'
		pkg_name += str(self.ui_data['horizontalPadCount'])
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_density_level_for_smd(self.ui_data['densityLevel'])	
		return pkg_name

	def get_ipc_package_description(self):
	
		ao = addin_utility.AppObjects()
		unit = 'mm'	

		lead_span = ao.units_manager.convert((self.ui_data['horizontalLeadToLeadSpanMax']+self.ui_data['horizontalLeadToLeadSpanMin'])/2, 'cm', unit)
		pin_pitch = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', unit)

		short_description = str(self.ui_data['horizontalPadCount']) + '-SOTFL, '
		short_description += str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch, '
		short_description += str('{:.2f}'.format(round(lead_span,2))) + ' ' + unit + ' span, '
		short_description += self.get_body_description(True,True) + unit + ' body'
			
		full_description = str(self.ui_data['horizontalPadCount']) + '-pin SOTFL package with '
		full_description += str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch, '
		full_description += str('{:.2f}'.format(round(lead_span,2))) + ' ' + unit + ' span'
		full_description += self.get_body_description(False,True) + unit

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		super().get_ipc_package_metadata()
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "SOTFL"
		self.metadata["pitch"] = str(round(ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm'), 4))
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_SOTFL, PackageCalculatorSotfl) 