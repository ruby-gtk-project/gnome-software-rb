# frozen_string_literal: true

require 'gtk4'

# Common holds the module-level utility functions ported from upstream's
# src/gs-common.c / src/gs-common.h. Only the pure, UI-framework-agnostic
# helpers and the ones this port actually needs are ported; the rest
# (app data dirs, reboot plumbing, bus policy formatting) belong with the
# plugin/backend layer this round does not reach yet.
module Common
  # gs_utils_split_time_difference(): the difference between now and
  # +unix_time_seconds+, split into minutes/hours/days/weeks/months/years
  # ago. Returns nil for a non-positive timestamp, exactly as upstream does.
  def self.split_time_difference(unix_time_seconds)
    if unix_time_seconds.nil? || unix_time_seconds <= 0
      nil
    else
      minutes_ago = ((Time.now - Time.at(unix_time_seconds)) / 60).to_i
      hours_ago = minutes_ago / 60
      days_ago = hours_ago / 24
      weeks_ago = days_ago / 7
      months_ago = days_ago / 30
      years_ago = weeks_ago / 52
      {
        minutes_ago: minutes_ago,
        hours_ago:   hours_ago,
        days_ago:    days_ago,
        weeks_ago:   weeks_ago,
        months_ago:  months_ago,
        years_ago:   years_ago,
      }
    end
  end

  # gs_utils_time_to_datestring(): a day-accurate relative date, e.g.
  # "Today", "Yesterday", "5 days ago", "2 weeks ago", "3 months ago",
  # "1 year ago".
  def self.time_to_datestring(unix_time_seconds)
    split_time_difference(unix_time_seconds).then do |diff|
      diff && split_time_to_datestring(diff)
    end
  end

  # gs_utils_time_to_timestring(): a minute-accurate relative time, e.g.
  # "Just now", "5 minutes ago", "3 hours ago", else falls back to the
  # day-accurate string above.
  def self.time_to_timestring(unix_time_seconds)
    split_time_difference(unix_time_seconds).then do |diff|
      if diff.nil?
        nil
      elsif diff[:minutes_ago] < 5
        'Just now'
      elsif diff[:hours_ago] < 1
        pluralize(diff[:minutes_ago], 'minute')
      elsif diff[:days_ago] < 1
        pluralize(diff[:hours_ago], 'hour')
      else
        split_time_to_datestring(diff)
      end
    end
  end

  def self.split_time_to_datestring(diff)
    if diff[:days_ago] < 1
      'Today'
    elsif diff[:days_ago] < 2
      'Yesterday'
    elsif diff[:days_ago] < 15
      pluralize(diff[:days_ago], 'day')
    elsif diff[:weeks_ago] < 8
      pluralize(diff[:weeks_ago], 'week')
    elsif diff[:years_ago] < 1
      pluralize(diff[:months_ago], 'month')
    else
      pluralize(diff[:years_ago], 'year')
    end
  end
  private_class_method :split_time_to_datestring

  def self.pluralize(count, unit)
    if count == 1
      "#{count} #{unit} ago"
    else
      "#{count} #{unit}s ago"
    end
  end
  private_class_method :pluralize

  # gs_utils_format_size(): a human size, e.g. "13.0 MB". The upstream
  # markup-splitting variant is a display nicety this port does not need;
  # callers get the same string GLib's own g_format_size() would produce.
  def self.format_size(size_bytes)
    units = %w[bytes kB MB GB TB PB]
    size_bytes.then do |bytes|
      if bytes < 1000
        "#{bytes} bytes"
      else
        exponent = (Math.log(bytes, 1000)).floor.clamp(1, units.length - 1)
        value = bytes.to_f / (1000**exponent)
        format('%<value>.1f %<unit>s', value: value, unit: units[exponent])
      end
    end
  end

  # gs_utils_get_error_value(): the machine-readable suffix GLib::Error
  # messages sometimes carry after an "@", e.g.
  # "Requires authentication with @provider-id" -> "provider-id".
  def self.error_value(error)
    error&.message.to_s.then do |message|
      index = message.index('@')
      index && message[(index + 1)..]
    end
  end

  # gs_show_uri(): launches the default handler for +uri+, logging instead
  # of raising if the launch fails (there is no parent window to put an
  # error dialog on in every caller).
  def self.show_uri(parent, uri)
    Gtk::UriLauncher.new(uri).launch(parent, nil) do |launcher, result|
      launcher.launch_finish(result)
    rescue GLib::Error => e
      warn "Could not show #{uri}: #{e.message}"
    end
  end

  # gs_utils_is_current_desktop(): whether +name+ appears in
  # $XDG_CURRENT_DESKTOP, which upstream uses to gate desktop-specific UI
  # (e.g. only offering GNOME Online Accounts integration under GNOME).
  def self.current_desktop?(name)
    ENV.fetch('XDG_CURRENT_DESKTOP', '').split(':').include?(name)
  end
end
