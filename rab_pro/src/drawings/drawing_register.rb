# ==============================================================================
# RAB Pro - Drawing Register (Fase 3)
# Track drawing numbers, revisions, and status.
# ==============================================================================

module RABPro
  module Drawings
    class DrawingRegister

      DISCIPLINES = %i[architecture structural mep landscape general].freeze
      STATUS_LABELS = {
        issued_for_review: 'Dikirim untuk Review',
        approved: 'Disetujui',
        issued_for_construction: 'Dikirim untuk Konstruksi',
        as_built: 'As-Built',
        superseded: 'Diganti',
        archived: 'Diarsipkan'
      }.freeze

      DrawingEntry = Struct.new(
        :drawing_no,
        :title,
        :discipline,
        :scale,
        :scene_name,
        :revision_history,   # Array of { revision, date, description, issued_by, status }
        :current_revision,
        :current_status,
        :created_at,
        keyword_init: true
      ) do
        def to_h
          {
            drawing_no: drawing_no,
            title: title,
            discipline: discipline,
            scale: scale,
            scene_name: scene_name,
            current_revision: current_revision,
            current_status: current_status,
            revision_count: revision_history.size,
            created_at: created_at
          }
        end
      end

      DRAWING_CODE_PREFIX = %i[A B C D E F G H I J].freeze  # Per discipline

      def initialize(model)
        @model = model
        @register = _load_register
      end

      # --------- CRUD Operations ---------

      def add(title:, discipline: :general, scale: '1:100', scene_name: nil)
        """Add new drawing to register."""
        discipline = discipline.to_sym unless discipline.is_a?(Symbol)
        discipline = :general unless DISCIPLINES.include?(discipline)

        # Generate drawing number
        count_in_discipline = @register.count { |e| e.discipline == discipline }
        prefix = DRAWING_CODE_PREFIX[DISCIPLINES.index(discipline)] || 'X'
        drawing_no = "#{prefix}-#{(count_in_discipline + 1).to_s.rjust(3, '0')}"

        entry = DrawingEntry.new(
          drawing_no: drawing_no,
          title: title,
          discipline: discipline,
          scale: scale,
          scene_name: scene_name,
          revision_history: [],
          current_revision: '0',
          current_status: :issued_for_review,
          created_at: Time.now.iso8601
        )

        @register << entry
        _save_register

        Logger.info("DrawingRegister: added #{drawing_no} - #{title}")
        entry
      end

      def issue_revision(drawing_no, description: 'Revisi', issued_by: 'RAB Pro', status: :issued_for_review)
        """Issue new revision for drawing."""
        entry = find(drawing_no)
        return nil unless entry

        rev_num = (entry.current_revision.to_i + 1).to_s
        entry.revision_history << {
          revision: rev_num,
          date: Time.now.iso8601,
          description: description,
          issued_by: issued_by,
          status: status
        }

        entry.current_revision = rev_num
        entry.current_status = status

        _save_register
        Logger.info("DrawingRegister: issued revision #{rev_num} for #{drawing_no}")
        entry
      end

      def update_status(drawing_no, status)
        """Update drawing status."""
        entry = find(drawing_no)
        return nil unless entry

        status = status.to_sym
        return entry unless STATUS_LABELS.key?(status)

        entry.current_status = status
        _save_register

        Logger.info("DrawingRegister: updated #{drawing_no} status to #{status}")
        entry
      end

      # --------- Queries ---------

      def find(drawing_no)
        @register.find { |e| e.drawing_no == drawing_no.to_s }
      end

      def all
        @register
      end

      def by_discipline(discipline)
        @register.select { |e| e.discipline == discipline.to_sym }
      end

      def by_status(status)
        @register.select { |e| e.current_status == status.to_sym }
      end

      def to_table
        """Generate table view for UI."""
        @register.map.with_index(1) do |entry, idx|
          {
            no: idx,
            drawing_no: entry.drawing_no,
            title: entry.title,
            discipline: entry.discipline,
            scale: entry.scale,
            revision: entry.current_revision,
            status: entry.current_status,
            status_label: STATUS_LABELS[entry.current_status] || entry.current_status.to_s,
            created_at: entry.created_at
          }
        end
      end

      private

      def _load_register
        data = @model.get_attribute('RABPro_Register', 'entries', nil)
        return [] unless data

        begin
          register_data = JSON.parse(data)
          register_data.map do |entry_hash|
            DrawingEntry.new(
              drawing_no: entry_hash['drawing_no'],
              title: entry_hash['title'],
              discipline: entry_hash['discipline']&.to_sym || :general,
              scale: entry_hash['scale'],
              scene_name: entry_hash['scene_name'],
              revision_history: entry_hash['revision_history'] || [],
              current_revision: entry_hash['current_revision'],
              current_status: entry_hash['current_status']&.to_sym || :issued_for_review,
              created_at: entry_hash['created_at']
            )
          end
        rescue => e
          Logger.warn("_load_register: #{e.message}")
          []
        end
      end

      def _save_register
        data = @register.map do |entry|
          {
            drawing_no: entry.drawing_no,
            title: entry.title,
            discipline: entry.discipline.to_s,
            scale: entry.scale,
            scene_name: entry.scene_name,
            revision_history: entry.revision_history,
            current_revision: entry.current_revision,
            current_status: entry.current_status.to_s,
            created_at: entry.created_at
          }
        end

        @model.set_attribute('RABPro_Register', 'entries', JSON.generate(data))
      rescue => e
        Logger.error("_save_register: #{e.message}")
      end
    end
  end
end
