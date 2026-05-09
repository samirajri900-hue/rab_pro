# ==============================================================================
# RAB Pro - Geometry Analyzer
# Analyzes geometric properties of entities in the model
# ==============================================================================

module RABPro
  module Core
    module Inspector
      class GeometryAnalyzer

        def initialize
          @logger = Logger
        end

        # Analyze all entities in a container for geometry metrics
        def analyze(container)
          result = {
            total_area: 0.0,
            total_volume: 0.0,
            face_count: 0,
            edge_count: 0,
            by_layer: {},
            by_material: {},
            by_type: {}
          }

          _analyze_recursive(container, result)
          result
        rescue => e
          @logger.error("GeometryAnalyzer#analyze: #{e.message}")
          result
        end

        # Calculate volume for a component/group with transformation
        def calculate_volume(entity)
          case entity
          when Sketchup::ComponentInstance, Sketchup::Group
            _calculate_container_volume(entity)
          else
            0.0
          end
        rescue => e
          @logger.error("GeometryAnalyzer#calculate_volume: #{e.message}")
          0.0
        end

        # Calculate surface area for faces
        def calculate_surface_area(container)
          area = 0.0
          container.entities.each do |entity|
            if entity.is_a?(Sketchup::Face)
              area += entity.area.to_f
            elsif entity.respond_to?(:entities)
              area += calculate_surface_area(entity)
            end
          end
          area
        rescue => e
          @logger.error("GeometryAnalyzer#calculate_surface_area: #{e.message}")
          0.0
        end

        # Get bounding box dimensions
        def get_dimensions(entity)
          bounds = entity.respond_to?(:bounds) ? entity.bounds : nil
          return { width: 0, height: 0, depth: 0 } unless bounds

          {
            width: (bounds.max.x - bounds.min.x).to_f.round(4),
            height: (bounds.max.z - bounds.min.z).to_f.round(4),
            depth: (bounds.max.y - bounds.min.y).to_f.round(4),
            diagonal: bounds.diagonal.to_f.round(4)
          }
        rescue
          { width: 0, height: 0, depth: 0 }
        end

        # Estimate quantity based on geometry
        def estimate_quantity(entity, unit = 'm2')
          return 0.0 unless entity

          case unit.to_s.downcase
          when 'm2', 'square_meter', 'sqm'
            _calculate_area_for_unit(entity)
          when 'm3', 'cubic_meter', 'cum'
            calculate_volume(entity)
          when 'pieces', 'unit', 'pcs', 'bh'
            entity.is_a?(Sketchup::ComponentInstance) ? 1.0 : 0.0
          when 'meter', 'm', 'linear_meter', 'lm'
            _calculate_length_for_unit(entity)
          when 'kg', 'ton', 'kilograms'
            _estimate_weight(entity)
          else
            0.0
          end
        rescue => e
          @logger.error("GeometryAnalyzer#estimate_quantity: #{e.message}")
          0.0
        end

        # Analyze proximity (for grouping related entities)
        def find_nearby_entities(entity, radius_m = 0.5)
          return [] unless entity.respond_to?(:bounds)

          center = entity.bounds.center
          nearby = []

          _search_nearby_recursive(entity, center, radius_m, nearby)
          nearby
        rescue => e
          @logger.error("GeometryAnalyzer#find_nearby_entities: #{e.message}")
          []
        end

        private

        def _analyze_recursive(container, result, depth = 0)
          return if depth > 10

          container.entities.each do |entity|
            type_name = entity.class.name.split('::').last
            layer_name = entity.layer&.name || 'Default'
            material_name = entity.material&.name || 'Default'

            # Track by type
            result[:by_type][type_name] ||= 0
            result[:by_type][type_name] += 1

            # Track by layer
            result[:by_layer][layer_name] ||= { count: 0, area: 0.0, volume: 0.0 }
            result[:by_layer][layer_name][:count] += 1

            # Track by material
            result[:by_material][material_name] ||= { count: 0, area: 0.0 }
            result[:by_material][material_name][:count] += 1

            # Calculate area and volume
            if entity.is_a?(Sketchup::Face)
              area = entity.area.to_f
              result[:total_area] += area
              result[:by_layer][layer_name][:area] += area
              result[:by_material][material_name][:area] += area
            elsif entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
              volume = _calculate_container_volume(entity)
              result[:total_volume] += volume
              result[:by_layer][layer_name][:volume] += volume
            end

            if entity.is_a?(Sketchup::Face)
              result[:face_count] += 1
            elsif entity.is_a?(Sketchup::Edge)
              result[:edge_count] += 1
            end

            # Recurse
            if entity.respond_to?(:entities)
              _analyze_recursive(entity, result, depth + 1)
            end
          end
        end

        def _calculate_container_volume(entity)
          return 0.0 unless entity.respond_to?(:bounds)

          bounds = entity.bounds
          width = (bounds.max.x - bounds.min.x).to_f.abs
          depth = (bounds.max.y - bounds.min.y).to_f.abs
          height = (bounds.max.z - bounds.min.z).to_f.abs

          (width * depth * height).round(6)
        rescue
          0.0
        end

        def _calculate_area_for_unit(entity)
          case entity
          when Sketchup::Face
            entity.area.to_f
          when Sketchup::ComponentInstance, Sketchup::Group
            # Use bounds to estimate area (top surface)
            bounds = entity.bounds
            width = (bounds.max.x - bounds.min.x).to_f.abs
            depth = (bounds.max.y - bounds.min.y).to_f.abs
            (width * depth).round(4)
          else
            0.0
          end
        rescue
          0.0
        end

        def _calculate_length_for_unit(entity)
          case entity
          when Sketchup::Edge
            entity.length.to_f
          when Sketchup::ComponentInstance, Sketchup::Group
            bounds = entity.bounds
            (bounds.max.x - bounds.min.x).to_f.abs
          else
            0.0
          end
        rescue
          0.0
        end

        def _estimate_weight(entity)
          # Simple weight estimation: volume * assumed density (2.5 tons/m3 for concrete)
          volume = calculate_volume(entity)
          (volume * 2.5).round(2)
        rescue
          0.0
        end

        def _search_nearby_recursive(container, center, radius, nearby, depth = 0)
          return if depth > 5

          container.entities.each do |entity|
            if entity.respond_to?(:bounds)
              entity_center = entity.bounds.center
              distance = center.distance_to(entity_center)
              if distance <= radius
                nearby << {
                  entity_id: entity.entityID.to_i,
                  type: entity.class.name.split('::').last,
                  distance: distance.round(4)
                }
              end
            end

            if entity.respond_to?(:entities)
              _search_nearby_recursive(entity, center, radius, nearby, depth + 1)
            end
          end
        end

      end
    end
  end
end
