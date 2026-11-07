# frozen_string_literal: true

require 'gtk4'

# Lozenge is ported from upstream's src/gs-lozenge.c / src/gs-lozenge.h and
# its gs-lozenge.ui template: a small pill/circle-shaped GtkBox that shows
# either an icon or a line of text/markup, used for the "update available"
# count badge and similar small status markers.
#
# Deviation from upstream: upstream installs a custom GtkLayoutManager
# (GsLozengeLayout) whose only job is to make a #circular lozenge as tall
# as it is wide by feeding its own measured size back in as `for_size`.
# The Ruby GTK4 bindings have no supported way to subclass GtkLayoutManager
# (see .claude/skills/ruby-gtk), so #circular= here instead adds the
# "circular" CSS class (upstream's own gs-lozenge.ui already does this for
# the rounded-corner styling) and pins both halign/valign to :center with
# a fixed width/height request, which produces the same visual square the
# layout manager was built to guarantee.
class Lozenge < Gtk::Box
  def initialize
    super(:horizontal, 0)
    self.css_classes = ['lozenge']
    self.halign = :center
    self.valign = :center
    self.append(image)
    self.append(label)
    @pixel_size = 16
    @circular = false
    self.pixel_size = @pixel_size
    show_text
  end

  attr_reader :icon_name, :text, :markup, :pixel_size

  def circular? = @circular

  def circular=(value)
    @circular = !!value
    if @circular
      add_css_class('circular')
      self.width_request = self.height_request = natural_square_size
    else
      remove_css_class('circular')
      self.width_request = self.height_request = -1
    end
  end

  def icon_name=(value)
    @icon_name = value.nil? || value.empty? ? nil : value
    @text = nil
    @markup = nil
    if @icon_name
      image.icon_name = @icon_name
      label.visible = false
      image.visible = true
    else
      image.visible = false
      label.visible = true
    end
  end

  def pixel_size=(value)
    @pixel_size = value
    image.pixel_size = value
  end

  def text=(value)
    @text = value.nil? || value.empty? ? nil : value
    @icon_name = nil
    label.use_markup = false
    show_text
  end

  def markup=(value)
    @markup = value.nil? || value.empty? ? nil : value
    @icon_name = nil
    label.use_markup = true
    show_text
  end

  def use_markup? = label.use_markup?

  # Memoized widget methods

  def image = @image ||= Gtk::Image.new.tap { |img| img.visible = false }

  def label = @label ||= Gtk::Label.new.tap { |l| l.visible = true }

  private

  def show_text
    label.label = @markup || @text || ''
    image.visible = false
    label.visible = true
  end

  def natural_square_size
    [pixel_size + 16, 32].max
  end
end
