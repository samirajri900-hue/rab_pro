# ==============================================================================
# RAB Pro - Work Classifier
# Classifies work items into construction work types and standards
# ==============================================================================

module RABPro
  module Core
    module Classifier
      class WorkClassifier

        # Standard work classifications based on Indonesian construction standards
        WORK_TYPES = {
          structural: {
            name: 'Pekerjaan Struktur',
            subcategories: [:foundation, :column, :beam, :slab, :wall],
            code_prefix: 'STR'
          },
          finishing: {
            name: 'Pekerjaan Finishing',
            subcategories: [:plaster, :paint, :flooring, :ceiling, :doors, :windows],
            code_prefix: 'FIN'
          },
          mep: {
            name: 'Pekerjaan MEP',
            subcategories: [:electrical, :plumbing, :hvac, :fire_safety],
            code_prefix: 'MEP'
          },
          procurement: {
            name: 'Penyediaan Bahan',
            subcategories: [:materials, :equipment, :rentals],
            code_prefix: 'PRO'
          },
          labor: {
            name: 'Tenaga Kerja',
            subcategories: [:skilled, :unskilled, :supervision],
            code_prefix: 'LAB'
          }
        }.freeze

        def initialize
          @logger = Logger
        end

        # Classify an entity based on its properties
        def classify(entity)
          return nil unless entity

          classification = {
            work_type: _detect_work_type(entity),
            confidence: 0.5,
            basis: 'unknown'
          }

          classification
        end

        # Get all work types available
        def all_work_types
          WORK_TYPES.keys
        end

        # Get details about a work type
        def get_work_type_info(work_type)
          WORK_TYPES[work_type.to_sym] || nil
        end

        # Classify text/description to work type
        def classify_by_description(description)
          return nil unless description

          text = description.to_s.downcase

          WORK_TYPES.each do |work_type, info|
            keywords = info[:name].downcase.split
            if keywords.any? { |kw| text.include?(kw) }
              return {
                work_type: work_type,
                confidence: 0.8,
                basis: 'description_match'
              }
            end

            info[:subcategories].each do |subcat|
              if text.include?(subcat.to_s.downcase)
                return {
                  work_type: work_type,
                  subtype: subcat,
                  confidence: 0.8,
                  basis: 'description_match'
                }
              end
            end
          end

          nil
        end

        # Generate work code for an item
        def generate_code(work_type, sequence_number = 1)
          info = get_work_type_info(work_type)
          return nil unless info

          code_prefix = info[:code_prefix]
          "#{code_prefix}-#{sequence_number.to_s.rjust(4, '0')}"
        end

        # Get recommended unit for a work type
        def get_default_unit(work_type)
          case work_type.to_sym
          when :structural
            'm3'  # cubic meter
          when :finishing
            'm2'  # square meter
          when :mep
            'm'   # linear meter
          when :procurement
            'pcs' # pieces
          when :labor
            'hari' # days
          else
            'unit'
          end
        end

        # Estimate cost category factors
        def get_cost_factors(work_type)
          case work_type.to_sym
          when :structural
            { material: 0.45, labor: 0.35, equipment: 0.20 }
          when :finishing
            { material: 0.50, labor: 0.40, equipment: 0.10 }
          when :mep
            { material: 0.55, labor: 0.30, equipment: 0.15 }
          when :procurement
            { material: 0.80, labor: 0.10, equipment: 0.10 }
          when :labor
            { material: 0.0, labor: 1.0, equipment: 0.0 }
          else
            { material: 0.33, labor: 0.33, equipment: 0.34 }
          end
        end

        private

        def _detect_work_type(entity)
          # Try to detect work type from various entity properties
          layer = entity.layer&.name&.downcase
          material = entity.material&.name&.downcase
          name = entity.respond_to?(:name) ? entity.name.to_s.downcase : ''

          # Check structural indicators
          if [layer, material, name].compact.any? { |s| s.match?(/struktur|concrete|beton|steel|baja|column|kolom|beam|balok/i) }
            return :structural
          end

          # Check finishing indicators
          if [layer, material, name].compact.any? { |s| s.match?(/finishing|plaster|cat|paint|lantai|floor|ceiling|atap|roof|pintu|door|window/i) }
            return :finishing
          end

          # Check MEP indicators
          if [layer, material, name].compact.any? { |s| s.match?(/mep|electrical|mekanik|plumbing|air|udara|listrik|sanitasi/i) }
            return :mep
          end

          # Check procurement indicators
          if [layer, material, name].compact.any? { |s| s.match?(/procurement|material|supply|bahan/i) }
            return :procurement
          end

          # Check labor indicators
          if [layer, material, name].compact.any? { |s| s.match?(/labor|kerja|jasa|pekerja/i) }
            return :labor
          end

          nil
        end

      end
    end
  end
end
