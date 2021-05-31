module StaticSite
  class CalendarController < ApplicationController
    def monthly
      query_date = params[:start_date]&.to_datetime || Time.current

      @start_date = query_date.beginning_of_month.beginning_of_day
      @end_date = query_date.end_of_month.end_of_day

      @entries = Entry.where(notebook: @current_notebook.name).order(occurred_at: :asc).where("occurred_at >= ? and occurred_at <= ?", @start_date, @end_date)

      @tags = current_notebook.entries.notes.after(@start_date).before(@end_date).joins(:tags).group("tags.name").count.sort_by { |k,v| -v }
      @contacts = current_notebook.entries.notes.after(@start_date).before(@end_date).joins(:contacts).group("contacts.name").count.sort_by { |k,v| -v }

    end

    def daily
      if params[:date]
        @date = params[:date].to_date
      else
        @date = Date.today
      end

      @start_date = @date.beginning_of_day
      @end_date = @date.end_of_day

      @entries = Entry.where(notebook: @current_notebook.name).order(occurred_at: :asc).where("occurred_at >= ? and occurred_at <= ?", @start_date, @end_date)
    end

    def weekly
      query_date = params[:start_date]&.to_date || Time.current

      @start_date = query_date.beginning_of_week.beginning_of_day
      @end_date = query_date.end_of_week.end_of_day

      @entries = Entry.where(notebook: @current_notebook.name).visible.order(occurred_at: :asc).where("occurred_at >= ? and occurred_at <= ?", @start_date, @end_date)

      @tags = current_notebook.entries.notes.after(@start_date).before(@end_date).joins(:tags).group("tags.name").count.sort_by { |k,v| -v }
      @contacts = current_notebook.entries.notes.after(@start_date).before(@end_date).joins(:contacts).group("contacts.name").count.sort_by { |k,v| -v }

    end
  end
end