# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules

# this class defines the package Calculator for the ECAP Package.
class PackageCalculatorBga(pkg_calculator.PackageCalculator):
	
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
		model_data['b'] = self.ui_data['padWidthMax']
		model_data['E'] = self.ui_data['bodyWidthMax']
		model_data['D'] = self.ui_data['bodyLengthMax']
		model_data['d'] = self.ui_data['verticalPinPitch']
		model_data['e'] = self.ui_data['horizontalPinPitch']
		model_data['DPins'] = self.ui_data['horizontalPadCount']
		model_data['EPins'] = self.ui_data['verticalPadCount']
		return model_data

	def get_footprint_smd_data(self):

		if self.ui_data['padWidthMin'] == 0:  return 0

		# pad width and length are same for BGA. Either we can use width or length.
		ball_dia_idx = int((self.ui_data['padWidthMax'] + self.ui_data['padWidthMin'])*5000) 

		if self.ui_data['terminalType'] == constant.TERMINAL_TYPE_COLLAPSING:
			bga_goals = ipc_rules.PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE.get(str(ball_dia_idx))
		else:
			bga_goals = ipc_rules.PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE.get(str(ball_dia_idx))

		if bga_goals == None:
			if self.ui_data['terminalType'] == constant.TERMINAL_TYPE_COLLAPSING:
				dia_range = ipc_rules.PAD_GOAL_BGA_COLLAPSIBLE_RANGE
			else:
				dia_range = ipc_rules.PAD_GOAL_BGA_NONCOLLAPSIBLE_RANGE

			if ball_dia_idx < dia_range[0][0]:
				ball_dia_idx = dia_range[0][0]
			elif ball_dia_idx > dia_range[len(dia_range) - 1][1]:
				ball_dia_idx = dia_range[len(dia_range) - 1][1]
			else:
				for i in range(0, len(dia_range)):
					current_range = dia_range[i]
					if ball_dia_idx > current_range[0] and ball_dia_idx < current_range[1]:
						ball_dia_idx = current_range[0]
						break
			# get the gaols again based on the new index value
			if self.ui_data['terminalType'] == constant.TERMINAL_TYPE_COLLAPSING:
				bga_goals = ipc_rules.PAD_GOAL_BGA_COLLAPSIBLE_BALLDIA_TABLE.get(str(ball_dia_idx))
			else:
				bga_goals = ipc_rules.PAD_GOAL_BGA_NONCOLLAPSIBLE_BALLDIA_TABLE.get(str(ball_dia_idx))
		
		#	bga_goals[0] - percentage change
		#	bga_goals[1] - variation (+)
		#	bga_goals[2] - round off to increment
		
		X = round(ball_dia_idx * (1 + bga_goals[0])/bga_goals[2]) * bga_goals[2] + bga_goals[1]
		pad_dia = X/10000 # convert to cm unit
		return pad_dia

	def get_nth_row_name(self, n):
		name = ""
		while n > 0:
			n, remainder = divmod(n - 1, 26)
			name = chr(65 + remainder) + name
		return name

	def get_footprint(self):
		
		footprint_data = []

		# get the smd pad diameter. 
		pad_diameter = self.get_footprint_smd_data()

		#BGA row names do not support these letters to avoid confusion of treating these letters as numbers 
		#(e.g., I -> 1, O, Q -> 0, S -> 5, Z -> 2, X -> need input/NA)
		exclude_list = ['I', 'O', 'Q', 'S', 'X', 'Z']
		
		# if if ball diameter is zero dont push pads
		if pad_diameter > 0 :
			row_count = grid_row = self.ui_data['horizontalPadCount']
			grid_col = self.ui_data['verticalPadCount']

			row_names = []
			n = 1
			while n <= row_count:
				valid = True
				name = self.get_nth_row_name(n)

				for i in name:
					if i in exclude_list:
						valid = False
						break

				if valid: 
					row_names.append(name) 
				else: 
					row_count +=1 #row names array must contains rowCount number elements

				n +=1

			if self.ui_data['hasCustomFootprint'] :
				pad_diameter = self.ui_data['customPadDiameter']
			#build all the bga pads.
			for i in range(0, grid_row):
				for j in range(0, grid_col):
					pos_x = j * self.ui_data['horizontalPinPitch'] - self.ui_data['horizontalPinPitch'] * (grid_col - 1) / 2
					pos_y = -i * self.ui_data['verticalPinPitch'] + self.ui_data['verticalPinPitch']  * (grid_row - 1) / 2
					pad = footprint.FootprintSmd(pos_x, pos_y, pad_diameter, pad_diameter)
					pad.thermals = 'no'
					pad.roundness = constant.OBLONG_PAD_ROUNDNESS
					pad.name = row_names[i]+str(j+1)
					footprint_data.append(pad)


		first_left_pad = footprint_data[0]
		#build the silkscreens 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])
		stroke_width = ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth']
		silkscreen_offset = ipc_rules.SILKSCREEN_ATTRIBUTES['CornerClipPercentage']*min(body_width, body_length)

		# pin one marker
		self.build_silkscreen_pin_one_marker(footprint_data, first_left_pad.center_point_x, first_left_pad.center_point_y, first_left_pad.width, first_left_pad.height, body_width, True)

		#top left corner 		
		line_hori = footprint.FootprintWire(- body_width/2, body_length/2, - body_width/2 + silkscreen_offset, body_length/2, stroke_width)
		footprint_data.append(line_hori)
		line_vert = footprint.FootprintWire(- body_width/2, body_length/2, -body_width/2, body_length/2 - silkscreen_offset, stroke_width)
		footprint_data.append(line_vert)
		#top right corner 		
		line_hori = footprint.FootprintWire(body_width/2, body_length/2, body_width/2 - silkscreen_offset, body_length/2, stroke_width)
		footprint_data.append(line_hori)
		line_vert = footprint.FootprintWire(body_width/2, body_length/2, body_width/2, body_length/2 - silkscreen_offset, stroke_width)
		footprint_data.append(line_vert)
		#bottom left corner 		
		line_hori = footprint.FootprintWire(- body_width/2, -body_length/2, - body_width/2 + silkscreen_offset, -body_length/2, stroke_width)
		footprint_data.append(line_hori)
		line_vert = footprint.FootprintWire(- body_width/2, -body_length/2, -body_width/2, - body_length/2 + silkscreen_offset, stroke_width)
		footprint_data.append(line_vert)
		#bottom right corner 		
		line_hori = footprint.FootprintWire(body_width/2, -body_length/2, body_width/2 - silkscreen_offset, -body_length/2, stroke_width)
		footprint_data.append(line_hori)
		line_vert = footprint.FootprintWire(body_width/2, -body_length/2, body_width/2, -body_length/2 + silkscreen_offset, stroke_width)
		footprint_data.append(line_vert)
	
		# build the assembly body outline
		self.build_assembly_body_outline(footprint_data, self.ui_data['bodyWidthMax'], self.ui_data['bodyLengthMax'], stroke_width)

		#build the text
		self.build_footprint_text(footprint_data, 0)

		return footprint_data


	def get_ipc_package_name(self):
		"""
		single pitch used in both direction: name + Pin Qty + C or N + Pitch P + Ball Columns X Ball Rows_Body Length X Body Width X Height, C: collapsing ball, N: non-collapsing ball
        dual pitch specified: name + Pin Qty + C or N + Col Pitch X Row Pitch P + Ball Columns X Ball Rows_Body Length X Body Width X Height, C: collapsing ball, N: non-collapsing ball
        dual pitch package name falls back to single pitch package name when both pitch are equal
		"""
		if self.ui_data['terminalType'] == constant.TERMINAL_TYPE_COLLAPSING:
			terminal_str = 'C'
		else:
			terminal_str = 'N'
			
		pkg_name = 'BGA'
		pkg_name += str(self.ui_data['horizontalPadCount']* self.ui_data['verticalPadCount']) + terminal_str

		if self.ui_data['verticalPinPitch'] == self.ui_data['horizontalPinPitch']:
			pkg_name += str(int((self.ui_data['verticalPinPitch']*1000))) + 'P'
		else:
			pkg_name += str(int((self.ui_data['horizontalPinPitch']*1000))) + 'X' + str(int(round(self.ui_data['verticalPinPitch']*1000))) + 'P'

		pkg_name += str(self.ui_data['verticalPadCount']) + 'X' + str(self.ui_data['horizontalPadCount']) + '_'
		pkg_name += str(int(((self.ui_data['bodyLengthMax'] * 1000 + self.ui_data['bodyLengthMin'] * 1000)/2))) + 'X'
		pkg_name += str(int(((self.ui_data['bodyWidthMax'] * 1000 + self.ui_data['bodyWidthMin'] * 1000)/2))) + 'X'
		pkg_name += str(int((self.ui_data['bodyHeightMax']*1000))) 
		return pkg_name

	def get_ipc_package_description(self):
	
		ao = addin_utility.AppObjects()
		unit = 'mm'	

		ver_pin_pitch = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', unit)
		hori_pin_pitch = ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', unit)

		if self.ui_data['terminalType'] == constant.TERMINAL_TYPE_COLLAPSING:
			terminal_str = 'collapsing'
		else:
			terminal_str = 'non-collapsing'

		short_description = str(self.ui_data['horizontalPadCount']* self.ui_data['verticalPadCount']) + '-BGA, '
		short_description += terminal_str + ', '
		
		if ver_pin_pitch == hori_pin_pitch:
			short_description += str('{:.2f}'.format(round(ver_pin_pitch,2))) + ' ' + unit + ' pitch, '
		else:
			short_description += str('{:.2f}'.format(round(hori_pin_pitch,2))) + ' ' + unit + ' col pitch, '
			short_description += str('{:.2f}'.format(round(ver_pin_pitch,2))) + ' ' + unit + ' row pitch, '
		short_description += self.get_body_description(True,False) + unit + ' body'

		full_description = str(self.ui_data['horizontalPadCount']* self.ui_data['verticalPadCount']) + '-pin '
		full_description += terminal_str + ' BGA package with '
		full_description += str('{:.2f}'.format(round(hori_pin_pitch,2))) + ' ' + unit + ' col pitch and ' + str('{:.2f}'.format(round(ver_pin_pitch,2))) + ' ' + unit + ' row pitch'
		full_description += self.get_body_description(False,True) + unit
			
		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		super().get_ipc_package_metadata()
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "BGA"
		self.metadata["pitch"] = str(round(ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm'), 4))
		self.metadata["pitch2"] = str(round(ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'mm'), 4))
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount']* self.ui_data['verticalPadCount'])
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_BGA, PackageCalculatorBga) 