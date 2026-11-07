# frozen_string_literal: true

# Language is ported from upstream's src/gs-language.c / src/gs-language.h:
# it parses iso-codes' iso_639.xml into an ISO 639-1/639-2B code -> English
# language name lookup table, used to turn an app's content-rating or
# metadata language code into a human-readable name.
#
# Upstream's gs_language_parser_start_element() reads three attributes off
# each <iso_639_entry> element (iso_639_1_code, iso_639_2B_code, name) and
# inserts the name under both codes present. #populate mirrors that with a
# small attribute scanner rather than a full XML library: the gem runtime
# closure (see the gemspec) carries no general-purpose XML parser, and
# iso_639.xml's handful of self-closing, flatly-attributed
# <iso_639_entry .../> elements is exactly the shape GMarkup itself only
# ever needed to handle.
class Language
  # The same search path gs_language_populate() walks, stopping at the
  # first file that exists: the configured DATADIR, then the BSD/pkgsrc
  # fallbacks it tries in order.
  SEARCH_PATHS = [
    '/usr/share/xml/iso-codes/iso_639.xml',
    '/usr/local/share/xml/iso-codes/iso_639.xml',
    '/usr/pkg/share/xml/iso-codes/iso_639.xml',
  ].freeze

  def initialize
    @hash = {}
  end

  # gs_language_populate(): parses the first iso_639.xml found on
  # SEARCH_PATHS into the lookup table. Returns false (and leaves the
  # table empty) when no such file exists, matching upstream's boolean
  # return rather than raising.
  ENTRY_PATTERN = /<iso_639_entry\b([^>]*)\/?>/
  ATTR_PATTERN = /(\w[\w-]*)\s*=\s*"([^"]*)"/

  def populate
    filename = SEARCH_PATHS.find { |path| File.exist?(path) }
    return false unless filename

    File.read(filename).scan(ENTRY_PATTERN) do |(attrs)|
      entry = attrs.to_enum(:scan, ATTR_PATTERN).to_h { |key, value| [key, value] }
      name = entry['name']
      next unless name

      @hash[entry['iso_639_1_code']] = name if entry['iso_639_1_code']
      @hash[entry['iso_639_2B_code']] = name if entry['iso_639_2B_code']
    end

    true
  end

  # gs_language_iso639_to_language(): the English name for +iso639+ (an
  # ISO 639-1 or 639-2B code), or nil when it is not in the table.
  def iso639_to_language(iso639) = @hash[iso639]
end
