# ==============================================================================
# RAB Pro - Entity Reader (Core Inspector)
# Reads and catalogs all entities from a SketchUp model
# ==============================================================================

module RABPro
  module Core
    module Inspector
      class EntityReader

        def initialize(model)
          @model = model
          @logger = Logger
        end

        # Return summary statistics about the model
        def summary
          entities = @model.entities
          {
            total_entities: entities.length,
            components: entities.select { |e| e.is_a?(Sketchup::ComponentInstance) }.length,
            groups: entities.select { |e| e.is_a?(Sketchup::Group) }.length,
            faces: entities.select { |e| e.is_a?(Sketchup::Face) }.length,
            edges: entities.select { |e| e.is_a?(Sketchup::Edge) }.length,
            texts: entities.select { |e| e.is_a?(Sketchup::Text) }.length,
            dimensions: entities.select { |e| e.is_a?(Sketchup::Dimension) }.length,
            construction_lines: entities.select { |e| e.is_a?(Sketchup::ConstructionLine) }.length,
            construction_points: entities.select { |e| e.is_a?(Sketchup::ConstructionPoint) }.length,
            image_count: entities.select { |e| e.is_a?(Sketchup::Image) }.length,
            layer_count: @model.layers.length,
            material_count: @model.materials.length,
            scene_count: @model.pages.length,
            bounds: _read_bounds
          }
        rescue => e
          @logger.error("EntityReader#summary: #{e.message}")
          {}
        end

        # Read all entities with full details (expensive operation)
        def read_all
          result = []
          _read_entities_recursive(@model.entities, result, 0)
          result
        rescue => e
          @logger.error("EntityReader#read_all: #{e.message}")
          []
        end

        # Read entities at top level only
        def read_top_level
          result = []
          @model.entities.each do |entity|
            result << _entity_to_hash(entity, 0)
          end
          result
        rescue => e
          @logger.error("EntityReader#read_top_level: #{e.message}")
          []
        end

        # Find entity by ID
        def find_entity(entity_id)
          @model.find_entity_by_id(entity_id)
        rescue
          nil
        end

        # Read all layers
        def read_layers
          @model.layers.map do |layer|
            {
              id: layer.entityID.to_i,
              name: layer.name.to_s,
              visible: layer.visible?,
              color: layer.color.nil? ? nil : layer.color.to_a,
              material: layer.material&.name
            }
          end
        rescue => e
          @logger.error("EntityReader#read_layers: #{e.message}")
          []
        end

        # Read all materials
        def read_materials
          @model.materials.map do |mat|
            {
              id: mat.entityID.to_i,
              name: mat.name.to_s,
              display_name: mat.display_name.to_s,
              color: mat.color&.to_a || [128, 128, 128, 255],
              texture: mat.texture&.filename
            }
          end
        rescue => e
          @logger.error("EntityReader#read_materials: #{e.message}")
          []
        end

        # Get all component definitions
        def read_components
          @model.definitions.map do |defn|
            {
              id: defn.entityID.to_i,
              name: defn.name.to_s,
              count: defn.count.to_i,
              description: defn.description.to_s,
              insertion_point: defn.insertion_point.to_a,
              bounds: _bounds_to_hash(defn.bounds)
            }
          end
        rescue => e
          @logger.error("EntityReader#read_components: #{e.message}")
          []
        end

        private

        def _read_entities_recursive(container, result, depth)
          return if depth > 10  # Prevent infinite recursion
          container.each do |entity|
            result << _entity_to_hash(entity, depth)
            if entity.respond_to?(:entities)
              _read_entities_recursive(entity.entities, result, depth + 1)
            end
          end
        end

        def _entity_to_hash(entity, depth)
          hash = {
            id: entity.entityID.to_i,
            type: entity.class.name.split('::').last,
            depth: depth,
            layer: entity.layer&.name,
            material: entity.material&.name,
            hidden: entity.hidden?,
            deleted: entity.deleted?
          }

          case entity
          when Sketchup::ComponentInstance
            hash.merge!({
              definition_id: entity.definition.entityID.to_i,
              definition_name: entity.definition.name.to_s,
              transformation: entity.transformation.to_a.flatten,
              bounds: _bounds_to_hash(entity.bounds)
            })
          when Sketchup::Group
            hash.merge!({
              transformation: entity.transformation.to_a.flatten,
              bounds: _bounds_to_hash(entity.bounds),
              entity_count: entity.entities.length
            })
          when Sketchup::Face
            hash.merge!({
              area: entity.area.to_f,
              normal: entity.normal.to_a,
              bounds: _bounds_to_hash(entity.bounds)
            })
          when Sketchup::Edge
            hash.merge!({
              length: entity.length.to_f,
              start_point: entity.start.position.to_a,
              end_point: entity.end.position.to_a
            })
          when Sketchup::Text
            hash.merge!({
              text: entity.text.to_s,
              point: entity.point.to_a,
              font: entity.font_name.to_s,
              size: entity.font_size.to_i
            })
          when Sketchup::Image
            hash.merge!({
              width: entity.width.to_f,
              height: entity.height.to_f,
              filename: entity.filename.to_s
            })
          when Sketchup::Dimension
            hash.merge!({
              value: entity.value.to_f,
              text: entity.text.to_s
            })
          when Sketchup::ConstructionLine
            hash.merge!({
              start_point: entity.start.to_a,
              end_point: entity.end.to_a
            })
          when Sketchup::ConstructionPoint
            hash.merge!({
              position: entity.position.to_a
            })
          end

          hash
        rescue => e
          hash[:error] = e.message
          hash
        end

        def _read_bounds
          bounds = @model.bounds
          {
            min: bounds.min.to_a,
            max: bounds.max.to_a,
            center: bounds.center.to_a,
            diagonal: bounds.diagonal.to_f
          }
        rescue
          nil
        end

        def _bounds_to_hash(bounds)
          return nil unless bounds
          {
            min: bounds.min.to_a,
            max: bounds.max.to_a,
            center: bounds.center.to_a,
            diagonal: bounds.diagonal.to_f
          }
        rescue
          nil
        end

      end
    end
  end
end
