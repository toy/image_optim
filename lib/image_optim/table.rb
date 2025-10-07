# frozen_string_literal: true

class ImageOptim
  # Handy class for pretty printing a table in the terminal. This is very simple, switch to Terminal
  # Table, Table Tennis or similar if we need more.
  class Table
    attr_reader :rows

    def initialize(rows)
      @rows = rows
    end

    def write(io)
      io.puts render_row(columns)
      io.puts render_sep
      rows.each do |row|
        io.puts render_row(row.values)
      end
    end

  protected

    # array of column names
    def columns
      @columns ||= rows.first.keys
    end

    # should columns be justified left or right?
    def justs
      @justs ||= columns.map do |col|
        rows.first[col].is_a?(Numeric) ? :rjust : :ljust
      end
    end

    # max width of each column
    def widths
      @widths ||= columns.map do |col|
        values = rows.map{ |row| fmt(row[col]) }
        ([col] + values).map(&:length).max
      end
    end

    # render an array of row values
    def render_row(values)
      values.zip(justs, widths).map do |value, just, width|
        fmt(value).send(just, width)
      end.join('  ')
    end

    # render a separator line
    def render_sep
      render_row(widths.map{ |width| '-' * width })
    end

    # format one cell value
    def fmt(value)
      if value.is_a?(Float)
        format('%0.3f', value)
      else
        value.to_s
      end
    end
  end
end
