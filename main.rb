#!/usr/bin/env ruby

# Add current directory to load path for local files
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

begin
  require 'gtk4'
rescue LoadError
  puts "Error: The 'gtk4' gem is not installed."
  puts "Please install it by running: bundle install"
  puts "If you don't have Bundler, install it with: gem install bundler"
  exit 1
end

require 'net/http'
require 'json'
require 'open-uri'
require 'fileutils'

# Load all required files first
require_relative 'utils/config'
require_relative 'utils/system_detector'
require_relative 'models/app'
require_relative 'models/category'
require_relative 'services/icon_service'
require_relative 'services/flatpak_service'
require_relative 'services/pacman_service'
require_relative 'services/pactrans_service'
require_relative 'services/aur_service'
require_relative 'services/category_service'

# Now define the main application class
class AppStore
  def initialize
    # Initialize services
    @config = Config.new
    @system_detector = SystemDetector.new
    @flatpak_service = FlatpakService.new
    @pacman_service = PacmanService.new if @system_detector.has_pacman?
    @pactrans_service = PactransService.new if @system_detector.is_biglinux? && @system_detector.has_pactrans?
    @aur_service = AurService.new if @system_detector.has_aur?
    @category_service = CategoryService.new
    
    # Create GTK application
    @app = Gtk::Application.new('org.example.appstore', :flags_none)
    @app.signal_connect('activate') do |application|
      # Create main view when application is activated
      @main_view = MainView.new(application, self)
      @main_view.present
    end
  end

  def run
    @app.run
  end

  # Get all categories
  def get_categories
    Category.default_categories
  end

  # Get apps by category
  def get_apps_by_category(category_id)
    apps = []
    
    begin
      # Get Flatpak apps
      flatpak_apps = @flatpak_service.get_apps(category_id)
      apps += flatpak_apps.map { |app| App.from_flatpak(app) }.compact
      
      # Get native apps using pacman
      if @pacman_service
        native_apps = @pacman_service.get_apps(category_id)
        apps += native_apps.map { |app| App.from_package(app) }.compact
      end
      
      # Get BigLinux apps
      if @pactrans_service
        biglinux_apps = @pactrans_service.get_apps(category_id)
        apps += biglinux_apps.map { |app| App.from_package(app) }.compact
      end
      
      # Get AUR apps
      if @aur_service
        aur_apps = @aur_service.get_apps(category_id)
        apps += aur_apps.map { |app| App.from_package(app) }.compact
      end
      
      # Categorize apps
      apps = @category_service.categorize_apps(apps, category_id)
      
    rescue => e
      puts "Error getting apps by category: #{e.message}"
    end
    
    apps
  end

  # Get installed apps by category
  def get_installed_apps_by_category(category_id)
    apps = []
    
    begin
      # Get installed Flatpak apps
      flatpak_apps = @flatpak_service.get_installed_apps
      apps += flatpak_apps.map { |app| App.from_flatpak(app) }.compact
      
      # Get installed native apps using pacman
      if @pacman_service
        native_apps = @pacman_service.get_installed_apps
        apps += native_apps.map { |app| App.from_package(app) }.compact
      end
      
      # Get installed BigLinux apps
      if @pactrans_service
        biglinux_apps = @pactrans_service.get_installed_apps
        apps += biglinux_apps.map { |app| App.from_package(app) }.compact
      end
      
      # Get installed AUR apps
      if @aur_service
        aur_apps = @aur_service.get_installed_apps
        apps += aur_apps.map { |app| App.from_package(app) }.compact
      end
      
      # Filter by category if not "all"
      if category_id != 'all'
        apps = apps.select { |app| @category_service.app_belongs_to_category?(app, category_id) }
      end
      
    rescue => e
      puts "Error getting installed apps by category: #{e.message}"
    end
    
    apps
  end

  # Get all installed apps
  def get_installed_apps
    get_installed_apps_by_category('all')
  end

  # Search apps
  def search_apps(query)
    apps = []
    
    begin
      # Search Flatpak apps
      flatpak_apps = @flatpak_service.search_apps(query)
      apps += flatpak_apps.map { |app| App.from_flatpak(app) }.compact
      
      # Search native apps using pacman
      if @pacman_service
        native_apps = @pacman_service.search_apps(query)
        apps += native_apps.map { |app| App.from_package(app) }.compact
      end
      
      # Search BigLinux apps
      if @pactrans_service
        biglinux_apps = @pactrans_service.search_apps(query)
        apps += biglinux_apps.map { |app| App.from_package(app) }.compact
      end
      
      # Search AUR apps
      if @aur_service
        aur_apps = @aur_service.search_apps(query)
        apps += aur_apps.map { |app| App.from_package(app) }.compact
      end
      
    rescue => e
      puts "Error searching apps: #{e.message}"
    end
    
    apps
  end

  # Search installed apps
  def search_installed_apps(query)
    apps = get_installed_apps
    apps.select { |app| 
      app.name.downcase.include?(query.downcase) || 
      (app.description && app.description.downcase.include?(query.downcase))
    }
  end

  # Install app
  def install_app(app_id, app_type)
    begin
      case app_type
      when :flatpak
        @flatpak_service.install_app(app_id)
      when :native
        @pacman_service.install_app(app_id)
      when :biglinux
        @pactrans_service.install_app(app_id)
      when :aur
        @aur_service.install_app(app_id)
      else
        raise "Unknown app type: #{app_type}"
      end
    rescue => e
      puts "Error installing app: #{e.message}"
      raise e
    end
  end

  # Uninstall app
  def uninstall_app(app_id, app_type)
    begin
      case app_type
      when :flatpak
        @flatpak_service.uninstall_app(app_id)
      when :native
        @pacman_service.uninstall_app(app_id)
      when :biglinux
        @pactrans_service.uninstall_app(app_id)
      when :aur
        @aur_service.uninstall_app(app_id)
      else
        raise "Unknown app type: #{app_type}"
      end
    rescue => e
      puts "Error uninstalling app: #{e.message}"
      raise e
    end
  end

  # Get app icon
  def get_app_icon(app_id, app_type, icon_path = nil)
    begin
      icon_service = IconService.new
      icon_service.get_app_icon(app_id, app_type, icon_path)
    rescue => e
      puts "Error getting app icon: #{e.message}"
      nil
    end
  end
