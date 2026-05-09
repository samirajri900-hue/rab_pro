# ==============================================================================
# RAB Pro - Tag Engine (Core Tagger)
# Manages entity tagging system for RAB categorization
# ==============================================================================

module RABPro
  module Core
    module Tagger
      class TagEngine

        ATTRIBUTE_DICTIONARY = 'RABPro_Tags'.freeze
        CATEGORY_ATTR = 'category_id'.freeze
        QUANTITY_ATTR = 'quantity'.freeze
        QUANTITY_OVERRIDE_ATTR = 'quantity_override'.freeze
        UNIT_ATTR = 'unit'.freeze
        NOTES_ATTR = 'notes'.freeze

        def self.tag_entity(entity, category_id, unit = nil, notes = nil)
          return false unless entity

          dict = entity.attribute_dictionary(ATTRIBUTE_DICTIONARY, true)
          dict[CATEGORY_ATTR] = category_id.to_s
          dict[UNIT_ATTR] = unit.to_s if unit
          dict[NOTES_ATTR] = notes.to_s if notes
          true
        rescue => e
          Logger.error("TagEngine.tag_entity: #{e.message}")
          false
        end

        def self.get_category(entity)
          return nil unless entity
          entity.get_attribute(ATTRIBUTE_DICTIONARY, CATEGORY_ATTR)
        rescue
          nil
        end

        def self.get_tags(entity)
          return {} unless entity

          dict = entity.get_attribute(ATTRIBUTE_DICTIONARY, nil)
          return {} unless dict

          {
            category_id: dict[CATEGORY_ATTR],
            quantity: dict[QUANTITY_ATTR],
            quantity_override: dict[QUANTITY_OVERRIDE_ATTR],
            unit: dict[UNIT_ATTR],
            notes: dict[NOTES_ATTR]
          }
        rescue
          {}
        end

        def self.set_quantity_override(entity, quantity)
          return false unless entity

          dict = entity.attribute_dictionary(ATTRIBUTE_DICTIONARY, true)
          dict[QUANTITY_OVERRIDE_ATTR] = quantity.to_f
          true
        rescue => e
          Logger.error("TagEngine.set_quantity_override: #{e.message}")
          false
        end

        def self.get_quantity_override(entity)
          return nil unless entity
          entity.get_attribute(ATTRIBUTE_DICTIONARY, QUANTITY_OVERRIDE_ATTR)
        rescue
          nil
        end

        def self.has_quantity_override?(entity)
          get_quantity_override(entity).nil? ? false : true
        end

        def self.remove_override(entity)
          return false unless entity

          dict = entity.get_attribute(ATTRIBUTE_DICTIONARY)
          return true unless dict

          dict.delete(QUANTITY_OVERRIDE_ATTR)
          true
        rescue
          false
        end

        def self.set_notes(entity, notes)
          return false unless entity

          dict = entity.attribute_dictionary(ATTRIBUTE_DICTIONARY, true)
          dict[NOTES_ATTR] = notes.to_s
          true
        rescue
          false
        end

        def self.get_notes(entity)
          return '' unless entity
          entity.get_attribute(ATTRIBUTE_DICTIONARY, NOTES_ATTR) || ''
        rescue
          ''
        end

        # Get statistics about tags in the model
        def self.stats(model)
          return {} unless model

          total = 0
          tagged = 0
          by_category = {}
          has_override = 0

          _count_tags_recursive(model.entities, total, tagged, by_category, has_override)

          {
            total_entities: total,
            tagged_entities: tagged,
            untagged_entities: total - tagged,
            tagged_percentage: total > 0 ? ((tagged.to_f / total) * 100).round(1) : 0,
            by_category: by_category,
            entities_with_override: has_override
          }
        rescue => e
          Logger.error("TagEngine.stats: #{e.message}")
          {}
        end

        # Find all entities with a specific category
        def self.find_by_category(model, category_id)
          result = []
          _find_category_recursive(model.entities, category_id, result)
          result
        rescue => e
          Logger.error("TagEngine.find_by_category: #{e.message}")
          []
        end

        # Find all untagged entities
        def self.find_untagged(model)
          result = []
          _find_untagged_recursive(model.entities, result)
          result
        rescue => e
          Logger.error("TagEngine.find_untagged: #{e.message}")
          []
        end

        # Clear all tags from an entity
        def self.clear_tags(entity)
          return false unless entity

          entity.delete_attribute(ATTRIBUTE_DICTIONARY) rescue true
          true
        rescue
          false
        end

        # Check if entity is tagged
        def self.is_tagged?(entity)
          return false unless entity
          !get_category(entity).nil?
        end

        private

        def self._count_tags_recursive(container, total, tagged, by_category, has_override, depth = 0)
          return if depth > 15

          container.entities.each do |entity|
            case entity
            when Sketchup::ComponentInstance, Sketchup::Group, Sketchup::Face
              total += 1
              category = get_category(entity)
              if category
                tagged += 1
                by_category[category.to_s] ||= 0
                by_category[category.to_s] += 1
              end
              has_override += 1 if has_quantity_override?(entity)
            end

            if entity.respond_to?(:entities)
              _count_tags_recursive(entity.entities, total, tagged, by_category, has_override, depth + 1)
            end
          end
        end

        def self._find_category_recursive(container, category_id, result, depth = 0)
          return if depth > 15

          category_str = category_id.to_s

          container.entities.each do |entity|
            if get_category(entity)&.to_s == category_str
              result << {
                id: entity.entityID.to_i,
                type: entity.class.name.split('::').last,
                name: entity.respond_to?(:name) ? entity.name.to_s : 'Entity',
                layer: entity.layer&.name,
                tags: get_tags(entity)
              }
            end

            if entity.respond_to?(:entities)
              _find_category_recursive(entity.entities, category_id, result, depth + 1)
            end
          end
        end

        def self._find_untagged_recursive(container, result, depth = 0)
          return if depth > 15

          container.entities.each do |entity|
            case entity
            when Sketchup::ComponentInstance, Sketchup::Group, Sketchup::Face
              unless is_tagged?(entity)
                result << {
                  id: entity.entityID.to_i,
                  type: entity.class.name.split('::').last,
                  name: entity.respond_to?(:name) ? entity.name.to_s : 'Entity',
                  layer: entity.layer&.name
                }
              end
            end

            if entity.respond_to?(:entities)
              _find_untagged_recursive(entity.entities, result, depth + 1)
            end
          end
        end

      end
    end
  end
end
