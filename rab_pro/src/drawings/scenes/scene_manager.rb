# ==============================================================================
# RAB Pro - Scene Manager (Fase 3)
# Manage SketchUp scenes/pages for different technical drawing views.
# ==============================================================================

module RABPro
  module Drawings
    module Scenes
      class SceneManager

        # Standard scene definitions with configurations
        STANDARD_SCENES = {
          denah: {
            id: :denah,
            name: 'RAB_Denah (Floor Plan)',
            camera_mode: :top,
            layer_visibility: { all: true, hide: ['RAB_3D_Details'] },
            description: 'Tampilan denah/floor plan dari atas'
          },
          elevasi_depan: {
            id: :elevasi_depan,
            name: 'RAB_Elevasi Depan (Front)',
            camera_mode: :front,
            layer_visibility: { all: true },
            description: 'Tampilan elevasi depan'
          },
          elevasi_samping: {
            id: :elevasi_samping,
            name: 'RAB_Elevasi Samping (Side)',
            camera_mode: :right,
            layer_visibility: { all: true },
            description: 'Tampilan elevasi samping'
          },
          potongan_melintang: {
            id: :potongan_melintang,
            name: 'RAB_Potongan Melintang (Cross Section)',
            camera_mode: :front,
            layer_visibility: { all: true, hide: ['Facade'] },
            description: 'Potongan melintang bangunan'
          },
          potongan_memanjang: {
            id: :potongan_memanjang,
            name: 'RAB_Potongan Memanjang (Long Section)',
            camera_mode: :right,
            layer_visibility: { all: true, hide: ['Facade'] },
            description: 'Potongan memanjang bangunan'
          },
          detail_pondasi: {
            id: :detail_pondasi,
            name: 'RAB_Detail Pondasi (Foundation)',
            camera_mode: :bottom,
            layer_visibility: { show: ['Foundation', 'RAB_Details'] },
            description: 'Detail pondasi dengan scale besar'
          },
          detail_sambungan: {
            id: :detail_sambungan,
            name: 'RAB_Detail Sambungan (Connection)',
            camera_mode: :front,
            layer_visibility: { show: ['Details', 'RAB_Details'] },
            description: 'Detail sambungan struktur'
          },
          perspektif_3d: {
            id: :perspektif_3d,
            name: 'RAB_3D Perspektif (3D View)',
            camera_mode: :iso,
            layer_visibility: { all: true },
            description: 'Tampilan 3D isometric'
          }
        }.freeze

        def initialize(model)
          @model = model
        end

        # --------- Scene Creation & Management ---------

        def create_standard_scenes(scene_ids: nil)
          """Create standard scene set. If scene_ids specified, create only those."""
          scenes_to_create = scene_ids ? STANDARD_SCENES.slice(*scene_ids) : STANDARD_SCENES
          created = []

          scenes_to_create.each do |id, config|
            begin
              page = create_scene(id, config)
              created << config[:name] if page
            rescue => e
              Logger.warn("SceneManager: error creating #{id}: #{e.message}")
            end
          end

          Logger.info("SceneManager: created #{created.size} scenes")
          created
        end

        def create_scene(scene_id, config = nil)
          """Create or get single scene by ID."""
          config ||= STANDARD_SCENES[scene_id.to_sym]
          return nil unless config

          name = config[:name]
          existing = @model.pages.find { |p| p.name == name }
          return existing if existing

          page = @model.pages.add(name)
          page.description = config[:description]

          # Set layer visibility
          _apply_layer_visibility(page, config[:layer_visibility])

          # Set camera angle (simplified — SketchUp doesn't expose camera directly)
          Logger.info("SceneManager: created scene '#{name}'")
          page
        end

        def delete_rab_scenes
          """Delete all RAB-prefixed scenes."""
          rab_pages = @model.pages.select { |p| p.name.start_with?('RAB_') }
          rab_pages.each(&:delete)
          Logger.info("SceneManager: deleted #{rab_pages.size} RAB scenes")
        end

        def existing_rab_scenes
          """Get all existing RAB-prefixed scenes."""
          @model.pages.select { |p| p.name.start_with?('RAB_') }
        end

        # --------- Scene Listing & Metadata ---------

        def self.scene_list
          STANDARD_SCENES.map do |id, config|
            {
              id: id,
              name: config[:name],
              description: config[:description]
            }
          end
        end

        private

        def _apply_layer_visibility(page, config)
          """Apply layer visibility configuration to scene."""
          return unless config

          if config[:all]
            # Show all layers
            @model.layers.each { |l| page.layers.remove(l) } rescue nil
          end

          if config[:show]
            # Show only specific layers
            @model.layers.each do |layer|
              if config[:show].include?(layer.name)
                page.layers.remove(layer) rescue nil
              else
                page.layers.add(layer) rescue nil
              end
            end
          end

          if config[:hide]
            # Hide specific layers
            config[:hide].each do |layer_name|
              layer = @model.layers[layer_name]
              page.layers.add(layer) if layer
            end
          end
        rescue => e
          Logger.warn("_apply_layer_visibility: #{e.message}")
        end
      end
    end
  end
end
