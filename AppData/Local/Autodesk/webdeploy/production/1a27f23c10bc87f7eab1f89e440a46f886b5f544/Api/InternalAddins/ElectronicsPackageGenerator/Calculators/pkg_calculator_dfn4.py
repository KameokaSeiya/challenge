# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules


class PackageCalculatorDfn4(pkg_calculator.PackageCalculator):
	
	# initialize the data members
	def __init__(self, pkg_type: str):
		super().__init__(pkg_type)
		self.pkg_type = constant.PKG_TYPE_DFN4

	def get_general_footprint(self):
		pass

	def get_3d_model_data(self):
		pass
		
	# process the data for 3d model generator	
	def get_ipc_3d_model_data(self):
		model_data = {}
		model_data['type'] = self.pkg_type
		model_data['A'] = self.ui_data['bodyHeightMax']
		model_data['E'] = self.ui_data['bodyLengthMax']	
		model_data['D'] = self.ui_data['bodyWidthMax']	
		model_data['e'] = self.ui_data['verticalPinPitch']
		model_data['d'] = self.ui_data['horizontalPinPitch']
		model_data['b'] = self.ui_data['padHeightMax']
		model_data['L'] = self.ui_data['padWidthMax']
		
		return model_data
		
	def get_footprint(self):
		
		footprint_data = []
		pin_pitch = self.ui_data['horizontalPinPitch']	
		
		pad_width_min = self.ui_data['padWidthMin']
		pad_width_max = self.ui_data['padWidthMax']
		pad_height_min = self.ui_data['padHeightMin']
		pad_height_max = self.ui_data['padHeightMax']
		vertical_pitch = self.ui_data['verticalPinPitch']	

		L_min = pin_pitch + pad_width_min
		L_max = pin_pitch + pad_width_max
		T_min = pad_width_min
		T_max = pad_width_max
		W_min = pad_height_min
		W_max = pad_height_max

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
			
		n_row = 2

		for i in range (0, 2 * n_row):
			col = math.floor(i / n_row)
			row = i % n_row
			if (col % 2 == 1) :
				row = n_row - 1 - row
			# create Pad
			pad = footprint.FootprintSmd((col - 0.5) * pin_pitch, ((n_row - 1) / 2 - row)* vertical_pitch, pad_width, pad_height)
			pad.name = str(i + 1)
			pad.shape = self.ui_data['padShape']
			footprint_data.append(pad)

		#build the silkscreen 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])

		if (vertical_pitch/2 + pad_height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2 > body_length/2):
			top_line_y = vertical_pitch/2 + pad_height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2
			bottom_line_y = -vertical_pitch/2 - pad_height/2 - ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] - ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2
		else:
			top_line_y = body_length/2
			bottom_line_y = -body_length/2

		#top line
		line1 = footprint.FootprintWire(-body_width/2, top_line_y, body_width/2, top_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line1)

		line2 = footprint.FootprintWire(body_width/2, bottom_line_y, -body_width/2, bottom_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line2)

		#build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		#build pin one marker
		self.build_silkscreen_pin_one_marker(footprint_data, -pin_pitch/2  ,vertical_pitch/2  , pad_width, pad_height, body_width, True)

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

		short_description = 'DFN4, '
		short_description += self.get_body_description(True, False) + unit + ' body'

		full_description = 'DFN4 package'
		full_description += self.get_body_description(False, False) + unit

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		super().get_ipc_package_metadata()
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "DFN"
		self.metadata["pitch"] = str(round(ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm'),4))
		self.metadata["pitch2"] = str(round(ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'mm'),4))
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_DFN4, PackageCalculatorDfn4) 