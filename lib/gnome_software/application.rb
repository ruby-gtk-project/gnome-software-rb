# frozen_string_literal: true

require 'gtk4'
require 'adwaita'

require_relative '../settings'
require_relative '../common'
require_relative '../primary_menu'
require_relative '../shortcuts_dialog'
require_relative '../system_info'
require_relative '../shell'

module GnomeSoftware
  # The port's application shell, ported from upstream's src/gs-application.c
  # / src/gs-application.h: the Gtk::Application, the app-wide actions
  # (app.about, app.shortcuts, app.quit) upstream registers from its own
  # ACTION_ENTRIES table, and window lifecycle (window-state save/restore,
  # narrow-width tracking). The window's own navigation chrome — header
  # bar, view stack, back button, toast overlay, updates-paused banner —
  # is lib/shell.rb's Shell, ported from src/gs-shell.c.
  #
  # House style (see .claude/skills/ruby-gtk): every widget is a memoized
  # method, all configuration lives in its `tap`, assembly happens only in
  # `build`, and the launcher is one expression.
  class Application
    APP_ID = 'org.rubygtkproject.GnomeSoftware'
    VERSION = '0.1.0'

    # The same action names upstream's gs-application.c ACTION_ENTRIES
    # registers at the app scope, with the accelerators gs-shell.ui binds to
    # them (app.sources has none yet — it opens a dialog this round does not
    # build, so it stays off PrimaryMenu's hidden-when guard via being absent
    # entirely rather than present-and-broken).
    # app.sources and app.prefs are deliberately absent: they would open the
    # repositories and preferences dialogs, neither of which is ported yet,
    # and PrimaryMenu hides their menu items as soon as the action is
    # missing rather than wiring them to nothing.
    ACTIONS = {
      'about'     => [],
      'shortcuts' => ['<Control>question'],
      'quit'      => ['<Control>q'],
    }.freeze

    attr_reader :settings

    def initialize
      @settings = Settings.new
    end

    def build
      app.tap do
        app.signal_connect('activate') do
          window.tap { |win| win.content = shell.root }

          shell.header_bar.tap { |bar| bar.pack_end(primary_menu_button) }

          window.signal_connect('close-request') { on_close_request }
          window.signal_connect('notify::default-width') do
            shell.update_narrow_for_width(window.default_width)
          end

          shell.restore_window_state(window)

          # Mirrors gs-loading-page.c's own read of this key: the first run
          # gets a 24h cache-age refresh once the plugin loader exists;
          # until then this just records that first run happened.
          if settings.first_run?
            settings.first_run = false
          end

          setup_actions
          window.present
        end
      end
    end

    # Adwaita::Application is broken in the Ruby bindings; the application
    # object comes from Gtk and only the window is Adwaita.
    def app = @app ||= Gtk::Application.new(APP_ID, :default_flags)

    def window
      @window ||= Adwaita::ApplicationWindow.new(app).tap do |win|
        win.title = 'Software'
        win.icon_name = 'org.gnome.Software'
        win.width_request = 360
        win.height_request = 400
        win.set_default_size(1200, 800)
      end
    end

    def shell = @shell ||= Shell.new

    def primary_menu_button
      @primary_menu_button ||= Gtk::MenuButton.new.tap do |btn|
        btn.icon_name = 'open-menu-symbolic'
        btn.tooltip_text = 'Main Menu'
        btn.menu_model = PrimaryMenu.build
        btn.add_css_class('image-button')
      end
    end

    def about_dialog
      @about_dialog ||= Adwaita::AboutDialog.new.tap do |about|
        about.application_name = 'Software'
        about.application_icon = 'org.gnome.Software'
        about.developer_name = 'The GNOME Project'
        about.version = VERSION
        about.website = 'https://apps.gnome.org/Software'
        about.support_url = 'https://discourse.gnome.org/tag/gnome-software'
        about.issue_url = 'https://gitlab.gnome.org/GNOME/gnome-software/-/issues'
        about.copyright = 'Copyright © 2016–2026 GNOME Software contributors'
        about.license_type = Gtk::License::GPL_2_0
        about.debug_info = SystemInfo.report
      end
    end

    private

      def setup_actions
        ACTIONS.each_key { |name| add_action(name, ACTIONS[name]) }
      end

      def add_action(name, accels)
        Gio::SimpleAction.new(name, nil).tap do |action|
          action.signal_connect('activate') { send(:"action_#{name}") }
          app.add_action(action)
          if accels.any?
            app.set_accels_for_action("app.#{name}", accels)
          end
        end
      end

      def action_about = about_dialog.present(window)

      def action_shortcuts
        ShortcutsDialog.new.tap do |dialog|
          dialog.build
          dialog.present(window)
        end
      end

      def action_quit = app.quit

      def on_close_request
        shell.save_window_state(window)
        false
      end
  end
end
