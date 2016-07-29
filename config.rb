require 'yaml'

prod = './config.prod.yaml' 
default = './config.yaml'

f = File.exist?(prod) ? prod :default
raise "could not load config file '#{f}'" if !File.exist? f
CONFIG = YAML.load_file f
