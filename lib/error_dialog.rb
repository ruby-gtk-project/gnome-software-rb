# frozen_string_literal: true

require 'adwaita'

# ErrorDialog shows a title and a scrollable, copyable block of error detail
# text, ported from upstream's src/gs-utils-error-dialog-simple.ui and the
# gs_utils_show_error_dialog_simple() function in src/gs-common.c.
class ErrorDialog < Adwaita::Dialog
  def initialize(title, text)
    super()
    @title_text = title
    @details_text = text
  end

  def build
    tap do |dialog|
      dialog.title = 'Error Details'
      dialog.content_width = 500
      dialog.content_height = 350
      dialog.child = toolbar_view

      toolbar_view.tap do |view|
        view.add_top_bar(header_bar)
        view.content = toast_overlay

        toast_overlay.tap do |overlay|
          overlay.child = preferences_page

          preferences_page.tap do |page|
            page.add(title_group)
            page.add(details_group)

            title_group.tap { |group| group.add(title_label) }

            details_group.tap do |group|
              group.header_suffix = copy_button
              group.add(scrolled_window)

              scrolled_window.tap { |sw| sw.child = text_view }
            end
          end
        end
      end

      copy_button.signal_connect('clicked') { copy_details_to_clipboard }
    end
  end

  def header_bar = @header_bar ||= Adwaita::HeaderBar.new
  def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new
  def toast_overlay = @toast_overlay ||= Adwaita::ToastOverlay.new
  def preferences_page = @preferences_page ||= Adwaita::PreferencesPage.new
  def title_group = @title_group ||= Adwaita::PreferencesGroup.new

  def title_label
    @title_label ||= Gtk::Label.new(@title_text).tap do |label|
      label.wrap = true
      label.justify = :center
      label.add_css_class('title-1')
    end
  end

  def details_group
    @details_group ||= Adwaita::PreferencesGroup.new.tap do |group|
      group.title = 'Details'
    end
  end

  def copy_button
    @copy_button ||= Gtk::Button.new.tap do |button|
      button.tooltip_text = 'Copy Details'
      button.icon_name = 'edit-copy-symbolic'
      button.valign = :center
      button.add_css_class('flat')
    end
  end

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap do |sw|
      sw.vexpand = true
      sw.overflow = :hidden
      sw.add_css_class('card')
    end
  end

  def text_view
    @text_view ||= Gtk::TextView.new.tap do |view|
      view.editable = false
      view.wrap_mode = :word_char
      view.top_margin = 12
      view.bottom_margin = 12
      view.left_margin = 12
      view.right_margin = 12
      view.monospace = true
      view.buffer.text = @details_text.to_s
      view.add_css_class('monospace')
      view.add_css_class('inline')
    end
  end

  private

    def copy_details_to_clipboard
      text_view.display.clipboard.set(text_view.buffer.text)
      toast_overlay.add_toast(Adwaita::Toast.new('Details copied to clipboard'))
    end
end
