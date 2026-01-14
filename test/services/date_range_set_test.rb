require "test_helper"

class DateRangeSetTest < ActiveSupport::TestCase
  test "from_pairs merges overlapping and adjacent ranges" do
    set = DateRangeSet.from_pairs([
      [Date.new(2026, 1, 1), Date.new(2026, 1, 3)],
      [Date.new(2026, 1, 4), Date.new(2026, 1, 5)],
      [Date.new(2026, 1, 10), Date.new(2026, 1, 10)]
    ])

    assert_equal [[Date.new(2026, 1, 1), Date.new(2026, 1, 5)], [Date.new(2026, 1, 10), Date.new(2026, 1, 10)]], set.to_a
  end

  test "intersect returns overlaps" do
    a = DateRangeSet.from_pairs([[Date.new(2026, 1, 1), Date.new(2026, 1, 10)]])
    b = DateRangeSet.from_pairs([[Date.new(2026, 1, 5), Date.new(2026, 1, 6)]])

    assert_equal [[Date.new(2026, 1, 5), Date.new(2026, 1, 6)]], a.intersect(b).to_a
  end

  test "subtract removes overlaps" do
    a = DateRangeSet.from_pairs([[Date.new(2026, 1, 1), Date.new(2026, 1, 10)]])
    b = DateRangeSet.from_pairs([[Date.new(2026, 1, 3), Date.new(2026, 1, 4)], [Date.new(2026, 1, 8), Date.new(2026, 1, 12)]])

    assert_equal [
      [Date.new(2026, 1, 1), Date.new(2026, 1, 2)],
      [Date.new(2026, 1, 5), Date.new(2026, 1, 7)]
    ], a.subtract(b).to_a
  end
end
