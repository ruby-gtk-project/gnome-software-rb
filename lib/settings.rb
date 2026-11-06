# frozen_string_literal: true

require 'json'
require 'fileutils'

# Settings holds the same keys as upstream's org.gnome.software GSettings
# schema, data/org.gnome.software.gschema.xml (plus its "auth" child schema,
# folded in here under the "auth." prefix).
#
# Upstream uses GSettings, which needs its schema compiled into the system's
# glib-2.0/schemas directory before the app can even start. Requiring that
# install step to run the port from a checkout is worse than the alternative,
# so the same keys, types and defaults are backed by a small JSON file under
# XDG_CONFIG_HOME instead.
class Settings
  DEFAULTS = {
    'compatible-projects'                     => %w[GNOME KDE XFCE],
    'allow-updates'                           => true,
    'download-updates'                        => true,
    'download-updates-notify'                 => true,
    'refresh-when-metered'                    => false,
    'first-run'                               => true,
    'show-ratings'                            => false,
    'filter-default-branch'                   => true,
    'prompt-for-nonfree'                      => true,
    'check-timestamp'                         => 0,
    'upgrade-notification-timestamp'          => 0,
    'update-notification-timestamp'           => 0,
    'security-timestamp'                      => 0,
    'install-timestamp'                       => 0,
    'screenshot-cache-age-maximum'            => 2_592_000,
    'review-server'                           => 'https://odrs.gnome.org/1.0/reviews/api',
    'review-karma-required'                   => 0,
    'official-repos'                          => [],
    'required-repos'                          => [],
    'free-repos'                              => [],
    'free-repos-url'                          => '',
    'install-bundles-system-wide'             => true,
    'enable-repos-dialog'                     => true,
    'show-upgrade-prerelease'                 => false,
    'show-nonfree-ui'                         => true,
    'installed-page-show-size'                => true,
    'nonfree-software-uri'                    => 'https://en.wikipedia.org/wiki/Proprietary_software',
    'external-appstream-urls'                 => [],
    'external-appstream-system-wide'          => false,
    'packaging-format-preference'             => [''],
    'flatpak-purge-timestamp'                 => 0,
    'show-only-free-apps'                     => false,
    'show-only-verified-apps'                 => false,
    'packagekit-historical-updates-timestamp' => 0,
    'auth.account-id'                         => '',
  }.freeze

  def initialize(path: nil)
    @path = path || default_path
    @values = DEFAULTS.merge(read)
  end

  def [](key) = @values.fetch(key.to_s, DEFAULTS[key.to_s])

  def []=(key, value)
    @values[key.to_s] = value
    write
    value
  end

  def location = @path

  # Named accessors for every key, so callers do not repeat the string keys:
  # 'allow-updates' becomes #allow_updates / #allow_updates= / #allow_updates?
  # (the boolean-only predicate), 'auth.account-id' becomes #auth_account_id.
  DEFAULTS.each_key do |key|
    method_name = key.tr('-', '_').tr('.', '_')
    define_method(method_name) { self[key] }
    define_method(:"#{method_name}=") { |value| self[key] = value }
    if DEFAULTS[key] == true || DEFAULTS[key] == false
      define_method(:"#{method_name}?") { self[key] == true }
    end
  end

  private

    def default_path
      File.join(
        ENV.fetch('XDG_CONFIG_HOME', File.expand_path('~/.config')),
        'gnome-software-rb',
        'settings.json',
      )
    end

    def read
      File.exist?(@path) ? JSON.parse(File.read(@path)) : {}
    rescue JSON::ParserError => e
      warn "Error parsing #{@path}: #{e.message}"
      {}
    end

    def write
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, JSON.pretty_generate(@values))
    end
end
