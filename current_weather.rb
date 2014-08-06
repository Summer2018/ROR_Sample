require 'nokogiri'
require 'open-uri'
require 'iconv'

class CurrentWeather
	GOOGLE_WEATHER_URL = "http://www.google.com/ig/api?weather="
	WUNDERGROUND_URL = "http://api.wunderground.com/api/14f53cac111754f2/conditions/q/"
	SERVICE_TO_USE = "WUNDERGROUND"
	attr_accessor :location, :temp, :wind, :icon, :condition, :data_found

	def initialize(loc)
		@location = loc
		@data_found = false
		@temp = "N/A"
		@condition = "N/A"
		@wind = "N/A"
		@icon = "N/A"

		if SERVICE_TO_USE == "WUNDERGROUND"
			wunderground_loc = @location.split(",")
			full_path = WUNDERGROUND_URL + URI.encode(wunderground_loc.last) + "/" + URI.encode(wunderground_loc.first) + ".xml"
			begin
				weather_data = Nokogiri::XML(open(full_path),full_path,"ISO-8859-1")
			rescue Timeout::Error
				@data_found = false
			rescue OpenURI::HTTPError => e
				@data_found = false
			rescue Exception
				@data_found = false
			end
			if weather_data
				current_conditions = weather_data.search('current_observation').first
				if current_conditions
					if current_conditions.search('temp_f').first
						@temp = current_conditions.search('temp_f').first.text
					end
					if current_conditions.search('weather').first
						@condition = current_conditions.search('weather').first.text
					end
					if current_conditions.search('wind_string').first
						@wind = current_conditions.search('wind_string').first.text
					end
					if current_conditions.search('icon_url').first
						@icon = current_conditions.search('icon_url').first.text
					end
					@data_found = true
				end
			end
		elsif SERVICE_TO_USE == "GOOGLE"
			full_path = GOOGLE_WEATHER_URL + URI.encode(location)
			begin
				weather_data = Nokogiri::XML(open(full_path),full_path,"ISO-8859-1")
			rescue Timeout::Error
				@data_found = false
			rescue OpenURI::HTTPError => e
				@data_found = false
			rescue Exception
				@data_found = false
			end

			if weather_data
				current_conditions = weather_data.search('current_conditions').first
				if current_conditions
					if current_conditions.search('condition').first
						@condition = current_conditions.search('condition').first[:data]
					end
					if current_conditions.search('temp_f').first
						@temp = current_conditions.search('temp_f').first[:data]
					end
					if current_conditions.search('wind_condition').first
						@wind = current_conditions.search('wind_condition').first[:data]
					end
					temp_icon = current_conditions.search('icon').first[:data]
					@icon = "http://www.google.com/" + temp_icon
					@data_found = true
				end
			end
		end
	end
end