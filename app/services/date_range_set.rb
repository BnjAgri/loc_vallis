# frozen_string_literal: true

# DateRangeSet
# Représente un ensemble normalisé de plages de dates inclusives (Date..Date).
# Permet de faire des opérations d'intersection et de soustraction sans itérer jour par jour.
class DateRangeSet
  def self.from_pairs(pairs)
    normalized = pairs
      .compact
      .filter { |(from, to)| from.present? && to.present? }
      .map { |(from, to)| [from.to_date, to.to_date] }
      .filter { |(from, to)| to >= from }
      .sort_by(&:first)

    merged = []
    normalized.each do |from, to|
      if merged.empty? || (merged.last[1] + 1.day) < from
        merged << [from, to]
      else
        merged.last[1] = [merged.last[1], to].max
      end
    end

    new(merged)
  end

  def self.from_records(records, start_attr:, end_attr:, end_exclusive: false)
    pairs = Array(records).map do |record|
      from = record.public_send(start_attr)
      to = record.public_send(end_attr)
      to = to - 1.day if end_exclusive && to.present?
      [from, to]
    end

    from_pairs(pairs)
  end

  def initialize(pairs)
    @pairs = pairs
  end

  def empty?
    @pairs.empty?
  end

  def intersect(other)
    a = @pairs
    b = other.to_a

    i = 0
    j = 0
    out = []

    while i < a.length && j < b.length
      a_from, a_to = a[i]
      b_from, b_to = b[j]

      from = [a_from, b_from].max
      to = [a_to, b_to].min
      out << [from, to] if to >= from

      if a_to < b_to
        i += 1
      else
        j += 1
      end
    end

    self.class.new(out)
  end

  # Retourne self \ other (plages présentes dans self, hors celles de other)
  def subtract(other)
    result = []

    @pairs.each do |from, to|
      cursor = from

      other.to_a.each do |o_from, o_to|
        next if o_to < cursor
        break if o_from > to

        if o_from > cursor
          result << [cursor, [o_from - 1.day, to].min]
        end

        cursor = [cursor, o_to + 1.day].max
        break if cursor > to
      end

      result << [cursor, to] if cursor <= to
    end

    self.class.from_pairs(result)
  end

  def to_a
    @pairs
  end

  def to_range_hashes
    @pairs.map { |from, to| { from:, to: } }
  end
end
