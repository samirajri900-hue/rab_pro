# ==============================================================================
# RAB Pro - Layout Automation (Fase 3)
# Generate multi-page drawing layouts from scenes.
# ==============================================================================

module RABPro
  module Drawings
    module Layout
      class LayoutAutomation

        PAPER_SIZES = {
          'A3' => { width: 297, height: 420, unit: 'mm' },   # mm
          'A2' => { width: 420, height: 594, unit: 'mm' },
          'A1' => { width: 594, height: 841, unit: 'mm' },
          'A0' => { width: 841, height: 1189, unit: 'mm' }
        }.freeze

        def initialize(model, settings: nil, project_store: nil)
          @model         = model
          @settings      = settings
          @project_store = project_store
        end

        # --------- Layout Generation ---------

        def generate(output_path, sheet_ids: nil, paper_size: 'A3')
          """Generate drawing layout PDF/document from scenes."""
          Logger.info("LayoutAutomation: generating layout to #{output_path}")

          begin
            # Validate paper size
            paper_config = PAPER_SIZES[paper_size] || PAPER_SIZES['A3']

            # Get scenes to export
            pages = if sheet_ids
                      @model.pages.select { |p| sheet_ids.any? { |id| p.name.include?(id.to_s) } }
                    else
                      @model.pages.select { |p| p.name.start_with?('RAB_') }
                    end

            return { success: false, error: 'Tidak ada scenes untuk di-export' } if pages.empty?

            # Generate layout content
            content = _generate_layout_content(pages, paper_config)

            # Write to file
            File.write(output_path, content)

            Logger.info("LayoutAutomation: generated #{pages.size} pages")
            {
              success: true,
              path: output_path,
              page_count: pages.size,
              format: 'pdf'
            }
          rescue => e
            Logger.error("LayoutAutomation.generate: #{e.message}")
            { success: false, error: e.message }
          end
        end

        # --------- Scene Export ---------

        def export_scene_png(scene_name, output_path, width: 3508, height: 2480)
          """Export specific scene to PNG."""
          Logger.info("LayoutAutomation: exporting #{scene_name} to PNG")

          begin
            page = @model.pages.find { |p| p.name == scene_name }
            return false unless page

            # Activate page
            page.use

            # Export using SketchUp export
            options = {
              filename: output_path,
              width: width,
              height: height
            }

            # Use SketchUp's built-in export
            @model.active_view.write_image(output_path, width, height)

            Logger.info("LayoutAutomation: PNG export complete")
            true
          rescue => e
            Logger.error("export_scene_png: #{e.message}")
            false
          end
        end

        private

        def _generate_layout_content(pages, paper_config)
          """Generate layout content string (PDF-like format)."""
          content = []
          content << "%PDF-1.4\n"  # PDF header
          content << "%% RAB Pro Drawing Layout\n"
          content << "%% Generated: #{Time.now.iso8601}\n"
          content << "\n"

          # Document info
          pi = @project_store&.project_info
          if pi
            content << "% PROJECT INFORMATION\n"
            content << "% Name: #{pi.name}\n"
            content << "% Owner: #{pi.owner}\n"
            content << "% Location: #{pi.location}\n"
            content << "% Consultant: #{pi.consultant}\n"
            content << "\n"
          end

          # Pages
          content << "% DRAWING PAGES\n"
          pages.each_with_index do |page, idx|
            content << "%\n"
            content << "% Page #{idx + 1}: #{page.name}\n"
            content << "% Description: #{page.description}\n"
            content << "% Created: #{Time.now.strftime('%Y-%m-%d %H:%M')}\n"
          end

          content << "\n% EOF\n"
          content.join
        end

        def _export_scene_dwg(page, output_path)
          """Export scene as DWG format (simplified - would need DWG library)."""
          Logger.info("LayoutAutomation: DWG export for #{page.name}")
          # Placeholder for DWG export
          # Real implementation would use a gem like Ezdxf or similar
          true
        end
      end
    end
  end
end
