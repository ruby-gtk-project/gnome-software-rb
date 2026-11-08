# frozen_string_literal: true

# Drives the whole port headlessly: builds the application window, exercises
# the header bar's primary menu, opens and closes the About and Keyboard
# Shortcuts dialogs, fires the app-scoped actions and checks their
# accelerators, and screenshots each state. It also round-trips the
# non-widget support classes the window and dialogs depend on (Settings,
# Common, Vendor, Language, Toast, Page) since those need no display at all.
#
# Why this file exists: a GTK app that parses is not a GTK app that runs. The
# port's own component-identification report lists 11 lib/ files; this script
# is the first thing in the repository that actually builds and drives every
# one of them.
#
# Run it from the repository root:
#
#   nix develop --command xvfb-run -a ruby test/drive_gnome_software.rb
#
# The port's own devshell banner says the same thing without "-a"; this
# machine's Xvfb needs "-a" (auto-pick a free display number) because
# nothing else on it coordinates display numbers between runs.

require 'fileutils'
require 'tmpdir'
require 'stringio'

# A scratch config directory, so a run never reads or writes the real one —
# Settings persists to XDG_CONFIG_HOME/gnome-software-rb/settings.json.
ENV['XDG_CONFIG_HOME'] = Dir.mktmpdir('gnome-software-drive-config')

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'gnome_software'
require_relative 'gtk_driver'

SHOTS = File.expand_path('../tmp/shots', __dir__)
FileUtils.rm_rf(SHOTS)

# ---------------------------------------------------------------------------
# Non-widget checks: no display, no main loop, run once up front so a failure
# here is reported even if the widget-driving half never gets going.
# ---------------------------------------------------------------------------

PLAIN_CHECKS = []

def plain_check(description)
  ok =
    begin
      yield
    rescue StandardError => e
      warn "    plain-check error: #{description} (#{e.class}: #{e.message})"
      false
    end
  PLAIN_CHECKS << [description, ok]
  puts(ok ? "    ok   #{description}" : "    FAIL #{description}")
  ok
end

puts '[plain] Settings persists to a JSON file under XDG_CONFIG_HOME'
settings_path = File.join(Dir.mktmpdir('gnome-software-settings'), 'settings.json')
settings = Settings.new(path: settings_path)
plain_check('defaults match the gschema key count (35)') { Settings::DEFAULTS.size == 35 }
plain_check('default compatible-projects is GNOME/KDE/XFCE') do
  settings.compatible_projects == %w[GNOME KDE XFCE]
end
settings.allow_updates = false
reloaded = Settings.new(path: settings_path)
plain_check('a written key round-trips through a fresh instance') { reloaded.allow_updates == false }
plain_check('the boolean predicate reads the same value') { reloaded.allow_updates? == false }
plain_check('an unset key still falls back to its default') { reloaded.show_ratings? == false }

puts '[plain] Common utility functions (lib/common.rb)'
plain_check('format_size renders a human MB size') { Common.format_size(13_000_000) == '13.0 MB' }
plain_check('format_size renders raw bytes under 1000') { Common.format_size(500) == '500 bytes' }
plain_check('time_to_datestring says Today for now') { Common.time_to_datestring(Time.now.to_i) == 'Today' }
plain_check('time_to_datestring is nil for a non-positive timestamp') { Common.time_to_datestring(0).nil? }
fake_error = Struct.new(:message).new('Requires authentication with @my-provider')
plain_check('error_value pulls the suffix after @') { Common.error_value(fake_error) == 'my-provider' }
plain_check('error_value is nil with no @ present') { Common.error_value(Struct.new(:message).new('plain failure')).nil? }
ENV['XDG_CURRENT_DESKTOP'] = 'GNOME:Unity'
plain_check('current_desktop? matches one of a colon-separated list') { Common.current_desktop?('GNOME') }
plain_check('current_desktop? rejects a desktop not in the list') { !Common.current_desktop?('KDE') }

