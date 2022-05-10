# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules

class PackageCalculatorChipArray2SideConvex(pkg_calculator.PackageCalculator):
	
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
		model_data['DPins'] = self.ui_data['horizontalPadCount']	

		# get the proper body color
		body_color = self.get_body_color()
		model_data['color_r'] = body_color[0]
		model_data['color_g'] = body_color[1]
		model_data['color_b'] = body_color[2] 	

		return model_data

	def get_footprint(self):

		footprint_data = []

		L_min = self.ui_data['bodyWidthMin']	
		L_max = self.ui_data['bodyWidthMax']	
		T_min = self.ui_data['padWidthMin']	
		T_max = self.ui_data['padWidthMax']	
		W_min = self.ui_data['padHeightMin']	
		W_max = self.ui_data['padHeightMax']	
		W_min_odd = self.ui_data['oddPadHeightMin']	
		W_max_odd = self.ui_data['oddPadHeightMax']

		toe_goal = ipc_rules.PAD_GOAL_CHIPARRAY['toeFilletMaxMedMin'][self.ui_data['densityLevel']]
		heel_goal = ipc_rules.PAD_GOAL_CHIPARRAY['heelFilletMaxMedMin'][self.ui_data['densityLevel']]
		side_goal = ipc_rules.PAD_GOAL_CHIPARRAY['sideFilletMaxMedMin'][self.ui_data['densityLevel']]
		
		pin_num = self.ui_data['horizontalPadCount']
		row_num = pin_num/2
		vert_pin_pitch = self.ui_data['verticalPinPitch']

		for i in range (0, pin_num):
			col = math.floor(i / row_num)
			row = i % row_num
			if col %2 == 1 :
				row = row_num - 1 - row #in odd columns change order from bottom to top
			if (i == 0 or i == row_num - 1 or i == row_num or i == pin_num - 1):
				#if (W_max != W_max_odd or W_min != W_min_odd):
				if self.ui_data['hasCustomFootprint'] :
					pad_width = self.ui_data['customPadLength']
					pad_height = self.ui_data['customOddPadWidth']
					pin_pitch = self.ui_data['customPadToPadGap'] + self.ui_data['customPadLength']
				else:
					pad_width, pad_height, pin_pitch = self.get_footprint_smd_data(L_min, L_max, T_min, T_max, W_min_odd, W_max_odd, toe_goal, heel_goal, side_goal) 	
			else:
				if self.ui_data['hasCustomFootprint'] :
					pad_width = self.ui_data['customPadLength']
					pad_height = self.ui_data['customPadWidth']
					pin_pitch = self.ui_data['customPadToPadGap'] + self.ui_data['customPadLength']
				else:
					pad_width, pad_height, pin_pitch = self.get_footprint_smd_data(L_min, L_max, T_min, T_max, W_min, W_max, toe_goal, heel_goal, side_goal) 	
			# create Pad
			pad = footprint.FootprintSmd((col-0.5)*pin_pitch, ((row_num - 1) / 2 - row)* vert_pin_pitch, pad_width, pad_height)
			pad.name = str(i + 1)
			pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
			footprint_data.append(pad)

		#draw silkscreen
		odd_pad_width, odd_pad_height, odd_pin_pitch = self.get_footprint_smd_data(L_min, L_max, T_min, T_max, W_min_odd, W_max_odd, toe_goal, heel_goal, side_goal) 	
		
		#build the silkscreen 
		first_left_pad = footprint_data[0]
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])

		# pin one marker
		self.build_silkscreen_pin_one_marker(footprint_data, -body_width/2 + L_max/2 , (row_num - 1) * vert_pin_pitch/2  , pad_width, pad_height, body_width, False)

		top_edge = first_left_pad.center_point_y + first_left_pad.height/2 + ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']
		bot_edge = -top_edge

		top_line_y = top_edge + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2
		bot_line_y = -top_line_y

		if top_edge + ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']/2 > body_length/2 :
			line_top = footprint.FootprintWire(-body_width/2, top_line_y, body_width/2, top_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_top)	

			line_bot = footprint.FootprintWire(-body_width/2, bot_line_y, body_width/2, bot_line_y, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line_bot)		
		else:
			top_line_left = footprint.FootprintWire(-body_width/2, body_length/2, -body_width/2, top_edge, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(top_line_left)

			top_line_top = footprint.FootprintWire(-body_width/2, body_length/2, body_width/2, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(top_line_top)	

			top_line_right = footprint.FootprintWire(body_width/2, top_edge, body_width/2, body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(top_line_right)	

			bot_line_left = footprint.FootprintWire(-body_width/2, -body_length/2, -body_width/2, bot_edge, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(bot_line_left)

			bot_line_top = footprint.FootprintWire(-body_width/2, -body_length/2, body_width/2, -body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(bot_line_top)	

			bot_line_right = footprint.FootprintWire(body_width/2, bot_edge, body_width/2, -body_length/2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(bot_line_right)	

		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])

		#build the text
		self.build_footprint_text(footprint_data, 0)

		return footprint_data
	
	def get_ipc_package_name(self):
	
		if self.ui_data['padHeightMin']	 == self.ui_data['oddPadHeightMin'] and self.ui_data['padHeightMax'] == self.ui_data['oddPadHeightMax']:
			pin_same_size = True
		else : 
			pin_same_size = False

		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_RESISTOR):
			family_name = 'RESCAXE' if pin_same_size else 'RESCAXS'  
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_INDUCTOR):
			family_name = 'INDCAXE' if pin_same_size else 'INDCAXS'  
		if (self.ui_data['componentFamily'] == constant.COMP_FAMILY_NONPOLARIZED_CAPACITOR):
			family_name = 'CAPCAXE' if pin_same_size else 'CAPCAXS'  

		#family name + Pitch P + Body Length X Body Width X Height - Pin Qty
		pkg_name =  family_name
		pkg_name += str(int((self.ui_data['verticalPinPitch']*1000))) 
		pkg_name += 'P' + str(int(((self.ui_data['bodyLengthMax'] * 1000 +self.ui_data['bodyLengthMin'] * 1000)/2)))
		pkg_name += 'X' + str(int(((self.ui_data['bodyWidthMax'] * 1000 +self.ui_data['bodyWidthMin'] * 1000)/2))) 
		pkg_name += 'X' + str(int((self.ui_data['bodyHeightMax']*1000))) 
		pkg_name += '-' + str(int(self.ui_data['horizontalPadCount']))
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_density_level_for_smd(self.ui_data['densityLevel'])
			
		return pkg_name	

	def get_ipc_package_description(self):
	
		ao = addin_utility.AppObjects()
		unit = 'mm'	

		pin_pitch = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', unit)

		short_description = str(int(self.ui_data['horizontalPadCount'])) + '-Chiparray 2-Side Convex, ' 
		short_description += str('{:.2f}'.format(round(pin_pitch,2))) + ' ' + unit + ' pitch, '
		short_description += self.get_body_description(True, True) + unit + ' body'

		full_description = str(int(self.ui_data['horizontalPadCount'])) + '-pin Chiparray 2-Side Convex package' 
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
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_CHIPARRAY2SIDECONVEX, PackageCalculatorChipArray2SideConvex) 