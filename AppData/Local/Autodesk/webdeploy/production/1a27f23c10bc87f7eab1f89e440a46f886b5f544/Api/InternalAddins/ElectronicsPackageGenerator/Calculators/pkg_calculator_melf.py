# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules


# this class defines the package Calculator for the Melf Package.
class PackageCalculatorMelf(pkg_calculator.PackageCalculator):
	
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
		model_data['L'] = self.ui_data['padWidthMax']
		model_data['D'] = self.ui_data['bodyWidthMax']	
		model_data['E'] = self.ui_data['bodyLengthMax']	

        # get the proper body color
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_RESISTOR):
			model_data['color_r'] = 10
			model_data['color_g'] = 10
			model_data['color_b'] = 10    
			model_data['isPolarized'] = 0
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE):
			model_data['color_r'] = 167
			model_data['color_g'] = 38
			model_data['color_b'] = 12
			model_data['isPolarized'] = 1

		return model_data
		
	def get_footprint(self):
		
		footprint_data = []

		toe_goal = ipc_rules.PAD_GOAL_MELF['toeFilletMaxMedMin'][self.ui_data['densityLevel']]
		heel_goal = ipc_rules.PAD_GOAL_MELF['heelFilletMaxMedMin'][self.ui_data['densityLevel']]
		side_goal = ipc_rules.PAD_GOAL_MELF['sideFilletMaxMedMin'][self.ui_data['densityLevel']]

		W_min = self.ui_data['bodyLengthMin']	
		W_max = self.ui_data['bodyLengthMax']	
		L_min = self.ui_data['bodyWidthMin']	
		L_max = self.ui_data['bodyWidthMax']	
		T_min = self.ui_data['padWidthMin']
		T_max = self.ui_data['padWidthMax']

		#calculate the smd data. 
		if self.ui_data['hasCustomFootprint'] :
			pad_width = self.ui_data['customPadLength']
			pad_height = self.ui_data['customPadWidth']
			pin_pitch = self.ui_data['customPadToPadGap'] + self.ui_data['customPadLength']
		else:
			pad_width, pad_height, pin_pitch = self.get_footprint_smd_data(L_min, L_max, T_min, T_max, W_min, W_max, toe_goal, heel_goal, side_goal) 	

		# initiate the left pad data 
		left_pad = footprint.FootprintSmd(-pin_pitch/2, 0, pad_width, pad_height)
		if self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE:
			left_pad.name = 'C'
		else:
			left_pad.name = '1'
		left_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(left_pad)

		# initiate the right pad data 
		right_pad = footprint.FootprintSmd(pin_pitch/2, 0, pad_width, pad_height)
		if self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE:
			right_pad.name = 'A'
		else:
			right_pad.name = '2'
		right_pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(right_pad)
		

		#build the silkscreen

		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])

		if (pad_height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2) > body_length/2:
			top_line_y = pad_height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2
			bottom_line_y = - top_line_y
		else:
			top_line_y = body_length/2
			bottom_line_y = - top_line_y
		
		line_end_x = pin_pitch/2 - pad_width/2
		# build top layer silk screen
		if self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE:
			line_start_x = - (pin_pitch/2 + pad_width/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance'] + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2)

			line_top = footprint.FootprintWire(line_start_x, top_line_y, line_end_x, top_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_top)		

			line_left = footprint.FootprintWire(line_start_x, top_line_y, line_start_x, bottom_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_left)	

			line_bottom = footprint.FootprintWire(line_start_x, bottom_line_y, line_end_x, bottom_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_bottom)
		else : 
			line_start_x = - (pin_pitch/2 - pad_width/2)

			line_top = footprint.FootprintWire(line_start_x, top_line_y, line_end_x, top_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_top)		

			line_bottom = footprint.FootprintWire(line_start_x, bottom_line_y, line_end_x, bottom_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_bottom)

		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		#build the textbody_length
		self.build_footprint_text(footprint_data, 0)

		return footprint_data

	def get_ipc_package_name(self):
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE):
			family_name = 'DIOMELF'     
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_RESISTOR):
			family_name = 'RESMELF' 

		#component family name + Body Length + Body Diameter + density level
		pkg_name = family_name
		
		body_w = int(((self.ui_data['bodyWidthMax'] * 1000 +self.ui_data['bodyWidthMin'] * 1000 )/20))
		if body_w < 10:
			pkg_name += '0' + str(body_w) 
		else:
			pkg_name += str(body_w) 
		
		body_l = int(((self.ui_data['bodyLengthMax'] * 1000 +self.ui_data['bodyLengthMin'] * 1000 )/20))
		if body_l < 10:
			pkg_name += '0' + str(body_l) 
		else:
			pkg_name += str(body_l) 
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_density_level_for_smd(self.ui_data['densityLevel'])		
		return pkg_name

	def get_ipc_package_description(self):
	
		ao = addin_utility.AppObjects()
		unit = 'mm'	

		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE):
			family_name = 'Diode'     
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_RESISTOR):
			family_name = 'Resistor' 

		body_width = ao.units_manager.convert((self.ui_data['bodyWidthMax']+self.ui_data['bodyWidthMin'])/2, 'cm', unit)
		body_length = ao.units_manager.convert((self.ui_data['bodyLengthMax']+self.ui_data['bodyLengthMin'])/2, 'cm', unit)
		
		short_description = 'MELF, '
		short_description += str('{:.2f}'.format(round(body_width,2))) + ' ' + unit + ' length, '
		short_description += str('{:.2f}'.format(round(body_length,2))) + ' ' + unit + ' diameter'

		full_description = 'MELF '+ family_name + ' package '
		full_description += ' with ' + str('{:.2f}'.format(round(body_width,2))) + ' ' + unit + ' length'
		full_description += ' and ' + str('{:.2f}'.format(round(body_length,2))) + ' ' + unit + ' diameter'

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		super().get_ipc_package_metadata()
		self.metadata['ipcFamily'] = "MELF"
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_MELF, PackageCalculatorMelf) 