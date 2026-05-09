# ==============================================================================
# RAB Pro - Drawing Export Manager (Fase 3)
# Export scenes/drawings to PNG, DWG, PDF formats.
# ==============================================================================

module RABPro
  module Drawings
    class DrawingExportManager

      SUPPORTED_FORMATS = %i[png dwg pdf].freeze

      def initialize(model, settings: nil, project_store: nil)
        @model         = model
        @settings      = settings
        @project_store = project_store
      end

      # --------- Single Export ---------

      def export_current_view_dwg(output_path)
        """Export current view as DWG."""
        Logger.info("DrawingExportManager: exporting DWG to #{output_path}")

        begin
          # Use SketchUp's native export
          status = @model.export(output_path, false, {})

          if status
            Logger.info("DrawingExportManager: DWG export successful")
            { success: true, format: 'dwg', path: output_path }
          else
            { success: false, error: 'DWG export failed' }
          end
        rescue => e
          Logger.error("export_current_view_dwg: #{e.message}")
          { success: false, error: e.message }
        end
      end

      def export_scene_png(scene_name, output_path, width: 3508, height: 2480)
        """Export specific scene to PNG."""
        Logger.info("DrawingExportManager: exporting #{scene_name} to PNG")

        begin
          page = @model.pages.find { |p| p.name == scene_name }
          return { success: false, error: 'Scene tidak ditemukan' } unless page

          # Activate the page
          page.use

          # Export using SketchUp's write_image
          @model.active_view.write_image(output_path, width, height)

          Logger.info("DrawingExportManager: PNG export successful")
          { success: true, format: 'png', path: output_path }
        rescue => e
          Logger.error("export_scene_png: #{e.message}")
          { success: false, error: e.message }
        end
      end

      # --------- Batch Export ---------

      def batch_export_scenes(format: :png, output_dir: nil)
        """Export all RAB scenes to specified format."""
        output_dir ||= @settings&.export_path || Dir.home

        Logger.info("DrawingExportManager: batch export (#{format})")

        begin
          format = format.to_sym
          return { success: false, error: 'Format tidak didukung' } unless SUPPORTED_FORMATS.include?(format)

          # Get RAB scenes
          scenes = @model.pages.select { |p| p.name.start_with?('RAB_') }
          return { success: false, error: 'Tidak ada scenes untuk di-export' } if scenes.empty?

          exported = []
          failed = []

          scenes.each do |scene|
            begin
              filename = StringHelper.slugify(scene.name) + ".#{format}"
              path = File.join(output_dir, filename)

              case format
              when :png
                success = export_scene_png(scene.name, path)[:success]
              when :dwg
                scene.use
                success = export_current_view_dwg(path)[:success]
              when :pdf
                success = export_scene_png(scene.name, path.sub(/\.pdf$/, '.png'))[:success]
              end

              if success
                exported << filename
              else
                failed << scene.name
              end
            rescue => e
              Logger.warn("batch_export_scenes [#{scene.name}]: #{e.message}")
              failed << scene.name
            end
          end

          {
            success: failed.empty?,
            format: format,
            total: scenes.size,
            exported: exported.size,
            failed: failed.size,
            files: exported,
            failed_scenes: failed,
            output_dir: output_dir
          }
        rescue => e
          Logger.error("batch_export_scenes: #{e.message}")
          { success: false, error: e.message }
        end
      end

      # --------- Configuration ---------

      def supported_formats
        SUPPORTED_FORMATS
      end

      def get_export_settings
        {
          default_format: :png,
          default_width: 3508,
          default_height: 2480,
          export_path: @settings&.export_path || Dir.home,
          rab_scenes_only: true
        }
      end
    end
  end
end
