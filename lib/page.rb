# frozen_string_literal: true

require 'gtk4'

# Page is the abstract base every top-level and sub page extends, ported
# from upstream's src/gs-page.c / src/gs-page.h.
#
# Upstream derives GsPage from GtkWidget and gives it install/remove/launch
# helpers that run a plugin-loader job and show the shared "reboot required"
# / "no space" / "needs login" follow-up UI, plus a vfunc table
# (switch_to/switch_from/reload/setup) each page subclass overrides. This
# port keeps the same shape as a plain Ruby class rather than a GObject
# subclass: a page is composed into the shell's view stack as whatever
# widget #root returns, and the shell drives it through the same lifecycle
# methods.
class Page
  attr_accessor :header_start_widget, :header_end_widget
  attr_reader :shell

  def initialize(shell)
    @shell = shell
    @active = false
  end

  # gs_page_get_title(): the AdwViewStack page title. Subclasses override.
  def title
    raise NotImplementedError, "#{self.class} must implement #title"
  end

  # The root widget the shell adds to its view stack. Subclasses override.
  def root
    raise NotImplementedError, "#{self.class} must implement #root"
  end

  # gs_page_switch_to(): called when the shell navigates to this page.
  def switch_to
    @active = true
  end

  # gs_page_switch_from(): called when the shell navigates away.
  def switch_from
    @active = false
  end

  # gs_page_reload(): refetch and redisplay this page's content.
  def reload; end

  # gs_page_is_active()
  def active? = @active

  # gs_page_install_app() / gs_page_remove_app() / gs_page_update_app() /
  # gs_page_launch_app(): the shared app-lifecycle actions every page can
  # trigger from a row or a details view. Each one delegates to the shell,
  # which owns the single plugin-loader job queue and the shared
  # reboot/no-space/login follow-up dialogs upstream's gs-page.c shows after
  # the job completes.
  def install_app(app) = shell.install_app(app)
  def remove_app(app) = shell.remove_app(app)
  def update_app(app) = shell.update_app(app)
  def launch_app(app) = shell.launch_app(app)
end