end

# Define view classes
class AppGrid < Gtk::ScrolledWindow
  def initialize(app_store, show_installed_only = false)
    super()
    
    @app_store = app_store
    @show_installed_only = show_installed_only
    @current_category = nil
    @parent_window = nil
    
    # Create main container
    @main_box = Gtk::Box.new(:vertical, 0)
    @main_box.add_css_class('app-grid-container')
    set_child(@main_box)
    
    # Create flow box for app grid
    @flow_box = Gtk::FlowBox.new
    @flow_box.add_css_class('app-grid')
    @flow_box.homogeneous = false
    @flow_box.row_spacing = 24
    @flow_box.column_spacing = 24
    @flow_box.margin_start = 24
    @flow_box.margin_end = 24
    @flow_box.margin_top = 24
    @flow_box.margin_bottom = 24
    @flow_box.selection_mode = :none
    
    # Set properties
    @flow_box.max_children_per_line = 4
    @flow_box.min_children_per_line = 1
    
    # Add flow box to main container
    @main_box.append(@flow_box)
    
    # Create loading container
    @loading_box = Gtk::Box.new(:vertical, 20)
    @loading_box.add_css_class('loading-container')
    @loading_box.halign = :center
    @loading_box.valign = :center
    @loading_box.visible = false
    
    # Create loading indicator
    @loading_spinner = Gtk::Spinner.new
    @loading_spinner.add_css_class('loading-spinner')
    @loading_spinner.halign = :center
    @loading_spinner.valign = :center
    @loading_spinner.width_request = 48
    @loading_spinner.height_request = 48
    @loading_box.append(@loading_spinner)
    
    # Create loading label
    @loading_label = Gtk::Label.new("Loading apps...")
    @loading_label.add_css_class('loading-label')
    @loading_label.halign = :center
    @loading_label.valign = :center
    @loading_box.append(@loading_label)
    
    # Add loading container to main container
    @main_box.append(@loading_box)
    
    # Create empty state container
    @empty_box = Gtk::Box.new(:vertical, 20)
    @empty_box.add_css_class('empty-state')
    @empty_box.halign = :center
    @empty_box.valign = :center
    @empty_box.visible = false
    
    # Add empty state icon
    @empty_icon = Gtk::Image.new(:icon_name => 'application-x-executable-symbolic')
    @empty_icon.add_css_class('empty-state-icon')
    @empty_icon.pixel_size = 64
    @empty_box.append(@empty_icon)
    
    # Add empty state label
    @empty_label = Gtk::Label.new("No apps found")
    @empty_label.add_css_class('empty-state-label')
    @empty_box.append(@empty_label)
    
    # Add empty state container to main container
    @main_box.append(@empty_box)
  end

  def set_parent_window(window)
    @parent_window = window
  end

  def load_category(category)
    @current_category = category
    
    # Clear existing apps
    clear_apps
    
    # Show loading indicator
    show_loading
    
    # Load apps in a separate thread
    Thread.new do
      begin
        if @show_installed_only
          apps = @app_store.get_installed_apps_by_category(category.id)
        else
          apps = @app_store.get_apps_by_category(category.id)
        end
        
        # Update UI in the main thread
        GLib::Idle.add do
          hide_loading
          add_apps_to_grid(apps)
          false
        end
      rescue => e
        puts "Error loading apps: #{e.message}"
        
        # Update UI in the main thread
        GLib::Idle.add do
          hide_loading
          show_empty_state("Failed to load apps")
          false
        end
      end
    end
  end

  def search_apps(query)
    # Clear existing apps
    clear_apps
    
    # Show loading indicator
    show_loading
    
    # Search for apps in a separate thread
    Thread.new do
      begin
        if @show_installed_only
          apps = @app_store.search_installed_apps(query)
        else
          apps = @app_store.search_apps(query)
        end
        
        # Update UI in the main thread
        GLib::Idle.add do
          hide_loading
          add_apps_to_grid(apps)
          false
        end
      rescue => e
        puts "Error searching apps: #{e.message}"
        
        # Update UI in the main thread
        GLib::Idle.add do
          hide_loading
          show_empty_state("Failed to search apps")
          false
        end
      end
    end
  end

  def refresh_apps
    if @current_category
      load_category(@current_category)
    end
  end

  def clear_apps
    @flow_box.children.each { |child| @flow_box.remove(child) }
    @empty_box.visible = false
  end

  def add_apps_to_grid(apps)
    # Filter out nil apps
    apps = apps.compact
    
    # Sort apps by name
    apps.sort_by! { |app| app.name.downcase }
    
    # Add apps to grid
    apps.each do |app|
      app_widget = create_app_widget(app)
      @flow_box.append(app_widget)
    end
    
    # Show empty state if no apps found
    if apps.empty?
      show_empty_state("No apps found")
    end
  end

  def create_app_widget(app)
    # Create main container
    container = Gtk::Box.new(:vertical, 12)
    container.add_css_class('app-card')
    container.width_request = 280
    container.height_request = 320
    
    # Create icon container
    icon_container = Gtk::Box.new(:horizontal, 0)
    icon_container.add_css_class('app-icon-container')
    icon_container.halign = :center
    container.append(icon_container)
    
    # Create icon
    icon = nil
    icon_path = @app_store.get_app_icon(app.id, app.type, app.icon)
    
    if icon_path && File.exist?(icon_path)
      icon = Gtk::Image.new(:file => icon_path)
    else
      icon = Gtk::Image.new(:icon_name => 'application-x-executable')
    end
    
    icon.add_css_class('app-icon')
    icon.pixel_size = 96
    icon_container.append(icon)
    
    # Create name label
    name_label = Gtk::Label.new(app.name)
    name_label.add_css_class('app-name')
    name_label.halign = :center
    name_label.wrap = true
    name_label.wrap_mode = :word_char
    name_label.max_width_chars = 25
    name_label.ellipsize = :end
    container.append(name_label)
    
    # Create description label
    if app.description && !app.description.empty?
      desc_label = Gtk::Label.new(app.description)
      desc_label.add_css_class('app-description')
      desc_label.halign = :center
      desc_label.wrap = true
      desc_label.wrap_mode = :word_char
      desc_label.max_width_chars = 25
      desc_label.ellipsize = :end
      container.append(desc_label)
    end
    
    # Create source badge
    source_box = Gtk::Box.new(:horizontal, 0)
    source_box.add_css_class('app-source-container')
    source_box.halign = :center
    container.append(source_box)
    
    source_label = Gtk::Label.new(app.type.to_s.upcase)
    source_label.add_css_class("app-source-#{app.type}")
    source_box.append(source_label)
    
    # Create action button
    if app.installed
      action_button = Gtk::Button.new(label: "Remove")
      action_button.add_css_class('app-button-remove')
    else
      action_button = Gtk::Button.new(label: "Install")
      action_button.add_css_class('app-button-install')
    end
    
    action_button.halign = :center
    container.append(action_button)
    
    # Connect button click
    action_button.signal_connect("clicked") do
      if app.installed
        on_remove_clicked(app, action_button)
      else
        on_install_clicked(app, action_button)
      end
    end
    
    # Add hover effect
    container.signal_connect("enter-notify-event") do
      container.add_css_class('app-card-hover')
      false
    end
    
    container.signal_connect("leave-notify-event") do
      container.remove_css_class('app-card-hover')
      false
    end
    
    # Store app reference
    container.instance_variable_set(:@app, app)
    
    container
  end

  def on_install_clicked(app, button)
    # Disable button during installation
    button.sensitive = false
    button.label = "Installing..."
    button.add_css_class('app-button-installing')
    
    # Install app in a separate thread
    Thread.new do
      begin
        @app_store.install_app(app.id, app.type)
        
        # Update UI in the main thread
        GLib::Idle.add do
          button.label = "Remove"
          button.add_css_class('app-button-remove')
          button.remove_css_class('app-button-installing')
          button.sensitive = true
          
          # Show success notification
          show_notification("#{app.name} installed successfully!", :success)
          
          # Refresh the grid if showing installed apps
          refresh_apps if @show_installed_only
          
          false
        end
      rescue => e
        puts "Error installing app: #{e.message}"
        
        # Update UI in the main thread
        GLib::Idle.add do
          button.label = "Install"
          button.add_css_class('app-button-install')
          button.remove_css_class('app-button-installing')
          button.sensitive = true
          show_error("Failed to install app: #{e.message}")
          false
        end
      end
    end
  end

  def on_remove_clicked(app, button)
    # Disable button during removal
    button.sensitive = false
    button.label = "Removing..."
    button.add_css_class('app-button-removing')
    
    # Remove app in a separate thread
    Thread.new do
      begin
        @app_store.uninstall_app(app.id, app.type)
        
        # Update UI in the main thread
        GLib::Idle.add do
          # Remove app from grid with animation
          @flow_box.children.each do |child|
            if child.instance_variable_get(:@app)&.id == app.id
              child.add_css_class('app-card-exit')
              
              # Remove after animation
              GLib::Timeout.add(300) do
                @flow_box.remove(child)
                
                # Show empty state if no apps left
                show_empty_state("No apps found") if @flow_box.children.empty?
                
                false
              end
              
              break
            end
          end
          
          # Show success notification
          show_notification("#{app.name} removed successfully!", :success)
          
          false
        end
      rescue => e
        puts "Error removing app: #{e.message}"
        
        # Update UI in the main thread
        GLib::Idle.add do
          button.label = "Remove"
          button.add_css_class('app-button-remove')
          button.remove_css_class('app-button-removing')
          button.sensitive = true
          show_error("Failed to remove app: #{e.message}")
          false
        end
      end
    end
  end

  def show_loading
    @flow_box.visible = false
    @loading_box.visible = true
    @loading_spinner.start
  end

  def hide_loading
    @flow_box.visible = true
    @loading_box.visible = false
    @loading_spinner.stop
  end

  def show_empty_state(message)
    @empty_label.text = message
    @empty_box.visible = true
  end

  def show_error(message)
    dialog = Gtk::MessageDialog.new(
      parent: @parent_window || nil,
      flags: :modal,
      type: :error,
      buttons_type: :close,
      message: message
    )
    
    dialog.add_css_class('error-dialog')
    
    dialog.signal_connect("response") do
      dialog.destroy
    end
    
    dialog.show
  end

  def show_notification(message, type = :info)
    # Create toast notification
    toast = Gtk::Box.new(:horizontal, 12)
    toast.add_css_class(type == :success ? 'toast-success' : 'toast-info')
    toast.halign = :center
    toast.valign = :start
    toast.margin_top = 20
    
    # Add icon
    icon_name = type == :success ? 'emblem-ok-symbolic' : 'dialog-information-symbolic'
    icon = Gtk::Image.new(:icon_name => icon_name)
    icon.pixel_size = 20
    toast.append(icon)
    
    # Add message
    label = Gtk::Label.new(message)
    label.add_css_class('toast-label')
    toast.append(label)
    
    # Add to parent
    if @parent_window
      @parent_window.add_overlay(toast)
      toast.visible = true
      
      # Auto-hide after 3 seconds
      GLib::Timeout.add(3000) do
        toast.visible = false
        @parent_window.remove_overlay(toast)
        false
      end
    end
  end
