# require all the models in subdirectories
file_path = File.dirname(__FILE__)
model_path = File.join file_path, 'models/*.rb'
Dir[model_path].each{|f| require f }
