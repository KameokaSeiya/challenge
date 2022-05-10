# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant, footprint_utility
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules, pkg_calculator_surface_mount_header

# this class defines the package Calculator 
class PackageCalculatorSurfaceMountPinHeaderRightAngle(pkg_calculator.PackageCalculator):
	
	# initialize the data members
	def __init__(self, pkg_type: str):
		super().__init__(pkg_type)

	def get_general_footprint(self):
		pass

	def get_3d_model_data(self):
		pass    

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

	def get_silkscreen_body_width(self, silkscreen_map_body_type):
		# this case is different form othe SMD Headers (see L and E params)
		body_width = self.ui_data['bodyHeightMax']
		return body_width              

	# process the data for 3d model generator	
	def get_ipc_3d_model_data(self):
		model_data = {}
		model_data['type'] = self.pkg_type
		model_data['cols'] = self.ui_data['horizontalPadCount']
		model_data['e'] = self.ui_data['verticalPinPitch']
		model_data['d'] = self.ui_data['horizontalPinPitch']
		model_data['b'] = self.ui_data['padHeightMax']
		model_data['D'] = self.ui_data['bodyLengthMax']
		model_data['E'] = self.ui_data['verticalLeadToLeadSpanMax']
		model_data['L'] = self.ui_data['bodyHeightMax']
		model_data['L1'] = self.ui_data['terminalTailLength1']
		model_data['L2'] = self.ui_data['terminalPostLength']
		model_data['L3'] = self.ui_data['terminalTailLength2']
		model_data['footprintOriginLocation'] = self.ui_data['footprintOriginLocation']

		if self.ui_data['footprintOriginLocation'] == constant.FOOTPRINT_LOCATION_CENTER:
			model_data['originLocationId'] = 4
		elif self.ui_data['footprintOriginLocation'] == constant.FOOTPRINT_LOCATION_PIN1:
			if self.ui_data['pinNumberSequencePattern'] == constant.PIN_NUM_SEQUENCE_LRCW:
				model_data['originLocationId'] = 1
			else:
				model_data['originLocationId'] = 3

		#type of row
		if self.ui_data['verticalPadCount'] == constant.ROW_TYPE_SINGLE:
			model_data['rows'] = 1
		else :
			model_data['rows'] = 2

		return model_data
		
	def get_footprint(self):
		footprint_data = []

		#build pads
		pad_height = self.ui_data['customPadLength']
		pad_width = self.ui_data['customPadWidth']

		#type of row
		if self.ui_data['verticalPadCount'] == constant.ROW_TYPE_SINGLE:
			row_num = 1
		else :
			row_num = 2
		col_num = self.ui_data['horizontalPadCount']
		pin_pitch_y = (self.ui_data['customPadSpan1'] - self.ui_data['customPadLength'])

		if row_num == 2 :

			x_offset = 0
			y_offset = 0

			# adjust the location offset based on the footprint origin location and pin number sequence pattern		
			if self.ui_data['footprintOriginLocation'] == constant.FOOTPRINT_LOCATION_CENTER:
				x_offset = -self.ui_data['horizontalPinPitch'] * (col_num - 1) / 2
				y_offset = pin_pitch_y/2
				y_direction = -1
			else : 
				#x_offset = 0
				if self.ui_data['pinNumberSequencePattern'] == constant.PIN_NUM_SEQUENCE_LRCW: # pin on is Top Left
					y_direction = -1
					y_offset = self.ui_data['customPadLength']/2 - self.ui_data['padHeightMax']
				else: # pin one is Bottom Left
					y_direction = 1
					y_offset = self.ui_data['customPadLength']/2 - self.ui_data['padHeightMax']

			if self.ui_data['pinNumberSequencePattern'] == constant.PIN_NUM_SEQUENCE_LRCCW: #LRCCW - Counter-clockwise from bottom left
				# 10 9 8 7 6
				# 1 2 3 4 5
				for i in range(0, row_num):				
					for j in range(0, col_num): 
						if i % 2 == 0 :
							pad = footprint.FootprintSmd(self.ui_data['horizontalPinPitch'] *j + x_offset , y_direction *pin_pitch_y*i + y_offset, pad_width, pad_height)
						else:
							pad = footprint.FootprintSmd(self.ui_data['horizontalPinPitch'] * (col_num - j - 1) + x_offset , y_direction *pin_pitch_y*i + y_offset, pad_width, pad_height)
						pad.name = str(i*col_num + j + 1)
						pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
						footprint_data.append(pad)

			elif self.ui_data['pinNumberSequencePattern'] == constant.PIN_NUM_SEQUENCE_LRCW: # LRCW - Clockwise from top left
				#1 2 3 4 5
				#10 9 8 7 6
				for i in range(0, row_num):				
					for j in range(0, col_num): 
						pad = footprint.FootprintSmd(self.ui_data['horizontalPinPitch'] *j + x_offset , y_direction * pin_pitch_y*i + y_offset, pad_width, pad_height)
						if i % 2 == 0:
							pad.name = str(i*col_num + j + 1)
						else :
							pad.name = str((i+1)*col_num - j)
						
						pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
						footprint_data.append(pad)	

			elif self.ui_data['pinNumberSequencePattern'] == constant.PIN_NUM_SEQUENCE_ZZBT: # ZZBT - ZigZag from bottom left
				#	2 4 6 8 10
				#	1 3 5 7 9
				for j in range(0, col_num): 
					for i in range(0, row_num):
						pad = footprint.FootprintSmd(self.ui_data['horizontalPinPitch'] * j + x_offset , y_direction *  pin_pitch_y*i + y_offset, pad_width, pad_height )
						pad.name = str(j*row_num + i + 1)
						pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
						footprint_data.append(pad)
		else : 
			for i in range(0, col_num):
				col_index = i % (col_num )
				smd_pos_x = -((col_num - 1)/2 - col_index) * self.ui_data['horizontalPinPitch']
				if self.ui_data['footprintOriginLocation'] == constant.FOOTPRINT_LOCATION_CENTER:
					x_offset = 0
				else :
					x_offset = (col_num - 1) * self.ui_data['horizontalPinPitch']/2
				
				y_offset = 0
				pad = footprint.FootprintSmd(smd_pos_x + x_offset , y_offset, pad_width, pad_height )
				pad.name = str(i + 1)
				pad.roundness = footprint_utility.get_smd_pad_roundness(self.ui_data)
				footprint_data.append(pad)

		#build body silkscreen 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		body_length = self.get_silkscreen_body_length(self.ui_data['silkscreenMappingTypeToBody'])

		#type of row
		if self.ui_data['verticalPadCount'] == constant.ROW_TYPE_SINGLE:
			rows = 1
		else :
			rows = 2
		L3 = self.ui_data['terminalTailLength2']
		L1 = self.ui_data['terminalTailLength1']
		e = self.ui_data['verticalPinPitch']

		body_offset_x = 0
		body_offset_y = 0
		# calculate the body offset from the original based on the footprint location and pin sequence pattern
		if self.ui_data['footprintOriginLocation'] == constant.FOOTPRINT_LOCATION_CENTER:
			body_offset_x = 0
			if rows == 2 :
				body_offset_y = -L3 - body_width/2 + (L3 - L1)/2 + e/2
			else : 
				body_offset_y = -L3 - body_width/2 + L3/4

		elif self.ui_data['footprintOriginLocation'] == constant.FOOTPRINT_LOCATION_PIN1:
			body_offset_x = self.ui_data['horizontalPinPitch'] * (self.ui_data['horizontalPadCount'] - 1) / 2
			if rows == 2 : 
				if self.ui_data['pinNumberSequencePattern'] == 'LRCW': # pin on is Top Left
					body_offset_y = -L3 - body_width/2 + L3/4
				else: # pin one is Bottom Left
					body_offset_y = -L3 - body_width/2 + L3 - L1 + L3/8
			else : 
				body_offset_y = -L3 - body_width/2 + L3/4

		self.build_silkscreen_body_outline(footprint_data, body_width, body_length, body_offset_x, body_offset_y )

		#build terminal outlines
		col_num = self.ui_data['horizontalPadCount']
		for i in range(0, col_num):
			x1 = body_offset_x - (col_num-1)*self.ui_data['horizontalPinPitch']/2 +  i*self.ui_data['horizontalPinPitch']
			x2 = x1
			y1 = body_offset_y - body_width/2 
			y2 = y1 - self.ui_data['terminalPostLength'] 
			line = footprint.FootprintWire(x1, y1, x2, y2, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
			footprint_data.append(line)

		#build the text
		self.build_footprint_text(footprint_data, 0)

		#build pin one marker
		first_pad = footprint_data[0]
		pin_marker_size = ipc_rules.SILKSCREEN_ATTRIBUTES['dotPinMarkerSize']
		clearance = ipc_rules.SILKSCREEN_ATTRIBUTES['PinMarkerDotClearance'] + pin_marker_size/2

		pin_marker_x = first_pad.center_point_x
		
		if self.ui_data['pinNumberSequencePattern'] == 'LRCW': # pin one is Top Left. build marker on top
			pad_y = first_pad.center_point_y + first_pad.height/2
			text_offset_y = y_offset + (ipc_rules.SILKSCREEN_ATTRIBUTES['PinMarkerDotClearance'] + pin_marker_size)/2
			if (body_width/2 + y_offset) > pad_y:
				pin_marker_y = body_width/2 + y_offset + clearance
			else : 
				pin_marker_y = pad_y + clearance
		else: #pin one is bottome, build marker at bottom 
			pad_y = first_pad.center_point_y - first_pad.height/2
			text_offset_y = y_offset - (ipc_rules.SILKSCREEN_ATTRIBUTES['PinMarkerDotClearance'] + pin_marker_size)/2
			if (y_offset - body_width/2) < pad_y:
				pin_marker_y = y_offset - body_width/2 - clearance
			else : 
				pin_marker_y = pad_y - clearance
			if self.ui_data['footprintOriginLocation'] == constant.FOOTPRINT_LOCATION_CENTER :
				pin_marker_y = -first_pad.center_point_y - first_pad.height/2 - clearance

		if row_num == 2 :
			pin_marker = footprint.FootprintCircle(pin_marker_x, pin_marker_y, 0, pin_marker_size/2)
		else:
			if col_num % 2 == 0 :
				pin_marker_y = first_pad.center_point_y - first_pad.height/2 - clearance
			else :
				pin_marker_y = first_pad.center_point_y + first_pad.height/2 + clearance
			pin_marker = footprint.FootprintCircle(pin_marker_x, pin_marker_y, 0, pin_marker_size/2)
		
		footprint_data.append(pin_marker)
		
		return footprint_data

	def get_pitch_info(self):
		#if both pad count are 1 use pin pitch as 0
        #if either one of the pad count is 1 use pin pitch for other
		pitch_info = ''
		if self.ui_data['verticalPadCount'] == constant.ROW_TYPE_SINGLE and self.ui_data['horizontalPadCount']== 1:
			pitch_info += '0'
		elif self.ui_data['horizontalPadCount'] == 1:
			pitch_info += str(int(self.ui_data['verticalPinPitch']*1000))
		elif self.ui_data['verticalPadCount'] == constant.ROW_TYPE_SINGLE:
			pitch_info += str(int(self.ui_data['horizontalPinPitch']*1000))
		else:
			if self.ui_data['horizontalPinPitch'] == self.ui_data['verticalPinPitch']:
				pitch_info += str(int(self.ui_data['verticalPinPitch']*1000))
			else:
				pitch_info += str(int(self.ui_data['verticalPinPitch']*1000)) +  'X' + str(int(self.ui_data['horizontalPinPitch']*1000))
		return pitch_info

	def get_ipc_package_name(self):

		if self.ui_data['verticalPadCount'] == constant.ROW_TYPE_SINGLE:
			row_num = 1
		else :
			row_num = 2

		pkg_name = 'HDRRA_SMD_' + str(self.ui_data['horizontalPadCount']* row_num)
		pkg_name += 'S' + str(int(round(self.ui_data['padHeightMax']*1000,0)))
		pkg_name += 'P' + self.get_pitch_info()
		pkg_name += '_' + str(row_num) + 'X' + str(self.ui_data['horizontalPadCount'])
		pkg_name += '_' + str(int(round((self.ui_data['bodyLengthMax'] * 1000 +self.ui_data['bodyLengthMin'] * 1000 )/2,0)))
		pkg_name += 'X' + str(int(round(self.ui_data['bodyHeightMax']*1000,0)))
		pkg_name += 'X' + str(int(round((self.ui_data['verticalLeadToLeadSpanMin'] * 1000 +self.ui_data['verticalLeadToLeadSpanMax'] * 1000 )/2,0)))
		
		return pkg_name

	def get_ipc_package_description(self):
	
		ao = addin_utility.AppObjects()
		unit = 'mm'	

		col_num = self.ui_data['horizontalPadCount']
		mating_length = ao.units_manager.convert(self.ui_data['terminalPostLength'], 'cm', 'mm')
		body_length = ao.units_manager.convert((self.ui_data['bodyLengthMax'] + self.ui_data['bodyLengthMin'])/2, 'cm', 'mm')
		body_width = ao.units_manager.convert(self.ui_data['bodyHeightMax'], 'cm', 'mm')
		body_height = ao.units_manager.convert((self.ui_data['verticalLeadToLeadSpanMax'] + self.ui_data['verticalLeadToLeadSpanMin'])/2, 'cm', 'mm')
		lead_width = ao.units_manager.convert((self.ui_data['padHeightMax'] + self.ui_data['padHeightMin'])/2, 'cm', 'mm')
		tail_length = ao.units_manager.convert(self.ui_data['terminalTailLength2'], 'cm', 'mm')
		row_pitch_mm = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm')
		row_pitch_inch = ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'in')
		ver_pitch_mm = ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'mm')
		ver_pitch_inch = ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'in')

		if self.ui_data['verticalPadCount'] == constant.ROW_TYPE_SINGLE:
			row_num = 1
		else :
			row_num = 2

		#compose the short description
		if row_num == 1 :
			short_description = 'Single-row, '
		else : 
			short_description = 'Double-row, '
		short_description += str(self.ui_data['horizontalPadCount']* row_num) + ' - pin SMD Header (Male) Right Angle, '
		if row_num == 2 :
			short_description += str('{:.2f}'.format(round(row_pitch_mm,3))) + ' mm (' + str('{:.2f}'.format(round(row_pitch_inch,3))) + ' in) row pitch, '
		if not col_num == 1:
			short_description += str('{:.2f}'.format(round(ver_pitch_mm,3))) + ' mm (' + str('{:.2f}'.format(round(ver_pitch_inch,3))) + ' in) col pitch, '
		
		short_description += str('{:.2f}'.format(round(mating_length,2))) + ' mm mating length(L2), '
		short_description += str('{:.2f}'.format(round(body_length,2)))+ ' X ' + str('{:.2f}'.format(round(body_width,2))) + ' X '
		short_description += str('{:.2f}'.format(round(body_height,2))) + ' mm body'

		#compose the full description
		if row_num == 1 :
			full_description = 'Single-row (1X' + str(self.ui_data['horizontalPadCount']) + '), '
		else : 
			full_description = 'Double-row (2X' + str(self.ui_data['horizontalPadCount']) + '), '
		full_description += str(self.ui_data['horizontalPadCount']* row_num) + ' - pin SMD Header (Male) Right Angle package with '
		if row_num == 2 :
			full_description += str('{:.2f}'.format(round(row_pitch_mm,3))) + ' mm (' + str('{:.2f}'.format(round(row_pitch_inch,3))) + ' in) row pitch, '
		if not col_num == 1:
			full_description += str('{:.2f}'.format(round(ver_pitch_mm,3))) + ' mm (' + str('{:.2f}'.format(round(ver_pitch_inch,3))) + ' in) col pitch, '
		
		full_description += str('{:.2f}'.format(round(lead_width,2))) + ' mm lead width, '
		full_description += str('{:.2f}'.format(round(tail_length,2))) + ' mm tail length (L3) and '
		full_description += str('{:.2f}'.format(round(mating_length,2))) + ' mm mating length with overall size '
		full_description += str('{:.2f}'.format(round(body_length,2)))+ ' X ' + str('{:.2f}'.format(round(body_width,2))) + ' X '
		full_description += str('{:.2f}'.format(round(body_height,2))) + ' mm '

		if row_num == 2:
			full_description += ', pin-pattern - '
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
		if self.ui_data["verticalPadCount"] == constant.ROW_TYPE_SINGLE:
			if self.ui_data["horizontalPadCount"] > 1: #store other pitch in this metadata if other pad count is more than 1
				self.metadata['pitch'] = str(round(ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'mm'), 4))		
		else:
			self.metadata['pitch'] = str(round(ao.units_manager.convert(self.ui_data['verticalPinPitch'], 'cm', 'mm'), 4))
					
		if self.ui_data["horizontalPadCount"] != 1:
			if self.ui_data["verticalPadCount"] == constant.ROW_TYPE_DOUBLE:	#store metadata if other pad count is more than 1
				self.metadata['pitch2'] = str(round(ao.units_manager.convert(self.ui_data['horizontalPinPitch'], 'cm', 'mm'), 4))		
		if self.ui_data["verticalPadCount"] == constant.ROW_TYPE_DOUBLE:
			self.metadata["pins"] = str(self.ui_data['horizontalPadCount']* 2) #the vertical pad count is 2 here.
		else : 
			self.metadata["pins"] = str(self.ui_data['horizontalPadCount']) #the vertical pad count is 1 here.
		
		return self.metadata

# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_SMD_HEADER_RIGHT_ANGLE, PackageCalculatorSurfaceMountPinHeaderRightAngle) 
