#Author-Autodesk Inc.
#Description-Generate a 3D package with a 3D model and IPC compilant 2D footprint from parameters.

import adsk.core, adsk.fusion, traceback
from .Utilities.localization import _LCLZ, locale                   
from .Commands import PaletteCommandPackageGenerator as pkg_gen_cmd
from .Commands import PackageCommand as pkg_cmd
from .Commands import *
from .Utilities import constant
import json

ATTRI_GROUP_PKG_DATA = 'PackageGeneratorDataGroup'
ATTRI_JSON_UI_INPUT = 'UIInput'

app = adsk.core.Application.get()
ui  = app.userInterface

# global config to control drawing
enableFootprintGeneration = True
footprintName = None
_package_generator_palette_visibility = False

# config for saving
enableSavingPackage = False
only3dModelGenerator = 0

# collection of commands ...
commands = [] 
package_cmd_id_list = []
events = []
tabs = []

class DocumentCreatedHandler(adsk.core.DocumentEventHandler):
    def __init__(self):
        super().__init__()

    def notify(self, args):
        for cmd in commands:
            if isinstance(cmd, pkg_gen_cmd.PaletteCommandPackageGenerator):
                cmd.set_palette_visibility(False)

class DocumentDeactivatingHandler(adsk.core.DocumentEventHandler):
    def __init__(self):
        super().__init__()

    def notify(self, args):
        for cmd in commands:
            if isinstance(cmd, pkg_gen_cmd.PaletteCommandPackageGenerator):
                cmd.delete_palette()

class DocumentClosingHandler(adsk.core.DocumentEventHandler):
    def __init__(self):
        super().__init__()

    def notify(self, args):
        for cmd in commands:
            if isinstance(cmd, pkg_gen_cmd.PaletteCommandPackageGenerator):
                cmd.delete_palette()

class DocumentSavingHandler(adsk.core.DocumentEventHandler):
    def __init__(self):
        super().__init__()

    def notify(self, args):
        eventArgs = adsk.core.DocumentEventArgs.cast(args)
        for cmd in commands:
            if isinstance(cmd, pkg_gen_cmd.PaletteCommandPackageGenerator):
                cmd.delete_palette()
        
        # remove temporary attribute used for detecting full package generation progress
        full_package_generation_in_progress_attr = eventArgs.document.attributes.itemByName(pkg_cmd.ATTRI_GROUP_PKG_DATA, pkg_cmd.ATTRI_FLAG_PKG_IN_PROGRESS)
        if full_package_generation_in_progress_attr:
            full_package_generation_in_progress_attr.deleteMe()

        #remove the erroneous ui data attribute from the doc 
        error_present_attr = eventArgs.document.attributes.itemByName(pkg_cmd.ATTRI_GROUP_PKG_DATA, pkg_cmd.ATTRI_ERROR_INPUT)
        if error_present_attr:
            error_present_attr.deleteMe()

class WorkspacePreActivateHandler(adsk.core.WorkspaceEventHandler):
    def __init__(self):
        super().__init__()

    def notify(self, args):
        eventArgs = adsk.core.WorkspaceEventArgs.cast(args)

        # this prevents from deleting the palette when switching document since workspace event is fired during that time
        # delete palette if switching to workspace different than package
        if eventArgs.workspace.id not in ['FusionSolidEnvironment', 'Package3DEnvironment']:
            for cmd in commands:
                if isinstance(cmd, pkg_gen_cmd.PaletteCommandPackageGenerator):
                    cmd.delete_palette()


class CommandTerminatedHandler(adsk.core.ApplicationCommandEventHandler):
    
    def __init__(self):
        super().__init__()
    
    def notify(self, args):
        eventArgs = adsk.core.ApplicationCommandEventArgs.cast(args)

        if eventArgs.commandId == 'ResetToDefaultLayoutCommand':
            # Code to react to this Reset Event
            for cmd in commands:
                if isinstance(cmd, pkg_gen_cmd.PaletteCommandPackageGenerator):
                    cmd.initialize_palette_layout()
                    cmd.set_palette_visibility(_package_generator_palette_visibility)

