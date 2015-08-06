require 'squid/base'
require 'squid/graph/baseline'
require 'squid/graph/chart'
require 'squid/graph/grid'
require 'squid/graph/legend'

module Squid
  class Graph < Base
    has_settings :baseline, :border, :chart, :format, :gridlines, :height
    has_settings :legend, :ticks

    # Draws the graph.
    def draw
      bounding_box [0, cursor], width: bounds.width, height: height do
        draw_graph
      end if data.any?
    end

  private

    def draw_graph
      draw_legend if legend
      draw_grid if grid
      draw_baseline if baseline
      draw_chart if chart
      draw_border if border
    end

    def draw_legend
      Legend.new(pdf, data.keys).draw
    end

    def draw_grid
      Grid.new(pdf, labels, grid_options).draw
    end

    def draw_baseline
      Baseline.new(pdf, categories, left: left, ticks: ticks).draw
    end

    def draw_chart
      min, max = min_max first_series
      Chart.new(pdf, first_series, grid_options.merge(min: min, max: max)).draw
    end

    def grid_options
      {left: left, height: chart_height, top: chart_top}
    end

    def draw_border
      with(line_width: 0.5) { stroke_bounds }
    end

    def first_series
      data.values.first.values
    end

    # Returns the categories to print below the baseline.
    def categories
      data.values.first.keys
    end

    # Returns the width of the left axis
    def left
      @left ||= max_width_of left_labels
    end

    def chart_height
      bounds.height - padding_top - padding_bottom
    end

    def chart_top
      bounds.top - padding_top
    end

    # Return the padding between the top of the graph and the grid.
    # In any case, a padding is present (for values above the top of the grid).
    # If there is a legend, an equivalent padding is present for the legend.
    def padding_top
      legend_height * (legend ? 2 : 1)
    end

    # Return the padding between the grid and the bottom of the graph.
    # It is only present if baseline and categories are drawn
    def padding_bottom
      baseline ? text_height : 0
    end

    # Returns the labels to print in the left axis.
    def left_labels
      @left_labels ||= labels_for first_series
    end

    # Returns the labels to print on both axes.
    def labels
      @labels ||= left_labels.map{|v| {left: v}}
    end

    # Returns the width of the longest label in the given font size.
    def max_width_of(labels)
      labels.map{|label| width_of label, size: font_size}.max
    end

    # Transform a numeric value into a label according to the given format.
    def labels_for(values)
      min, max = min_max values
      gap = (min - max)/gridlines.to_f
      max.step(by: gap, to: min).map{|value| format_for value}
    end

    # Returns the minimum and maximum value, approximated to significant digits.
    def min_max(values)
      min = (values + [0]).compact.min
      max = (values + [gridlines]).compact.max
      [min, max].map{|value| approximate_value_for value}
    end

    # Returns an approximation of a value that looks nicer on a graph axis.
    # For instance, rounds 99.67 to 100, which makes for a better axis value.
    def approximate_value_for(value)
      number_to_rounded(value, significant: true, precision: 2).to_f
    end

    # Returns the formatted value (currency, percentage, ...).
    def format_for(value)
      case format
      when :percentage then number_to_percentage value, precision: 1
      when :currency then number_to_currency value
      when :seconds then number_to_minutes_and_seconds value
      when :float then number_to_delimited value
      else number_to_delimited value.to_i
      end.to_s
    end

    def number_to_minutes_and_seconds(value)
      "#{value.round / 60}:#{(value.round % 60).to_s.rjust 2, '0'}"
    end

    # Returns whether the grid should be drawn at all.
    def grid
      gridlines > 0
    end
  end
end
