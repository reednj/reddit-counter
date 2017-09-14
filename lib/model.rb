require 'json'
require 'sequel'
require './lib/config.rb'

DB = Sequel.connect CONFIG['db']
Sequel::Deprecation.output = nil

class TagValue < Sequel::Model(:tag_values)
	def self.for_tag(tag_id, value)
		self.new do |v|
			v.tag_id = tag_id
			v.value = value
		end
	end

	def self.latest_for_tag(tag_id)
		self.where(:tag_id => tag_id).reverse_order(:value_id).first
	end
	
	def value
		tag_value || tag_value_bigint
	end

	def value=(v)
		if !v.is_a?(Float) && v > 2**31
			self.tag_value_bigint = v
		else
			self.tag_value = v
		end
	end

	def prev
		@prev ||= self.class.
			where('tag_id = ? and value_id < ?', self.tag_id, self.value_id).
			reverse_order(:value_id).
			first
	end
end
