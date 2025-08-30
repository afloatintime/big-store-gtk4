class Category
  attr_accessor :id, :name, :icon

  def initialize(id, name, icon = nil)
    @id = id
    @name = name
    @icon = icon
  end

  def self.default_categories
    [
      Category.new('all', 'All Apps', 'view-all'),
      Category.new('featured', 'Featured', 'starred'),
      Category.new('popular', 'Popular', 'trending-up'),
      Category.new('recent', 'Recent', 'update'),
      Category.new('audio', 'Audio', 'audio-headphones'),
      Category.new('video', 'Video', 'video'),
      Category.new('graphics', 'Graphics', 'image'),
      Category.new('games', 'Games', 'games'),
      Category.new('office', 'Office', 'office'),
      Category.new('education', 'Education', 'school'),
      Category.new('system', 'System', 'settings'),
      Category.new('network', 'Network', 'network'),
      Category.new('development', 'Development', 'code'),
      Category.new('utility', 'Utility', 'tools')
    ]
  end
end
