import adsk.core, adsk.fusion, traceback, math

from ..Utilities import fusion_sketch
from ..Utilities import fusion_model
from ..Utilities import addin_utility, constant
from ..Utilities.localization import _LCLZ

APPEARANCE_ID_DIODE_BAND = 'Prism-116'  # 'Plastic - Matte (Gray)'
app = adsk.core.Application.get()


def axial_diode(params, design = None, target_comp = None):

    if not design:
        app.documents.add(adsk.core.DocumentTypes.FusionDesignDocumentType)
        design = app.activeProduct

    # Get the root component of the active design
    root_comp = design.rootComponent
    if target_comp:
        root_comp = target_comp

    #get the default unit of the system.  need consider to set the right unit. consider if user use the imperial unit.
    #define default value of the input paramters of diode. unit is mm
    A = params.get('A') or 0.25 #body height
    D = params.get('D') or 0.85 #body width
    E = params.get('E') or 0.25 #body length
    b = params.get('b') or 0.06 #Terminal width
    R = params.get('R') or 0.05 #bend radius
    e = params.get('e')  #pin pitch
    if e == None:
        L1 = params.get('L1')
        e = (L1+R)*2 + D
    board_thickness = params.get('boardThickness') or 0.16
    is_polarized = params['isPolarized'] if 'isPolarized' in params else 0


    color_r = params.get('color_r')
    if color_r == None: color_r = 30
    color_g = params.get('color_g')
    if color_g == None: color_g = 30
    color_b = params.get('color_b')
    if color_b == None: color_b = 30

    # get default system unit.
    default_unit = design.unitsManager.defaultLengthUnits
  
    is_update = False
    is_update = addin_utility.process_user_param(design, 'param_A', A, default_unit, _LCLZ("BodyHeight", "body height"))
    is_update = addin_utility.process_user_param(design, 'param_D', D, default_unit, _LCLZ("BodyLength", "body length"))
    is_update = addin_utility.process_user_param(design, 'param_E', E, default_unit, _LCLZ("BodyWidth", "body width"))
    is_update = addin_utility.process_user_param(design, 'param_b', b, default_unit, _LCLZ("TerminalWidth", "terminal width"))
    is_update = addin_utility.process_user_param(design, 'param_R', R, default_unit, _LCLZ("BendRadius", "bend radius"))
    is_update = addin_utility.process_user_param(design, 'param_e', e, default_unit, _LCLZ("PinPitch", "pin pitch"))
    is_update = addin_utility.process_user_param(design, 'board_thickness', board_thickness, default_unit, _LCLZ("BoardThickness", "board thickness"))

    # the paramters are already there, just update the models with the paramters. will skip the model creation process.
    if is_update: return 

    # Create a new sketch on the xz plane.
    body_sketch = root_comp.sketches.add(root_comp.xZConstructionPlane)

    # Step 1 create the body profile.
    body_sketch.isComputeDeferred = True
    lines = body_sketch.sketchCurves.sketchLines

    top_line = lines.addByTwoPoints(adsk.core.Point3D.create(-D/2, -E/2, 0), adsk.core.Point3D.create(D/2, -E/2, 0))
    left_line = lines.addByTwoPoints(adsk.core.Point3D.create(-D/2, 0, 0), top_line.startSketchPoint)
    right_line = lines.addByTwoPoints( top_line.endSketchPoint, adsk.core.Point3D.create(D/2, 0, 0))
    bottom_line = lines.addByTwoPoints(right_line.endSketchPoint,left_line.startSketchPoint)

    # add line constrains
    geom_constrains = body_sketch.geometricConstraints
    geom_constrains.addHorizontal(top_line)
    geom_constrains.addHorizontal(bottom_line)
    geom_constrains.addVertical(left_line)
    geom_constrains.addVertical(right_line)

    # add dementions
    body_sketch.sketchDimensions.addDistanceDimension(top_line.startSketchPoint, top_line.endSketchPoint,
                                                     adsk.fusion.DimensionOrientations.HorizontalDimensionOrientation,
                                                     adsk.core.Point3D.create(0.1, 0.1, 0)).parameter.expression = 'param_D'
    body_sketch.sketchDimensions.addDistanceDimension(top_line.startSketchPoint, body_sketch.originPoint,
                                                     adsk.fusion.DimensionOrientations.HorizontalDimensionOrientation,
                                                     adsk.core.Point3D.create(0.2, 0.1, 0)).parameter.expression = 'param_D/2'
    body_sketch.sketchDimensions.addDistanceDimension(top_line.startSketchPoint, body_sketch.originPoint,
                                                     adsk.fusion.DimensionOrientations.VerticalDimensionOrientation,
                                                     adsk.core.Point3D.create(0.1, 0.2, 0)).parameter.expression = 'param_A - param_E/2'
    body_sketch.sketchDimensions.addDistanceDimension(top_line.startSketchPoint, bottom_line.endSketchPoint,
                                                     adsk.fusion.DimensionOrientations.VerticalDimensionOrientation,
                                                     adsk.core.Point3D.create(0.2, 0.2, 0)).parameter.expression = 'param_E/2'

    body_sketch.isComputeDeferred = True

      # Step 2. create the component body by revolve feature.
    # Get the profile defined by the circle.
    prof = body_sketch.profiles.item(0)
    # Create an revolution input to be able to define the input needed for a revolution
    # while specifying the profile and that a new component is to be created
    revolves = root_comp.features.revolveFeatures
    rev_input = revolves.createInput(prof, top_line, adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
    # Define that the extent is an angle of pi to get half of a torus.
    angle = adsk.core.ValueInput.createByReal(math.pi)
    rev_input.setAngleExtent(True, angle)
    # Create the revolve body.
    rev_body = revolves.add(rev_input)
    addin_utility.apply_material(app, design, rev_body.bodies.item(0), constant.MATERIAL_ID_BODY_DEFAULT)

    if not is_polarized:
        addin_utility.apply_rgb_appearance(app, design, rev_body.bodies.item(0),color_r, color_g, color_b, constant.COLOR_NAME_AXIAL_DIODE_BODY)
    else:
        #split the body to create the polarized info
        polarized_plane = addin_utility.create_offset_plane(root_comp, root_comp.yZConstructionPlane, '-param_D*3/8')
        polarized_plane.name = 'SplitOffset'

        # create the polarized band
        split_faces = root_comp.features.splitFaceFeatures
        faces_collection = adsk.core.ObjectCollection.create()
        for face_i in rev_body.faces:
            face_geo = adsk.core.Cylinder.cast(face_i.geometry)
            if face_geo: 
                faces_collection.add(face_i)

        split_face_input = split_faces.createInput(faces_collection, polarized_plane, True)
        # Create split body feature
        split_face = split_faces.add(split_face_input)
        split_face.name = 'Polarized'

        band_face = split_face.faces.item(1)
        comp_face = split_face.faces.item(0)
        #apply the right appearance.
        addin_utility.apply_appearance(app, design, band_face, APPEARANCE_ID_DIODE_BAND)  
        addin_utility.apply_rgb_appearance(app, design, comp_face,color_r, color_g, color_b, constant.COLOR_NAME_AXIAL_DIODE_BODY)

    # create consctruntion plan for contain the sketh of pin profile.
    pin_offset_plane = addin_utility.create_offset_plane(root_comp, root_comp.yZConstructionPlane, 'param_D/2')
    pin_offset_plane.name = 'PinProOffset'
    pin_sketch = root_comp.sketches.add(pin_offset_plane)

    # create pin profile circle sketch with contrains.
    fusion_sketch.create_center_point_circle(pin_sketch,adsk.core.Point3D.create(E/2-A,0,0), 'param_A-param_E/2','', b,'param_b')

    #step 5 Create Sketch of Pin Path
    fusion_sketch.create_axial_pin_path(body_sketch, e, 'param_e',D, 'param_D', A-E/2, 'param_A - param_E / 2',
                            A-E/2-R+board_thickness*1.2,'param_A- param_E/2 - param_R + board_thickness*1.2', R, 'param_R')

    #Step 6. Create the axial pin body
    path = root_comp.features.createPath(body_sketch.sketchCurves.sketchArcs.item(0),True)
    # Create a sweep input
    sweeps = root_comp.features.sweepFeatures
    sweep_input = sweeps.createInput(pin_sketch.profiles.item(0), path, adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
    # Create the sweep.
    sweep_body = sweeps.add(sweep_input)

    # assign the pysical material to pin.
    addin_utility.apply_material(app, design, sweep_body.bodies.item(0), constant.MATERIAL_ID_COPPER_ALLOY)
    # assign the apparance to pin
    addin_utility.apply_appearance(app, design, sweep_body.bodies.item(0), constant.APPEARANCE_ID_NICKEL_POLISHED)

    #step 7 combine the model by the mirror feature.
    # Create input entities for mirror feature
    input_entites = adsk.core.ObjectCollection.create()
    input_entites.add(sweep_body.bodies.item(0))
    # Create the input for mirror feature
    mirrors = root_comp.features.mirrorFeatures
    mirror_input = mirrors.createInput(input_entites, root_comp.yZConstructionPlane)
    # Create the mirror feature
    mirror_body = mirrors.add(mirror_input)

    #hide all the construction planes
    for plane_i in root_comp.constructionPlanes:
        plane_i.isVisable = False
        plane_i.isLightBulbOn = False

from .base import package_3d_model_base

class AxialDiode3DModel(package_3d_model_base.Package3DModelBase):
    def __init__(self):
        super().__init__()

    @staticmethod
    def type():
        return "axial_diode"

    def create_model(self, params, design, component):
        axial_diode(params, design, component)

package_3d_model_base.factory.register_package(AxialDiode3DModel.type(), AxialDiode3DModel) 

def run(context):
    ui = app.userInterface

    try:
        runWithInput(context)
    except:
        if ui:
            ui.messageBox('Failed:\n{}'.format(traceback.format_exc()))

def runWithInput(params, design = None, target_comp = None):
    axial_diode(params, design, target_comp)
