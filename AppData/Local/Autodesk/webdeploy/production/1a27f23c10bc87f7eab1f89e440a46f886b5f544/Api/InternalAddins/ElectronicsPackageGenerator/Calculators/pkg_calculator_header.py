# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules

# this class defines the package Calculator for the Axial Packages.
class PackageCalculatorHeader(pkg_calculator.PackageCalculator):
	
	def get_general_footprint(self):
		pass

	def get_3d_model_data(self):
		pass

	# process the data for 3d model generator	
	def get_ipc_3d_model_data(self):
		model_data = {}
		model_data['type'] = self.pkg_type
		model_data['DPins'] = self.ui_data['horizontalPadCount']
		model_data['D'] = self.ui_data['bodyLengthMax'] 
		model_data['EPins'] = self.ui_data['verticalPadCount']
		model_data['b'] = self.ui_data['terminalWidth']
		model_data['d'] = self.ui_data['horizontalPinPitch']
		model_data['e'] = self.ui_data['verticalPinPitch']
		if self.ui_data['footprintOriginLocation'] == constant.FOOTPRINT_LOCATION_CENTER:
			model_data['originLocationId'] = 4
		elif self.ui_data['footprintOriginLocation'] == constant.FOOTPRINT_LOCATION_PIN1:
			if self.ui_data['pinNumberSequencePattern'] == constant.PIN_NUM_SEQUENCE_LRCW:
				model_data['originLocationId'] = 0
			else:
				model_data['originLocationId'] = 3
		return model_data
		
	def build_footprint_pads(self, footprint_data):
		
		#calculate the terminal diameter. 
		terminal_diam = math.sqrt(self.ui_data['terminalWidth']*self.ui_data['terminalWidth']*2 )

		if self.ui_data['hasCustomFootprint'] :
			drill_size = self.ui_data['customHoleDiameter']
			pad_diameter = self.ui_data['customPadDiameter']
		else:
			drill_size = self.get_footprint_pad_drill_size(self.ui_data['densityLevel'],terminal_diam)
			pad_diameter = self.get_footprint_pad_diameter(self.ui_data['densityLevel'],terminal_diam,self.ui_data['padToHoleRatio'])
		
		row_num = self.ui_data['verticalPadCount']
		col_num = self.ui_data['horizontalPadCount']

		x_offset = 0
		y_offset = 0
		# adjust the location offset based on the footprint origin location and pin number sequence pattern		
		if self.ui_data['footprintOriginLocation'] == constant.FOOTPRINT_LOCATION_CENTER:
			if self.ui_data['pinNumberSequencePattern'] == constant.PIN_NUM_SEQUENCE_LRCW: # pin on is Top Left
				y_direction = 1
			else: # pin one is Bottom Left
				y_direction = -1
			x_offset = -self.ui_data['horizontalPinPitch'] * (col_num - 1) / 2
			y_offset = y_direction *self.ui_data['verticalPinPitch'] * (row_num - 1) / 2


		if self.ui_data['pinNumberSequencePattern'] == constant.PIN_NUM_SEQUENCE_LRCCW: #LRCCW - Counter-clockwise from bottom left
			# 10 9 8 7 6
			# 1 2 3 4 5
			for i in range(0, row_num):				
				for j in range(0, col_num): 
					if i % 2 == 0 :
						pad = footprint.FootprintPad(self.ui_data['horizontalPinPitch'] *j + x_offset , self.ui_data['verticalPinPitch']*i + y_offset, pad_diameter, drill_size)
					else:
						pad = footprint.FootprintPad(self.ui_data['horizontalPinPitch'] * (col_num - j - 1) + x_offset , self.ui_data['verticalPinPitch']*i + y_offset, pad_diameter, drill_size)
					pad.name = str(i*col_num + j + 1)
					pad.shape = self.ui_data['padShape']
					footprint_data.append(pad)

		elif self.ui_data['pinNumberSequencePattern'] == constant.PIN_NUM_SEQUENCE_LRCW: # LRCW - Clockwise from top left
			#1 2 3 4 5
			#10 9 8 7 6
			for i in range(0, row_num):				
				for j in range(0, col_num): 
					pad = footprint.FootprintPad(self.ui_data['horizontalPinPitch'] *j + x_offset , - self.ui_data['verticalPinPitch']*i + y_offset, pad_diameter, drill_size)
					if i % 2 == 0:
						pad.name = str(i*col_num + j + 1)
					else :
						pad.name = str((i+1)*col_num - j)
						
					pad.shape = self.ui_data['padShape']
					footprint_data.append(pad)	

		elif self.ui_data['pinNumberSequencePattern'] == constant.PIN_NUM_SEQUENCE_ZZBT: # ZZBT - ZigZag from bottom left
			#	2 4 6 8 10
			#	1 3 5 7 9
			for j in range(0, col_num): 
				for i in range(0, row_num):
					pad = footprint.FootprintPad(self.ui_data['horizontalPinPitch'] * j + x_offset , self.ui_data['verticalPinPitch']*i + y_offset, pad_diameter, drill_size)
					pad.name = str(j*row_num + i + 1)
					pad.shape = self.ui_data['padShape']
					footprint_data.append(pad)


		
	def build_silkscreen_body_outline(self, footprint_data, body_width, body_length, x_offset, y_offset):
		line1 = footprint.FootprintWire(-body_length/2 + x_offset, -body_width/2 + y_offset, -body_length/2+ x_offset, body_width/2+y_offset, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line1)
		line1_b = footprint.FootprintWire(-body_length/2 + x_offset, -body_width/2 + y_offset, -body_length/2+ x_offset, body_width/2+y_offset, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		line1_b.layer = 51
		footprint_data.append(line1_b)

		line2 = footprint.FootprintWire(-body_length/2+x_offset, body_width/2+y_offset, body_length/2+x_offset, body_width/2+y_offset, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line2)
		line2_b = footprint.FootprintWire(-body_length/2+x_offset, body_width/2+y_offset, body_length/2+x_offset, body_width/2+y_offset, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		line2_b.layer = 51
		footprint_data.append(line2_b)

		line3 = footprint.FootprintWire(body_length/2+x_offset, body_width/2+y_offset, body_length/2+x_offset, -body_width/2+y_offset, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line3)
		line3_b = footprint.FootprintWire(body_length/2+x_offset, body_width/2+y_offset, body_length/2+x_offset, -body_width/2+y_offset, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		line3_b.layer = 51
		footprint_data.append(line3_b)

		line4 = footprint.FootprintWire(body_length/2+x_offset, -body_width/2+y_offset, -body_length/2+x_offset, -body_width/2+y_offset, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		footprint_data.append(line4)
		line4_b = footprint.FootprintWire(body_length/2+x_offset, -body_width/2+y_offset, -body_length/2+x_offset, -body_width/2+y_offset, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
		line4_b.layer = 51
		footprint_data.append(line4_b)
	
	def get_pitch_info(self):
		#if both pad count are 1 use pin pitch as 0
        #if either one of the pad count is 1 use pin pitch for other
		pitch_info = ''
		if self.ui_data['verticalPadCount'] == 1 and self.ui_data['horizontalPadCount']== 1:
			pitch_info += '0'
		elif self.ui_data['horizontalPadCount'] == 1:
			pitch_info += str(int(self.ui_data['verticalPinPitch']*1000))
		elif self.ui_data['verticalPadCount'] == 1:
			pitch_info += str(int(self.ui_data['horizontalPinPitch']*1000))
		else:
			if self.ui_data['horizontalPinPitch'] == self.ui_data['verticalPinPitch']:
				pitch_info += str(int(self.ui_data['verticalPinPitch']*1000))
			else:
				pitch_info += str(int(self.ui_data['verticalPinPitch']*1000)) +  'X' + str(int(self.ui_data['horizontalPinPitch']*1000))
		return pitch_info

	def get_pitch_description(self):
		#if both pad count are 1 use pin pitch as 0
        	#if either one of the pad count is 1 use pin pitch for other
		description = ''
		ao = addin_utility.AppObjects()
		ver_pitch_mm = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm')
		ver_pitch_inch = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'in')
		hori_pitch_mm = ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'mm')
		hori_pitch_inch = ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'in')
		
		if self.ui_data['verticalPadCount'] != self.ui_data['horizontalPadCount']:
			if (self.ui_data['horizontalPadCount'] > 1 and self.ui_data['verticalPadCount'] > 1 ):
				description += str('{:.2f}'.format(round(ver_pitch_mm,3))) + ' mm (' + str('{:.2f}'.format(round(ver_pitch_inch,3))) + ' in) row pitch, '
				description += str('{:.2f}'.format(round(hori_pitch_mm,3))) + ' mm (' + str('{:.2f}'.format(round(hori_pitch_inch,3))) + ' in) col pitch, '
			elif self.ui_data['verticalPadCount'] > 1:
				description += str('{:.2f}'.format(round(ver_pitch_mm,3))) + ' mm (' + str('{:.2f}'.format(round(ver_pitch_inch,3))) + ' in) row pitch, '
			elif self.ui_data['horizontalPadCount'] > 1:
				description += str('{:.2f}'.format(round(hori_pitch_mm,3))) + ' mm (' + str('{:.2f}'.format(round(hori_pitch_inch,3))) + ' in) col pitch, '
		elif self.ui_data['horizontalPadCount'] != 1:
			description += str('{:.2f}'.format(round(ver_pitch_mm,3))) + ' mm (' + str('{:.2f}'.format(round(ver_pitch_inch,3))) + ' in) pitch, '
		return description
	
	def get_pin_count_description(self, is_short):
		# generate pin count related description
		pin_count_info = ''
		col_row_desc = str(self.ui_data['verticalPadCount']) + 'X' + str(self.ui_data['horizontalPadCount'])
		if self.ui_data['verticalPadCount'] == 1:
			pin_count_info = is_short and 'Single-row, ' or 'Single-row (' + col_row_desc + '), '
		elif self.ui_data['verticalPadCount'] == 2:
			pin_count_info = is_short and 'Double-row, ' or 'Double-row (' + col_row_desc + '), '
		elif self.ui_data['verticalPadCount'] == 3:
			pin_count_info = is_short and 'Three-row, ' or 'Three-row (' + col_row_desc + '), '
		elif self.ui_data['verticalPadCount'] == 4:
			pin_count_info = is_short and 'Four-row, ' or 'Four-row (' + col_row_desc + '), '
		else: 
			pin_count_info +=  col_row_desc + ', '
		
		return pin_count_info + str(self.ui_data['verticalPadCount']*self.ui_data['horizontalPadCount'])

	def get_ipc_package_name(self, package_name):
        #HDRV + total Pins + W Lead Width + P Row Pitch (+ X Column Pitch [if different]) + _ Row s + X Pins per Row + _ BodyLength + X Body Thickness + X Component Height + producibility level (A, B, C)
        #E.g., HDRV20W64P254_2X10_2540X254X838P
		body_height = self.ui_data['bodyHeightMax']
		if self.pkg_type == constant.PKG_TYPE_HEADER_STRAIGHT: 
			body_height += self.ui_data['terminalPostLength']
			
		pkg_name = package_name + str(self.ui_data['horizontalPadCount']*self.ui_data['verticalPadCount'])
		pkg_name += 'W' + str(int(round(self.ui_data['terminalWidth']*1000,0))) 
		pkg_name += 'P' + self.get_pitch_info()
		pkg_name += '_' + str(self.ui_data['verticalPadCount']) + 'X' + str(self.ui_data['horizontalPadCount'])
		pkg_name += '_' + str(int(round((self.ui_data['bodyLengthMax'] * 1000 +self.ui_data['bodyLengthMin'] * 1000 )/2,0)))
		pkg_name += 'X' + str(int(round((self.ui_data['bodyWidthMax'] * 1000 +self.ui_data['bodyWidthMin'] * 1000 )/2,0)))
		pkg_name += 'X' + str(int(round(body_height*1000,0)))
		if not self.ui_data['hasCustomFootprint'] :
			pkg_name += self.get_producibility_level_for_pth(self.ui_data['densityLevel'])		
		return pkg_name
		
	def get_ipc_package_description(self, family_name):

		ao = addin_utility.AppObjects()
		unit = ao.units_manager.defaultLengthUnits

		body_length = ao.units_manager.convert((self.ui_data['bodyLengthMax'] + self.ui_data['bodyLengthMin'])/2, 'cm', 'mm')
		body_width = ao.units_manager.convert((self.ui_data['bodyWidthMax'] + self.ui_data['bodyWidthMin'])/2, 'cm', 'mm')
		# get height need add post length for header straight type
		body_height = self.ui_data['bodyHeightMax']
		if self.pkg_type == constant.PKG_TYPE_HEADER_STRAIGHT: 
			body_height += self.ui_data['terminalPostLength']
		body_height = ao.units_manager.convert(body_height, 'cm', 'mm')

		type_specific_info = ''
		if self.pkg_type == constant.PKG_TYPE_HEADER_STRAIGHT or self.pkg_type == constant.PKG_TYPE_HEADER_RIGHT_ANGLE:
			type_specific_info = str('{:.2f}'.format(round(ao.units_manager.convert(self.ui_data['terminalPostLength'], 'cm', 'mm'),2))) + ' mm' +  ' mating length'
		elif self.pkg_type == constant.PKG_TYPE_HEADER_STRAIGHT_SOCKET:
			type_specific_info = str('{:.2f}'.format(round(ao.units_manager.convert(self.ui_data['bodyHeightMax'], 'cm', 'mm'),2))) + ' mm' + ' insulator length'
		elif self.pkg_type == constant.PKG_TYPE_HEADER_RIGHT_ANGLE_SOCKET:
			type_specific_info = str('{:.2f}'.format(round(body_width,2))) + ' mm' + ' insulator length'

		#compose the short description
		short_description = self.get_pin_count_description(True) + '-pin ' + family_name + ', '
		short_description += self.get_pitch_description()
		short_description += type_specific_info + ', '
		short_description += str('{:.2f}'.format(round(body_length,2)))+ ' X ' + str('{:.2f}'.format(round(body_width,2))) + ' X '
		short_description += str('{:.2f}'.format(round(body_height,2))) + ' mm body'

		
		#compose the full description
		full_description = self.get_pin_count_description(False) + '-pin ' + family_name + ' package with '
		full_description += self.get_pitch_description()
		full_description += str('{:.2f}'.format(round(ao.units_manager.convert(self.ui_data['terminalWidth'], 'cm', 'mm'),2))) + ' mm' + ' lead width, '
		if self.pkg_type == constant.PKG_TYPE_HEADER_STRAIGHT or self.pkg_type == constant.PKG_TYPE_HEADER_STRAIGHT_SOCKET:
			full_description += str('{:.2f}'.format(round(ao.units_manager.convert(self.ui_data['terminalTailLength'], 'cm', 'mm'),2))) + ' mm' +  ' tail length and '
		else:
			full_description += str('{:.2f}'.format(round(ao.units_manager.convert(self.ui_data['verticalTerminalTailLength'], 'cm', 'mm'),2))) + ' mm' +  ' tail length and '

		full_description += type_specific_info + ' '

		if self.pkg_type == constant.PKG_TYPE_HEADER_STRAIGHT or self.pkg_type == constant.PKG_TYPE_HEADER_STRAIGHT_SOCKET:
			full_description += ' with overall size '
		else:
			full_description += ' with body size '

		full_description += str('{:.2f}'.format(round(body_length,2)))+ ' X ' + str('{:.2f}'.format(round(body_width,2))) + ' X ' + str('{:.2f}'.format(round(body_height,2))) + ' mm'

		if self.ui_data['verticalPadCount']*self.ui_data['horizontalPadCount'] != 1:
			full_description += ', pin pattern - ' 
		
			if self.ui_data['pinNumberSequencePattern'] == constant.PIN_NUM_SEQUENCE_LRCCW:
				full_description += 'counter-clockwise from bottom left'
			elif self.ui_data['pinNumberSequencePattern'] == constant.PIN_NUM_SEQUENCE_LRCW:
				full_description += 'clockwise from top left'
			elif self.ui_data['pinNumberSequencePattern'] == constant.PIN_NUM_SEQUENCE_ZZBT:
				full_description += 'zigzag from bottom left'

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		super().get_ipc_package_metadata()
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "HEADER"
		if self.ui_data["verticalPadCount"] == 1:
			if self.ui_data["horizontalPadCount"] > 1: #store other pitch in this metadata if other pad count is more than 1
				self.metadata['pitch'] = str(round(ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'mm'), 4))		
		else:
			self.metadata['pitch'] = str(round(ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm'), 4))
					
		if self.ui_data["horizontalPadCount"] != 1:
			if self.ui_data["verticalPadCount"] > 1:	#store metadata if other pad count is more than 1
				self.metadata['pitch2'] = str(round(ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'mm'), 4))		
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount']* self.ui_data['verticalPadCount'])

		return self.metadata