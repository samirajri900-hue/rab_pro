# ==============================================================================
# RAB Pro - Material Database
# Store and manage material pricing and specifications
# ==============================================================================

module RABPro
  module Data
    class MaterialDatabase
      
      # Database of materials with default pricing
      MATERIALS = {
        # Procurement materials
        m_001: {
          name: 'Material Frame',
          category: :material_frame,
          unit: 'item',
          unit_price: 500_000.0,
          supplier: 'PT Supplier A',
          notes: 'Frame standar'
        },
        m_002: {
          name: 'Kaca Tempered',
          category: :material_glass,
          unit: 'item',
          unit_price: 150_000.0,
          supplier: 'PT Supplier B',
          notes: 'Ukuran standar'
        },
        # Structural materials
        s_001: {
          name: 'Baja Tulangan',
          category: :structural,
          unit: 'kg',
          unit_price: 15_000.0,
          supplier: 'PT Steel',
          notes: 'Diameter 12mm'
        },
        s_002: {
          name: 'Beton Ready Mix',
          category: :structural,
          unit: 'm3',
          unit_price: 800_000.0,
          supplier: 'PT Beton',
          notes: 'K300'
        },
        # Finishing materials
        f_001: {
          name: 'Cat Tembok',
          category: :finishing,
          unit: 'liter',
          unit_price: 75_000.0,
          supplier: 'PT Cat',
          notes: 'Cat dinding interior'
        },
        f_002: {
          name: 'Keramik Lantai',
          category: :finishing,
          unit: 'm2',
          unit_price: 100_000.0,
          supplier: 'PT Keramik',
          notes: 'Ukuran 40x40'
        }
      }.freeze

      # Get a material
      # @param [Symbol] material_id
      # @return [Hash] material data
      def self.find(material_id)
        MATERIALS[material_id.to_sym]
      end

      # Get all materials
      # @return [Array<Hash>] all materials
      def self.all
        MATERIALS.values
      end

      # Get materials by category
      # @param [Symbol] category_id
      # @return [Array<Hash>] materials in category
      def self.by_category(category_id)
        MATERIALS.values.select { |m| m[:category] == category_id.to_sym }
      end

      # Get unit price of a material
      # @param [Symbol] material_id
      # @return [Float] unit price
      def self.unit_price(material_id)
        material = find(material_id)
        material ? material[:unit_price] : 0.0
      end

      # Search materials
      # @param [String] query
      # @return [Array<Hash>] matching materials
      def self.search(query)
        query_lower = query.to_s.downcase
        MATERIALS.values.select do |m|
          m[:name].downcase.include?(query_lower) ||
          m[:supplier].downcase.include?(query_lower)
        end
      end
    end
  end
end
