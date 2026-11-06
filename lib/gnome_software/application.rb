# frozen_string_literal: true

require 'gtk4'
require 'adwaita'

require_relative '../settings'
require_relative '../common'
require_relative '../primary_menu'
require_relative '../shortcuts_dialog'

module GnomeSoftware
  # The port's application shell, ported from upstream's src/gs-application.c
  # / src/gs-application.h: the Gtk::Application, the main window's chrome
  # (header bar, main menu, toast overlay) and the app-wide actions
  # (app.about, app.shortcuts, app.quit) upstream registers from its own
  # ACTION_ENTRIES table.
  #
  # The page content (Explore/Installed/Updates and the rest of the view
  # stack GsShell owns) is not ported yet, so the window shows an
  # Adw::StatusPage in its place rather than a half-built page tree — see
  # lib/shell.rb's entry in the component inventory for what replaces it.
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
          window.tap { |win| win.content = toast_overlay }

          toast_overlay.tap { |overlay| overlay.child = toolbar_view }

          toolbar_view.tap do |view|
            view.add_top_bar(header_bar)
            view.content = status_page
          end

          header_bar.tap do |bar|
            bar.pack_end(primary_menu_button)
          end

          window.signal_connect('close-request') { on_close_request }

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

    def toast_overlay = @toast_overlay ||= Adwaita::ToastOverlay.new
    def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new
    def header_bar = @header_bar ||= Adwaita::HeaderBar.new

    def primary_menu_button
      @primary_menu_button ||= Gtk::MenuButton.new.tap do |btn|
        btn.icon_name = 'open-menu-symbolic'
        btn.tooltip_text = 'Main Menu'
        btn.menu_model = PrimaryMenu.build
        btn.add_css_class('image-button')
      end
    end

    # Stands in for GsShell's view stack until the pages it switches between
    # are ported; see the component inventory for what replaces this.
    def status_page
      @status_page ||= Adwaita::StatusPage.new.tap do |page|
        page.title = 'Software'
        page.icon_name = 'org.gnome.Software'
        page.add_css_class('icon-dropshadow')
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

      def on_close_request = false
  end
end
