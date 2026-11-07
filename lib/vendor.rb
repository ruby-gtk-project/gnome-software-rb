# frozen_string_literal: true

require 'glib2'

# Vendor is ported from upstream's src/gs-vendor.c / src/gs-vendor.h: a
# thin reader over /etc/PackageKit/Vendor.conf's "PackagesNotFound" group,
# used to pick a distro-branded URL to send the user to when a codec, font,
# MIME handler or piece of hardware support could not be found.
#
# Upstream only reads the file when built with PackageKit support
# (`HAVE_PACKAGEKIT`); this port always has the `packagekit-glib` gem
# available, so #initialize always attempts the read, exactly like the
# `HAVE_PACKAGEKIT` branch of gs_vendor_init().
class Vendor
  CONF_PATH = '/etc/PackageKit/Vendor.conf'

  # gs_vendor_type_to_string(): the GKeyFile key for each URL type,
  # matched 1:1 against upstream's GsVendorUrlType enum order.
  TYPE_KEYS = {
    codec:    'CodecUrl',
    font:     'FontUrl',
    mime:     'MimeUrl',
    hardware: 'HardwareUrl',
    default:  'DefaultUrl',
  }.freeze

  GROUP = 'PackagesNotFound'

  def initialize(conf_path = CONF_PATH)
    @conf_path = conf_path
    @key_file = GLib::KeyFile.new
    load_key_file
  end

  # gs_vendor_get_not_found_url(): the branded URL for +type+ (one of
  # TYPE_KEYS' keys), falling back to the :default URL when +type+ itself
  # has none configured, and treating the literal value "none" as "no URL"
  # at both levels exactly as upstream does.
  def not_found_url(type)
    key = TYPE_KEYS.fetch(type) { raise ArgumentError, "unknown vendor URL type: #{type.inspect}" }
    url = none_is_nil(lookup(key))

    if url || type == :default
      url
    else
      none_is_nil(lookup(TYPE_KEYS[:default]))
    end
  end

  private

  def load_key_file
    @key_file.load_from_file(@conf_path, GLib::KeyFile::NONE)
  rescue GLib::ErrorInfo, Errno::ENOENT
    # gs_vendor_init(): a missing file is silently tolerated; any other
    # failure upstream only logs a warning for, so it is not fatal here
    # either.
  end

  def lookup(key)
    @key_file.get_string(GROUP, key)
  rescue GLib::ErrorInfo
    nil
  end

  def none_is_nil(url) = (url == 'none' ? nil : url)
end
