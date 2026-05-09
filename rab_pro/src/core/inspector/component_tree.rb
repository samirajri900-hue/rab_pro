# ==============================================================================
# RAB Pro - Component Tree Builder
# Builds a hierarchical tree of components and groups in the model
# ==============================================================================

module RABPro
  module Core
    module Inspector
      class ComponentTree

        def initialize(model)
          @model = model
          @logger = Logger
        end

        # Build complete component tree with hierarchy
        def build
          {
            root: _build_tree_recursive(@model.entities, 0),
            total_nodes: _count_entities(@model.entities),
            max_depth: _find_max_depth(@model.entities)
          }
        rescue => e
          @logger.error("ComponentTree#build: #{e.message}")
          { root: [], total_nodes: 0, max_depth: 0 }
        end

        # Find all instances of a specific component definition
        def find_definition_instances(definition_name)
          result = []
          defn = @model.definitions[definition_name]
          return [] unless defn

          _search_instances_recursive(@model.entities, defn, result)
          result
        rescue => e
          @logger.error("ComponentTree#find_definition_instances: #{e.message}")
          []
        end

        # Get component definition by name
        def get_definition(name)
          defn = @model.definitions[name]
          return nil unless defn

          {
            id: defn.entityID.to_i,
            name: defn.name.to_s,
            count: defn.count.to_i,
            description: defn.description.to_s,
            insertion_point: defn.insertion_point.to_a,
            bounds: _bounds_to_hash(defn.bounds)
          }
        rescue
          nil
        end

        # List all component definitions used in model
        def list_definitions
          @model.definitions.map do |defn|
            {
              id: defn.entityID.to_i,
              name: defn.name.to_s,
              count: defn.count.to_i,
              description: defn.description.to_s
            }
          end
        rescue => e
          @logger.error("ComponentTree#list_definitions: #{e.message}")
          []
        end

        # Count component instances by type
        def count_by_definition
          result = {}
          @model.definitions.each do |defn|
            result[defn.name] = defn.count
          end
          result
        rescue => e
          @logger.error("ComponentTree#count_by_definition: #{e.message}")
          {}
        end

        # Get path to a specific entity (hierarchy)
        def get_entity_path(entity_id)
          entity = @model.find_entity_by_id(entity_id)
          return nil unless entity

          path = []
          _trace_path(entity, path)
          path.reverse
        rescue
          nil
        end

        # Find all groups
        def find_all_groups
          result = []
          _find_groups_recursive(@model.entities, result)
          result
        rescue => e
          @logger.error("ComponentTree#find_all_groups: #{e.message}")
          []
        end

        # Find all component instances
        def find_all_components
          result = []
          _find_components_recursive(@model.entities, result)
          result
        rescue => e
          @logger.error("ComponentTree#find_all_components: #{e.message}")
          []
        end

        private

        def _build_tree_recursive(container, depth, parent_id = nil)
          return [] if depth > 15

          nodes = []
          container.entities.each do |entity|
            case entity
            when Sketchup::ComponentInstance
              node = {
                id: entity.entityID.to_i,
                type: 'component',
                definition_id: entity.definition.entityID.to_i,
                definition_name: entity.definition.name.to_s,
                name: entity.name.to_s,
                depth: depth,
                parent_id: parent_id,
                layer: entity.layer&.name,
                material: entity.material&.name,
                hidden: entity.hidden?,
                transformation: entity.transformation.to_a.flatten,
                bounds: _bounds_to_hash(entity.bounds),
                children: []
              }
              nodes << node
            when Sketchup::Group
              children = _build_tree_recursive(entity.entities, depth + 1, entity.entityID.to_i)
              node = {
                id: entity.entityID.to_i,
                type: 'group',
                name: entity.name.to_s,
                depth: depth,
                parent_id: parent_id,
                layer: entity.layer&.name,
                material: entity.material&.name,
                hidden: entity.hidden?,
                transformation: entity.transformation.to_a.flatten,
                bounds: _bounds_to_hash(entity.bounds),
                children: children
              }
              nodes << node
            end
          end
          nodes
        end

        def _find_groups_recursive(container, result, depth = 0)
          return if depth > 15

          container.entities.each do |entity|
            if entity.is_a?(Sketchup::Group)
              result << {
                id: entity.entityID.to_i,
                name: entity.name.to_s,
                entity_count: entity.entities.length,
                layer: entity.layer&.name,
                bounds: _bounds_to_hash(entity.bounds)
              }
              _find_groups_recursive(entity.entities, result, depth + 1)
            elsif entity.is_a?(Sketchup::ComponentInstance)
              _find_groups_recursive(entity.definition.entities, result, depth + 1)
            end
          end
        end

        def _find_components_recursive(container, result, depth = 0)
          return if depth > 15

          container.entities.each do |entity|
            if entity.is_a?(Sketchup::ComponentInstance)
              result << {
                id: entity.entityID.to_i,
                definition_id: entity.definition.entityID.to_i,
                definition_name: entity.definition.name.to_s,
                layer: entity.layer&.name,
                bounds: _bounds_to_hash(entity.bounds)
              }
            end

            if entity.respond_to?(:entities)
              _find_components_recursive(entity.entities, result, depth + 1)
            end
          end
        end

        def _search_instances_recursive(container, definition, result, depth = 0)
          return if depth > 15

          container.entities.each do |entity|
            if entity.is_a?(Sketchup::ComponentInstance) && entity.definition == definition
              result << {
                id: entity.entityID.to_i,
                layer: entity.layer&.name,
                position: entity.transformation.origin.to_a,
                bounds: _bounds_to_hash(entity.bounds)
              }
            end

            if entity.respond_to?(:entities)
              _search_instances_recursive(entity.entities, definition, result, depth + 1)
            end
          end
        end

        def _count_entities(container, depth = 0)
          return 0 if depth > 15

          count = container.entities.length
          container.entities.each do |entity|
            if entity.respond_to?(:entities)
              count += _count_entities(entity.entities, depth + 1)
            end
          end
          count
        end

        def _find_max_depth(container, depth = 0)
          return depth if depth > 15

          max = depth
          container.entities.each do |entity|
            if entity.respond_to?(:entities)
              child_depth = _find_max_depth(entity.entities, depth + 1)
              max = child_depth if child_depth > max
            end
          end
          max
        end

        def _bounds_to_hash(bounds)
          return nil unless bounds

          {
            min: bounds.min.to_a,
            max: bounds.max.to_a,
            center: bounds.center.to_a,
            diagonal: bounds.diagonal.to_f.round(4)
          }
        rescue
          nil
        end

        def _trace_path(entity, path)
          # Note: This is a simplified implementation
          # Full implementation would need to traverse parent relationships
          path << {
            id: entity.entityID.to_i,
            type: entity.class.name.split('::').last,
            name: entity.respond_to?(:name) ? entity.name.to_s : 'Entity'
          }
        end

      end
    end
  end
end
