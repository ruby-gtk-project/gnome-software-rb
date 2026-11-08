# frozen_string_literal: true

# Drives the five widgets the port added after drive_gnome_software.rb was
# written (ProgressButton, ContextDialogRow, UpdatesPausedBanner, ReviewBar,
# DescriptionBox) the same way that script drives the application: build a
# real window, host each widget in it, exercise its public API through a
# GtkDriver step and assert the observable result — not just "it didn't
# raise". None of these widgets are wired into a real page yet (no
# Explore/Installed/Updates page stack exists on this branch), so this is
# the most real a drive of them can be: standalone, inside a mapped window,
# screenshotted.
#
# Run it from the repository root:
#
#   nix develop --command xvfb-run -a ruby test/drive_new_widgets.rb

require 'fileutils'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'gnome_software'
require_relative 'gtk_driver'

SHOTS = File.expand_path('../tmp/shots', __dir__)

# A minimal object answering `#build` (the house `App.new.build.run` shape
# GtkDriver expects) so these widgets get the same real GTK main loop,
# windowing and screenshot plumbing drive_gnome_software.rb uses, without
# needing a second full Application.
#
# The window is built and presented synchronously inside the app's own
# `activate` handler, not from the first GtkDriver step: GtkApplication
# drops its use-count (and the whole main loop) the instant `activate`
# returns with no window yet registered, so a step-0 `Gtk::ApplicationWindow.new`
# never gets a tick to run at all — it has to exist before `activate` returns,
# exactly like `GnomeSoftware::Application#build` already does.
class WidgetsHarness
  attr_reader :window

  def build
    @app ||= Gtk::Application.new('org.example.drivewidgets', :default_flags).tap do |app|
      app.signal_connect('activate') do
        # Adwaita::ApplicationWindow, not a bare Gtk::ApplicationWindow,
        # because UpdatesPausedBanner's Details button presents an
        # Adwaita::AlertDialog on `root`, and only Adw.ApplicationWindow
        # exposes #visible_dialog to assert that against.
        @window = Adwaita::ApplicationWindow.new(app)
        @window.set_default_size(800, 600)
        @window.present
      end
    end
  end
end

