require 'yaml'
require 'yaml/load_first'

CONFIG = YAML.load_first_file [
    "#{ENV['HOME']}/config/reddit-counter.db.yaml",
    './config/config.prod.yaml',
    './config/config.yaml'
]
