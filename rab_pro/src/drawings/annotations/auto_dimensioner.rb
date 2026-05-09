# ==============================================================================
# RAB Pro - Auto Dimensioner (Fase 3)
# Automatically add dimensions to drawing entities.
# ==============================================================================

module RABPro
  module Drawings
    module Annotations
      class AutoDimensioner

        DIMENSION_LAYER = 'RAB_Dimensions'.freeze

        def initialize(model)
          @model = model
          @dimensions_added = 0
        end

        # --------- Main API ---------

        def auto_dimension_all
          """Auto-dimension all edges and components in model."""
          Logger.info('AutoDimensioner: starting auto-dimension')
          @dimensions_added = 0

          _ensure_dimension_layer

          # Process all edges
          @model.entities.each do |entity|
            case entity
            when Sketchup::Edge
              _dimension_edge(entity)
            when Sketchup::Face
              _dimension_face(entity)
            when Sketchup::ComponentInstance
              _dimension_component(entity)
            end
          end

          Logger.info("AutoDimensioner: added #{@dimensions_added} dimensions")
          @dimensions_added
        end

        def dimension_entity(entity)
          """Dimension a single entity."""
          _ensure_dimension_layer

          case entity
          when Sketchup::Edge
            _dimension_edge(entity)
          when Sketchup::Face
            _dimension_face(entity)
          when Sketchup::ComponentInstance
            _dimension_component(entity)
          end
        end

        private

        def _ensure_dimension_layer
          @model.layers.add(DIMENSION_LAYER) unless @model.layers[DIMENSION_LAYER]
        end

        def _dimension_edge(edge)
          """Add dimension to an edge."""
          return unless edge.valid?

          length_m = edge.length.to_m
          return if length_m < 0.1 # Skip very short edges

          # Create a text note with dimension
          pt1 = edge.start.position
          pt2 = edge.end.position
          mid = Geom::Point3d.new(
            (pt1.x + pt2.x) / 2,
            (pt1.y + pt2.y) / 2,
            (pt1.z + pt2.z) / 2 + 0.1  # Offset slightly above
          )

          # Add as text entity
          text = @model.entities.add_text(
            StringHelper.format_dimension(length_m),
            mid
          )
          text.layer = @model.layers[DIMENSION_LAYER] if text

          @dimensions_added += 1
        rescue => e
          Logger.warn("_dimension_edge: #{e.message}")
        end

        def _dimension_face(face)
          """Add dimension annotation to a face."""
          return unless face.valid?

          area_m2 = face.area.to_m2
          return if area_m2 < 0.1

          # Place text at face center
          center = face.bounds.center
          text = @model.entities.add_text(
            "#{area_m2.round(2)} m²",
            center
          )
          text.layer = @model.layers[DIMENSION_LAYER] if text

          @dimensions_added += 1
        rescue => e
          Logger.warn("_dimension_face: #{e.message}")
        end

        def _dimension_component(component)
          """Add dimension to component bounding box."""
          return unless component.valid?

          bb = component.bounds
          return if bb.empty?

          length_m = bb.max.x - bb.min.x
          width_m = bb.max.y - bb.min.y
          height_m = bb.max.z - bb.min.z

          text_lines = []
          text_lines << "L: #{length_m.round(2)}m" if length_m > 0.1
          text_lines << "W: #{width_m.round(2)}m" if width_m > 0.1
          text_lines << "H: #{height_m.round(2)}m" if height_m > 0.1

          if text_lines.any?
            text = @model.entities.add_text(
              text_lines.join("\n"),
              bb.center
            )
            text.layer = @model.layers[DIMENSION_LAYER] if text
            @dimensions_added += 1
          end
        rescue => e
          Logger.warn("_dimension_component: #{e.message}")
        end
      end
    end
  end
end