GtkDriver.drive(WidgetsHarness.new, shots: SHOTS) do |d, harness|
  d.window { harness.window }

  d.step('a host window is built for the widgets under test') do
    @window = harness.window
    @progress_button = ProgressButton.new
    @context_row = ContextDialogRow.new_icon('dialog-warning-symbolic', :warning, 'Hardware support', 'Needs a touchscreen')
    @banner = UpdatesPausedBanner.new
    @review_bar = ReviewBar.new
    @description_box = DescriptionBox.new
    @window.content = Gtk::Box.new(:vertical, 4).tap do |box|
      box.append(@progress_button)
      box.append(@context_row)
      box.append(@banner)
      box.append(@review_bar)
      box.append(@description_box)
    end
    @window.present
  end

  d.step('ProgressButton switches between label and icon faces and renders a progress fill (lib/progress_button.rb)') do
    @progress_button.label_text = 'Install'
    d.check('starts in label mode') { @progress_button.stack.visible_child.equal?(@progress_button.label) }
    d.check('the label shows the text that was set') { @progress_button.label.label == 'Install' }
    @progress_button.icon_name = 'folder-symbolic'
    @progress_button.show_icon = true
    d.check('show_icon switches the stack to the image child') { @progress_button.stack.visible_child.equal?(@progress_button.image) }
    d.check('show_icon swaps text-button for image-button') { @progress_button.css_classes.include?('image-button') && !@progress_button.css_classes.include?('text-button') }
    @progress_button.show_progress = true
    d.check('show_progress adds the install-progress CSS class') { @progress_button.css_classes.include?('install-progress') }
    @progress_button.progress = 42
    d.check('setting a numeric progress does not raise') { true }
    @progress_button.progress = :unknown
    d.check('an unknown progress does not raise either') { true }
    @progress_button.show_progress = false
    d.check('show_progress removes the CSS class again') { !@progress_button.css_classes.include?('install-progress') }
  end

  d.step('ContextDialogRow colours its Lozenge prefix by importance (lib/context_dialog_row.rb)') do
    d.check('importance starts as :warning, per new_icon') { @context_row.importance == :warning }
    d.check('the lozenge carries the orange CSS class for :warning') { @context_row.lozenge.css_classes.include?('orange') }
    d.check('the row title is the title text') { @context_row.title == 'Hardware support' }
    d.check('the row subtitle is the description text') { @context_row.subtitle == 'Needs a touchscreen' }
    @context_row.importance = :important
    d.check('changing importance to :important swaps the CSS class to red') { @context_row.lozenge.css_classes.include?('red') }
    d.check('and drops the old :warning class') { !@context_row.lozenge.css_classes.include?('orange') }
  end

  d.step('UpdatesPausedBanner reveals a single-reason title with no Details button (lib/updates_paused_banner.rb)') do
    @banner.updates_paused_flags = [:metered]
    d.check('the banner is revealed') { @banner.banner.revealed? }
    d.check('a single reason gets its own titled message') { @banner.banner.title == 'Network connection is metered — software updates paused' }
    d.check('a single reason has no Details button') { @banner.banner.button_label.nil? }
    d.shot('05-updates-paused-single')
  end

  d.step('two reasons collapse to a generic title plus a Details button that opens an AlertDialog') do
    @banner.updates_paused_flags = %i[metered power_saver]
    d.check('the title becomes the generic multi-reason message') { @banner.banner.title == 'Software updates paused' }
    d.check('the button label is Details') { @banner.banner.button_label == 'Details' }
    @banner.banner.signal_emit('button-clicked')
  end

  d.step('clicking Details presents an AlertDialog listing both reasons') do
    dialog = @window.visible_dialog
    d.check('a dialog is showing') { !dialog.nil? }
    d.check('it is the paused-reasons AlertDialog') { dialog.is_a?(Adwaita::AlertDialog) }
    d.check('its body names both paused reasons') do
      body = dialog.extra_child.label
      body.include?('metered') && body.include?('Power saver')
    end
    d.shot('06-updates-paused-details')
    dialog&.close
  end

  d.step('clearing the flags hides the banner again') do
    @banner.updates_paused_flags = []
    d.check('the banner is no longer revealed') { !@banner.banner.revealed? }
  end

  d.step('ReviewBar fills left-to-right by fraction, clamped to [0, 1] (lib/review_bar.rb)') do
    @review_bar.fraction = 0.5
    d.check('fraction reads back exactly what was set') { @review_bar.fraction == 0.5 }
    @review_bar.fraction = 1.5
    d.check('a fraction above 1.0 clamps to 1.0') { @review_bar.fraction == 1.0 }
    @review_bar.fraction = (-0.5)
    d.check('a negative fraction clamps to 0.0') { @review_bar.fraction.zero? }
  end

  d.step('DescriptionBox collapses long text and expands it on button click (lib/description_box.rb)') do
    long_text = (['A line of description text that stays short.'] * 20).join("\n")
    @description_box.text = long_text
    @description_box.recalculate
    d.check('a long description shows the Show More button') { @description_box.button.visible? }
    d.check('it starts collapsed') { @description_box.collapsed? }
    d.check('the button reads _Show More while collapsed') { @description_box.button.label == '_Show More' }
    @description_box.button.signal_emit('clicked')
    d.check('clicking the button expands it') { !@description_box.collapsed? }
    d.check('the button now reads _Show Less') { @description_box.button.label == '_Show Less' }
    d.shot('07-description-box-expanded')
  end

  d.step('a short DescriptionBox text hides the Show More button entirely') do
    # Appended into the real, already-presented window rather than measured
    # standalone: an unparented widget has no real allocated width yet, so
    # #recalculate's line count is meaningless noise (observed: wrapping one
    # character per line) instead of the few real lines "One short line."
    # actually takes once laid out at the window's real width. GTK only
    # performs that layout between main-loop ticks, so the check itself runs
    # on the *next* step, after a tick has passed and sizing has settled.
    @short_box = DescriptionBox.new
    @window.content.append(@short_box)
    @short_box.text = 'One short line.'
  end

  d.step('...once a tick has passed to actually allocate it') do
    @short_box.recalculate
    d.check('a short description has no toggle button') { !@short_box.button.visible? }
  end

  d.step('an empty DescriptionBox text hides the label and stays inert') do
    empty_box = DescriptionBox.new
    empty_box.text = ''
    d.check('an empty text hides the whole box') { !empty_box.visible? }
  end

  d.step('a final screenshot shows all five widgets together') do
    d.shot('08-all-widgets')
  end
end
