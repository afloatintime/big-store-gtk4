require 'net/http'
require 'json'
require 'open-uri'

class FlatpakService
  def initialize(config = Config.new)
    @config = config
    @flathub_url = config.flathub_url
    @flathub_search_url = "https://flathub.org/api/v1/search"
  end

  def get_apps(category = nil)
    # Fetch apps from Flathub API
    url = "#{@flathub_url}/apps"
    if category && category.respond_to?(:id) && category.id
      url += "?category=#{URI.encode_www_form_component(category.id)}"
    end
    
    begin
      response = Net::HTTP.get(URI(url))
      apps_data = JSON.parse(response)
      
      # Ensure apps_data is an array
      apps_data = [apps_data] unless apps_data.is_a?(Array)
      
      # Convert to our app format
      apps = []
      apps_data.each do |app_data|
        next unless app_data.is_a?(Hash)
        
        apps << {
          id: app_data['flatpak_app_id'] || '',
          name: app_data['name'] || '',
          description: app_data['summary'] || '',
          version: app_data['version'] || 'latest',
          icon: app_data['icon'] || '',
          categories: app_data['categories'] || [],
          type: :flatpak,
          installed: installed?(app_data['flatpak_app_id'])
        }
      end
      
      apps
    rescue => e
      puts "Error fetching apps from Flathub: #{e.message}"
      []
    end
  end

  def get_app_details(app_id)
    # Fetch app details from Flathub API
    url = "#{@flathub_url}/apps/#{URI.encode_www_form_component(app_id)}"
    
    begin
      response = Net::HTTP.get(URI(url))
      JSON.parse(response)
    rescue => e
      puts "Error fetching app details: #{e.message}"
      {}
    end
  end

  def get_installed_apps
    # Get installed Flatpak apps
    begin
      output = `flatpak list --app --columns=application,name,version,branch,origin`
      apps = []
      
      output.each_line do |line|
        next if line.strip.empty?
        
        parts = line.strip.split("\t")
        # Ensure we have at least 5 parts (application, name, version, branch, origin)
        if parts.length >= 5
          # Get additional details from Flathub API
          app_details = get_app_details(parts[0])
          
          apps << {
            id: parts[0],
            name: parts[1],
            version: parts[2],
            branch: parts[3],
            origin: parts[4],
            description: app_details['summary'] || '',
            icon: app_details['icon'] || '',
            categories: app_details['categories'] || [],
            type: :flatpak,
            installed: true
          }
        else
          puts "Warning: Unexpected flatpak list output format: #{line}"
        end
      end
      
      apps
    rescue => e
      puts "Error getting installed Flatpak apps: #{e.message}"
      []
    end
  end

  def search_apps(query)
    # Search for Flatpak apps using Flathub API
    begin
      url = "#{@flathub_search_url}?query=#{URI.encode_www_form_component(query)}"
      response = Net::HTTP.get(URI(url))
      search_results = JSON.parse(response)
      
      # Ensure search_results is an array
      search_results = search_results['results'] if search_results.is_a?(Hash) && search_results['results']
      search_results = [search_results] unless search_results.is_a?(Array)
      
      # Convert search results to app format
      apps = []
      search_results.each do |result|
        next unless result.is_a?(Hash)
        
        apps << {
          id: result['flatpak_app_id'] || '',
          name: result['name'] || '',
          description: result['summary'] || '',
          version: result['version'] || 'latest',
          icon: result['icon'] || '',
          categories: result['categories'] || [],
          type: :flatpak,
          installed: installed?(result['flatpak_app_id'])
        }
      end
      
      apps
    rescue => e
      puts "Error searching Flatpak apps: #{e.message}"
      []
    end
  end

  def install_app(app_id)
    # Install a Flatpak app
    system("flatpak install -y flathub #{app_id}")
  end

  def uninstall_app(app_id)
    # Uninstall a Flatpak app
    system("flatpak uninstall -y #{app_id}")
  end

  private

  def installed?(app_id)
    # Check if a Flatpak app is installed using a more robust method
    return false if app_id.nil? || app_id.empty?
    
    begin
      # Get list of installed flatpak apps and check if app_id is in the list
      output = `flatpak list --app --columns=application`
      installed_apps = output.split("\n").map(&:strip)
      installed_apps.include?(app_id.strip)
    rescue => e
      puts "Error checking if app is installed: #{e.message}"
      false
    end
  end
end
