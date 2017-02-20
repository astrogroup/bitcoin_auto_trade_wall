module Config
  require 'yaml'
  class << self
    def load
      # load global config
      $config = YAML.load(File.open("./password.yml", "r").read)
    end
  end
end

