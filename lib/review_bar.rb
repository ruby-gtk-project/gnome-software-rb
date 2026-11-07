# frozen_string_literal: true

require 'gtk4'

# ReviewBar is ported from upstream's src/gs-review-bar.c / src/gs-review-bar.h:
# a thin horizontal bar used in the review histogram, filled from the left by
# a fraction of its own width, in the widget's current foreground colour.
#
# Upstream subclasses GtkWidget directly and overrides its snapshot vfunc.
# This port draws the same thing with Gtk::DrawingArea's draw_func instead
# -- the fully-supported Cairo entry point for custom drawing in the Ruby
# bindings -- rather than a raw GtkWidget snapshot override.
class ReviewBar < Gtk::DrawingArea
  def initialize
    super()
    add_css_class('review-bar')
    @fraction = 0.0
    self.content_height = 12
    set_draw_func { |_area, cr, width, height| draw(cr, width, height) }
  end

  attr_reader :fraction

  def fraction=(value)
    @fraction = value.to_f.clamp(0.0, 1.0)
    queue_draw
  end

  private

    def draw(cr, width, height)
      color = color_for_rendering
      bar_width = (fraction * width).round
      cr.set_source_rgba(color.red, color.green, color.blue, color.alpha)
      cr.rectangle(0, 0, bar_width, height)
      cr.fill
    end

    def color_for_rendering
      respond_to?(:color) ? color : Gdk::RGBA.new(0.0, 0.0, 0.0, 1.0)
    end
end
