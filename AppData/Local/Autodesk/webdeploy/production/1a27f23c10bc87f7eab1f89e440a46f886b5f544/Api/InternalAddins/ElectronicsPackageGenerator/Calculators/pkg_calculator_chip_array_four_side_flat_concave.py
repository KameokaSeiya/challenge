# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules


class PackageCalculatorChipArray4SideFlatConcave(pkg_calculator.PackageCalculator):
	
	# initialize the data members
	def __init__(self, pkg_type: str):
		super().__init__(pkg_type)

	def get_general_footprint(self):
		pass

	def get_3d_model_data(self):
		pass

	def get_body_color(self):
		     
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR ):
			return [160, 135, 130]
		else:
			return [10, 10, 10]       

	# process the data for 3d model generator	
	def get_ipc_3d_model_data(self):

		model_data = {}
		model_data['type'] = self.pkg_type
		model_data['A'] = self.ui_data['bodyHeightMax']
		model_data['D'] = self.ui_data['bodyLengthMax']
		model_data['b'] = self.ui_data['padHeightMax']
		model_data['b1'] = self.ui_data['oddPadHeightMax']	
		model_data['E'] = self.ui_data['bodyWidthMax']	
		model_data['e'] = self.ui_data['verticalPinPitch']
		model_data['L'] = self.ui_data['padWidthMax']	
		model_data['L1'] = self.ui_data['oddPadWidthMax']	
		model_data['N'] = self.ui_data['horizontalPadCount']

		# get the proper body color
		body_color = self.get_body_color()
		model_data['color_r'] = body_color[0]
		model_data['color_g'] = body_color[1]
		model_data['color_b'] = body_color[2] 	

		#type of lens
		if self.ui_data['leadShapeType'] == 'Flat':
			model_data['isFlatLead'] = 1
		else :
			model_data['isFlatLead'] = 0

		return model_data

	def get_footprint(self):

		footprint_data = []

		L_min = self.ui_data['bodyWidthMin']	
		L_max = self.ui_data['bodyWidthMax']	
		T_min = self.ui_data['padWidthMin']	
		T_max = self.ui_data['padWidthMax']	
		W_min = self.ui_data['padHeightMin']	
		W_max = self.ui_data['padHeightMax']	

		L_min_top = self.ui_data['bodyLengthMin']	
		L_max_top = self.ui_data['bodyLengthMax']	
		T_min_top = self.ui_data['oddPadWidthMin']	
		T_max_top = self.ui_data['oddPadWidthMax']	
		W_min_top = self.ui_data['oddPadHeightMin']	
		W_max_top = self.ui_data['oddPadHeightMax']	
		pin_pitch = self.ui_data['verticalPinPitch']

		toe_goal = ipc_rules.PAD_GOAL_CHIPARRAY['toeFilletMaxMedMin'][self.ui_data['densityLevel']]
		heel_goal = ipc_rules.PAD_GOAL_CHIPARRAY['heelFilletMaxMedMin'][self.ui_data['densityLevel']]
		side_goal = ipc_rules.PAD_GOAL_CHIPARRAY['sideFilletMaxMedMin'][self.ui_data['densityLevel']]
		
		if self.ui_data['hasCustomFootprint'] :
			#for custom footprint
			pad_width_vert = self.ui_data['customPadLength']
			pad_height_vert = self.ui_data['customPadWidth']
			pin_pitch_vert = self.ui_data['customPadToPadGap'] + self.ui_data['customPadLength']
			pad_width_hori = self.ui_data['customOddPadLength']
			pad_height_hori = self.ui_data['customOddPadWidth']
			pin_pitch_hori = self.ui_data['customPadToPadGap1'] + self.ui_data['customOddPadLength']
		else:
			pad_width_vert, pad_height_vert, pin_pitch_vert = self.get_footprint_smd_data(L_min, L_max, T_min, T_max, W_min, W_max, toe_goal, heel_goal, side_goal) 	
			pad_width_hori, pad_height_hori, pin_pitch_hori = self.get_footprint_smd_data(L_min_top, L_max_top, T_min_top, T_max_top, W_min_top, W_max_top,
																						toe_goal, heel_goal, side_goal) 	

		#create_top_pad
		pad = footprint.FootprintSmd(0, pin_pitch_hori/2, pad_width_hori, pad_height_hori)
		pad.name = '1'
		pad.angle = 'R90.0'
		pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(pad)

		#create left pad
		n_row = math.ceil((self.ui_data['horizontalPadCount'] - 2) / 2)
		for i in range (0, n_row):
			rowIdx = i % n_row
			#create Pad
			pad = footprint.FootprintSmd(-pin_pitch_vert/2, ((n_row - 1) / 2 - rowIdx)* pin_pitch, pad_width_vert, pad_height_vert)
			pad.name = str(i + 2)
			pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(pad)

		#create bottom pad
		pad = footprint.FootprintSmd(0, -pin_pitch_hori/2, pad_width_hori, pad_height_hori)
		pad.name = str(n_row  + 2)
		pad.angle = 'R90.0'	
		pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
		footprint_data.append(pad)

		#create right pad
		for i in range (0, n_row):
			rowIdx = n_row - 1 - i % n_row;
			#create Pad
			pad = footprint.FootprintSmd(pin_pitch_vert/2, ((n_row - 1) / 2 - rowIdx)* pin_pitch, pad_width_vert, pad_height_vert)
			pad.name = str(n_row + 3 + i)
			pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(pad)

		#pin one marker
		self.build_silkscreen_pin_one_marker(footprint_data, 0 ,L_max_top/2 - pad_height_hori/2  , pad_width_hori, pad_height_hori, pad_height_hori, False)
		
		#build the silkscreen 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])

		top_pad = footprint_data[0]
		first_left_pad = footprint_data[1]

		clearance = ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']
		stroke_width = ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']
		first_left_pad_info = first_left_pad.center_point_y + first_left_pad.height/2
		top_pad_info = top_pad.center_point_x - top_pad.height/ 2

		#return if left first pad's top edge including clearence is above top pad's top edge
		if (first_left_pad_info + clearance + stroke_width/2 <= top_pad.center_point_y + top_pad.height/2) and (first_left_pad_info + clearance + stroke_width/2 <= body_length/2):

			#top left corner
			top_line_left1 = footprint.FootprintWire(-body_width/2, first_left_pad_info + clearance, -body_width/2, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(top_line_left1)

			top_line_left2 = footprint.FootprintWire(-body_width/2, body_length/2, top_pad_info - clearance, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(top_line_left2)

			#top_right_corner
			top_line_right1 = footprint.FootprintWire(body_width/2, first_left_pad_info + clearance, body_width/2, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(top_line_right1)

			top_line_right2 = footprint.FootprintWire(body_width/2, body_length/2, -top_pad_info + clearance, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(top_line_right2)

			#bottom left corner
			bot_line_left1 = footprint.FootprintWire(-body_width/2, -first_left_pad_info - clearance, -body_width/2, -body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(bot_line_left1)

			bot_line_left2 = footprint.FootprintWire(-body_width/2, -body_length/2, top_pad_info - clearance, -body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(bot_line_left2)

			#bottom_right_corner
			bot_line_right1 = footprint.FootprintWire(body_width/2, -first_left_pad_info - clearance, body_width/2, -body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(bot_line_right1)

			bot_line_right2 = footprint.FootprintWire(body_width/2, -body_length/2, -top_pad_info + clearance, -body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(bot_line_right2)

		
		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		#build the text
		self.build_footprint_text(footprint_data, 0)
		
		return footprint_data
	
	def get_ipc_package_name(self):
	
		if self.ui_data['leadShapeType'] == 'Flat':
			flat_type = True
		else : 
			flat_type = False

		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_RESISTOR):
			family_name = 'RESCAF' if flat_type else 'RESCAV'  
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_INDUCTOR):
			family_name = 'INDCAF' if flat_type else 'INDCAV'  
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_DIODE):
			family_name = 'DIOCAF' if flat_type else 'DIOCAV'  
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR):
			family_name = 'CAPCAF' if flat_type else 'CAPCAV'  

		#family name + Pitch P + Body Length X Body Width X Height - Pin Qty
		pkg_name =  family_name
		pkg_name += str(int((self.ui_data['verticalPinPitch']*1000))) 
		pkg_name += 'P' + str(int(((self.ui_data['bodyLengthMax'] * 1000+self.ui_data['bodyLengthMin'] * 1000)/2)))
		pkg_name += 'X' + str(int(((self.ui_data['bodyWidthMax'] * 1000+self.ui_data['bodyWidthMin'] * 1000)/2))) 
		pkg_name += 'X' + str(int((self.ui_data['bodyHeightMax']*1000))) 
		pkg_name += '-' + str(int(self.ui_data['horizontalPadCount']))
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_density_level_for_smd(self.ui_data['densityLevel'])
			
		return pkg_name	

	def get_ipc_package_description(self):
	
		ao = addin_utility.AppObjects()
		unit = 'mm'	

		pin_pitch = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', unit)

		short_description = str(int(self.ui_data['horizontalPadCount'])) + '-Chiparray 4-Side Flat, ' 
		short_description += str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch, '
		short_description += self.get_body_description(True, True) + unit + ' body'

		full_description = str(int(self.ui_data['horizontalPadCount'])) + '-pin Chiparray 4-Side Flat package' 
		full_description += ' with ' + str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch '
		full_description += 'with body size ' + self.get_body_description(True, True) + unit

		return short_description + '\n <p>' + full_description + '</p>'
	
	
	def	get_ipc_package_metadata(self):
		super().get_ipc_package_metadata()
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "CHIPARR"
		self.metadata["pitch"] = str(round(ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm'),4))
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_CHIPARRAY4SIDEFLAT, PackageCalculatorChipArray4SideFlatConcave) 