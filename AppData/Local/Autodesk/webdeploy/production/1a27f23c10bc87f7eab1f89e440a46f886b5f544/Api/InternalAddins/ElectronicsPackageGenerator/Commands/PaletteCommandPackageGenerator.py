import adsk.core
import os, traceback
import json
from pathlib import Path
from . import PaletteCommandBase
from ..Utilities import addin_utility
from ..Calculators import *
from ..Scripts3d import *
from ..Utilities.localization import _LCLZ, locale 
from . import PackageCommand
#need to remove
# PanelId = 'SolidCreatePanel'
class PaletteCommandPackageGenerator(PaletteCommandBase.PaletteCommandBase):
    def __init__(self, name: str, options: dict):
        super().__init__(name, options)
        
        # customize the toolbar and command definition
        self.toolbar_panel_id = 'Package3DPanel'
        # self.toolbar_panel_id = PanelId
        self.cmd_id = 'PackageGenerator'
        self.cmd_name = _LCLZ('CmdNamePackageGenerator', '3D Package Generator')
        self.cmd_description = _LCLZ('CmdDescPackageGenerator', 'Generate a 3D package for PCB.')
        self.command_promoted = True
        
        self.cmd_resources = os.path.join(Path(__file__).parent.parent, 'Resources')
        # customize the palette defition.
        self.palette_id = 'packageGeneratorPalette_'  # DO NOT CHANGE the prefix - See FUS-58345s
        self.palette_name = _LCLZ('PaletteNamePackageGenerator', 'Package Generator')

        self.palette_is_visible = True
        self.palette_show_close_button = True
        self.palette_is_resizable = True
        self.palette_width = 340
        self.palette_height = 600
        self.palette_new_web_browser = True
        #set the landing page path
        parent_folder = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) 
        self.palette_html_file_url = 'file:///' + parent_folder.replace('\\','/') + '/Resources/index.html' + "?locale=" + locale        


    def on_html_event(self, html_args: adsk.core.HTMLEventArgs):
        # UI input for selected package type in editor.
        ao = addin_utility.AppObjects()
        palette = ao.ui.palettes.itemById(self.palette_id)
        if html_args.action == 'sendPackageType':
            try:
                selectedPackage = json.loads(html_args.data)
            except:
                ao.ui.messageBox('Failed to load, not a valid JSON:\n{}'.format(traceback.format_exc()))

            # get the related command object.
            active_cmd = PackageCommand.cmd_factory.get_command(selectedPackage['type'])
            if active_cmd:
                button_def = ao.ui.commandDefinitions.itemById(active_cmd.cmd_id)
                button_def.execute()
            
            #hide the palette
            self.set_palette_visibility(False)
           

    def on_create(self, command: adsk.core.Command, inputs: adsk.core.CommandInputs):
        #initialize the palette layout
        self.initialize_palette_layout()
        
    def delete_palette(self):
        app = adsk.core.Application.get()
        ui = app.userInterface
        # get the command related palette.
        palette = ui.palettes.itemById(self.palette_id)
        if palette:
            for handler in self.html_handlers:
                palette.incomingFromHTML.remove(handler)
            palette.deleteMe()

    def set_palette_visibility(self, is_visible):
        app = adsk.core.Application.get()
        ui = app.userInterface
        # get the command related palette.
        palette = ui.palettes.itemById(self.palette_id)
        if palette:
            palette.isVisible = is_visible

    def on_palette_close(self):
        PackageCommand._palette_opened = False

    def initialize_palette_layout(self):
        app = adsk.core.Application.get()
        ui = app.userInterface
        # get the command related palette.
        palette = ui.palettes.itemById(self.palette_id)
        if palette:
            palette.width = self.palette_width
            palette.dockingOption = adsk.core.PaletteDockingOptions.PaletteDockOptionsNone
            palette.dockingState = adsk.core.PaletteDockingStates.PaletteDockStateFloating
    
            position = app.activeViewport.viewToScreen(adsk.core.Point2D.create(0, 0))
            palette.setPosition(int(position.x + app.activeViewport.width- self.palette_width - 2), int(position.y +2))
            palette.height = app.activeViewport.height - 32