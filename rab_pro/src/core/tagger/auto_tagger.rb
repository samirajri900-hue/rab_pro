# ==============================================================================
# RAB Pro - Auto Tagger
# Automatically tags entities based on layer names, material, and geometry
# ==============================================================================

module RABPro
  module Core
    module Tagger
      class AutoTagger

        LAYER_PATTERNS = {
          procurement: /procurement|material|supply|bahan/i,
          structural: /structure|concrete|beton|steel|baja|column|kolom|beam|balok|wall|dinding/i,
          finishing: /finishing|plaster|cat|paint|lantai|floor|ceiling|atap|roof|pintu|door|window/i,
          mep: /mep|electrical|mekanik|plumbing|air|udara|listrik|sanitasi/i,
          labor: /labor|kerja|jasa|pekerja/i
        }.freeze

        def initialize(model)
          @model = model
          @logger = Logger
          @category_lib = Data::CategoryLibrary
        end

        # Run auto-tagging on entire model
        def run
          result = {
            total_processed: 0,
            tagged: 0,
            by_method: {}
          }

          _auto_tag_recursive(@model.entities, result)
          result
        rescue => e
          @logger.error("AutoTagger#run: #{e.message}")
          result
        end

        # Auto-tag a single entity
        def tag_entity(entity, category = nil)
          return false unless entity

          # If category provided, use it
          if category
            TagEngine.tag_entity(entity, category)
            return true
          end

          # Otherwise, auto-detect
          detected_category = _detect_category(entity)
          if detected_category
            TagEngine.tag_entity(entity, detected_category)
            return true
          end

          false
        rescue => e
          @logger.error("AutoTagger#tag_entity: #{e.message}")
          false
        end

        # Suggest category for an entity
        def suggest_category(entity)
          return nil unless entity
          _detect_category(entity)
        end

        private

        def _auto_tag_recursive(container, result, depth = 0)
          return if depth > 15

          container.entities.each do |entity|
            case entity
            when Sketchup::ComponentInstance, Sketchup::Group, Sketchup::Face
              result[:total_processed] += 1

              # Skip if already tagged
              next if TagEngine.is_tagged?(entity)

              # Try to auto-detect and tag
              detected = _detect_category(entity)
              if detected
                TagEngine.tag_entity(entity, detected)
                result[:tagged] += 1
                result[:by_method][detected] ||= 0
                result[:by_method][detected] += 1
              end
            end

            if entity.respond_to?(:entities)
              _auto_tag_recursive(entity.entities, result, depth + 1)
            end
          end
        end

        def _detect_category(entity)
          # Priority order: manual tag > layer pattern > material > geometry

          # 1. Check if already has category
          existing = TagEngine.get_category(entity)
          return existing if existing

          # 2. Try layer-based detection
          layer_cat = _detect_by_layer(entity)
          return layer_cat if layer_cat

          # 3. Try material-based detection
          material_cat = _detect_by_material(entity)
          return material_cat if material_cat

          # 4. Try geometry-based detection
          geometry_cat = _detect_by_geometry(entity)
          return geometry_cat if geometry_cat

          # 5. Default fallback
          nil
        end

        def _detect_by_layer(entity)
          layer_name = entity.layer&.name
          return nil unless layer_name

          LAYER_PATTERNS.each do |category, pattern|
            return category if layer_name.match?(pattern)
          end

          nil
        end

        def _detect_by_material(entity)
          material = entity.material
          return nil unless material

          material_name = material.name.to_s.downcase

          LAYER_PATTERNS.each do |category, pattern|
            return category if material_name.match?(pattern)
          end

          nil
        end

        def _detect_by_geometry(entity)
          # Detect based on geometry shape/properties
          case entity
          when Sketchup::ComponentInstance
            definition = entity.definition
            defn_name = definition.name.to_s.downcase

            LAYER_PATTERNS.each do |category, pattern|
              return category if defn_name.match?(pattern)
            end

          when Sketchup::Face
            # Faces often indicate finishing work
            return :finishing

          when Sketchup::Group
            # Groups often contain structural elements
            entity_count = entity.entities.length
            return :structural if entity_count > 5
          end

          nil
        end

      end
    end
  end
end
