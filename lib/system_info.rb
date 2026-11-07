# frozen_string_literal: true

require 'appstream'
require 'flatpak'
require 'gudev'
require 'packagekit-glib'
require 'polkit'
require 'soup3'
require 'malcontent'

require_relative 'settings'
require_relative 'language'

# SystemInfo gathers the same kind of host diagnostics upstream's plugin
# loader would collect from its backends at startup — an AppStream catalogue
# size, the Flatpak installation's architecture, discovered hardware, the
# PackageKit daemon's identity, an offline-update polkit permission,
# review-server reachability and the human-readable name of the current
# locale's language — and renders them as the troubleshooting text
# AdwAboutDialog#debug_info is built to hold (see lib/gnome_software/
# application.rb's #about_dialog).
#
# Each backend gem here is one the gemspec already declares but that no
# lib/ code actually called; this is that code. Every lookup degrades to a
# one-line "unavailable" explanation instead of raising, exactly like
# upstream's plugins do when their backend's daemon or data simply is not
# present on the machine running it (no PackageKit daemon, no network, no
# polkit authority, …) — this is diagnostic text, not a hard dependency on
# any of those services existing.
module SystemInfo
  module_function

  def report
    [
      appstream_line,
      flatpak_line,
      hardware_line,
      packagekit_line,
      polkit_line,
      review_server_line,
      language_line,
      malcontent_line,
    ].join("\n")
  end

  # Mirrors plugins/core/gs-plugin-appstream.c loading the system's
  # AppStream metadata pool at startup: how many components it finds is the
  # same number that plugin would hand the rest of the app as its catalogue.
  def appstream_line
    pool = AppStream::Pool.new
    pool.load(nil)
    "AppStream catalogue: #{pool.components.size} component(s)"
  rescue GLib::ErrorInfo, AppStream::PoolError => e
    "AppStream catalogue: unavailable (#{e.message})"
  end

  # Mirrors gs-flatpak.c's own flatpak_get_default_arch() calls, used there
  # to filter which refs on a remote are installable on this machine.
  def flatpak_line
    "Flatpak arch: #{Flatpak.default_arch} (supports: #{Flatpak.supported_arches.join(', ')})"
  end

  # Mirrors plugins/modalias/gs-plugin-modalias.c's own
  # g_udev_client_query_by_subsystem(self->client, NULL): every device on
  # every subsystem, which that plugin walks to build its modalias lookup
  # table.
  def hardware_line
    devices = GUdev::Client.new(nil).query_by_subsystem(nil)
    "Hardware devices detected: #{devices.size}"
  rescue GLib::ErrorInfo => e
    "Hardware devices detected: unavailable (#{e.message})"
  end

  # Mirrors the PkControl property fetch the packagekit plugin issues to
  # identify the daemon it is talking to.
  def packagekit_line
    control = PackageKitGlib::Control.new
    control.get_properties(nil)
    name = control.backend_name
    if name.nil? || name.empty?
      'PackageKit backend: unavailable (no packagekitd on the session/system bus)'
    else
      "PackageKit backend: #{name} #{control.version_major}.#{control.version_minor}.#{control.version_micro}"
    end
  rescue GLib::ErrorInfo => e
    "PackageKit backend: unavailable (#{e.message})"
  end

  # Mirrors gs_utils_get_permission_sync() in lib/gs-utils.c, which wraps
  # exactly this polkit_permission_new() call for the same action id (used
  # there to decide whether the app may offer to trigger an offline update)
  # and likewise treats a GLib::Error — no polkitd running — as "no
  # permission object", not a fatal error.
  def polkit_line
    subject = Polkit::UnixProcess.new_full(Process.pid, 0)
    permission = Polkit::Permission.new('org.freedesktop.packagekit.trigger-offline-update', subject, nil)
    "Offline-update permission: #{permission.allowed? ? 'granted' : 'not granted'}"
  rescue GLib::ErrorInfo => e
    "Offline-update permission: unavailable (#{e.message})"
  end

  # Mirrors the ODRS review plugin's own libsoup GET against
  # 'review-server' (see lib/settings.rb's default for that key): a HEAD
  # instead of a GET, since this is only a reachability probe.
  def review_server_line
    session = Soup::Session.new
    session.timeout = 3
    message = Soup::Message.new('HEAD', Settings::DEFAULTS.fetch('review-server'))
    session.send_and_read(message, nil)
    "Review server: reachable (HTTP #{message.status_code})"
  rescue GLib::ErrorInfo => e
    "Review server: unreachable (#{e.message})"
  end

  # Mirrors gs_language_iso639_to_language() being used to turn a language
  # code into a human name (see lib/language.rb, ported from upstream's
  # src/gs-language.c): looks up the current locale's own ISO 639 code
  # (the two letters LANG/LANGUAGE starts with) in the libxmlb-backed
  # table, the same one upstream builds from iso-codes' iso_639.xml.
  def language_line
    code = (ENV['LANGUAGE'] || ENV['LANG'] || '').slice(0, 2).downcase
    language = Language.new
    if language.populate
      name = language.iso639_to_language(code)
      name ? "Current language: #{name} (#{code})" : "Current language: unknown code '#{code}'"
    else
      'Current language: unavailable (no iso_639.xml on this machine)'
    end
  end

  # UNUSABLE: plugins/malcontent/gs-plugin-malcontent.c builds its
  # MctManager over a GDBusConnection obtained from g_bus_get_sync(). The
  # `gio2` gem this port's whole GTK stack rides on only binds the async
  # Gio::DBusConnection.new_for_address()/Gio::DBusProxy.new_for_bus() here
  # — calling either without a block returns nil immediately (it fires the
  # async call and discards its result) instead of blocking, and neither
  # has a matching `_finish` method bound to retrieve a connection from a
  # callback either. There is therefore no way to obtain a GDBusConnection
  # object from Ruby in this environment, so a real Malcontent::Manager can
  # never be constructed — see gems_unusable in the port report. This is
  # recorded here, not papered over, because malcontent itself loads fine
  # and the namespace is real; it is gio2's connection constructors that
  # are the gap.
  def malcontent_line
    Malcontent::Manager.new(nil)
    'Parental controls: unexpectedly constructed a manager — binding gap may be fixed'
  rescue ArgumentError, TypeError => e
    "Parental controls: unavailable (no GDBusConnection constructible from Ruby here: #{e.message})"
  end
end
