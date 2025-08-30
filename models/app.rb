class App
  attr_accessor :id, :name, :description, :version, :category, :icon, :banner, :type, :installed

  def initialize(id, name, description = '', version = '', category = '', icon = nil, banner = nil, type = :flatpak, installed = false)
    @id = id.to_s
    @name = name.to_s
    @description = description.to_s
    @version = version.to_s
    @category = category.to_s
    @icon = icon
    @banner = banner
    @type = type
    @installed = !!installed
  end

  def self.from_flatpak(flatpak_data)
    return nil unless flatpak_data.is_a?(Hash)
    
    App.new(
      flatpak_data['flatpak_app_id'] || flatpak_data['id'] || '',
      flatpak_data['name'] || '',
      flatpak_data['summary'] || '',
      flatpak_data['version'] || '',
      flatpak_data['categories']&.first || '',
      flatpak_data['icon'] || '',
      flatpak_data['icon'] || '',
      :flatpak,
      false
    )
  end

  def self.from_package(package_data)
    return nil unless package_data.is_a?(Hash)
    
    App.new(
      package_data[:id] || '',
      package_data[:name] || '',
      '',
      package_data[:version] || '',
      '',
      nil,
      nil,
      package_data[:type] || :native,
      package_data[:installed] || false
    )
  end
end
