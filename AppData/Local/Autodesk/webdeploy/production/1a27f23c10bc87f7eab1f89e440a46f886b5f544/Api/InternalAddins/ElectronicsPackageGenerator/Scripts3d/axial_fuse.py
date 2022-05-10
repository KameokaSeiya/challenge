import adsk.core, adsk.fusion, traceback, math
from ..Utilities import fusion_sketch
from ..Utilities import fusion_model
from ..Utilities import addin_utility, constant
from ..Utilities.localization import _LCLZ

app = adsk.core.Application.get()

def axial_fuse(params, design = None, target_comp = None):

    if not design:
        app.documents.add(adsk.core.DocumentTypes.FusionDesignDocumentType)
        design = app.activeProduct

    # Get the root component of the active design
    root_comp = design.rootComponent
    if target_comp:
        root_comp = target_comp
    # get default system unit.
    default_unit = design.unitsManager.defaultLengthUnits

    #define default value of the input paramters of Fuse. unit is mm
    A = params.get('A') or 0.25 #Body Height
    D = params.get('D') or 0.85 #Body Length
    E = params.get('E') or 0.25 #Body width
    b = params.get('b') or 0.06 #Terminal width
    R = params.get('R') or 0.05 #bend radius
    e = params.get('e')  #pin pitch
    if e == None:
        L1 = params.get('L1')
        e = (L1+R)*2 + D
    board_thickness = params.get('boardThickness') or 0.16

    color_r = params.get('color_r')
    if color_r == None: color_r = 192
    color_g = params.get('color_g')
    if color_g == None: color_g = 192
    color_b = params.get('color_b')
    if color_b == None: color_b = 192

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

    # if all parameters need be created, we need create the model from scrach
    # Create a new sketch on the xz plane.
    body_sketch = root_comp.sketches.add(root_comp.xZConstructionPlane)

    # Step 1 create the body profile.
    body_sketch.isComputeDeferred = True
    lines = body_sketch.sketchCurves.sketchLines
    top_line = lines.addByTwoPoints(adsk.core.Point3D.create(-D/2, -E/2, 0), adsk.core.Point3D.create(D/2, -E/2, 0))
    left_line = lines.addByTwoPoints(adsk.core.Point3D.create(-D/2, 0, 0), top_line.startSketchPoint)
    right_line = lines.addByTwoPoints( top_line.endSketchPoint, adsk.core.Point3D.create(D/2, 0, 0))
    left_bottom_line1 = lines.addByTwoPoints(left_line.startSketchPoint, adsk.core.Point3D.create(-D*3/8, 0, 0))
    left_bottom_line12 = lines.addByTwoPoints(left_bottom_line1.endSketchPoint, adsk.core.Point3D.create(-D*3/8, -E/2*0.05, 0))
    left_bottom_line2 = lines.addByTwoPoints(left_bottom_line12.endSketchPoint, adsk.core.Point3D.create(-D/4, -E/2*0.05, 0))
    bottom_line = lines.addByTwoPoints(adsk.core.Point3D.create(-D/4, -E/2*0.15, 0),adsk.core.Point3D.create(D/4, -E/2*0.15, 0))
    right_bottom_line1 = lines.addByTwoPoints(right_line.endSketchPoint, adsk.core.Point3D.create(D*3/8, 0, 0))
    right_bottom_line12 = lines.addByTwoPoints(right_bottom_line1.endSketchPoint, adsk.core.Point3D.create(D*3/8, -E/2*0.05, 0))
    right_bottom_line2 = lines.addByTwoPoints(right_bottom_line12.endSketchPoint, adsk.core.Point3D.create(D/4, -E/2*0.05, 0))
    left_bottom_line22 = lines.addByTwoPoints(left_bottom_line2.endSketchPoint, bottom_line.startSketchPoint)
    right_bottom_line22 = lines.addByTwoPoints(bottom_line.endSketchPoint,right_bottom_line2.endSketchPoint)

    # add line constrains
    geom_constrains = body_sketch.geometricConstraints
    geom_constrains.addHorizontal(top_line)
    geom_constrains.addHorizontal(bottom_line)
    geom_constrains.addHorizontal(left_bottom_line1)
    geom_constrains.addHorizontal(left_bottom_line2)
    geom_constrains.addHorizontal(right_bottom_line1)
    geom_constrains.addHorizontal(right_bottom_line2)
    geom_constrains.addVertical(left_line)
    geom_constrains.addVertical(right_line)
    geom_constrains.addVertical(left_bottom_line12)
    geom_constrains.addVertical(right_bottom_line12)
    geom_constrains.addVertical(left_bottom_line22)
    geom_constrains.addVertical(right_bottom_line22)
    geom_constrains.addEqual(left_line,right_line)
    geom_constrains.addEqual(left_bottom_line1,right_bottom_line1)
    geom_constrains.addEqual(left_bottom_line2,right_bottom_line2)
    geom_constrains.addEqual(left_bottom_line12,right_bottom_line12)

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
    body_sketch.sketchDimensions.addDistanceDimension(left_line.startSketchPoint, left_line.endSketchPoint,
                                                     adsk.fusion.DimensionOrientations.VerticalDimensionOrientation,
                                                     adsk.core.Point3D.create(0.2, 0.2, 0)).parameter.expression = 'param_E/2'
    body_sketch.sketchDimensions.addDistanceDimension(left_bottom_line1.startSketchPoint, left_bottom_line1.endSketchPoint,
                                                     adsk.fusion.DimensionOrientations.HorizontalDimensionOrientation,
                                                     adsk.core.Point3D.create(-0.2, -0.2, 0)).parameter.expression = 'param_D/8'
    body_sketch.sketchDimensions.addDistanceDimension(left_bottom_line2.startSketchPoint, left_bottom_line2.endSketchPoint,
                                                     adsk.fusion.DimensionOrientations.HorizontalDimensionOrientation,
                                                     adsk.core.Point3D.create(-0.1, -0.2, 0)).parameter.expression = 'param_D/8'
    body_sketch.sketchDimensions.addDistanceDimension(left_bottom_line2.startSketchPoint, top_line.startSketchPoint,
                                                     adsk.fusion.DimensionOrientations.VerticalDimensionOrientation,
                                                     adsk.core.Point3D.create(-0.3, 0.2, 0)).parameter.expression = 'param_E/2 * 0.95'
    body_sketch.sketchDimensions.addDistanceDimension(bottom_line.startSketchPoint, top_line.endSketchPoint,
                                                     adsk.fusion.DimensionOrientations.VerticalDimensionOrientation,
                                                     adsk.core.Point3D.create(0.4, 0.1, 0)).parameter.expression = 'param_E/2 * 0.85'


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

    # assign the pysical material to body.
    addin_utility.apply_material(app, design, rev_body.bodies.item(0), constant.MATERIAL_ID_GLASS)
    #apply the right appearance.
    addin_utility.apply_appearance(app, design, rev_body.bodies.item(0), constant.APPEARANCE_ID_ALUMINUM_POLISHED)

    #apply the different appearance on the center revolve face
    center_face = None
    current_rad = E
    for face_i in rev_body.faces:
        face_geo = adsk.core.Cylinder.cast(face_i.geometry)
        if face_geo and face_geo.radius < current_rad:
            center_face = face_i
            current_rad = face_geo.radius

    addin_utility.apply_appearance(app, design, center_face, constant.APPEARANCE_ID_GLASS)

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


from .base import package_3d_model_base

class AxialFuse3DModel(package_3d_model_base.Package3DModelBase):
    def __init__(self):
        super().__init__()

    @staticmethod
    def type():
        return "axial_fuse"

    def create_model(self, params, design, component):
        axial_fuse(params, design, component)

package_3d_model_base.factory.register_package(AxialFuse3DModel.type(), AxialFuse3DModel) 


def run(context):
    ui = app.userInterface

    try:
        runWithInput(context)
    except:
        if ui:
            ui.messageBox('Failed:\n{}'.format(traceback.format_exc()))

def runWithInput(params, design = None, target_comp = None):
    axial_fuse(params, design, target_comp)