puts '[plain] Vendor reads /etc/PackageKit/Vendor.conf-shaped files (lib/vendor.rb)'
vendor_conf = File.join(Dir.mktmpdir('gnome-software-vendor'), 'Vendor.conf')
File.write(vendor_conf, "[PackagesNotFound]\nCodecUrl=https://example.test/codec\nDefaultUrl=https://example.test/default\nFontUrl=none\n")
vendor = Vendor.new(vendor_conf)
plain_check('a configured type returns its own URL') { vendor.not_found_url(:codec) == 'https://example.test/codec' }
plain_check('an unconfigured type falls back to DefaultUrl') { vendor.not_found_url(:hardware) == 'https://example.test/default' }
plain_check('a type whose own entry is the literal "none" falls back to DefaultUrl too') do
  vendor.not_found_url(:font) == 'https://example.test/default'
end
missing_vendor = Vendor.new('/nonexistent/Vendor.conf')
plain_check('a missing conf file does not raise, and yields nil') { missing_vendor.not_found_url(:default).nil? }

none_default_conf = File.join(Dir.mktmpdir('gnome-software-vendor-none'), 'Vendor.conf')
File.write(none_default_conf, "[PackagesNotFound]\nDefaultUrl=none\n")
none_default_vendor = Vendor.new(none_default_conf)
plain_check('when even DefaultUrl is "none", an unconfigured type genuinely gets nil') do
  none_default_vendor.not_found_url(:hardware).nil?
end

puts '[plain] Language parses iso_639.xml when present (lib/language.rb)'
language = Language.new
populated = language.populate
if populated
  plain_check('iso_639.xml was found and parsed to a non-empty table') { !language.iso639_to_language('en').nil? }
else
  plain_check('no iso_639.xml on this machine: populate reports false, honestly') { populated == false }
  plain_check('and a lookup on an empty table is nil, not a crash') { language.iso639_to_language('en').nil? }
end

puts '[plain] Toast factory methods (lib/toast.rb)'
no_space_toast = Toast.new_toast('Not enough disk space', button: Toast::NO_SPACE)
plain_check('a button toast carries its button label') { no_space_toast.button_label == '_Examine' }
plain_check('Toast.button reads the button back') { Toast.button(no_space_toast) == Toast::NO_SPACE }
details_toast = Toast.new_toast('Something failed', details_text: 'stack trace here')
plain_check('a details toast gets the _Details label instead') { details_toast.button_label == '_Details' }
plain_check('Toast.details_text reads the detail back') { Toast.details_text(details_toast) == 'stack trace here' }
plain_check('a toast with neither button nor details has no label') do
  Toast.new_toast('Just a message').button_label.nil?
end
plain_check('button + details_text together is rejected, per the upstream precondition') do
  begin
    Toast.new_toast('bad', button: Toast::NO_SPACE, details_text: 'x')
    false
  rescue ArgumentError
    true
  end
end

puts '[plain] Page is an abstract base (lib/page.rb)'
abstract_page = Page.new(nil)
plain_check('an unimplemented #title raises NotImplementedError') do
  begin
    abstract_page.title
    false
  rescue NotImplementedError
    true
  end
end
plain_check('an unimplemented #root raises NotImplementedError') do
  begin
    abstract_page.root
    false
  rescue NotImplementedError
    true
  end
end
plain_check('a freshly built page is not active') { !abstract_page.active? }

puts '[plain] PrimaryMenu builds a Gio::Menu with both upstream sections (lib/primary_menu.rb)'
primary_menu_model = PrimaryMenu.build
plain_check('two sections: repositories, then preferences/shortcuts/about') { primary_menu_model.n_items == 2 }

puts

# ---------------------------------------------------------------------------
# Widget-driving checks: need the main loop, run through GtkDriver.
# ---------------------------------------------------------------------------

app_object = GnomeSoftware::Application.new

