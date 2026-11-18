# frozen_string_literal: true

module RecruitingGoals
  # 25 weeks. Week 1 is the last week of October 2026. Week 25 runs through
  # April 24, 2027, so two weeks in is 8% of the season.
  class Calendar
    START = Date.new(2026, 10, 26)
    END_ON = Date.new(2027, 4, 24)
    WEEKS = 25

    def self.weeks
      (1..WEEKS).map do |number|
        starts_on = START + ((number - 1) * 7)
        ends_on = number == WEEKS ? END_ON : starts_on + 6
        { week_number: number, starts_on: starts_on, ends_on: ends_on }
      end
    end
  end
end
