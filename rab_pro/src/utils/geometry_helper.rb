# ==============================================================================
# RAB Pro - Geometry Helper Utility
# Helper methods for 3D geometry calculations and analysis
# ==============================================================================

module RABPro
  module GeometryHelper
    # Calculate volume of a face (extrusion depth)
    def self.calculate_volume(entity, extrusion_depth = nil)
      return 0.0 unless entity
      
      case entity
      when Sketchup::Face
        area = entity.area.to_f
        depth = extrusion_depth || 1.0
        area * depth
      when Sketchup::Group, Sketchup::ComponentInstance
        bounding_box_volume(entity)
      else
        0.0
      end
    rescue => e
      Logger.warn("GeometryHelper.calculate_volume error: #{e.message}")
      0.0
    end

    # Calculate surface area
    def self.calculate_area(entity)
      return 0.0 unless entity
      
      case entity
      when Sketchup::Face
        entity.area.to_f
      when Sketchup::Group, Sketchup::ComponentInstance
        total = 0.0
        entity.entities.each do |e|
          total += calculate_area(e) if e.is_a?(Sketchup::Face)
        end
        total
      else
        0.0
      end
    rescue => e
      Logger.warn("GeometryHelper.calculate_area error: #{e.message}")
      0.0
    end

    # Get bounding box volume
    def self.bounding_box_volume(entity)
      return 0.0 unless entity
      
      bbox = entity.bounds
      width = (bbox.max.x - bbox.min.x).abs.to_f
      height = (bbox.max.y - bbox.min.y).abs.to_f
      depth = (bbox.max.z - bbox.min.z).abs.to_f
      
      (width * height * depth).round(4)
    rescue => e
      Logger.warn("GeometryHelper.bounding_box_volume error: #{e.message}")
      0.0
    end

    # Get linear dimension (length)
    def self.calculate_length(entity)
      return 0.0 unless entity
      
      case entity
      when Sketchup::Edge
        entity.length.to_f
      when Sketchup::Group, Sketchup::ComponentInstance
        bbox = entity.bounds
        # Return longest dimension
        width = (bbox.max.x - bbox.min.x).abs.to_f
        height = (bbox.max.y - bbox.min.y).abs.to_f
        depth = (bbox.max.z - bbox.min.z).abs.to_f
        [width, height, depth].max
      else
        0.0
      end
    rescue => e
      Logger.warn("GeometryHelper.calculate_length error: #{e.message}")
      0.0
    end

    # Find bounding box
    def self.get_bounds(entity)
      return nil unless entity
      entity.bounds
    rescue => e
      Logger.warn("GeometryHelper.get_bounds error: #{e.message}")
      nil
    end

    # Find nearby entities within distance
    def self.find_nearby_entities(entity, distance = 1.0, model = nil)
      return [] unless entity && model
      
      nearby = []
      bbox = entity.bounds
      center = bbox.center
      
      search_box = Geom::BoundingBox.new
      search_box.add(center.offset(Geom::Vector3d.new(distance, distance, distance)))
      search_box.add(center.offset(Geom::Vector3d.new(-distance, -distance, -distance)))
      
      model.entities.each do |e|
        if e != entity && e.bounds && search_box.contains?(e.bounds.center)
          dist = center.distance_to_line([e.bounds.center, Geom::Vector3d.new(0, 0, 1)])
          nearby << { entity: e, distance: dist.to_f } if dist <= distance
        end
      end
      
      nearby.sort_by { |h| h[:distance] }
    rescue => e
      Logger.warn("GeometryHelper.find_nearby_entities error: #{e.message}")
      []
    end

    # Calculate perimeter of a face
    def self.calculate_perimeter(entity)
      return 0.0 unless entity.is_a?(Sketchup::Face)
      
      perimeter = 0.0
      entity.outer_loop.edges.each do |edge|
        perimeter += edge.length.to_f
      end
      perimeter.round(4)
    rescue => e
      Logger.warn("GeometryHelper.calculate_perimeter error: #{e.message}")
      0.0
    end
  end
end
