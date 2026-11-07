# frozen_string_literal: true

require 'gtk4'

# DescriptionBox is ported from upstream's src/gs-description-box.c /
# src/gs-description-box.h: shows app-description markup in a collapsed form
# (clamped to MAX_COLLAPSED_LINES) with a "Show More"/"Show Less" button that
# only appears when collapsing actually saves enough lines to be worth it.
#
# Upstream is a plain GtkWidget with its own measure/size_allocate overrides
# so it can recompute the Pango line count on every live resize. This port
# is a plain Gtk::Box (no custom measure/allocate vfuncs, which the Ruby
# bindings do not support overriding on an otherwise-ordinary widget): it
# recomputes from the real Gtk::Label Pango layout -- so the "Show More"
# threshold is the actual rendered line count, not a guess -- on #text=, on
# the box's own "realize", and whenever #recalculate is called explicitly
# (a page that embeds this and later resizes can call it to re-check).
class DescriptionBox < Gtk::Box
  MAX_COLLAPSED_LINES = 4
  MIN_HIDDEN_LINES = 3

  def initialize
    super(:vertical, 6)
    self.append(label)
    self.append(button)
    @text = nil
    @always_expanded = false
    @is_collapsed = true
    button.signal_connect('clicked') { toggle_collapsed }
    signal_connect('realize') { recalculate }
  end

  attr_reader :text, :always_expanded, :is_collapsed

  def text=(value)
    @text = value.nil? || value.empty? ? nil : value
    self.visible = !@text.nil?
    recalculate
  end

  def always_expanded=(value)
    @always_expanded = !!value
    recalculate
  end

  def collapsed? = @is_collapsed

  # Recomputes the collapsed/expanded label content from the label's own
  # Pango layout. Safe to call before the widget has an allocation: with no
  # layout yet, the button is simply hidden until a real recalc happens.
  def recalculate
    return label.visible = false if @text.nil?

    if @always_expanded
      button.visible = false
      label.use_markup = true
      label.lines = -1
      label.ellipsize = :none
      label.label = @text
      return
    end

    label.use_markup = true
    label.lines = -1
    label.ellipsize = :none
    label.label = @text

    layout = label.layout
    n_lines = layout ? layout.line_count : 0
    show_button = n_lines > MAX_COLLAPSED_LINES && (n_lines - MAX_COLLAPSED_LINES) >= MIN_HIDDEN_LINES
    button.visible = show_button
    button.label = @is_collapsed ? '_Show More' : '_Show Less'

    if @is_collapsed && show_button
      label.lines = MAX_COLLAPSED_LINES
      label.ellipsize = :end
    end
  end

  # Memoized widget methods

  def label
    @label ||= Gtk::Label.new.tap do |l|
      l.wrap = true
      l.wrap_mode = :word_char
      l.xalign = 0.0
      l.use_markup = true
    end
  end

  def button
    @button ||= Gtk::Button.new.tap do |b|
      b.use_underline = true
      b.halign = :start
      b.add_css_class('flat')
      b.visible = false
    end
  end

  private

    def toggle_collapsed
      @is_collapsed = !@is_collapsed
      recalculate
    end
end
