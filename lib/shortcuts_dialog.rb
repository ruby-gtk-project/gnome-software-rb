# frozen_string_literal: true

require 'adwaita'

# ShortcutsDialog lists the app's keyboard shortcuts.
#
# A direct port of upstream's src/gs-shortcuts-dialog.ui, an
# Adw.ShortcutsDialog with four sections: Navigation, Windows, Updates Page
# and Help.
class ShortcutsDialog < Adwaita::ShortcutsDialog
  SECTIONS = {
    'Navigation'   => [
      ['Navigate to Explore Page', '<Alt>1'],
      ['Navigate to Installed Page', '<Alt>2'],
      ['Navigate to Updates Page', '<Alt>3'],
      ['Open Search Bar', '<Control>f'],
      ['Open Main Menu', 'F10'],
    ],
    'Windows'      => [
      ['Open Preferences', '<Control>comma'],
      ['Open Software Repositories', '<Control>period'],
      ['Close Main Window', '<Alt>F4 <Control>q'],
    ],
    'Updates Page' => [
      ['Check for Updates', 'F5 <Control>r'],
    ],
    'Help'         => [
      ['Open Keyboard Shortcuts', '<Control>question'],
    ],
  }.freeze

  def build
    tap do |dialog|
      SECTIONS.each { |title, items| dialog.add(section(title, items)) }
    end
  end

  private

    def section(title, items)
      Adwaita::ShortcutsSection.new.tap do |section|
        section.title = title
        items.each { |label, accelerator| section.add(item(label, accelerator)) }
      end
    end

    def item(label, accelerator) = Adwaita::ShortcutsItem.new(label, accelerator)
end
