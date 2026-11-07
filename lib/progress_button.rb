# frozen_string_literal: true

require 'gtk4'

# ProgressButton is ported from upstream's src/gs-progress-button.c /
# src/gs-progress-button.h: a GtkButton that can show either a label or an
# icon (switched with a Gtk::Stack so the button's size doesn't jump), and
# that can paint an "install progress" bar across its own background using a
# scoped Gtk::CssProvider — the same trick upstream's gs_utils_widget_set_css
# plays, driven by the "install-progress" CSS class and a `background-size`
# declaration upstream's own gtk-style.css turns into a horizontal fill.
class ProgressButton < Gtk::Button
  def initialize
    super()
    self.child = stack
    @show_icon = false
    @label_text = nil
    @icon_name = nil
    add_css_class('text-button')
  end

  attr_reader :label_text, :icon_name

  def show_icon? = @show_icon

  # Upstream's gs_progress_button_get/set_label: replaces the button's own
  # child content rather than going through GtkButton's own #label=, which
  # upstream's doc comment says must not be used because it would replace the
  # whole stack.
  def label_text=(value)
    return if @label_text == value

    @label_text = value
    label.label = value.to_s
  end

  def icon_name=(value)
    return if @icon_name == value

    @icon_name = value
    image.icon_name = value if value
  end

  def show_icon=(value)
    value = !!value
    return if @show_icon == value

    @show_icon = value
    if value
      stack.visible_child = image
      remove_css_class('text-button')
      add_css_class('image-button')
    else
      stack.visible_child = label
      remove_css_class('image-button')
      add_css_class('text-button')
    end
  end

  def show_progress=(value)
    if value
      add_css_class('install-progress')
    else
      remove_css_class('install-progress')
    end
  end

  # Upstream's GS_APP_PROGRESS_UNKNOWN sentinel (G_MAXUINT) means "indeterminate,
  # animate instead of showing a real percentage".
  def progress=(percentage)
    css =
      if percentage.nil? || percentage == :unknown
        "background-size: 25%;\nanimation: install-progress-unknown-move infinite linear 2s;"
      else
        "background-size: #{percentage.clamp(0, 100)}%;"
      end
    set_scoped_css(css)
  end

  def set_size_groups(label_group, image_group)
    label_group&.add_widget(label)
    image_group&.add_widget(image)
  end

  # Memoized widget methods

  def stack = @stack ||= Gtk::Stack.new.tap { |s| s.add_child(label); s.add_child(image) }
  def label = @label ||= Gtk::Label.new
  def image = @image ||= Gtk::Image.new

  private

    def set_scoped_css(css)
      remove_scoped_css
      @css_provider = Gtk::CssProvider.new.tap do |provider|
        provider.load_from_data("button {\n#{css}\n}")
        style_context.add_provider(provider, Gtk::StyleProvider::PRIORITY_APPLICATION)
      end
    end

    def remove_scoped_css
      style_context.remove_provider(@css_provider) if @css_provider
    end
end
