# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'gnome_software'

app = Gtk::Application.new('org.example.drivewidgets', :default_flags)
app.signal_connect('activate') do
  window = Gtk::ApplicationWindow.new(app)

  pb = ProgressButton.new
  pb.label_text = 'Install'
  pb.show_progress = true
  pb.progress = 42
  pb.show_icon = true
  pb.icon_name = 'folder-symbolic'
  puts "ProgressButton ok, label_text=#{pb.label_text.inspect} icon_name=#{pb.icon_name.inspect}"

  row = ContextDialogRow.new_icon('dialog-warning-symbolic', :warning, 'Title', 'Description')
  puts "ContextDialogRow ok, importance=#{row.importance.inspect} title=#{row.title.inspect}"

  banner = UpdatesPausedBanner.new
  banner.updates_paused_flags = [:metered]
  puts "UpdatesPausedBanner ok, revealed=#{banner.banner.revealed?} title=#{banner.banner.title}"
  banner.updates_paused_flags = [:metered, :power_saver]
  puts "UpdatesPausedBanner multi ok, title=#{banner.banner.title} button_label=#{banner.banner.button_label}"

  bar = ReviewBar.new
  bar.fraction = 0.5
  puts "ReviewBar ok, fraction=#{bar.fraction}"

  box = DescriptionBox.new
  box.text = (['Line'] * 20).join("\n")
  window.child = Gtk::Box.new(:vertical, 4).tap do |b|
    b.append(pb)
    b.append(row)
    b.append(banner)
    b.append(bar)
    b.append(box)
  end
  window.present
  box.recalculate
  puts "DescriptionBox ok, button visible=#{box.button.visible?} collapsed=#{box.collapsed?}"

  GLib::Timeout.add(300) do
    app.quit
    false
  end
end
app.run([])
puts 'ALL WIDGETS DROVE OK'
