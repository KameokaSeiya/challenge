# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules

# this class defines the package Calculator for the Axial Packages.


class PackageCalculatorDfn3(pkg_calculator.PackageCalculator):

	# initialize the data members
	def __init__(self, pkg_type: str):
		super().__init__(pkg_type)
		self.pkg_type = constant.PKG_TYPE_DFN3

	def get_general_footprint(self):
		pass

	def get_3d_model_data(self):
		pass

	# process the data for 3d model generator
	def get_ipc_3d_model_data(self):
		model_data = {}
		model_data['type'] = self.pkg_type
		model_data['A'] = self.ui_data['bodyHeightMax']
		model_data['e'] = self.ui_data['verticalPinPitch']
		model_data['d'] = self.ui_data['horizontalPinPitch']
		model_data['b'] = self.ui_data['padHeightMax']
		model_data['b1'] = self.ui_data['oddPadWidthMax']
		model_data['L'] = self.ui_data['padWidthMax']
		model_data['L1'] = self.ui_data['oddPadHeightMax']
		model_data['D'] = self.ui_data['bodyWidthMax']
		model_data['E'] = self.ui_data['bodyLengthMax']
		return model_data

	def get_footprint(self):

		footprint_data = []
		horizontal_pin_pitch = self.ui_data['horizontalPinPitch']
		vertical_pin_pitch = self.ui_data['verticalPinPitch']
		pad_width_even = self.ui_data['padWidthMax']
		pad_height_even = self.ui_data['padHeightMax']
		pad_width_odd = self.ui_data['oddPadWidthMax']
		pad_height_odd = self.ui_data['oddPadHeightMax']
		body_width = self.ui_data['bodyWidthMax']

		L_min = horizontal_pin_pitch + self.ui_data['padWidthMin']/2 + self.ui_data['oddPadWidthMin']/2
		L_max = horizontal_pin_pitch + self.ui_data['padWidthMax']/2 + self.ui_data['oddPadWidthMax']/2
		T_min = self.ui_data['padWidthMin']
		T_max = self.ui_data['padWidthMax']
		W_min = self.ui_data['padHeightMin']
		W_max = self.ui_data['padHeightMax']

		toe_goal = ipc_rules.PAD_GOAL_DFN['periphery'][self.ui_data['densityLevel']]
		heel_goal = ipc_rules.PAD_GOAL_DFN['periphery'][self.ui_data['densityLevel']]
		side_goal = ipc_rules.PAD_GOAL_DFN['periphery'][self.ui_data['densityLevel']]

		if self.ui_data['hasCustomFootprint'] :
			#for custom footprint
			pad_width = self.ui_data['customPadLength']
			pad_height = self.ui_data['customPadWidth']
			pin_pitch = self.ui_data['customPadToPadGap'] + self.ui_data['customPadLength']
		else:
			pad_width, pad_height, pin_pitch = self.get_footprint_smd_data(L_min, L_max, T_min, T_max, W_min, W_max, toe_goal, heel_goal, side_goal) 	

		left_pad_count = 2
		for i in range (0, left_pad_count):
			row_i = i % left_pad_count 
			# create Pad
			pad = footprint.FootprintSmd( -0.5 * pin_pitch, ((left_pad_count - 1) / 2 - row_i)* vertical_pin_pitch, pad_width, pad_height)
			pad.name = str(i + 1)
			pad.shape = self.ui_data['padShape']
			footprint_data.append(pad)

		#draw right pad
		if (self.ui_data['padHeightMin'] != self.ui_data['oddPadHeightMin'] or self.ui_data['padHeightMax'] != self.ui_data['oddPadHeightMax'] or 
			self.ui_data['padWidthMin'] != self.ui_data['oddPadWidthMin'] or self.ui_data['padWidthMax'] != self.ui_data['oddPadWidthMax']):
			T_min = self.ui_data['oddPadWidthMin']
			T_max = self.ui_data['oddPadWidthMax']
			W_min = self.ui_data['oddPadHeightMin']
			W_max = self.ui_data['oddPadHeightMax']

		if self.ui_data['hasCustomFootprint'] :
			#for custom footprint
			odd_pad_width = self.ui_data['customOddPadLength']
			odd_pad_height = self.ui_data['customOddPadWidth']
			odd_pin_pitch = self.ui_data['customPadToPadGap'] + self.ui_data['customOddPadLength']
		else:
			odd_pad_width, odd_pad_height, odd_pin_pitch = self.get_footprint_smd_data(L_min, L_max, T_min, T_max, W_min, W_max, toe_goal, heel_goal, side_goal) 	

		pad = footprint.FootprintSmd( 0.5 * odd_pin_pitch, 0, odd_pad_width, odd_pad_height)
		pad.name = '3'
		pad.shape = self.ui_data['padShape']
		footprint_data.append(pad)

		#build the silkscreen 
		first_left_pad = footprint_data[0]
		second_left_pad = footprint_data[1]
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])

		if first_left_pad.center_point_y + first_left_pad.height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2 > body_length/2 :
			top_line_y = first_left_pad.center_point_y + first_left_pad.height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2
			bottom_line_y = second_left_pad.center_point_y - second_left_pad.height/2 - ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] - ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2
		else : 
			top_line_y = body_length/2
			bottom_line_y = -body_length/2

		line_start_x = -body_width/2
		line_end_x = body_width/2

		line_top = footprint.FootprintWire(line_start_x, top_line_y, line_end_x, top_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_top)		

		line_bottom = footprint.FootprintWire(line_start_x, bottom_line_y, line_end_x, bottom_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_bottom)

		#build pin one marker
		self.build_silkscreen_pin_one_marker(footprint_data, first_left_pad.center_point_x , first_left_pad.center_point_y  , pad_width, pad_height, body_width, True)

		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		#build the textbody_length
		self.build_footprint_text(footprint_data, 0)

		return footprint_data

	def get_ipc_package_name(self):
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_RESISTOR):
			family_name = 'RESDFN'
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR):
			family_name = 'CAPDFN'
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE):
			family_name = 'DIODFN'
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_INDUCTOR):
			family_name = 'INDDFN'
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_FILTER):
			family_name = 'FILTRDFN'
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_IC):
			family_name = 'DFN'
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_TRANSISTOR):
			family_name = 'TRXDFN'

		#family name + Body Length X Body Width X Height – Pin Qty + density level
		pkg_name = family_name
		pkg_name += str(int(((self.ui_data['bodyWidthMax'] * 1000 +self.ui_data['bodyWidthMin'] * 1000 )/2)))
		pkg_name += 'X' + str(int(((self.ui_data['bodyLengthMax'] * 1000 +self.ui_data['bodyLengthMin'] * 1000 )/2)))
		pkg_name += 'X' + str(int((self.ui_data['bodyHeightMax']*1000)))
		pkg_name += '-' + str(int(self.ui_data['horizontalPadCount']))
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_density_level_for_smd(self.ui_data['densityLevel'])		
		return pkg_name

	def get_ipc_package_description(self):
		ao = addin_utility.AppObjects()
		unit = 'mm'	

		short_description = 'DFN3, '
		short_description += self.get_body_description(True, False) + unit + ' body'

		full_description = 'DFN3 package'
		full_description += self.get_body_description(False, False) + unit

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		isPackageRotated = True
		super().get_ipc_package_metadata(isPackageRotated)
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "DFN"
		self.metadata["pitch"] = str(round(ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm'),4))
		self.metadata["pitch2"] = str(round(ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'mm'),4))
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		return self.metadata
		
# register the calculator into the factory.
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_DFN3, PackageCalculatorDfn3)
