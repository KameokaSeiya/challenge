# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules


# this class defines the package Calculator for the Axial Packages.
class PackageCalculatorMolded(pkg_calculator.PackageCalculator):
	
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
		model_data['b1'] = self.ui_data['oddPadHeightMax']
		model_data['L'] = self.ui_data['padWidthMax']
		model_data['L1'] = self.ui_data['oddPadWidthMax']
		model_data['D'] = self.ui_data['bodyWidthMax']
		model_data['E'] = self.ui_data['bodyLengthMax']

		if 	(self.ui_data['componentFamily'] == constant.COMP_FAMILY_POLARIZED_CAPACITOR or 
			self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE or
			self.ui_data['componentFamily'] == constant.COMP_FAMILY_LED) :
			model_data['isPolarized'] = 1
		else : 
			model_data['isPolarized'] = 0
		return model_data
		
	def get_footprint(self):
		
		footprint_data = []

		toe_goal = ipc_rules.PAD_GOAL_MOLDEDBODY['toeFilletMaxMedMin'][self.ui_data['densityLevel']]
		heel_goal = ipc_rules.PAD_GOAL_MOLDEDBODY['heelFilletMaxMedMin'][self.ui_data['densityLevel']]
		side_goal = ipc_rules.PAD_GOAL_MOLDEDBODY['sideFilletMaxMedMin'][self.ui_data['densityLevel']]

		#ipc footprint data
		L_min = self.ui_data['bodyWidthMin']	
		L_max = self.ui_data['bodyWidthMax']	

		#calculate the smd data. 
		if self.ui_data['hasCustomFootprint'] :
			#custom normal pad 
			pad_width = self.ui_data['customPadLength']
			pad_height = self.ui_data['customPadWidth']
			pin_pitch = self.ui_data['customPadToPadGap'] + self.ui_data['customPadLength']
			#custom odd pad
			odd_pad_width = self.ui_data['customOddPadLength']
			odd_pad_height = self.ui_data['customOddPadWidth']
			odd_pin_pitch = self.ui_data['customPadToPadGap'] + self.ui_data['customOddPadLength']
		else:
			pad_width, pad_height, pin_pitch = self.get_footprint_smd_data(L_min, L_max, self.ui_data['padWidthMin'], self.ui_data['padWidthMax'], self.ui_data['padHeightMin'], self.ui_data['padHeightMax'], toe_goal, heel_goal, side_goal)
			odd_pad_width, odd_pad_height, odd_pin_pitch = self.get_footprint_smd_data(L_min, L_max, self.ui_data['oddPadWidthMin'], self.ui_data['oddPadWidthMax'], self.ui_data['oddPadHeightMin'], self.ui_data['oddPadHeightMax'], toe_goal, heel_goal, side_goal)
		# initiate the left pad data 
		left_pad = footprint.FootprintSmd(-pin_pitch/2, 0, pad_width, pad_height)
		if 	(self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE or self.ui_data['componentFamily'] == constant.COMP_FAMILY_LED) :
			left_pad.name = 'C'
		else:
			left_pad.name = '1'
		left_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(left_pad)

		# initiate the right pad data 
		if self.ui_data['hasCustomFootprint'] :
			offset = odd_pin_pitch/2
		else:
			offset = pin_pitch / 2 - odd_pad_width / 2 + pad_width / 2
		odd_pad = footprint.FootprintSmd(offset, 0, odd_pad_width, odd_pad_height)
		if 	(self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE or self.ui_data['componentFamily'] == constant.COMP_FAMILY_LED) :
			odd_pad.name = 'A'
		else:
			odd_pad.name = '2'
		odd_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(odd_pad)

		#build the silkscreen 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])
		stroke_width = ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']
		
		top_y = max(max(odd_pad_height , pad_height)/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] + stroke_width/2 , body_length/2) 
		# top side silkscreen. need consider the clearance with the smd pads
		if 	(self.ui_data['componentFamily'] == constant.COMP_FAMILY_POLARIZED_CAPACITOR or 
			self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE or
			self.ui_data['componentFamily'] == constant.COMP_FAMILY_LED) :
			#silkscreen for polarized component
			left_x = left_pad.center_point_x - left_pad.width/2 - ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] - stroke_width/2
			line_top = footprint.FootprintWire(left_x, top_y, body_width/2, top_y, stroke_width)
			footprint_data.append(line_top)

			line_left = footprint.FootprintWire(left_x, top_y, left_x, - top_y, stroke_width)
			footprint_data.append(line_left)	

			line_bottom = footprint.FootprintWire(left_x, -top_y, body_width/2, -top_y, stroke_width)
			footprint_data.append(line_bottom)

		else : 
			#silkscreen for non polarized component
			line_top = footprint.FootprintWire( - body_width/2, top_y, body_width/2, top_y, stroke_width)
			footprint_data.append(line_top)

			line_bottom = footprint.FootprintWire(- body_width/2, -top_y, body_width/2, -top_y, stroke_width)
			footprint_data.append(line_bottom)
	
		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		#build the text
		self.build_footprint_text(footprint_data)

		return footprint_data

	def get_ipc_package_name(self):
		#component family name + Body Length + Body Width X Height + producibility level (A, B, C)
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_RESISTOR):
			family_name = 'RESM'     
		elif (self.ui_data['componentFamily'] == constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR):
			family_name = 'CAPM' 
		elif (self.ui_data['componentFamily'] == constant.COMP_FAMILY_FUSE):
			family_name = 'FUSM' 
		elif (self.ui_data['componentFamily'] == constant.COMP_FAMILY_INDUCTOR):
			family_name = 'INDM' 
		elif (self.ui_data['componentFamily'] == constant.COMP_FAMILY_PRECISION_INDUCTOR):
			family_name = 'INDPM' 
		elif (self.ui_data['componentFamily'] == constant.COMP_FAMILY_POLARIZED_CAPACITOR):
			family_name = 'CAPMP' 
		elif (self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE):
			family_name = 'DIOM' 
		elif (self.ui_data['componentFamily'] == constant.COMP_FAMILY_LED):
			family_name = 'LEDM' 
        
		body_width_nom = int(((self.ui_data['bodyWidthMax'] * 1000 + self.ui_data['bodyWidthMin']* 1000 )/20))
		if body_width_nom < 10:
			body_width_str = '0' + str(body_width_nom)
		else:
			body_width_str = str(body_width_nom)

		body_length_nom = int(((self.ui_data['bodyLengthMax'] * 1000 + self.ui_data['bodyLengthMin'] * 1000 )/20))
		if body_length_nom < 10:
			body_length_str = '0' + str(body_length_nom)
		else:
			body_length_str = str(body_length_nom)

		pkg_name = family_name + body_width_str + body_length_str + 'X'
		pkg_name += str(int((self.ui_data['bodyHeightMax']*1000))) 
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_density_level_for_smd(self.ui_data['densityLevel'])

		return pkg_name
		
	def get_ipc_package_description(self):

		unit = 'mm'	
		short_description = 'Molded Body, '
		short_description += self.get_body_description(True, False) + unit + ' body'
		full_description = 'Molded Body package'
		full_description += self.get_body_description(False, False) + unit

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		isPackageRotated = True
		super().get_ipc_package_metadata(isPackageRotated)
		self.metadata['ipcFamily'] = "MOLDED"
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_MOLDEDBODY, PackageCalculatorMolded)