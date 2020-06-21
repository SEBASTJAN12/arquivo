require 'test_helper'

class ScheduleTest < ActiveSupport::TestCase
  setup do
    @cal_url = File.join(Rails.root, "test", "fixtures", "cal-t1.ics")
    @ci = CalendarImport.create(notebook: "test", title: "example cal", url: @cal_url )
    importer = CalendarImporter.new(@ci)
    importer.process!

    @cal_url2 = File.join(Rails.root, "test", "fixtures", "cal-t2.ics")
  end

  # this test exercises a single work-week, during which we examine
  # - recurring events
  # - individual events
  # - recurring events with exceptions
  test "smoke test" do
    sched = Schedule.new(@ci)

    events = sched.events_for("2020-06-15", "2020-06-19 23:59:59")

    # having manually examined the test fixture,
    # i know that 20 is the right number of events
    assert_equal 20, events.size

    # On Tuesday, there is an all day event
    no_meeting_tuesday = events.select { |e| e[:occurred_at] == Date.parse("2020-06-16") }.first

    assert no_meeting_tuesday
    assert_equal "No Meeting Tuesday", no_meeting_tuesday[:subject]
    assert no_meeting_tuesday[:occurred_at].is_a?(Date)

    # should the schedule tell us if an event is recurring?
    # we've discussed how we need to serialize the uid somewhere into the Entry itself.

    # on the Wednesday, there are two non-recurring Ask Me Anythings
    wednesday_events = events.select { |e| e[:occurred_at] > Date.parse("2020-06-17") && e[:occurred_at] < Date.parse("2020-06-18") }

    assert_equal 2, wednesday_events.count { |e| e[:subject] == "Ask Me Anything" }

    # finally, every day of the week we end with a wind-down event,
    wind_downs = events.select { |e| e[:subject] == "🌇 wind-down 🌆"}
    assert_equal 5, wind_downs.size

    # which on MTWF happens at 16:30 but on Thursdays happens at 16:00
    wind_downs_by_date = wind_downs.group_by { |e| e[:occurred_at].to_date }

    # Monday,      Tuesday,      Wednesday,    Friday
    ["2020-06-15", "2020-06-16", "2020-06-17", "2020-06-19"].each do |s|
      d = Date.parse(s)
      event = wind_downs_by_date[d].first
      # fuck timezones: EDT??? ugh, will this test
      # break in the future?
      end_time  = DateTime.parse("#{s} 16:30 Eastern Daylight Time")
      assert_equal end_time, event[:occurred_at]
    end

    thursday = "2020-06-18"
    thurs_wind_down = wind_downs_by_date[Date.parse(thursday)].first

    assert_equal DateTime.parse("#{thursday} 16:00 Eastern Daylight Time"), thurs_wind_down[:occurred_at]
  end
end
