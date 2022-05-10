# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

from ..FootprintGenerators import footprint
from ..Calculators import ipc_rules
from ..Utilities import constant
import math
class CalculatorFactory:
    def __init__(self):
        self._creators = {}

    def register_calculator(self, pkg_type, creator):
        self._creators[pkg_type] = creator

    def get_calculator(self, pkg_type):
        creator = self._creators.get(pkg_type)
        if not creator:
            raise ValueError(pkg_type)
        return creator(pkg_type)


calc_factory = CalculatorFactory()

# this class is defined to apply the IPC rules based on the user inputs. 
class PackageCalculator(object):

	# initialize the data members
	def __init__(self, pkg_type: str):
		self.pkg_type = pkg_type	
		self.ui_data = {}
		self.metadata = dict.fromkeys(constant.META_PROPERTIES, "")

	def get_footprint(self):
		raise AssertionError

	def get_general_footprint(self):
		raise AssertionError

	def get_ipc_3d_model_data(self):
		raise AssertionError
			
	def get_3d_model_data(self):
		raise AssertionError	

	def get_ipc_package_name(self):
		raise AssertionError

	def get_ipc_package_description(self):
		raise AssertionError

	#calculate the pad drill size
	# # Drill Size = Maximum Lead diameter + Hole Over Lead
	def get_footprint_pad_drill_size(self,density_level, terminal_diam):
		hole_over_lead = ipc_rules.PTH_PAD_GOAL['holeDiameterFactor'][density_level]
		drill_size = terminal_diam + hole_over_lead
		return drill_size

	# calculate the Pad Diameter
	# Pad Diameter = Minimum Annular Ring X 2 + Minimum Fabrication Allowance + Drill Size			
	def get_footprint_pad_diameter(self, density_level, terminal_diam, pad_hole_ratio):
		min_fab_allowance = ipc_rules.FABRICATION_ATTRIBUTES['allowance'][density_level]
		annular_ring_width = ipc_rules.FABRICATION_ATTRIBUTES['minAnnularRingWidth']
		drill_size = self.get_footprint_pad_drill_size(density_level, terminal_diam)
		option_1 = drill_size + 2*annular_ring_width + min_fab_allowance
		option_2 = drill_size*pad_hole_ratio
		pad_diameter = max(option_1,option_2)
		return pad_diameter

	# another function of calculate the smd data for the packages which need update heelgoal 
	# depends on Smin, tTol, bodyWidthMax. this function is used by packages 
	def get_footprint_smd_data1(self,lead_span_max, lead_span_min, pad_width_max, pad_width_min, pad_height_max, pad_height_min, body_width_max, toe_goal, heel_goal, side_goal):

		fab_tol = self.ui_data['fabricationTolerance']
		place_tol = self.ui_data['placementTolerance']

		s_max = lead_span_max - pad_width_min*2
		s_min = lead_span_min - pad_width_max*2
		s_tol = s_max - s_min
		t_tol = pad_width_max - pad_width_min

		l_range = lead_span_max - lead_span_min
		t_range = pad_width_max - pad_width_min
		w_range = pad_height_max - pad_height_min
		s_tol_rms = math.sqrt(l_range * l_range + t_range * t_range*2)
		s_diff = s_tol - s_tol_rms

		s_max_actual = s_max - s_diff/2
		s_min_actual = s_min + s_diff/2
		s_diff_actual = s_max_actual - s_min_actual		
		
		toe_tol = math.sqrt((l_range * l_range) + 4 * (fab_tol * fab_tol) + 4 * (place_tol * place_tol))
		Z_max = lead_span_min + toe_tol + (2 * toe_goal)
		heel_tol = math.sqrt((s_diff_actual * s_diff_actual) + 4 * (fab_tol*fab_tol) + 4 * (place_tol*place_tol))

		# update heel goal depends on Smin, tTol, bodyWidthMax
		if t_range <= 0.0500 and s_min <= body_width_max:
			updatedGullWingHeelFilletMaxMedMinGT = [0.0250, 0.0150, 0.0050]
			heel_goal = updatedGullWingHeelFilletMaxMedMinGT[self.ui_data['densityLevel']]

		g_min = s_max_actual - (2 * heel_goal) - heel_tol 
		side_tol = math.sqrt((w_range * w_range) + 4 * (fab_tol * fab_tol) + 4 * (place_tol * place_tol))
		y_ref = pad_height_min + 2 * side_goal + side_tol

		C = (Z_max + g_min)/2
		X = (Z_max - g_min)/2
		Y = y_ref

		return X, Y, C

	# the general function of calculate the smd data
	def get_footprint_smd_data(self, L_min, L_max, T_min, T_max, W_min, W_max, toe_goal, heel_goal, side_goal):
		L_range = (L_max - L_min)
		T_range = (T_max - T_min)
		W_range = (W_max - W_min)

		fab_tol = self.ui_data['fabricationTolerance']
		place_tol = self.ui_data['placementTolerance']
		#place_rnd = 
		#size_rnd = 

		s_tol_RMS = math.sqrt(L_range * L_range + T_range * T_range + T_range * T_range)
		s_max = L_max - (2 * T_min)
		s_min = L_min - (2 * T_max)
		s_tol = s_max - s_min
		s_diff = s_tol - s_tol_RMS
		s_max_actual = s_max - s_diff/2
		s_min_actual = s_min + s_diff/2
		s_diff_actual = s_max_actual - s_min_actual

		#place_rnd_factor = 1/ place_rnd
		#size_rnd_factor = 1/ size_rnd

		toe_tol = math.sqrt((L_range * L_range) + 4 * (fab_tol * fab_tol) + 4 * (place_tol * place_tol))
		Z_max = L_min + toe_tol + (2 * toe_goal)
		heel_tol = math.sqrt((s_diff_actual * s_diff_actual) + 4 * (fab_tol*fab_tol) + 4 * (place_tol*place_tol))
		g_min = s_max_actual - (2 * heel_goal) - heel_tol 
		side_tol = math.sqrt((W_range * W_range) + 4 * (fab_tol * fab_tol) + 4 * (place_tol * place_tol))
		y_ref = W_min + 2 * side_goal + side_tol

		#used for aluminum electrolytic component
		#t_tol_AE = math.sqrt(s_tol * s_tol + l_tol * l_tol) / 2 #define l_tol

		#used for aluminum electrolytic component
		#l_tol_AE = math.sqrt(s_tol * s_tol + 2 * t_tol * t_tol) / 2 #define t_tol

		C = (Z_max + g_min)/2
		X = (Z_max - g_min)/2
		Y = y_ref

		toe_min = ((X + C) - (L_min + toe_tol)) / 2
		toe_max = (toe_min + (toe_tol / 2))
		heel_min = ((s_max_actual - heel_tol) - g_min) / 2
		heel_max = (heel_min + (heel_tol / 2))
		side_min = (Y - (W_min + side_tol)) / 2
		side_max = (side_min + (side_tol / 2))

		return X, Y, C
	
	def get_silkscreen_body_width(self, silkscreen_map_body_type):
		# the default value 
		body_width = self.ui_data['bodyWidthMax']
		if silkscreen_map_body_type == ipc_rules.SILKSCREEN_ATTRIBUTES['MappingTypeToBodyNom']:
			body_width =  (self.ui_data['bodyWidthMax'] + self.ui_data['bodyWidthMin'])/2
		if silkscreen_map_body_type == ipc_rules.SILKSCREEN_ATTRIBUTES['MappingTypeToBodyMin']:
			body_width = self.ui_data['bodyWidthMin']
		return body_width
	
	def get_silkscreen_body_length(self, silkscreen_map_body_type):
		# the default value 
		body_length = self.ui_data['bodyLengthMax'] 
		if silkscreen_map_body_type == ipc_rules.SILKSCREEN_ATTRIBUTES['MappingTypeToBodyNom']:
			body_length =  (self.ui_data['bodyLengthMax'] + self.ui_data['bodyLengthMin'])/2
		if silkscreen_map_body_type == ipc_rules.SILKSCREEN_ATTRIBUTES['MappingTypeToBodyMin']:
			body_length = self.ui_data['bodyLengthMin']	
		return body_length

	def get_silkscreen_smd_width(self, silkscreen_map_body_type):
		# the default value 
		pad_width = self.ui_data['padWidthMax']
		if silkscreen_map_body_type == ipc_rules.SILKSCREEN_ATTRIBUTES['MappingTypeToBodyNom']:
			pad_width =  (self.ui_data['padWidthMax'] + self.ui_data['padWidthMin'])/2
		if silkscreen_map_body_type == ipc_rules.SILKSCREEN_ATTRIBUTES['MappingTypeToBodyMin']:
			pad_width = self.ui_data['padWidthMin']
		return pad_width
	
	def get_silkscreen_smd_length(self, silkscreen_map_body_type):
		# the default value 
		pad_length = self.ui_data['padHeightMax'] 
		if silkscreen_map_body_type == ipc_rules.SILKSCREEN_ATTRIBUTES['MappingTypeToBodyNom']:
			pad_length =  (self.ui_data['padHeightMax'] + self.ui_data['padHeightMin'])/2
		if silkscreen_map_body_type == ipc_rules.SILKSCREEN_ATTRIBUTES['MappingTypeToBodyMin']:
			pad_length = self.ui_data['padHeightMin']	
		return pad_length


	# calculate the solder paste apertures and create data object into footprint collection.
	def build_solder_paste_of_thermal_pad(self, footprint_data, pad_length, pad_width, paste_rows, paste_cols, 
					aperture_length, aperture_width, aperture_gap_x, aperture_gap_y):

        #the notion of length (along x-dir) is width and width (along y-dir) is height in shape data
		left_edge_offset = (pad_length - paste_cols* aperture_length - (paste_cols - 1)*aperture_gap_x)/2
		top_edge_offset = (pad_width - paste_rows*aperture_width - (paste_rows - 1)*aperture_gap_y)/2
		sx = - pad_length/2 + left_edge_offset
		sy = - pad_width /2 + top_edge_offset		
		for i in range(0, paste_rows):
			for j in range (0, paste_cols):
				start_x = sx + j * (aperture_length + aperture_gap_x)
				start_y = sy + i * (aperture_width +aperture_gap_y)
				aperture_rect = footprint.FootprintRectangle(start_x, start_y, start_x + aperture_length, start_y + aperture_width)
				footprint_data.append(aperture_rect)

	def build_assembly_body_outline(self, footprint_data, body_width, body_length, stroke_width):
		line_left = footprint.FootprintWire(-body_width/2, -body_length/2, -body_width/2, body_length/2, stroke_width)
		line_left.layer = 51
		footprint_data.append(line_left)
		line_top = footprint.FootprintWire(-body_width/2, body_length/2, body_width/2, body_length/2, stroke_width)
		line_top.layer = 51
		footprint_data.append(line_top)
		line_right = footprint.FootprintWire(body_width/2, body_length/2, body_width/2, -body_length/2, stroke_width)
		line_right.layer = 51
		footprint_data.append(line_right)
		line_bottom = footprint.FootprintWire(body_width/2, -body_length/2, -body_width/2, -body_length/2, stroke_width)
		line_bottom.layer = 51
		footprint_data.append(line_bottom)


	# create the footprint elements for the pin one marker silkscreen
	def build_silkscreen_pin_one_marker(self, footprint_data, pin_one_x, pin_one_y, pad_width, pad_height, body_width, at_left):
		pin_marker_size = ipc_rules.SILKSCREEN_ATTRIBUTES['dotPinMarkerSize']
		clearance = ipc_rules.SILKSCREEN_ATTRIBUTES['PinMarkerDotClearance'] + pin_marker_size/2
		pad_x = pin_one_x - pad_width/2
		pad_y = pin_one_y + pad_height/2
		#if pad is outside body
		if pad_x < -body_width/2 :
			if at_left: # place at the left of the pin one pad
				pin_marker_x = pad_x - clearance
			else: #place the pin marker at the center between first pad and body left edge respectively if clearence is maintained else place dot maintaining clearence from body
				if abs(-body_width/2 - pad_x)/2 < clearance:
					pin_marker_x = - body_width/2 - clearance
				else:
					pin_marker_x = (pad_x - body_width/2)/2
		else:#if pad is inside body draw dot marker maintaining clearence from body
			pin_marker_x = -body_width/2 - clearance

		if at_left :
			pin_marker_y = pin_one_y
		else:
			pin_marker_y = pad_y + clearance

		pin_marker = footprint.FootprintCircle(pin_marker_x, pin_marker_y, 0, pin_marker_size/2)
		footprint_data.append(pin_marker)
	

	def get_new_boundingbox(self, bbox1:footprint.BoundingBox, bbox2:footprint.BoundingBox):
		new_x_min = min(bbox1.x_min, bbox2.x_min)
		new_y_min = min(bbox1.y_min, bbox2.y_min)
		new_x_max = max(bbox1.x_max, bbox2.x_max)
		new_y_max = max(bbox1.y_max, bbox2.y_max)
		return footprint.BoundingBox(new_x_min, new_y_min, new_x_max, new_y_max)


	def build_footprint_text(self, footprint_data, pos_x = None, name_align = "bottom-center", value_align = "top-center"):
		
		footprint_bbox = footprint.BoundingBox()
		#go through the  footprint data node
		for elem in footprint_data:
			#calculate the new boundingbox
			footprint_bbox = self.get_new_boundingbox(footprint_bbox, elem.bounding_box())
	
		text_center_x = (footprint_bbox.x_min + footprint_bbox.x_max)/2
		text_center_y = (footprint_bbox.y_min + footprint_bbox.y_max)/2
		dy = footprint_bbox.y_max - footprint_bbox.y_min

		name_text = footprint.FootprintText('>NAME', text_center_x, text_center_y + dy/2 + ipc_rules.PROPERTY_ATTRIBUTES['clearance'])
		if pos_x != None: # use the input x value instead of the default bbox center. 
			name_text.x = pos_x
		name_text.size = ipc_rules.PROPERTY_ATTRIBUTES['fontSize']
		name_text.font = ipc_rules.PROPERTY_ATTRIBUTES['font']
		name_text.ratio = 8
		name_text.align = name_align
		name_text.distance = 50
		name_text.layer = 25
		footprint_data.append(name_text)

		value_text = footprint.FootprintText('>VALUE', text_center_x, text_center_y - dy/2 - ipc_rules.PROPERTY_ATTRIBUTES['clearance'])
		if pos_x != None: # use the input x value instead of the default bbox center. 
			value_text.x = pos_x
		value_text.size = ipc_rules.PROPERTY_ATTRIBUTES['fontSize']
		value_text.font = ipc_rules.PROPERTY_ATTRIBUTES['font']
		value_text.ratio = 8
		value_text.align = value_align
		value_text.distance = 50
		value_text.layer = 27
		footprint_data.append(value_text)


	def build_footprint_mounting_hole_vias(self, footprint_data, via_count, via_diameter, via_center_offset, thermal_type, density_level ):
		via_angle_interval = -2 * math.pi / via_count
		via_drill_size = self.get_footprint_pad_drill_size(density_level,via_diameter)
		via_pad_diameter = self.get_footprint_pad_diameter(density_level,via_diameter, 0 )
		for i in range(0, via_count):
			via_x = via_center_offset * math.cos(math.pi / 2 + i * via_angle_interval)
			via_y = via_center_offset * math.sin(math.pi / 2 + i * via_angle_interval)
			via_pad = footprint.FootprintPad(via_x, via_y, via_pad_diameter, via_drill_size)
			via_pad.name = str(i + 2)
			via_pad.thermals = thermal_type
			footprint_data.append(via_pad)


	def build_silkscreen_mounting_hole(self, footprint_data, pad_diameter, pad_shape, body_width):

		pad_with_clearance = pad_diameter + 2 * ipc_rules.SILKSCREEN_ATTRIBUTES['Clearance']
		silkscreen_body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])
		
		if pad_shape == 'Square':
			#if pad's diagonal with clearance is less than body diameter draw silkscreen
			if body_width*body_width > 2*pad_with_clearance*pad_with_clearance:
				circle_top = footprint.FootprintCircle(0, 0, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'], silkscreen_body_width/2)
				footprint_data.append(circle_top)
			else:
			# if pad's width is more than body diameter do not draw any silkscreen
				if silkscreen_body_width > pad_with_clearance:
					a = pad_with_clearance/2
					h = 0.5 * math.sqrt(silkscreen_body_width * silkscreen_body_width - pad_with_clearance * pad_with_clearance)
					r = silkscreen_body_width/2
					curve_value = (360/math.pi) * math.asin(h/r)
						
					#right arc
					arc = footprint.FootprintWire(a,-h,a,h,ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
					arc.curve = curve_value
					footprint_data.append(arc)
					# left arc
					arc = footprint.FootprintWire(-a,h,-a,-h,ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
					arc.curve = curve_value
					footprint_data.append(arc)
					#top arc
					arc = footprint.FootprintWire(h,a,-h,a, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
					arc.curve = curve_value
					footprint_data.append(arc)
					# bottom arc
					arc = footprint.FootprintWire(-h,-a,h,-a,ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'])
					arc.curve = curve_value
					footprint_data.append(arc)
		else:
			# if body diameter is greater than pad diameter draw silkscreen
			if silkscreen_body_width > pad_with_clearance:
				circle_top = footprint.FootprintCircle(0, 0, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'], silkscreen_body_width/2)
				footprint_data.append(circle_top)

	def set_ui_input(self, ui_input):
		# get the new UI input value
		self.ui_data = ui_input


	def get_body_description(self, is_short, is_x_direction):
		description = ''
		if is_short == False:
			description =  ' with body size '
		# convert from cm to mm
		body_length = str('{:.2f}'.format(round((self.ui_data['bodyLengthMax']+self.ui_data['bodyLengthMin'])/2 * 10, 2)))
		body_width = str('{:.2f}'.format(round((self.ui_data['bodyWidthMax']+self.ui_data['bodyWidthMin'])/2 * 10, 2)))
		body_height = str('{:.2f}'.format(round(self.ui_data['bodyHeightMax'] * 10, 2))) 
		
		if is_x_direction : #aligned in x direction
			description += body_length + ' X ' + body_width + ' X ' + body_height + ' '
		else: #aligned in y direction
			description +=  body_width  + ' X ' + body_length + ' X ' + body_height + ' '
		return description

	def get_density_level_for_smd(self, density_level):
		return 'M' if (density_level == 0) else ( 'N' if (density_level == 1) else 'L')

	def get_producibility_level_for_pth(self, density_level):
		return 'A' if (density_level == 0) else ( 'B' if (density_level == 1) else 'C')

	def get_ipc_package_metadata(self, isPackageRotated = False):
		self.metadata['ipcName'] = self.get_ipc_package_name()
		check_keys = ('bodyLengthMax', 'bodyWidthMax', 'bodyLengthMin', 'bodyWidthMin')
		if all(key in self.ui_data.keys() for key in check_keys): #check for params present for package (radial round, standoff, snaplock)
			if isPackageRotated:
				self.metadata["bodyWidth"] = str(round((self.ui_data['bodyLengthMax']+self.ui_data['bodyLengthMin'])/2 * 10, 4))
				self.metadata["bodyLength"] = str(round((self.ui_data['bodyWidthMax']+self.ui_data['bodyWidthMin'])/2 * 10, 4))
			else:
				self.metadata["bodyLength"] = str(round((self.ui_data['bodyLengthMax']+self.ui_data['bodyLengthMin'])/2 * 10, 4))
				self.metadata["bodyWidth"] = str(round((self.ui_data['bodyWidthMax']+self.ui_data['bodyWidthMin'])/2 * 10, 4))	
				
		if 'bodyHeightMax' in self.ui_data.keys():
			self.metadata["height"] = str(round(self.ui_data['bodyHeightMax'] * 10, 4)) 

		is_smd = is_pth = 0
		for elem in self.get_footprint():
			if isinstance(elem, footprint.FootprintPad) or isinstance(elem, footprint.FootprintSmd):
				if isinstance(elem, footprint.FootprintSmd):
					is_smd = 1
				elif isinstance(elem, footprint.FootprintPad):
					is_pth = 1
		if is_smd:
			self.metadata["mountingType"] = "SMD"
		if is_pth:
			self.metadata["mountingType"] = "PTH"	
		if is_smd and is_pth:
			self.metadata["mountingType"] = "COMBO"	

		return self.metadata	
		






