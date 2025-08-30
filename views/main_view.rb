require 'gtk4'
require_relative 'app_view'
require_relative 'installed_view'
require_relative '../models/category'

class MainView < Gtk::ApplicationWindow
  def initialize(application, app_store)
    super(application)  # Pass the application to the parent class
    
    @app_store = app_store
    @config = app_store.instance_variable_get(:@config)
    
    # Set window properties
    self.title = @config.app_name
    self.default_width = 1200
    self.default_height = 800
    self.add_css_class('main-window')
    
    # Create main layout with styling
    @main_box = Gtk::Box.new(:horizontal, 0)
    @main_box.add_css_class('main-container')
    set_child(@main_box)
    
    # Create sidebar with styling
    @sidebar = Gtk::Box.new(:vertical, 0)
    @sidebar.add_css_class('sidebar')
    @sidebar.width_request = 240
    @main_box.append(@sidebar)
    
    # Create content area with styling
    @content_box = Gtk::Box.new(:vertical, 0)
    @content_box.add_css_class('content-area')
    @main_box.append(@content_box)
    
    # Create header with styling
    @header = Gtk::Box.new(:horizontal, 12)
    @header.add_css_class('header')
    @header.margin_start = 20
    @header.margin_end = 20
    @header.margin_top = 20
    @header.margin_bottom = 20
    @content_box.append(@header)
    
    # Create search container with styling
    search_container = Gtk::Box.new(:horizontal, 0)
    search_container.add_css_class('search-container')
    search_container.hexpand = true
    @header.append(search_container)
    
    # Create search icon
    search_icon = Gtk::Image.new(:icon_name => 'system-search-symbolic')
    search_icon.add_css_class('search-icon')
    search_container.append(search_icon)
    
    # Create search box with styling
    @search_entry = Gtk::Entry.new
    @search_entry.add_css_class('search-entry')
    @search_entry.placeholder_text = "Search apps..."
    @search_entry.hexpand = true
    search_container.append(@search_entry)
    
    # Create search button with styling
    @search_button = Gtk::Button.new(label: "Search")
    @search_button.add_css_class('search-button')
    @header.append(@search_button)
    
    # Create tabs with styling
    @notebook = Gtk::Notebook.new
    @notebook.add_css_class('main-tabs')
    @content_box.append(@notebook)
    
    # Create app grid view
    @app_view = AppView.new(@app_store)
    @app_view.set_parent_window(self)  # Set parent window for dialogs
    @notebook.append_page(@app_view, Gtk::Label.new("Browse"))
    
    # Create installed apps view
    @installed_view = InstalledView.new(@app_store)
    @installed_view.set_parent_window(self)  # Set parent window for dialogs
    @notebook.append_page(@installed_view, Gtk::Label.new("Installed"))
    
    # Create category sidebar with styling
    create_category_sidebar
    
    # Connect signals
    @search_button.signal_connect("clicked") { on_search }
    @search_entry.signal_connect("activate") { on_search }
    
    # Load initial data
    load_apps
    
    # Load CSS
    load_css
  end

  def create_category_sidebar
    # Add header to sidebar with styling
    header_box = Gtk::Box.new(:vertical, 0)
    header_box.add_css_class('sidebar-header')
    @sidebar.append(header_box)
    
    # App logo/icon
    logo = Gtk::Image.new(:icon_name => 'applications-other-symbolic')
    logo.add_css_class('sidebar-logo')
    logo.pixel_size = 48
    header_box.append(logo)
    
    # App title
    title_label = Gtk::Label.new(@config.app_name)
    title_label.add_css_class('sidebar-title')
    header_box.append(title_label)
    
    # Add separator with styling
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
    
    # Add category buttons with styling
    categories = Category.default_categories
    
    categories.each do |category|
      button = Gtk::Button.new(label: category.name)
      button.add_css_class('category-button')
      button.margin_start = 10
      button.margin_end = 10
      button.halign = :start
      
      # Add icon to button
      button_box = Gtk::Box.new(:horizontal, 8)
      button_box.add_css_class('category-button-content')
      
      icon = Gtk::Image.new(:icon_name => "#{category.icon}-symbolic")
      icon.add_css_class('category-icon')
      icon.pixel_size = 16
      button_box.append(icon)
      
      label = Gtk::Label.new(category.name)
      label.add_css_class('category-label')
      button_box.append(label)
      
      button.set_child(button_box)
      
      button.signal_connect("clicked") do
        on_category_selected(category)
      end
      
      @sidebar.append(button)
    end
    
    # Add bottom section with styling
    @sidebar.append(Gtk::Box.new(:vertical, 0))  # Spacer
    
    # Settings button
    settings_button = Gtk::Button.new
    settings_button.add_css_class('sidebar-bottom-button')
    settings_button.margin_start = 10
    settings_button.margin_end = 10
    settings_button.margin_bottom = 10
    settings_button.halign = :start
    
    settings_box = Gtk::Box.new(:horizontal, 8)
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
    
    # Search for apps
    @app_view.search_apps(query)
  end

  def on_category_selected(category)
    # Load apps for selected category
    @app_view.load_category(category)
  end

  def load_apps
    # Load initial apps
    @app_view.load_category(Category.default_categories.first)
    
    # Load installed apps
    @installed_view.load_installed_apps
  end

  def load_css
    css_provider = Gtk::CssProvider.new
    css_provider.load_from_path(File.join(__dir__, '..', 'assets', 'css', 'style.css'))
    
    Gtk::StyleContext.add_provider_for_display(
      Gdk::Display.default,
      css_provider,
      Gtk::StyleProvider::PRIORITY_APPLICATION
    )
  end
end
