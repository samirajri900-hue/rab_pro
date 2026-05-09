# ==============================================================================
# RAB Pro - Cloud Sync
# Project snapshots, JSON export/import, sharing, and comments management
# ==============================================================================

module RABPro
  module Collaboration
    class CloudSync

      Snapshot = Struct.new(
        :id, :label, :created_at, :created_by,
        :rab_total, :progress_pct, :item_count,
        keyword_init: true
      )

      Comment = Struct.new(
        :id, :author, :text, :created_at, :category, :entity_id, :resolved,
        keyword_init: true
      ) do
        def to_h
          super
        end
      end

      def initialize(model, project_store: nil, settings: nil)
        @model         = model
        @project_store = project_store
        @settings      = settings
        @snapshots     = []
        @comments      = []
      end

      # -----------------------------------------------------------------------
      # Create project snapshot
      # -----------------------------------------------------------------------
      def create_snapshot(label: nil, created_by: 'RAB Pro')
        snap = Snapshot.new(
          id: SecureRandom.uuid,
          label: label || "Snapshot #{Time.now.strftime('%Y-%m-%d %H:%M')}",
          created_at: Time.now.iso8601,
          created_by: created_by,
          rab_total: 0.0,
          progress_pct: 0.0,
          item_count: 0
        )

        @snapshots << snap
        Logger.info("Snapshot created: #{snap.label}")
        snap
      end

      # -----------------------------------------------------------------------
      # Load snapshots
      # -----------------------------------------------------------------------
      def load_snapshots
        @snapshots
      end

      # -----------------------------------------------------------------------
      # Export project as JSON
      # -----------------------------------------------------------------------
      def export_json(path)
        begin
          qto = RAB::QuantityTakeoffEngine.new(@model)
          rab_lines = qto.build_rab_lines

          export_data = {
            project_info: @project_store&.project_info&.to_h,
            rab_document: rab_lines,
            snapshots: @snapshots.map(&:to_h),
            comments: @comments.map(&:to_h),
            exported_at: Time.now.iso8601,
            version: '1.0'
          }

          require 'json'
          File.write(path, JSON.pretty_generate(export_data))

          Logger.info("Project exported to #{path}")
          { success: true, path: path, size: File.size(path) }
        rescue => e
          Logger.error("Export JSON error: #{e.message}")
          { success: false, error: e.message }
        end
      end

      # -----------------------------------------------------------------------
      # Import project from JSON
      # -----------------------------------------------------------------------
      def import_json(path)
        begin
          require 'json'
          data = JSON.parse(File.read(path))

          # Restore project info if available
          if data['project_info'] && @project_store
            @project_store.from_hash(data['project_info'])
          end

          # Restore snapshots
          @snapshots = data['snapshots']&.map do |s|
            Snapshot.new(
              id: s['id'],
              label: s['label'],
              created_at: s['created_at'],
              created_by: s['created_by'],
              rab_total: s['rab_total'],
              progress_pct: s['progress_pct'],
              item_count: s['item_count']
            )
          end || []

          # Restore comments
          @comments = data['comments']&.map do |c|
            Comment.new(
              id: c['id'],
              author: c['author'],
              text: c['text'],
              created_at: c['created_at'],
              category: c['category'],
              entity_id: c['entity_id'],
              resolved: c['resolved']
            )
          end || []

          Logger.info("Project imported from #{path}")
          { success: true, snapshots: @snapshots.size, comments: @comments.size }
        rescue => e
          Logger.error("Import JSON error: #{e.message}")
          { success: false, error: e.message }
        end
      end

      # -----------------------------------------------------------------------
      # Generate shareable HTML report
      # -----------------------------------------------------------------------
      def generate_share_report(path)
        begin
          qto = RAB::QuantityTakeoffEngine.new(@model)
          rab_lines = qto.build_rab_lines

          pi = @project_store&.project_info&.to_h || {}

          html = <<~HTML
            <!DOCTYPE html>
            <html lang="id">
            <head>
              <meta charset="UTF-8">
              <title>RAB Report - #{pi[:name]}</title>
              <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                h1 { color: #0071e3; border-bottom: 2px solid #0071e3; padding-bottom: 10px; }
                h2 { color: #333; margin-top: 30px; }
                table { width: 100%; border-collapse: collapse; margin: 20px 0; }
                th, td { padding: 10px; text-align: left; border: 1px solid #ddd; }
                th { background-color: #f5f5f5; font-weight: bold; }
                .summary { background-color: #f9f9f9; padding: 15px; border-radius: 5px; }
                .total { font-weight: bold; background-color: #e8f4f8; }
              </style>
            </head>
            <body>
              <h1>RAB Report</h1>
              <div class="summary">
                <p><strong>Proyek:</strong> #{pi[:name]}</p>
                <p><strong>Pemilik:</strong> #{pi[:owner]}</p>
                <p><strong>Lokasi:</strong> #{pi[:location]}</p>
                <p><strong>Tanggal:</strong> #{Time.now.strftime('%d-%m-%Y')}</p>
              </div>
              <h2>RAB Breakdown</h2>
              <table>
                <tr>
                  <th>No</th>
                  <th>Kategori</th>
                  <th>Satuan</th>
                  <th>Kuantitas</th>
                  <th>Harga Satuan</th>
                  <th>Jumlah</th>
                </tr>
          HTML

          rab_lines.each_with_index do |line, i|
            html += "<tr>"
            html += "<td>#{i + 1}</td>"
            html += "<td>#{line[:category_name]}</td>"
            html += "<td>#{line[:unit]}</td>"
            html += "<td>#{line[:quantity]}</td>"
            html += "<td>BND$ #{line[:unit_price]}</td>"
            html += "<td>BND$ #{line[:total_price]}</td>"
            html += "</tr>"
          end

          total = rab_lines.sum { |l| l[:total_price] }
          html += "<tr class='total'><td colspan='5'>TOTAL</td><td>BND$ #{total}</td></tr>"
          html += "</table></body></html>"

          File.write(path, html)
          Logger.info("Share report generated: #{path}")
          { success: true, path: path }
        rescue => e
          Logger.error("Generate report error: #{e.message}")
          { success: false, error: e.message }
        end
      end

      # -----------------------------------------------------------------------
      # Comments management
      # -----------------------------------------------------------------------
      def add_comment(author: 'User', text: '', category: nil, entity_id: nil)
        comment = Comment.new(
          id: SecureRandom.uuid,
          author: author,
          text: text,
          created_at: Time.now.iso8601,
          category: category,
          entity_id: entity_id,
          resolved: false
        )
        @comments << comment
        comment
      end

      def load_comments
        @comments
      end

      def resolve_comment(comment_id)
        comment = @comments.find { |c| c.id == comment_id.to_s }
        comment.resolved = true if comment
      end

    end
  end
end
