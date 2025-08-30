  def add_apps_to_grid(apps)
    # Filter out nil apps
    apps = apps.compact
    
    # Add apps with staggered animation effect
    apps.each_with_index do |app, index|
      GLib::Timeout.add(index * 50) do
        app_widget = create_app_widget(app)
        app_widget.add_css_class('app-card-enter')
        @flow_box.append(app_widget)
        false
      end
    end
    
    # Show message if no apps found
    if apps.empty?
      no_results_box = Gtk::Box.new(:vertical, 20)
      no_results_box.add_css_class('no-results')
      no_results_box.halign = :center
      no_results_box.valign = :center
      
      no_results_icon = Gtk::Image.new(:icon_name => 'edit-find-symbolic')
      no_results_icon.add_css_class('no-results-icon')
      no_results_icon.pixel_size = 64
      no_results_box.append(no_results_icon)
      
      no_results_label = Gtk::Label.new("No apps found")
      no_results_label.add_css_class('no-results-label')
      no_results_box.append(no_results_label)
      
      @flow_box.append(no_results_box)
    end
  end
