# frozen_string_literal: true

require 'adwaita'
require_relative 'lozenge'

# ContextDialogRow is ported from upstream's src/gs-context-dialog-row.c /
# src/gs-context-dialog-row.h and its gs-context-dialog-row.ui template: an
# Adw.ActionRow used in context dialogs (hardware support, storage, safety,
# age rating) to show how well an app supports some feature. Each row has a
# Lozenge prefix (an icon or short text) coloured by "importance", a title
# and a description.
class ContextDialogRow < Adwaita::ActionRow
  IMPORTANCE_CSS_CLASS = {
    neutral: 'grey',
    unimportant: 'green',
    information: 'yellow',
    warning: 'orange',
    important: 'red'
  }.freeze

  def self.new_icon(icon_name, importance, title, description)
    new.tap do |row|
      row.icon_name = icon_name
      row.importance = importance
      row.title = title
      row.subtitle = description
    end
  end

  def self.new_text(content, importance, title, description)
    new.tap do |row|
      row.content = content
      row.importance = importance
      row.title = title
      row.subtitle = description
    end
  end

  def initialize
    super()
    @importance = :neutral
    add_prefix(lozenge)
    lozenge.add_css_class(IMPORTANCE_CSS_CLASS[:neutral])
  end

  attr_reader :icon_name, :content, :importance

  def icon_name=(value)
    @icon_name = value
    @content = nil
    lozenge.icon_name = value
  end

  def content=(value)
    @content = value
    @icon_name = nil
    lozenge.text = value
  end

  def content_is_markup? = lozenge.use_markup?

  def content_markup=(value)
    @content = value
    @icon_name = nil
    lozenge.markup = value
  end

  def importance=(value)
    css_class = IMPORTANCE_CSS_CLASS.fetch(value) { IMPORTANCE_CSS_CLASS[:neutral] }
    IMPORTANCE_CSS_CLASS.each_value { |klass| lozenge.remove_css_class(klass) }
    lozenge.add_css_class(css_class)
    @importance = value
  end

  # Upstream groups the lozenge, title and description widths across rows so
  # several rows line up. Adw.ActionRow doesn't expose its internal title/
  # subtitle labels through GObject-Introspection, so only the lozenge --
  # which this row owns directly -- can actually be added to a size group.
  def set_size_groups(lozenge_group, _title_group = nil, _description_group = nil)
    lozenge_group&.add_widget(lozenge)
  end

  # Memoized widget methods

  def lozenge = @lozenge ||= Lozenge.new.tap { |l| l.circular = true }
end
