# frozen_string_literal: true

require 'gtk4'

# PrimaryMenu builds the app's main menu, ported from the `menu
# id="primary_menu"` defined at the top of upstream's src/gs-shell.ui.
module PrimaryMenu
  # The same two sections upstream defines: repositories on their own, then
  # preferences/shortcuts/about together. Both app.sources and app.prefs open
  # dialogs this round does not build, so — exactly like upstream's own
  # hidden-when="action-disabled" on the repositories item — those two items
  # carry that attribute and simply do not render until the app registers
  # the action; GTK treats a missing action the same as a disabled one.
  def self.build
    Gio::Menu.new.tap do |menu|
      menu.append_section(
        nil,
        Gio::Menu.new.tap do |section|
          section.append_item(hideable_item('_Software Repositories', 'app.sources'))
        end,
      )

      menu.append_section(
        nil,
        Gio::Menu.new.tap do |section|
          section.append_item(hideable_item('_Preferences', 'app.prefs'))
          section.append('_Keyboard Shortcuts', 'app.shortcuts')
          section.append('_About Software', 'app.about')
        end,
      )
    end
  end

  def self.hideable_item(label, action)
    Gio::MenuItem.new(label, action).tap do |item|
      item.set_attribute_value('hidden-when', GLib::Variant.new('action-disabled'))
    end
  end
end
