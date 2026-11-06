# frozen_string_literal: true

require 'adwaita'

# Toast builds the app's AdwToast instances, ported from upstream's
# src/gs-toast.c / src/gs-toast.h.
#
# Upstream's GsToast is a set of wrapper *functions* around AdwToast rather
# than a subclass, because AdwToast is a final type in GObject and cannot be
# derived from. The Ruby binding has the same restriction, so this is a
# module of factory methods rather than a class, exactly mirroring the shape
# upstream chose for the same reason.
module Toast
  NONE = :none
  NO_SPACE = :no_space
  RESTART_REQUIRED = :restart_required
  DETAILS_URI = :details_uri
  SHOW_APP_REVIEWS = :show_app_reviews

  BUTTON_LABELS = {
    NO_SPACE         => '_Examine',
    RESTART_REQUIRED => '_Restart',
    DETAILS_URI      => '_Details',
    SHOW_APP_REVIEWS => '_Show Review',
  }.freeze

  # gs_toast_new(): builds an AdwToast with no timeout (the caller dismisses
  # it, or the user does) and the given button, if any. A non-nil
  # +details_text+ implies the "_Details" button and must not be combined
  # with another +button+ value — exactly the precondition upstream asserts.
  def self.new_toast(title, button: NONE, details_message: nil, details_text: nil)
    if details_text && button != NONE
      raise ArgumentError, 'Toast: do not set both button and details text'
    end

    Adwaita::Toast.new(title).tap do |toast|
      toast.timeout = 0
      toast.instance_variable_set(:@gs_toast_button, button)
      toast.instance_variable_set(:@gs_toast_details_message, details_message)
      toast.instance_variable_set(:@gs_toast_details_text, details_text)

      if details_text
        toast.button_label = '_Details'
      elsif button != NONE
        toast.button_label = BUTTON_LABELS.fetch(button)
      end
    end
  end

  # gs_toast_get_button()
  def self.button(toast) = toast.instance_variable_get(:@gs_toast_button) || NONE

  # gs_toast_get_details_message()
  def self.details_message(toast) = toast.instance_variable_get(:@gs_toast_details_message)

  # gs_toast_get_details_text()
  def self.details_text(toast) = toast.instance_variable_get(:@gs_toast_details_text)
end
