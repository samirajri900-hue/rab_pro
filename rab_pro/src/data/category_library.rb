# ==============================================================================
# RAB Pro - Data Layer: Category Library
# Centralized library of RAB categories, groups, and work items
# ==============================================================================

module RABPro
  module Data
    class CategoryLibrary
      
      # Define all categories by group
      CATEGORIES = {
        procurement: {
          label: 'Procurement',
          group_label: 'Pengadaan',
          items: [
            { id: :material_frame, code: 'M-001', name: 'Material Frame', unit: 'item', group: 'procurement' },
            { id: :material_glass, code: 'M-002', name: 'Material Kaca', unit: 'item', group: 'procurement' },
            { id: :hardware, code: 'M-003', name: 'Hardware', unit: 'item', group: 'procurement' }
          ]
        },
        structural: {
          label: 'Structural',
          group_label: 'Struktur',
          items: [
            { id: :column, code: 'S-001', name: 'Kolom', unit: 'm', group: 'structural' },
            { id: :beam, code: 'S-002', name: 'Balok', unit: 'm', group: 'structural' },
            { id: :foundation, code: 'S-003', name: 'Pondasi', unit: 'm3', group: 'structural' }
          ]
        },
        finishing: {
          label: 'Finishing',
          group_label: 'Finishing',
          items: [
            { id: :paint, code: 'F-001', name: 'Cat Dinding', unit: 'm2', group: 'finishing' },
            { id: :flooring, code: 'F-002', name: 'Lantai', unit: 'm2', group: 'finishing' },
            { id: :ceiling, code: 'F-003', name: 'Plafon', unit: 'm2', group: 'finishing' }
          ]
        },
        mep: {
          label: 'MEP (Mechanical, Electrical, Plumbing)',
          group_label: 'MEP',
          items: [
            { id: :electrical_cable, code: 'E-001', name: 'Kabel Listrik', unit: 'm', group: 'mep' },
            { id: :pipe, code: 'P-001', name: 'Pipa', unit: 'm', group: 'mep' },
            { id: :hvac, code: 'H-001', name: 'HVAC', unit: 'item', group: 'mep' }
          ]
        },
        labor: {
          label: 'Labor',
          group_label: 'Tenaga Kerja',
          items: [
            { id: :skilled_worker, code: 'L-001', name: 'Pekerja Terampil', unit: 'org', group: 'labor' },
            { id: :unskilled_worker, code: 'L-002', name: 'Pekerja Tidak Terampil', unit: 'org', group: 'labor' }
          ]
        }
      }.freeze

      # Get all categories as array
      # @return [Array<Hash>] all categories with metadata
      def self.all
        result = []
        CATEGORIES.each do |group_id, group_data|
          group_data[:items].each do |item|
            result << {
              id:           item[:id],
              code:         item[:code],
              name:         item[:name],
              unit:         item[:unit],
              group:        group_id,
              group_label:  group_data[:group_label]
            }
          end
        end
        result
      end

      # Get categories by group
      # @param [Symbol] group_id
      # @return [Array<Hash>] categories in group
      def self.by_group(group_id)
        group_data = CATEGORIES[group_id]
        return [] unless group_data
        
        group_data[:items].map do |item|
          {
            id:           item[:id],
            code:         item[:code],
            name:         item[:name],
            unit:         item[:unit],
            group:        group_id,
            group_label:  group_data[:group_label]
          }
        end
      end

      # Find a single category
      # @param [Symbol] category_id
      # @return [Hash] category or nil
      def self.find(category_id)
        all.find { |c| c[:id] == category_id }
      end

      # Get all groups
      # @return [Array<Hash>] groups with metadata
      def self.groups
        CATEGORIES.map do |group_id, group_data|
          {
            id:    group_id,
            label: group_data[:label],
            name:  group_data[:group_label],
            count: group_data[:items].size
          }
        end
      end

      # Convert to JSON-safe array
      # @return [Array<Hash>] categories
      def self.to_json_array
        all.map do |cat|
          {
            id:          cat[:id].to_s,
            code:        cat[:code],
            name:        cat[:name],
            unit:        cat[:unit],
            group:       cat[:group].to_s,
            group_label: cat[:group_label]
          }
        end
      end

      # Validate a category ID
      # @param [Symbol, String] category_id
      # @return [Boolean]
      def self.valid?(category_id)
        find(category_id.to_sym).present?
      end
    end
  end
end
