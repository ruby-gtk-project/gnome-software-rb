# frozen_string_literal: true

require 'adwaita'

# UpdatesPausedBanner is ported from upstream's src/gs-updates-paused-banner.c
# / src/gs-updates-paused-banner.h: an Adw.Bin wrapping a single Adw.Banner
# that explains why automatic updates are paused (metered connection, large
# downloads prohibited, power saver, game mode) and, when more than one
# reason applies, offers a "Details" button that opens an Adw.AlertDialog
# listing every reason.
#
# Upstream represents the reasons as a bitmask (GsUpdatesPausedBannerFlags);
# this port uses a plain array of symbols from FLAGS below, which is the same
# set of reasons without hand-rolling bit twiddling the Ruby bindings have no
# need for.
class UpdatesPausedBanner < Adwaita::Bin
  FLAGS = %i[metered no_large_downloads power_saver game_mode].freeze

  TITLES = {
    metered: 'Network connection is metered — software updates paused',
    no_large_downloads: 'Network connection prohibits large downloads — software updates paused',
    power_saver: 'Power saver mode is active — software updates paused',
    game_mode: 'Game mode is active — software updates paused'
  }.freeze

  REASON_LINES = {
    metered: 'The current network connection is metered',
    no_large_downloads: 'The current network connection prohibits large downloads',
    power_saver: 'Power saver mode is active',
    game_mode: 'Game mode is active'
  }.freeze

  def initialize
    super()
    self.child = banner
    @updates_paused_flags = []
    banner.signal_connect('button-clicked') { show_details }
  end

  attr_reader :updates_paused_flags

  def updates_paused_flags=(flags)
    flags = Array(flags) & FLAGS
    return if flags == @updates_paused_flags

    @updates_paused_flags = flags

    if flags.empty?
      banner.revealed = false
    else
      update_banner_title
      banner.revealed = true
    end
  end

  # Memoized widget methods

  def banner = @banner ||= Adwaita::Banner.new('')

  private

    def update_banner_title
      if @updates_paused_flags.size > 1
        banner.button_label = 'Details'
        banner.title = 'Software updates paused'
      else
        banner.button_label = nil
        banner.title = TITLES.fetch(@updates_paused_flags.first)
      end
    end

    def show_details
      body = +"Automatic software updates have been paused for the following reasons:\n"
      FLAGS.each { |flag| body << "\n• #{REASON_LINES[flag]}" if @updates_paused_flags.include?(flag) }

      dialog = Adwaita::AlertDialog.new('Software Updates Paused', nil)
      dialog.extra_child = Gtk::Label.new(body).tap do |label|
        label.wrap = true
        label.wrap_mode = :word_char
        label.max_width_chars = 40
      end
      dialog.add_response('close', '_Close')
      dialog.present(root)
    end
end
