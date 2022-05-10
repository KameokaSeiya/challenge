# Use of this script is subject to the Autodesk Terms of Use.
# https://www.autodesk.com/company/terms-of-use/en/general-terms

import math
from ..Utilities import addin_utility, constant
from ..FootprintGenerators import footprint
from ..Calculators import pkg_calculator, ipc_rules
from ..Utilities.localization import _LCLZ

# this class defines the package Calculator for the Axial Packages.
class PackageCalculatorSnaplock(pkg_calculator.PackageCalculator):
	
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
		model_data['A'] = self.ui_data['bodyHeightMax']
		model_data['A1'] = self.ui_data['boardThickness']
		model_data['E'] = self.ui_data['bodyWidthMax']
		model_data['L1'] = self.ui_data['lockHeightMax']
		model_data['H'] = self.ui_data['holeDiameter']
		if self.ui_data['lockWidthOverride']!= None:
			model_data['E1'] = self.ui_data['lockWidth']
		else:
			model_data['E1'] = (self.ui_data['bodyWidthMax'] + self.ui_data['holeDiameter'])/2
		return model_data
		
	def get_footprint(self):
		
		footprint_data = []

		# create hole object
		hole = footprint.FootprintHole(0,0,self.ui_data['holeDiameter'])
		footprint_data.append(hole)

		#build the silkscreen 
		body_width = self.get_silkscreen_body_width(self.ui_data['silkscreenMappingTypeToBody'])

		circle_top = footprint.FootprintCircle(0, 0, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'], body_width/2)
		footprint_data.append(circle_top)

		circle_bottom = footprint.FootprintCircle(0, 0, ipc_rules.SILKSCREEN_ATTRIBUTES['StrokeWidth'], body_width/2)
		circle_bottom.layer = 51
		footprint_data.append(circle_bottom)

		#build the text
		self.build_footprint_text(footprint_data)

		return footprint_data

	def get_ipc_package_name(self):
        #SNAPLOCK _ Mounting Type _ Body Dia(E) X Height(A) _ Board-thickness(A1) _ [MTG + NP (non-plated) + H + Hole Size(b)]
        #E.g., SNAPLOCK_LOCK-IN_320X635_157_MTGNPH320
		pkg_name = 'SNAPLOCK_LOCK-IN'
		pkg_name += '_' + str(int((self.ui_data['bodyWidthMax']*1000))) 
		pkg_name += 'X' + str(int((self.ui_data['bodyHeightMax']*1000))) 
		pkg_name += '_' + str(int((self.ui_data['boardThickness']*1000)))
		pkg_name += '_MTGNP' + 'H' + str(int((self.ui_data['holeDiameter']*1000)))
		return pkg_name

	def get_ipc_package_description(self):
		ao = addin_utility.AppObjects()
		unit = 'mm'		
		# get the pin pitch
		hole_diameter = ao.units_manager.convert(self.ui_data['holeDiameter'], 'cm', unit)
		body_height = ao.units_manager.convert(self.ui_data['bodyHeightMax'], 'cm', unit)
		board_thichness = ao.units_manager.convert(self.ui_data['boardThickness'], 'cm', unit)
		body_width = ao.units_manager.convert(self.ui_data['bodyWidthMax'], 'cm', unit)

		short_description = 'Snap Lock (lock-in), '
		short_description += str('{:.2f}'.format(round(hole_diameter,2))) + ' ' + unit + ' hole diameter, '
		short_description += str('{:.2f}'.format(round(body_height,2))) + ' ' + unit + ' body height for '
		short_description += str('{:.2f}'.format(round(board_thichness,2))) + ' ' + unit + ' board/panel thickness'
		         
		full_description = 'Snap Lock (lock-in) package'
		full_description += ' with ' + str('{:.2f}'.format(round(hole_diameter,2))) + ' ' + unit + ' hole diameter, '
		full_description += str('{:.2f}'.format(round(body_width,2))) + ' ' + unit + ' body diameter and '
		full_description += str('{:.2f}'.format(round(body_height,2))) + ' ' + unit + ' body height for '
		full_description += str('{:.2f}'.format(round(board_thichness,2))) + ' ' + unit + ' board/panel thickness'

		return short_description + '\n <p>' + full_description + '</p>'

	def	get_ipc_package_metadata(self):
		super().get_ipc_package_metadata()
		ao = addin_utility.AppObjects()
		self.metadata['ipcFamily'] = "SNAPLOCK"
		self.metadata["pins"] = str(self.ui_data['horizontalPadCount'])
		self.metadata["bodyWidth"] = str(round(ao.units_manager.convert(self.ui_data['bodyWidthMax'], 'cm', 'mm'), 4))
		self.metadata["bodyLength"] = self.metadata["bodyWidth"]
		return self.metadata
	
# register the calculator into the factory. 
pkg_calculator.calc_factory.register_calculator(constant.PKG_TYPE_SNAP_LOCK, PackageCalculatorSnaplock) 