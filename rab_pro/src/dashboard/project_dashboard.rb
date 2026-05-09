# ==============================================================================
# RAB Pro - Project Dashboard
# Tracks project progress, milestones, S-curve, and financial metrics
# ==============================================================================

module RABPro
  module Dashboard
    class ProjectDashboard

      ProgressEntry = Struct.new(
        :category_id, :category_name, :planned_qty, :actual_qty,
        :planned_cost, :actual_cost, :pct_complete, :status,
        keyword_init: true
      ) do
        def to_h
          super
        end
      end

      Milestone = Struct.new(
        :id, :name, :planned_date, :actual_date, :status,
        keyword_init: true
      ) do
        def to_h
          super
        end
      end

      def initialize(model, project_store: nil)
        @model         = model
        @project_store = project_store
        @progress      = {}
        @milestones    = []
        @created_at    = Time.now
      end

      # -----------------------------------------------------------------------
      # Get full dashboard snapshot
      # -----------------------------------------------------------------------
      def snapshot
        {
          project_info: @project_store&.project_info&.to_h,
          progress: @progress.transform_values(&:to_h),
          milestones: @milestones.map(&:to_h),
          financial: _financial_summary,
          scurve: _calculate_scurve,
          overall_pct: _calculate_overall_progress
        }
      end

      # -----------------------------------------------------------------------
      # Initialize progress from RAB
      # -----------------------------------------------------------------------
      def initialize_progress_from_rab
        qto = RAB::QuantityTakeoffEngine.new(@model)
        result = qto.run

        result[:summary].each do |cat_id, summary|
          cat = Data::CategoryLibrary.find(cat_id)
          next unless cat

          @progress[cat_id] = ProgressEntry.new(
            category_id: cat_id,
            category_name: cat.name,
            planned_qty: summary.total_quantity,
            actual_qty: 0.0,
            planned_cost: 0.0,
            actual_cost: 0.0,
            pct_complete: 0.0,
            status: 'not_started'
          )
        end

        Logger.info("Dashboard: initialized progress for #{@progress.size} categories")
        { ok: true, count: @progress.size }
      end

      # -----------------------------------------------------------------------
      # Update single category progress
      # -----------------------------------------------------------------------
      def update_progress(category_id, actual_qty: nil, actual_cost: nil, pct_complete: nil)
        cat_id = category_id.to_sym
        entry  = @progress[cat_id]
        return nil unless entry

        entry.actual_qty   = actual_qty if actual_qty
        entry.actual_cost  = actual_cost if actual_cost
        entry.pct_complete = pct_complete if pct_complete

        if pct_complete
          entry.status = if pct_complete >= 100
                          'completed'
                        elsif pct_complete > 0
                          'in_progress'
                        else
                          'not_started'
                        end
        end

        entry
      end

      # -----------------------------------------------------------------------
      # Update milestone
      # -----------------------------------------------------------------------
      def update_milestone(milestone_id, actual_date: nil, status: nil)
        ms = @milestones.find { |m| m.id == milestone_id }
        return nil unless ms

        ms.actual_date = actual_date if actual_date
        ms.status      = status if status
        ms
      end

      # -----------------------------------------------------------------------
      # Save milestones batch
      # -----------------------------------------------------------------------
      def save_milestones(milestones_array)
        @milestones = milestones_array.map do |m|
          Milestone.new(
            id: m['id'] || SecureRandom.uuid,
            name: m['name'],
            planned_date: m['planned_date'],
            actual_date: m['actual_date'],
            status: m['status'] || 'pending'
          )
        end

        { ok: true, count: @milestones.size }
      end

      private

      def _financial_summary
        total_planned = @progress.values.sum(&:planned_cost)
        total_actual  = @progress.values.sum(&:actual_cost)
        variance      = total_actual - total_planned
        variance_pct  = total_planned > 0 ? (variance / total_planned * 100) : 0

        {
          planned_total: total_planned.round(2),
          actual_total: total_actual.round(2),
          variance: variance.round(2),
          variance_pct: variance_pct.round(1),
          budget_status: variance_pct < 0 ? 'under' : variance_pct > 10 ? 'over' : 'on_track'
        }
      end

      def _calculate_overall_progress
        return 0 if @progress.empty?

        total_pct = @progress.values.sum(&:pct_complete)
        (total_pct / @progress.size).round(1)
      end

      def _calculate_scurve
        points = []
        @progress.values.each_with_index do |entry, i|
          points << {
            index: i,
            category: entry.category_name,
            progress_pct: entry.pct_complete,
            cumulative_pct: (points.map { |p| p[:progress_pct] }.sum / (i + 1)).round(1)
          }
        end
        points
      end

    end
  end
end