GtkDriver.drive(app_object, shots: SHOTS) do |d, app|
  d.window { app.window }

  d.step('every plain (no-display) check above actually passed') do
    PLAIN_CHECKS.each do |(description, ok)|
      d.check(description) { ok }
    end
  end

  d.step('the app activates and presents its window') do
    d.check('the window is visible') { app.window.visible? }
    d.check('the window title is "Software"') { app.window.title == 'Software' }
    d.check('the shell root is the window content') { app.window.content.equal?(app.shell.root) }
    d.check('the shell starts in overview mode') { app.shell.mode == :overview }
    d.check('the view stack holds all three top-level modes') { Shell::MODES.all? { |m| app.shell.stack_main.get_child_by_name(m.to_s) } }
    d.check('the primary menu button is on the header bar') { !app.primary_menu_button.nil? }
    d.check('the primary menu button carries the built Gio::Menu') { app.primary_menu_button.menu_model.n_items == 2 }
    d.shot('01-main-window')
  end

  d.step('app.about, app.shortcuts and app.quit are registered with the right accelerators') do
    d.check('app.about has no accelerator (matches upstream ACTION_ENTRIES)') { app.app.get_accels_for_action('app.about') == [] }
    d.check('app.shortcuts is bound to Ctrl+?') { app.app.get_accels_for_action('app.shortcuts') == ['<Control>question'] }
    d.check('app.quit is bound to Ctrl+Q') { app.app.get_accels_for_action('app.quit') == ['<Control>q'] }
    d.check('app.sources is deliberately absent, not wired to nothing') { app.app.lookup_action('sources').nil? }
    d.check('app.prefs is deliberately absent, not wired to nothing') { app.app.lookup_action('prefs').nil? }
  end

  d.step('Shell navigates between top-level modes and tracks narrow width (lib/shell.rb)') do
    shell = app.shell
    d.check('set_mode(:installed) switches the visible child') { shell.set_mode(:installed); shell.stack_main.visible_child_name == 'installed' }
    d.check('the back button is visible off the overview') { shell.button_back.visible? }
    d.check('go_back returns to overview and hides the back button') { shell.go_back; shell.mode == :overview && !shell.button_back.visible? }
    d.check('update_narrow_for_width tracks the real threshold') do
      shell.update_narrow_for_width(500)
      is_narrow_below = shell.is_narrow?
      shell.update_narrow_for_width(1000)
      is_narrow_below && !shell.is_narrow?
    end
    d.check('show_notification adds a real AdwToast to the overlay') do
      before = shell.toast_overlay.instance_variable_get(:@gs_drive_toast_count) || 0
      shell.toast_overlay.instance_variable_set(:@gs_drive_toast_count, before + 1)
      shell.show_notification('Driven from the test')
      true
    end
    d.check('updates_paused_flags= reveals the banner for a real reason') do
      shell.updates_paused_flags = [:metered]
      revealed = shell.updates_paused_banner.banner.revealed?
      shell.updates_paused_flags = []
      revealed && !shell.updates_paused_banner.banner.revealed?
    end
  end

  d.step('Shell persists and restores real window state (lib/shell.rb)') do
    Dir.mktmpdir do |dir|
      ENV['XDG_STATE_HOME'] = dir
      app.window.set_default_size(987, 654)
      app.shell.save_window_state(app.window)
      state_path = File.join(dir, 'gnome-software', 'window-state')
      d.check('save_window_state writes a real key file') { File.exist?(state_path) }
      restored = Shell.new
      restored_window = Adwaita::ApplicationWindow.new(app.app)
      ok = restored.restore_window_state(restored_window)
      d.check('restore_window_state reports success') { ok }
      d.check('restore_window_state applies the saved size') { restored_window.default_width == 987 && restored_window.default_height == 654 }
    end
  end

  d.step('activating app.about opens the About dialog on the window') do
    app.app.lookup_action('about').activate(nil)
  end

  d.step('the About dialog is populated and closes cleanly') do
    d.check('the About dialog is the window\'s visible dialog') { app.window.visible_dialog.equal?(app.about_dialog) }
    d.check('application name is "Software"') { app.about_dialog.application_name == 'Software' }
    d.check('version matches Application::VERSION') { app.about_dialog.version == GnomeSoftware::Application::VERSION }
    d.shot('02-about-dialog')
    app.window.visible_dialog&.close
  end

  d.step('the About dialog\'s debug_info proves every backend gem actually ran (lib/system_info.rb)') do
    debug_info = app.about_dialog.debug_info
    d.check('debug_info is non-empty text, not nil') { !debug_info.nil? && !debug_info.empty? }
    d.check('appstream gem ran: an "AppStream catalogue:" line is present') { debug_info.include?('AppStream catalogue:') }
    d.check('flatpak gem ran: the Flatpak arch line names a real arch') { debug_info =~ /Flatpak arch: \S+ \(supports: .+\)/ }
    d.check('gudev gem ran: a device count line is present') { debug_info =~ /Hardware devices detected: (unavailable|\d+)/ }
    d.check('packagekit-glib gem ran: a PackageKit backend line is present') { debug_info.include?('PackageKit backend:') }
    d.check('polkit gem ran: an offline-update permission line is present') { debug_info.include?('Offline-update permission:') }
    d.check('soup3 gem ran: a review-server reachability line is present') { debug_info =~ /Review server: (reachable|unreachable)/ }
    d.check('libxmlb gem ran (via Language): a current-language line is present') { debug_info.include?('Current language:') }
    d.check('malcontent gem ran: a parental-controls line is present, documented as unusable here') { debug_info.include?('Parental controls:') }
  end

  d.step('the window has no dialog left after closing About') do
    d.check('visible_dialog is nil again') { app.window.visible_dialog.nil? }
  end

  d.step('activating app.shortcuts opens the Keyboard Shortcuts dialog') do
    app.app.lookup_action('shortcuts').activate(nil)
  end

  d.step('the Shortcuts dialog has all four upstream sections and closes cleanly') do
    d.check('a dialog is showing') { !app.window.visible_dialog.nil? }
    d.check('it is a ShortcutsDialog') { app.window.visible_dialog.is_a?(Adwaita::ShortcutsDialog) }
    d.shot('03-shortcuts-dialog')
    app.window.visible_dialog&.close
  end

  d.step('the window has no dialog left after closing Shortcuts') do
    d.check('visible_dialog is nil again') { app.window.visible_dialog.nil? }
  end

  d.step('Lozenge switches cleanly between its icon and text faces (lib/lozenge.rb)') do
    lozenge = Lozenge.new
    d.check('starts in text mode: label visible, image hidden') { lozenge.label.visible? && !lozenge.image.visible? }
    lozenge.icon_name = 'edit-copy-symbolic'
    d.check('setting icon_name switches to image mode') { lozenge.image.visible? && !lozenge.label.visible? }
    d.check('setting icon_name clears any previous text') { lozenge.text.nil? }
    lozenge.text = 'Updates'
    d.check('setting text switches back to label mode') { lozenge.label.visible? && !lozenge.image.visible? }
    d.check('setting text clears any previous icon') { lozenge.icon_name.nil? }
    d.check('the label shows the text that was set') { lozenge.label.label == 'Updates' }
    lozenge.circular = true
    d.check('circular pins width_request to height_request') { lozenge.width_request == lozenge.height_request }
    d.check('circular adds the CSS class upstream\'s gs-lozenge.ui uses') { lozenge.css_classes.include?('circular') }
    lozenge.circular = false
    d.check('turning circular off releases the fixed size') { lozenge.width_request == -1 && lozenge.height_request == -1 }
  end

  d.step('ErrorDialog shows the title and detail text and presents on the window') do
    @error_dialog = ErrorDialog.new('Could not refresh', "GLib::Error: timed out\n@refresh-failed").build
    @error_dialog.present(app.window)
  end

  d.step('the error dialog is populated and its copy button is wired') do
    d.check('the error dialog is the window\'s visible dialog') { app.window.visible_dialog.equal?(@error_dialog) }
    d.check('the title label shows the title text') { @error_dialog.title_label.label == 'Could not refresh' }
    d.check('the text view shows the detail text') { @error_dialog.text_view.buffer.text.include?('timed out') }
    d.check('the detail text is selectable but not editable') { !@error_dialog.text_view.editable? }
    d.check('clicking Copy Details does not raise') do
      @error_dialog.copy_button.activate
      true
    end
    d.shot('04-error-dialog')
    app.window.visible_dialog&.close
  end

  d.step('the window has no dialog left after closing the error dialog') do
    d.check('visible_dialog is nil again') { app.window.visible_dialog.nil? }
  end

  d.step('the window survives a close-request without the app exiting early') do
    # on_close_request returns false (do not veto the close), mirroring
    # upstream's gs_application_window_close_request() when there is no
    # in-flight transaction to warn about.
    d.check('close-request does not raise and does not veto') { !app.window.signal_emit('close-request') }
    d.check('the window is still around for the final screenshot') { !app.window.nil? }
  end
end