end

class MainView < Gtk::ApplicationWindow
  def initialize(application, app_store)
    super(application)
    
    @app_store = app_store
    @config = app_store.instance_variable_get(:@config)
    
    # Set window properties
    self.title = @config.app_name
    self.default_width = 1200
    self.default_height = 800
    self.add_css_class('main-window')
    
    # Create main layout
    @main_box = Gtk::Box.new(:horizontal, 0)
    @main_box.add_css_class('main-container')
    set_child(@main_box)
    
    # Create sidebar
    @sidebar = Gtk::Box.new(:vertical, 0)
    @sidebar.add_css_class('sidebar')
    @sidebar.width_request = 260
    @main_box.append(@sidebar)
    
    # Create content area
    @content_box = Gtk::Box.new(:vertical, 0)
    @content_box.add_css_class('content-area')
    @content_box.hexpand = true
    @content_box.vexpand = true
    @main_box.append(@content_box)
    
    # Create header
    @header = Gtk::Box.new(:horizontal, 12)
    @header.add_css_class('header')
    @header.margin_start = 20
    @header.margin_end = 20
    @header.margin_top = 20
    @header.margin_bottom = 20
    @content_box.append(@header)
    
    # Create search container
    search_container = Gtk::Box.new(:horizontal, 0)
    search_container.add_css_class('search-container')
    search_container.hexpand = true
    @header.append(search_container)
    
    # Create search icon
    search_icon = Gtk::Image.new(:icon_name => 'system-search-symbolic')
    search_icon.add_css_class('search-icon')
    search_container.append(search_icon)
    
    # Create search entry
    @search_entry = Gtk::Entry.new
    @search_entry.add_css_class('search-entry')
    @search_entry.placeholder_text = "Search apps..."
    @search_entry.hexpand = true
    search_container.append(@search_entry)
    
    # Create search button
    @search_button = Gtk::Button.new(label: "Search")
    @search_button.add_css_class('search-button')
    @header.append(@search_button)
    
    # Create refresh button
    @refresh_button = Gtk::Button.new
    @refresh_button.add_css_class('refresh-button')
    @refresh_button.icon_name = 'view-refresh-symbolic'
    @header.append(@refresh_button)
    
    # Create tabs
    @notebook = Gtk::Notebook.new
    @notebook.add_css_class('main-tabs')
    @content_box.append(@notebook)
    
    # Create browse tab
    @browse_grid = AppGrid.new(@app_store, false)
    @browse_grid.set_parent_window(self)
    @notebook.append_page(@browse_grid, Gtk::Label.new("Explore"))
    
    # Create installed tab
    @installed_grid = AppGrid.new(@app_store, true)
    @installed_grid.set_parent_window(self)
    @notebook.append_page(@installed_grid, Gtk::Label.new("Installed"))
    
    # Create category sidebar
    create_category_sidebar
    
    # Connect signals
    @search_button.signal_connect("clicked") { on_search }
    @search_entry.signal_connect("activate") { on_search }
    @refresh_button.signal_connect("clicked") { on_refresh }
    
    # Connect tab switch signal
    @notebook.signal_connect("switch-page") do |_, page, page_num|
      on_tab_switched(page_num)
    end
    
    # Load initial data
    load_apps
    
    # Load CSS
    load_css
  end

  def create_category_sidebar
    # Add header to sidebar
    header_box = Gtk::Box.new(:vertical, 0)
    header_box.add_css_class('sidebar-header')
    @sidebar.append(header_box)
    
    # App logo
    logo = Gtk::Image.new(:icon_name => 'applications-other-symbolic')
    logo.add_css_class('sidebar-logo')
    logo.pixel_size = 48
    header_box.append(logo)
    
    # App title
    title_label = Gtk::Label.new(@config.app_name)
    title_label.add_css_class('sidebar-title')
    header_box.append(title_label)
    
    # Add separator
    separator = Gtk::Separator.new(:horizontal)
    separator.add_css_class('sidebar-separator')
    separator.margin_top = 10
    separator.margin_bottom = 10
    @sidebar.append(separator)
    
    # Categories label
    categories_label = Gtk::Label.new("Categories")
    categories_label.add_css_class('sidebar-section-title')
    categories_label.margin_start = 20
    categories_label.margin_end = 20
    categories_label.margin_top = 10
    categories_label.halign = :start
    @sidebar.append(categories_label)
    
    # Add category buttons
    categories = Category.default_categories
    
    categories.each do |category|
      button = Gtk::Button.new
      button.add_css_class('category-button')
      button.margin_start = 10
      button.margin_end = 10
      button.halign = :start
      
      # Create button content
      button_box = Gtk::Box.new(:horizontal, 12)
      button_box.add_css_class('category-button-content')
      
      # Add icon
      icon = Gtk::Image.new(:icon_name => "#{category.icon}-symbolic")
      icon.add_css_class('category-icon')
      icon.pixel_size = 16
      button_box.append(icon)
      
      # Add label
      label = Gtk::Label.new(category.name)
      label.add_css_class('category-label')
      button_box.append(label)
      
      button.set_child(button_box)
      
      # Connect click signal
      button.signal_connect("clicked") do
        on_category_selected(category)
      end
      
      @sidebar.append(button)
    end
    
    # Add spacer
    @sidebar.append(Gtk::Box.new(:vertical, 0))  # Spacer
    
    # Add settings button
    settings_button = Gtk::Button.new
    settings_button.add_css_class('sidebar-bottom-button')
    settings_button.margin_start = 10
    settings_button.margin_end = 10
    settings_button.margin_bottom = 10
    settings_button.halign = :start
    
    settings_box = Gtk::Box.new(:horizontal, 12)
    settings_box.add_css_class('category-button-content')
    
    settings_icon = Gtk::Image.new(:icon_name => 'preferences-system-symbolic')
    settings_icon.add_css_class('category-icon')
    settings_icon.pixel_size = 16
    settings_box.append(settings_icon)
    
    settings_label = Gtk::Label.new("Settings")
    settings_label.add_css_class('category-label')
    settings_box.append(settings_label)
    
    settings_button.set_child(settings_box)
    @sidebar.append(settings_button)
  end

  def on_search
    query = @search_entry.text.strip
    return if query.empty?
    
    # Search in current tab
    current_page = @notebook.page
    if current_page == 0
      @browse_grid.search_apps(query)
    else
      @installed_grid.search_apps(query)
    end
  end

  def on_refresh
    # Refresh current tab
    current_page = @notebook.page
    if current_page == 0
      @browse_grid.refresh_apps
    else
      @installed_grid.refresh_apps
    end
  end

  def on_category_selected(category)
    # Load category in browse tab
    @notebook.page = 0
    @browse_grid.load_category(category)
  end

  def on_tab_switched(page_num)
    # Load initial data for the tab if not already loaded
    if page_num == 0 && !@browse_loaded
      @browse_grid.load_category(Category.default_categories.first)
      @browse_loaded = true
    elsif page_num == 1 && !@installed_loaded
      @installed_grid.load_category(Category.default_categories.first)
      @installed_loaded = true
    end
  end

  def load_apps
    # Load initial data for browse tab
    @browse_grid.load_category(Category.default_categories.first)
    @browse_loaded = true
  end

  def load_css
    css_provider = Gtk::CssProvider.new
    css_provider.load_from_path(File.join(__dir__, 'assets', 'css', 'style.css'))
    
    Gtk::StyleContext.add_provider_for_display(
      Gdk::Display.default,
      css_provider,
      Gtk::StyleProvider::PRIORITY_APPLICATION
    )
  end
end

# Run the application
if __FILE__ == $0
  app = AppStore.new
  app.run
end
