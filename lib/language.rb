# frozen_string_literal: true

require 'libxmlb'
require 'gio2'

# Language is ported from upstream's src/gs-language.c / src/gs-language.h:
# it parses iso-codes' iso_639.xml into an ISO 639-1/639-2B code -> English
# language name lookup table, used to turn an app's content-rating or
# metadata language code into a human-readable name.
#
# Upstream's gs_language_parser_start_element() reads three attributes off
# each <iso_639_entry> element (iso_639_1_code, iso_639_2B_code, name) and
# inserts the name under both codes present. #populate mirrors that with the
# `libxmlb` gem: it builds an Xmlb::Silo over iso_639.xml (the same binary
# silo format AppStream itself uses as its backing store, see the gemspec)
# and queries it for each <iso_639_entry/>, rather than scanning the file
# with a hand-rolled regex — there used to be no XML-capable gem in this
# port's runtime closure, but `libxmlb` is one of the declared dependencies
# and is exactly the library upstream's own AppStream/Xmlb stack is built on.
class Language
  # The same search path gs_language_populate() walks, stopping at the
  # first file that exists: the configured DATADIR, then the BSD/pkgsrc
  # fallbacks it tries in order.
  SEARCH_PATHS = [
    '/usr/share/xml/iso-codes/iso_639.xml',
    '/usr/local/share/xml/iso-codes/iso_639.xml',
    '/usr/pkg/share/xml/iso-codes/iso_639.xml',
  ].freeze

  QUERY = 'iso_639_entries/iso_639_entry'

  def initialize
    @hash = {}
  end

  # gs_language_populate(): parses the first iso_639.xml found on
  # SEARCH_PATHS into the lookup table. Returns false (and leaves the
  # table empty) when no such file exists, matching upstream's boolean
  # return rather than raising.
  def populate
    filename = SEARCH_PATHS.find { |path| File.exist?(path) }
    if filename
      each_entry(build_silo(filename)) { |node| index_entry(node) }
      true
    else
      false
    end
  end

  # gs_language_iso639_to_language(): the English name for +iso639+ (an
  # ISO 639-1 or 639-2B code), or nil when it is not in the table.
  def iso639_to_language(iso639) = @hash[iso639]

  private

    # Compiles +filename+ into an in-memory Xmlb::Silo, exactly the
    # Builder/BuilderSource/compile sequence AppStream's own Xmlb-backed
    # cache uses, just without writing the compiled silo back to disk —
    # this table is rebuilt once per process, same as upstream's GMarkup
    # parse.
    def build_silo(filename)
      source = Xmlb::BuilderSource.new
      source.load_file(Gio::File.new_for_path(filename), Xmlb::BuilderSourceFlags::NONE, nil)

      builder = Xmlb::Builder.new
      builder.import_source(source)
      builder.compile(Xmlb::BuilderCompileFlags::IGNORE_INVALID, nil)
    end

    # Xmlb::Silo#query returns a GPtrArray of Xmlb::Node, which this gem's
    # GObject-Introspection loader cannot marshal back to Ruby (ptr-array
    # return values raise NotImplementedError); walking the result with
    # #query_first + Xmlb::Node#next, which only ever crosses the loader one
    # node at a time, avoids that entirely.
    def each_entry(silo)
      node = silo.query_first(QUERY)
      while node
        yield node
        node = node.next
      end
    end

    def index_entry(node)
      name = node.get_attr('name')
      if name
        code_1 = node.get_attr('iso_639_1_code')
        code_2b = node.get_attr('iso_639_2B_code')
        if code_1
          @hash[code_1] = name
        end
        if code_2b
          @hash[code_2b] = name
        end
      end
    end
end
