class CategoryService
  def initialize
    # Category keywords for matching apps
    @category_keywords = {
      'audio' => ['audio', 'music', 'sound', 'player', 'spotify', 'rhythmbox', 'vlc'],
      'video' => ['video', 'movie', 'player', 'vlc', 'mpv', 'obs'],
      'graphics' => ['image', 'photo', 'graphics', 'gimp', 'inkscape', 'krita'],
      'games' => ['game', 'steam', 'minecraft', 'lutris'],
      'office' => ['office', 'document', 'libreoffice', 'word', 'excel'],
      'education' => ['education', 'learning', 'teach', 'school'],
      'system' => ['system', 'utility', 'tool', 'settings'],
      'network' => ['network', 'internet', 'web', 'browser', 'chat'],
      'development' => ['development', 'programming', 'code', 'ide'],
      'utility' => ['utility', 'tool', 'helper', 'manager']
    }
  end

  def categorize_apps(apps, category_id)
    return apps if category_id == 'all'
    
    apps.select { |app| app_belongs_to_category?(app, category_id) }
  end

  def app_belongs_to_category?(app, category_id)
    return true if category_id == 'all'
    
    keywords = @category_keywords[category_id]
    return false unless keywords
    
    app_name = app.name.downcase
    app_description = (app.description || '').downcase
    
    keywords.any? do |keyword|
      app_name.include?(keyword) || app_description.include?(keyword)
    end
  end
end