class CommandStartingHandler(adsk.core.ApplicationCommandEventHandler):
    
    def __init__(self):
        super().__init__()
    
    def notify(self, args):
        eventArgs = adsk.core.ApplicationCommandEventArgs.cast(args)

        if eventArgs.commandId == 'PackageGenerator':
            pkg_cmd._palette_opened = True

        if eventArgs.commandId == 'APIFeatureEditCommand':
            doc_attributes = app.activeDocument.attributes
            attri = doc_attributes.itemByName(ATTRI_GROUP_PKG_DATA, ATTRI_JSON_UI_INPUT)
            if attri:
                stored_data = json.loads(attri.value)
                pkg_cmd.definition.editCommandId = stored_data['cmd_id']
        
        if eventArgs.commandDefinition.id == pkg_cmd.definition.editCommandId:
            for cmd in commands:
                if isinstance(cmd, pkg_gen_cmd.PaletteCommandPackageGenerator):
                    cmd.set_palette_visibility(False)

        if eventArgs.commandId == 'ResetToDefaultLayoutCommand':
            # Code to react to this Reset Event
            global _package_generator_palette_visibility
            for cmd in commands:
                if isinstance(cmd, pkg_gen_cmd.PaletteCommandPackageGenerator):
                    if ui.activeCommand in package_cmd_id_list:
                        _package_generator_palette_visibility = False
                    else:
                        _package_generator_palette_visibility = True
                        pkg_cmd._palette_opened = True        
def run(context):
    try:
        
        pkg_gen_command = pkg_gen_cmd.PaletteCommandPackageGenerator('electronic package generator',{})
        pkg_gen_command.on_run()
        commands.append(pkg_gen_command)



        for pkg_type in constant.SUPPORT_PACKAGE_TYPE:
            pkg_command = pkg_cmd.cmd_factory.get_command(pkg_type)
            pkg_command.on_run()
            commands.append(pkg_command)
            if pkg_command.cmd_id not in package_cmd_id_list:
                package_cmd_id_list.append(pkg_command.cmd_id)

        # deal with the UI reset events
        onCommandTerminated = CommandTerminatedHandler()
        ui.commandTerminated.add(onCommandTerminated)
        events.append(onCommandTerminated)

        onCommandStarting = CommandStartingHandler()
        ui.commandStarting.add(onCommandStarting)
        events.append(onCommandStarting)

        onWorkspacePreActivate = WorkspacePreActivateHandler()
        ui.workspacePreActivate.add(onWorkspacePreActivate)
        events.append(onWorkspacePreActivate)
        
        # deal with document related events
        onDocumentCreated = DocumentCreatedHandler()
        app.documentCreated.add(onDocumentCreated)
        events.append(onDocumentCreated)

        onDocumentClosing = DocumentClosingHandler()
        app.documentClosing.add(onDocumentClosing)
        events.append(onDocumentClosing)

        onDocumentDeactivating = DocumentDeactivatingHandler()
        app.documentDeactivating.add(onDocumentDeactivating)
        events.append(onDocumentDeactivating)

        onDocumentSaving = DocumentSavingHandler()
        app.documentSaving.add(onDocumentSaving)
        events.append(onDocumentSaving)
    

    except:
        if ui:
            ui.messageBox('Failed:\n{}'.format(traceback.format_exc()))

def stop(context):

    app = adsk.core.Application.get()
    ui = app.userInterface

    try:
        for stop_command in commands:
            stop_command.on_stop()

        for toolbar_tab in tabs:
            if toolbar_tab.isValid:
                toolbar_tab.deleteMe()
        
        #for event in events:
            #event.on_stop()

    except:
        if ui:
            ui.messageBox('Input changed event failed: {}'.format(traceback.format_exc()))        

