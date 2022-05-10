# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules
from ..Utilities.localization import _LCLZ

class PackageCalculatorChipLed(pkg_calculator.PackageCalculator):
	
	# initialize the data members
	def __init__(self, pkg_type: str):
		super().__init__(pkg_type)
		self.pkg_type = constant.PKG_TYPE_CHIP_LED

	def get_general_footprint(self):
		pass

	def get_3d_model_data(self):
		pass               
	
	# process the data for 3d model generator	
	def get_ipc_3d_model_data(self):
		model_data = {}
		model_data['type'] = self.pkg_type
		model_data['A'] = self.ui_data['bodyHeightMax']
		model_data['A1'] = self.ui_data['baseHeightMax']
		model_data['D'] = self.ui_data['bodyWidthMax']
		model_data['E'] = self.ui_data['bodyLengthMax']	
		model_data['L'] = self.ui_data['padWidthMax']	
		model_data['d'] = self.ui_data['domeDiameter']	

        # get the proper body color
		hex_rgb = self.ui_data['bodyColor']
		if hex_rgb == '' :
			hex_rgb = self.ui_data['customBodyColor']
		model_data['color_r'], model_data['color_g'], model_data['color_b'] = addin_utility.convert_rgb_color(hex_rgb)

		#type of lens
		if self.ui_data['lensType'] == 'Rectangle with Domed Top':
			model_data['isRoundLens'] = 1
		else :
			model_data['isRoundLens'] = 0

		return model_data
		
	def get_footprint(self):

		footprint_data = []

		body_width_min = self.ui_data['bodyWidthMin'] 
		body_width_max = self.ui_data['bodyWidthMax'] 
		pad_width_min = self.ui_data['padWidthMin'] 
		pad_width_max = self.ui_data['padWidthMax'] 
		body_length_min = self.ui_data['bodyLengthMin'] 
		body_length_max = self.ui_data['bodyLengthMax'] 

		if body_width_max >= (ipc_rules.PAD_GOAL_CHIP['bodyLengthTh']):
			toe_goal = ipc_rules.PAD_GOAL_CHIP['toeFilletMaxMedMinGTE'][self.ui_data['densityLevel']]
			heel_goal = ipc_rules.PAD_GOAL_CHIP['heelFilletMaxMedMinGTE'][self.ui_data['densityLevel']]
			side_goal = ipc_rules.PAD_GOAL_CHIP['sideFilletMaxMedMinGTE'][self.ui_data['densityLevel']]
		else :
			toe_goal = ipc_rules.PAD_GOAL_CHIP['toeFilletMaxMedMinLT'][self.ui_data['densityLevel']]
			heel_goal = ipc_rules.PAD_GOAL_CHIP['heelFilletMaxMedMinLT'][self.ui_data['densityLevel']]
			side_goal = ipc_rules.PAD_GOAL_CHIP['sideFilletMaxMedMinLT'][self.ui_data['densityLevel']]
		
		if self.ui_data['hasCustomFootprint'] :
			pad_width = self.ui_data['customPadLength']
			pad_height = self.ui_data['customPadWidth']
			pin_pitch = self.ui_data['customPadToPadGap'] + self.ui_data['customPadLength']
		else:
			pad_width, pad_height, pin_pitch = self.get_footprint_smd_data(body_width_min, body_width_max, pad_width_min,
		 																pad_width_max, body_length_min, body_length_max,
		 																toe_goal, heel_goal, side_goal) 
		# initiate the left pad data 
		left_pad = footprint.FootprintSmd(-pin_pitch/2, 0, pad_width, pad_height)
		left_pad.name = 'C'
		left_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(left_pad)

		# initiate the right pad data 
		right_pad = footprint.FootprintSmd(pin_pitch/2, 0, pad_width, pad_height)
		right_pad.name = 'A'
		right_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(right_pad)

		#build the silkscreen
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])	
		
		top_line_y = pad_height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2
		bottom_line_y = - top_line_y
		
		line_end_x = body_width/2
		line_start_x = - (pin_pitch/2 + pad_width/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'])

		line_top = footprint.FootprintWire(line_start_x, top_line_y, line_end_x, top_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_top)		

		line_left = footprint.FootprintWire(line_start_x, top_line_y, line_start_x, bottom_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_left)	

		line_bottom = footprint.FootprintWire(line_start_x, bottom_line_y, line_end_x, bottom_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line_bottom)

		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		#build the textbody_length
		self.build_footprint_text(footprint_data, 0)

		return footprint_data

	def get_ipc_package_name(self):

		#package name + Body Length + Body Width X Height + density level
		body_width_nom = int(((self.ui_data['bodyWidthMax'] * 1000 + self.ui_data['bodyWidthMin'] * 1000 )/20))
		if body_width_nom < 10:
			body_width_str = '0' + str(body_width_nom)
		else:
			body_width_str = str(body_width_nom)

		body_length_nom = int(((self.ui_data['bodyLengthMax'] * 1000 + self.ui_data['bodyLengthMin'] * 1000 )/20))
		if body_length_nom < 10:
			body_length_str = '0' + str(body_length_nom)
		else:
			body_length_str = str(body_length_nom)

		pkg_name = 'LEDC'+ body_width_str + body_length_str + 'X'
		pkg_name += str(int((self.ui_data['bodyHeightMax']*1000))) 
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_density_level_for_smd(self.ui_data['densityLevel'])	
		return pkg_name

	def get_ipc_package_description(self):
	
		ao = addin_utility.AppObjects()
		unit = 'mm'	

		short_description = 'Chip LED, '
		short_description += self.get_body_description(True, False) + unit + ' body'

		full_description = 'Chip LED package with body size '
		full_description += self.get_body_description(True, False) + unit

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		isPackageRotated = True
		super().get_ipc_package_metadata(isPackageRotated)
		self.metadata['ipcFamily'] = "CHIPLED"
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_CHIP_LED, PackageCalculatorChipLed) 