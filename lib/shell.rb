# frozen_string_literal: true

require 'gtk4'
require 'adwaita'
require 'fileutils'

require_relative 'toast'
require_relative 'updates_paused_banner'

# Shell owns the main window's navigation chrome: the Adw.ViewStack of
# top-level pages (Explore/Installed/Updates), the view switcher that moves
# between them, the back button, the updates-paused banner, window-state
# persistence and the toast overlay every page shows notifications
# through. Ported from upstream's src/gs-shell.c / src/gs-shell.h.
#
# Upstream's GsShell *is* the AdwApplicationWindow and also owns the
# plugin-loader job queue, the back-entry stack for drilling into details/
# search/category/extras pages, and the basic-auth / untrusted-app dialogs
# a job's completion triggers. None of those sub-pages or the plugin loader
# they need exist yet (see component-identification.md), so this port keeps
# Shell as a plain Ruby object that builds the navigation widgets and hosts
# an Adw.StatusPage placeholder per mode — the same honest placeholder
# Application used for the whole window before this file existed. A future
# page replaces its mode's placeholder by calling +stack_main.add_titled+
# with the same page name this file registers.
class Shell
  MODES = %i[overview installed updates].freeze

  MODE_TITLES = {
    overview: 'Explore',
    installed: 'Installed',
    updates: 'Updates',
  }.freeze

  MODE_ICONS = {
    overview: 'org.gnome.Software-symbolic',
    installed: 'folder-symbolic',
    updates: 'software-update-available-symbolic',
  }.freeze

  NARROW_WIDTH_THRESHOLD = 800
  WINDOW_STATE_FILE_NAME = 'window-state'

  def initialize
    @mode = :overview
    @is_narrow = false
  end

  attr_reader :mode

  def is_narrow? = @is_narrow

  # gs_shell_get_is_narrow() / the allocation-width notify handler that
  # keeps it current. Application calls this from the window's own
  # notify::default-width (Shell does not reach into Gtk::Window itself,
  # so it stays testable without one).
  def update_narrow_for_width(width)
    @is_narrow = width < NARROW_WIDTH_THRESHOLD
  end

  # gs_shell_set_mode(): switches the visible page and the header's back
  # button visibility — only non-overview modes show one, mirroring
  # upstream's gtk_widget_set_visible (shell->button_back, mode != OVERVIEW).
  def set_mode(mode)
    raise ArgumentError, "unknown mode: #{mode}" unless MODES.include?(mode)

    @mode = mode
    stack_main.visible_child_name = mode.to_s
    button_back.visible = mode != :overview
  end

  # gs_shell_change_mode(): upstream additionally pushes a BackEntry and
  # takes category/search/app parameters for the sub-pages that are not
  # ported yet; until they exist this is exactly set_mode.
  def change_mode(mode) = set_mode(mode)

  # gs_shell_back_button clicked handler: returns to the overview, the only
  # back target that exists while the back-entry stack has nothing to pop.
  def go_back = set_mode(:overview)

  # gs_shell_show_notification() / gs_shell_show_toast()
  def show_notification(title) = show_toast(Toast.new_toast(title))
  def show_toast(toast) = toast_overlay.add_toast(toast)

  # gs_shell_set_updates_paused_banner_... Application forwards the current
  # reasons here as GsUpdateMonitor would.
  def updates_paused_flags=(flags)
    updates_paused_banner.updates_paused_flags = flags
  end

  # Memoized widget methods

  def root
    @root ||= Adwaita::ToolbarView.new.tap do |view|
      view.add_top_bar(header_bar)
      view.content = content_box
    end
  end

  def header_bar
    @header_bar ||= Adwaita::HeaderBar.new.tap do |bar|
      bar.pack_start(button_back)
      bar.title_widget = view_switcher_title
    end
  end

  def button_back
    @button_back ||= Gtk::Button.new.tap do |btn|
      btn.icon_name = 'go-previous-symbolic'
      btn.tooltip_text = 'Go back'
      btn.visible = false
      btn.signal_connect('clicked') { go_back }
    end
  end

  def view_switcher_title
    @view_switcher_title ||= Adwaita::ViewSwitcherTitle.new.tap do |switcher|
      switcher.stack = stack_main
      switcher.title = 'Software'
    end
  end

  def content_box
    @content_box ||= Gtk::Box.new(:vertical, 0).tap do |box|
      box.append(updates_paused_banner)
      box.append(toast_overlay)
    end
  end

  def toast_overlay
    @toast_overlay ||= Adwaita::ToastOverlay.new.tap do |overlay|
      overlay.child = stack_main
      overlay.vexpand = true
    end
  end

  def updates_paused_banner = @updates_paused_banner ||= UpdatesPausedBanner.new

  def stack_main
    @stack_main ||= Adwaita::ViewStack.new.tap do |stack|
      MODES.each { |mode| stack.add_titled(placeholder(mode), mode.to_s, MODE_TITLES.fetch(mode)).icon_name = MODE_ICONS.fetch(mode) }
      stack.visible_child_name = @mode.to_s
    end
  end

  # Window-state persistence (gs_shell_save_window_state() /
  # gs_shell_restore_window_state()). Takes the window as a parameter
  # rather than holding one, since the window belongs to Application and
  # Shell only needs it for the duration of these two calls.

  def save_window_state(window)
    key_file = GLib::KeyFile.new
    key_file.set_integer('WindowState', 'width', window.default_width)
    key_file.set_integer('WindowState', 'height', window.default_height)
    key_file.set_boolean('WindowState', 'maximized', window.maximized?)

    FileUtils.mkdir_p(File.dirname(window_state_path))
    File.write(window_state_path, key_file.to_data)
  end

  # Returns true if a saved state was found and applied, false otherwise —
  # mirroring upstream's gboolean return.
  def restore_window_state(window)
    return false unless File.exist?(window_state_path)

    key_file = GLib::KeyFile.new
    key_file.load_from_file(window_state_path, GLib::KeyFile::Flags::NONE)
    window.set_default_size(
      key_file.get_integer('WindowState', 'width'),
      key_file.get_integer('WindowState', 'height'),
    )
    window.maximize if key_file.get_boolean('WindowState', 'maximized')
    true
  rescue GLib::ErrorInfo
    false
  end

  private

    def window_state_path
      File.join(ENV.fetch('XDG_STATE_HOME', File.expand_path('~/.local/state')), 'gnome-software', WINDOW_STATE_FILE_NAME)
    end

    # Stands in for the real page until src/gs-overview-page.c and its
    # siblings are ported — see this file's own header comment.
    def placeholder(mode)
      Adwaita::StatusPage.new.tap do |page|
        page.title = MODE_TITLES.fetch(mode)
        page.icon_name = MODE_ICONS.fetch(mode)
        page.add_css_class('icon-dropshadow')
      end
    end
end
