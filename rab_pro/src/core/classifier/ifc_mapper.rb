# ==============================================================================
# RAB Pro - IFC Mapper
# Maps SketchUp entities to IFC (Industry Foundation Classes) standards
# ==============================================================================

module RABPro
  module Core
    module Classifier
      class IFCMapper

        # IFC Object Type Classifications
        IFC_TYPES = {
          'IfcBuilding' => { name: 'Building', category: 'building' },
          'IfcBuildingStorey' => { name: 'Floor/Storey', category: 'level' },
          'IfcWall' => { name: 'Wall', category: 'structural' },
          'IfcColumn' => { name: 'Column', category: 'structural' },
          'IfcBeam' => { name: 'Beam', category: 'structural' },
          'IfcSlab' => { name: 'Floor Slab', category: 'structural' },
          'IfcRoof' => { name: 'Roof', category: 'structural' },
          'IfcDoor' => { name: 'Door', category: 'finishing' },
          'IfcWindow' => { name: 'Window', category: 'finishing' },
          'IfcStair' => { name: 'Stair', category: 'finishing' },
          'IfcRamp' => { name: 'Ramp', category: 'finishing' },
          'IfcCovering' => { name: 'Surface Finishing', category: 'finishing' },
          'IfcFurnishingElement' => { name: 'Furniture', category: 'finishing' },
          'IfcEquipmentElement' => { name: 'Equipment', category: 'mep' },
          'IfcFlowSegment' => { name: 'Pipe/Duct', category: 'mep' },
          'IfcElectricalElement' => { name: 'Electrical Element', category: 'mep' }
        }.freeze

        def initialize
          @logger = Logger
        end

        # Map SketchUp entity to IFC type
        def map_to_ifc(entity)
          return nil unless entity

          case entity
          when Sketchup::ComponentInstance
            _map_component_to_ifc(entity)
          when Sketchup::Group
            _map_group_to_ifc(entity)
          when Sketchup::Face
            _map_face_to_ifc(entity)
          when Sketchup::Edge
            _map_edge_to_ifc(entity)
          else
            nil
          end
        end

        # Get all available IFC types
        def available_ifc_types
          IFC_TYPES.keys.sort
        end

        # Get IFC type info
        def get_ifc_type_info(ifc_type)
          IFC_TYPES[ifc_type]
        end

        # Map layer to IFC storey
        def layer_to_storey(layer_name)
          {
            ifc_type: 'IfcBuildingStorey',
            name: layer_name,
            elevation: _extract_elevation_from_name(layer_name)
          }
        end

        # Generate IFC GUID
        def generate_ifc_guid
          # Simplified GUID generation (should be unique per project)
          time = Time.now
          "#{time.to_i}_#{rand(100000)}"
        end

        # Get IFC property set for entity
        def get_property_set(entity, ifc_type)
          return {} unless entity

          base_props = {
            GlobalId: generate_ifc_guid,
            Name: entity.respond_to?(:name) ? entity.name.to_s : 'Entity',
            Description: TagEngine.get_notes(entity),
            ObjectType: ifc_type
          }

          case ifc_type
          when 'IfcWall', 'IfcColumn', 'IfcBeam', 'IfcSlab'
            base_props.merge!(_get_structural_properties(entity))
          when 'IfcDoor', 'IfcWindow'
            base_props.merge!(_get_opening_properties(entity))
          when 'IfcCovering'
            base_props.merge!(_get_covering_properties(entity))
          end

          base_props
        end

        private

        def _map_component_to_ifc(component)
          name = component.definition.name.downcase
          category = Data::CategoryLibrary.find_by_name(name)

          # Map based on component definition name and category
          case name
          when /wall|dinding/
            'IfcWall'
          when /column|kolom/
            'IfcColumn'
          when /beam|balok/
            'IfcBeam'
          when /slab|lantai/
            'IfcSlab'
          when /roof|atap/
            'IfcRoof'
          when /door|pintu/
            'IfcDoor'
          when /window|jendela/
            'IfcWindow'
          when /stair|tangga/
            'IfcStair'
          when /equipment/
            'IfcEquipmentElement'
          when /furniture/
            'IfcFurnishingElement'
          else
            _map_by_category(category)
          end
        end

        def _map_group_to_ifc(group)
          # Groups are typically assemblies or containers
          entity_count = group.entities.length

          if entity_count > 10
            'IfcBuildingStorey'  # Could be a floor
          else
            nil  # Generic container, not mapped
          end
        end

        def _map_face_to_ifc(face)
          # Faces are typically coverings or slabs
          'IfcCovering'
        end

        def _map_edge_to_ifc(edge)
          # Edges could be structural or MEP elements
          'IfcFlowSegment'
        end

        def _map_by_category(category)
          return nil unless category

          case category.group.to_s.downcase
          when 'structural'
            'IfcWall'
          when 'finishing'
            'IfcCovering'
          when 'mep'
            'IfcEquipmentElement'
          when 'procurement'
            'IfcFurnishingElement'
          else
            nil
          end
        end

        def _extract_elevation_from_name(name)
          # Try to extract elevation number from layer name (e.g., "Level 2" -> 2)
          match = name.match(/(\d+)/)
          match ? match[1].to_i : 0
        end

        def _get_structural_properties(entity)
          bounds = entity.respond_to?(:bounds) ? entity.bounds : nil
          return {} unless bounds

          {
            Length: (bounds.max.x - bounds.min.x).to_f.round(4),
            Width: (bounds.max.y - bounds.min.y).to_f.round(4),
            Height: (bounds.max.z - bounds.min.z).to_f.round(4),
            Material: entity.material&.name
          }
        end

        def _get_opening_properties(entity)
          bounds = entity.respond_to?(:bounds) ? entity.bounds : nil
          return {} unless bounds

          {
            OverallHeight: (bounds.max.z - bounds.min.z).to_f.round(4),
            OverallWidth: (bounds.max.x - bounds.min.x).to_f.round(4)
          }
        end

        def _get_covering_properties(entity)
          {
            Area: entity.is_a?(Sketchup::Face) ? entity.area.to_f.round(4) : nil,
            Material: entity.material&.name
          }
        end

      end
    end
  end
end
