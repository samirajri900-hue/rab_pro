# ==============================================================================
# RAB Pro - Template Engine
# Pre-built project templates untuk berbagai tipe konstruksi
# ==============================================================================

module RABPro
  module Templates
    class TemplateEngine

      ProjectTemplate = Struct.new(
        :id, :name, :description, :icon, :typical_area_m2, :notes,
        :layers, :rab_categories, :default_scenes,
        keyword_init: true
      )

      # Predefined templates
      TEMPLATES = [
        ProjectTemplate.new(
          id: :rumah_tinggal,
          name: 'Rumah Tinggal',
          description: 'Template untuk rumah tinggal / residential house',
          icon: '🏠',
          typical_area_m2: 150,
          notes: 'Cocok untuk rumah single/double storey',
          layers: ['Pondasi', 'Struktur', 'Dinding', 'Lantai', 'Atap', 'Finishing'],
          rab_categories: {
            pondasi_batu: 'm³',
            kolom: 'm³',
            balok: 'm³',
            plat_lantai: 'm²',
            dinding_bata: 'm²',
            lantai_keramik: 'm²',
            rangka_atap_baja: 'm²',
            plafon_gypsum: 'm²'
          },
          default_scenes: ['Denah Lt.1', 'Denah Lt.2', 'Elevasi Depan', 'Elevasi Samping']
        ),

        ProjectTemplate.new(
          id: :ruko_toko,
          name: 'Ruko / Toko',
          description: 'Template untuk ruko dan toko / commercial building',
          icon: '🏢',
          typical_area_m2: 100,
          notes: 'Cocok untuk bangunan komersial',
          layers: ['Pondasi', 'Struktur', 'Dinding', 'Lantai', 'Atap', 'Interior', 'Finishing'],
          rab_categories: {
            pondasi_tapak: 'm³',
            kolom: 'm³',
            balok: 'm³',
            plat_lantai: 'm²',
            dinding_bata: 'm²',
            lantai_granit: 'm²',
            cat_dinding: 'm²',
            pintu: 'unit',
            jendela: 'unit'
          },
          default_scenes: ['Denah', 'Tampak Depan', 'Potongan A-A', '3D Perspektif']
        ),

        ProjectTemplate.new(
          id: :apartemen,
          name: 'Apartemen',
          description: 'Template untuk apartemen / multi-story residential',
          icon: '🏗️',
          typical_area_m2: 250,
          notes: 'Cocok untuk bangunan bertingkat',
          layers: ['Pondasi', 'Struktur', 'Dinding', 'MEP', 'Lantai', 'Atap', 'Finishing'],
          rab_categories: {
            pondasi_tapak: 'm³',
            kolom: 'm³',
            balok: 'm³',
            plat_lantai: 'm²',
            dinding_bata: 'm²',
            lantai_keramik: 'm²',
            rangka_atap_baja: 'm²'
          },
          default_scenes: ['Denah Lt.Dasar', 'Denah Tipikal', 'Elevasi', 'Potongan']
        ),

        ProjectTemplate.new(
          id: :kantor,
          name: 'Kantor',
          description: 'Template untuk kantor / office building',
          icon: '🏛️',
          typical_area_m2: 500,
          notes: 'Cocok untuk gedung perkantoran',
          layers: ['Pondasi', 'Struktur', 'Exterior', 'MEP', 'Interior', 'Finishing'],
          rab_categories: {
            pondasi_tapak: 'm³',
            kolom: 'm³',
            balok: 'm³',
            plat_lantai: 'm²'
          },
          default_scenes: ['Denah Lobby', 'Denah Tipikal', 'Elevasi Utama', '3D Exterior']
        ),

        ProjectTemplate.new(
          id: :gudang,
          name: 'Gudang',
          description: 'Template untuk gudang / warehouse',
          icon: '📦',
          typical_area_m2: 1000,
          notes: 'Cocok untuk bangunan gudang/pabrik',
          layers: ['Pondasi', 'Struktur Baja', 'Dinding', 'Atap', 'Lantai'],
          rab_categories: {
            pondasi_batu: 'm³',
            kolom: 'm³',
            balok: 'm³',
            rabat_beton: 'm²',
            penutup_atap: 'm²'
          },
          default_scenes: ['Denah', 'Elevasi', 'Potongan Melintang']
        )
      ].freeze

      # -----------------------------------------------------------------------
      # Get all templates
      # -----------------------------------------------------------------------
      def self.all
        TEMPLATES
      end

      # -----------------------------------------------------------------------
      # Find template by ID
      # -----------------------------------------------------------------------
      def self.find(template_id)
        TEMPLATES.find { |t| t.id == template_id.to_sym }
      end

      # -----------------------------------------------------------------------
      # Apply template to model
      # -----------------------------------------------------------------------
      def self.apply(model, template_id, project_store: nil, settings: nil)
        template = find(template_id)
        return { success: false, error: 'Template tidak ditemukan' } unless template

        begin
          # Create layers
          template.layers.each do |layer_name|
            model.layers.add(layer_name) unless model.layers[layer_name]
          end

          # Set project info if available
          if project_store
            project_store.set_template_id(template_id)
          end

          # Create default scenes
          if defined?(Drawings) && defined?(Drawings::Scenes)
            scene_mgr = Drawings::Scenes::SceneManager.new(model)
            template.default_scenes.each do |scene_name|
              scene = model.pages.add(scene_name)
              Logger.info("Created scene: #{scene_name}")
            end
          end

          Logger.info("Template #{template_id} applied successfully")
          { success: true, template_id: template_id, layers_created: template.layers.size }
        rescue => e
          Logger.error("Template apply error: #{e.message}")
          { success: false, error: e.message }
        end
      end

      # -----------------------------------------------------------------------
      # Export templates as JSON array
      # -----------------------------------------------------------------------
      def self.to_json_array
        TEMPLATES.map do |t|
          {
            id: t.id,
            name: t.name,
            description: t.description,
            icon: t.icon,
            typical_area_m2: t.typical_area_m2,
            layers: t.layers,
            categories: t.rab_categories.keys.map(&:to_s),
            scene_count: t.default_scenes.size
          }
        end
      end

    end
  end
end
