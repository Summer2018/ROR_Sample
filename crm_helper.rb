module CrmHelper

def search_criteria_text_field_row(form_object, conditions, field_criteria, options={})
	tmp_output = ''
	tmp_output << "<tr id='tr_#{field_criteria}' class='filter' style='#{(conditions.send(field_criteria).to_s != '') ? '' : 'display: none;'}'>"
	tmp_output << "<td style='vertical-align: top;'>"
	tmp_output << link_to_function(image_tag('bullet_toggle_minus.png'), "field_picklists.hide_field('#{field_criteria}')")
	tmp_output << form_object.label(field_criteria.to_sym)
	tmp_output << "</td>"
	tmp_output << "<td style='vertical-align: top;'>#{form_object.text_field field_criteria.to_sym, :class => 'txt'} #{options[:extra_text]}</td>"
	tmp_output << "</tr>"
	tmp_output
end

def search_criteria_check_box_field_row(form_object, conditions, field_criteria, options={})
	tmp_output = ''
	tmp_output << "<tr id='tr_#{field_criteria}' class='filter' style='#{(conditions.send(field_criteria).to_s != '') ? '' : 'display: none;'}'>"
	tmp_output << "<td style='vertical-align: top;'>"
	tmp_output << link_to_function(image_tag('bullet_toggle_minus.png'), 'field_picklists.hide_field("title_contains")')
	tmp_output << form_object.label(field_criteria.to_sym)
	tmp_output << "</td>"
	tmp_output << "<td style='vertical-align: top;'>#{form_object.check_box field_criteria.to_sym, :class => 'txt'} #{options[:extra_text]}</td>"
	tmp_output << "</tr>"
	tmp_output
end

def search_criteria_select_field_row(form_object, conditions, field_criteria, select_array, options={})
	tmp_output = ''
	tmp_output << "<tr id='tr_#{field_criteria}' class='filter' style='#{(conditions.send(field_criteria).to_s != '') ? '' : 'display: none;'}'>"
	tmp_output << "<td style='vertical-align: top;'>"
	tmp_output << link_to_function(image_tag('bullet_toggle_minus.png'), 'field_picklists.hide_field("title_contains")')
	tmp_output << form_object.label(field_criteria.to_sym)
	tmp_output << "</td>"
	tmp_output << "<td style='vertical-align: top;'>"
	if field_criteria && conditions.send(field_criteria) && conditions.send(field_criteria).is_a?(Array)
		multiple = true
	else
		multiple = false
	end
	tmp_output << form_object.select(field_criteria.to_sym, select_array, { :include_blank => true }, :name => "search[conditions][#{field_criteria}][]", :multiple => multiple, :class => 'txt')
	tmp_output << link_to_function(image_tag("bullet_toggle_plus.png"), "field_picklists.toggle_multiple('search_conditions_market_segment_id')")
	tmp_output << "#{options[:extra_text]}</td>"
	tmp_output << "</tr>"
	tmp_output
end

def phone_line_color(category)
	case category  
		when '2ndinternalline'   # This is the name of the .ics file
			return 'f66'
		when '1stinternal'
			return '4f4'	
		when '2ndexternal'
			return 'fb4'
		when '1stexternal'
			return '77f'
		else  
			return 'fb4'
  end
end

def phone_line_name(category)
	case category  
		when '2ndinternalline'   # This is the name of the .ics file
			return '2nd Internal Line'
		when '1stinternal'
			return '1st Internal Line'	
		when '2ndexternal'
			return '2nd External Line'
		when '1stexternal'
			return '1st External Line'
		else  
			return 'Other'
  end
end

def strategic_project_indicator(project)
	if project.strategic_account?
		image_tag "admin/award_star_gold_blue.png", :title => "This project belongs to a strategic account."
	else
		""
	end
end

def strategic_company_indicator(company)
	if company.strategic_account?
		image_tag "admin/award_star_gold_blue.png", :title => "This company is a strategic account."
	else
		""
	end
end

def crm_display_task_cell(task)
	if task.closed?
		style = "background-color: #00FF00;"
	elsif task.overdue?
		style = "background-color: #CF6A4D;"
	elsif task.created?
		style = "background-color: #ffffff;"
	end
	content_tag(:td, crm_task_details(task), :style => style, :class => "cellborders")
end

def crm_task_excel(task, specific_field=nil)
	if task
		if specific_field
			if specific_field == "owner"
				return task.owner.full_name
			elsif specific_field == "due_date"
				return task.due_date.strftime('%d-%b-%Y')
			elsif specific_field == "status"
				if task.closed?
					"DONE"
				else
					if task.overdue?
						return "OVERDUE"
					else
						return "OPEN"
					end
				end
			end
		else
			unless task.closed?
				if task.overdue?
					"OVERDUE BY " + time_ago_in_words(task.due_date) + " Assigned to: #{task.owner.full_name} - Due: #{task.due_date.strftime('%d-%b-%Y')}"
				else
					time_ago_in_words(task.due_date) + " Assigned to: #{task.owner.full_name} - Due: #{task.due_date.strftime('%d-%b-%Y')}"
				end
			else
				completion_date = task.completed_date
				display_link = ""
				if completion_date
					display_link = "Done on " +  task.completed_date.strftime("%d-%b-%Y")
				else
					display_link = "Done"
				end
				display_link + " Assigned to: #{task.owner.full_name} - Due: #{task.due_date.strftime('%d-%b-%Y')}"
			end
		end
	end
end

def crm_client_care_task_details(task, quarter)
	task_info = crm_task_details(task)
	if !task_info.nil?
		quarter + " : " + task_info
	end
end

def crm_task_details(task)
	if task
		unless task.closed?
			if task.overdue?
				link_to("OVERDUE BY " + (time_ago_in_words(task.due_date) + 
					" <span>Assigned to: #{task.owner.full_name}<br/>Due: #{task.due_date.strftime('%d-%b-%Y')}<br/>Status: #{task.status}<br/> Detail: #{task.description}</span>"), {:controller => "crm", :action => "edit_task", :id => task}, {:class => "tooltip"})
			else
				link_to((time_ago_in_words(task.due_date) + 
					" <span>Assigned to: #{task.owner.full_name}<br/>Due: #{task.due_date.strftime('%d-%b-%Y')}<br/>Status: #{task.status}<br/> Detail: #{task.description}</span>"), {:controller => "crm", :action => "edit_task", :id => task}, {:class => "tooltip"})
			end
		else
			completion_date = task.completed_date
			display_link = ""
			if completion_date
				display_link = "Done on " +  task.completed_date.strftime("%d-%b-%Y")
			else
				display_link = "Done"
			end
			link_to((display_link +
				" <span>Assigned to: #{task.owner.full_name}<br/>Due: #{task.due_date.strftime('%d-%b-%Y')}<br/>Status: #{task.status}<br/> Detail: #{task.description}</span>"), {:controller => "crm", :action => "edit_task", :id => task}, {:class => "tooltip"})
		end
	end
end

def crm_display_task_details(project, type_of_task)
	task = project.send(type_of_task + "_task")
	crm_task_details task
end

def crm_display_calendar_task(task)
	if task.closed?
		completion_date = task.completed_date
		display_link = ""
		if completion_date
			display_link = " - Done on " +  task.completed_date.strftime("%d-%b-%Y")
		else
			display_link = " - Done "
		end
		link_to(task.task_type + display_link +
			" <span>#{task.summary}<br/>Assigned to: #{task.owner.full_name}<br/>Due: #{task.due_date.strftime('%d-%b-%Y')}<br/>Status: #{task.status}<br/> Detail: #{task.description}</span>", {:controller => "crm", :action => "edit_task", :id => task}, {:class => "tooltip"})
	else
		link_to(task.task_type + 
			" <span>#{task.summary}<br/>Assigned to: #{task.owner.full_name}<br/>Due: #{task.due_date.strftime('%d-%b-%Y')}<br/>Status: #{task.status}<br/> Detail: #{task.description}</span>", {:controller => "crm", :action => "edit_task", :id => task}, {:class => "tooltip"})
	end
end

def crm_display_for(record, field, options = {})
	return "" if !record.respond_to?(field.to_s)
	field_value = record.send(field).to_s
	if field_value == "true"
		field_value = "Yes"
	elsif field_value == "false"
		field_value = "No"
	end
	line_break = options[:break] ? "<br/>" : ""
	if field_value && !field_value.to_s.blank?
		label = options[:label].nil? ? field.to_s.humanize + ": " : options[:label] + ": "
		if !options[:container].nil?
			if options[:container] == "" || options[:container] == false
				content_tag(:label, content_tag(:strong, label)) + field_value + line_break
			else
				content_tag(options[:container], ontent_tag(:label, content_tag(:strong, label))) + field_value + line_break
			end
		else
			content_tag(:p,	content_tag(:label, content_tag(:strong, label)) + field_value) + line_break
		end
	else
		""
	end
end

def time_and_weather(address)
	results = "<p>"
	results << weather_for(address)
	time = time_for(address)
	if time != ""
		results << " at #{time}"
	end
	results << "</p>"
	results
end

def time_for(record)
	if !record.timezone.to_s.blank?
		Time.now.in_time_zone(record.timezone).strftime("%l:%M%p")
	else
		""
	end
end

def weather_for(record)
	results = ""
	if record.country.to_s.empty? || record.country.to_s == "US" || record.country.to_s == "USA"
		unless record.city.to_s.empty? && record.state.to_s.empty?
			cw = CurrentWeather.new "#{record.city},#{record.state}"
			if cw.data_found
				results = "<img src='#{cw.icon}' height='20' width='20' style='float:left;' title='#{cw.condition}'/> &nbsp;&nbsp;#{cw.temp} &deg;F"
			end
		end
	else
		unless record.city.to_s.empty? && record.country.to_s.empty?
			cw = CurrentWeather.new "#{record.city},#{record.country}"
			if cw.data_found
				results = "<img src='#{cw.icon}' height='20' width='20' style='float:left;' title='#{cw.condition}'/> &nbsp;&nbsp;#{cw.temp} &deg;F"
			end
		end
	end
	results
end

def crm_address_for(record)
	results = ""
	tmp_val = ""
	if record.address_line_1 && !record.address_line_1.to_s.blank?
		tmp_val = record.address_line_1
		if record.address_line_2 && !record.address_line_2.to_s.blank?
			tmp_val << "<br/>#{record.address_line_2}"
		end
		tmp_val << "<br/>"
	end
	unless record.city.to_s.empty? && record.state.to_s.empty? && record.zip.to_s.empty?
		tmp_city = ""
		if !record.city.to_s.empty?
			tmp_city << record.city
		end
		if !record.state.to_s.empty?
			tmp_city << ", " + record.state
		end
		
		if !record.country.to_s.empty? && !(record.country.to_s.downcase == 'us' or record.country.to_s.downcase == 'usa')
			tmp_city << " " + record.country
		end
		
		if !record.zip.to_s.empty?
			tmp_city << " " + record.zip
		end
		results << content_tag(:p,	content_tag(:strong, "Address <br/>") + tmp_val + tmp_city)
	end
	results
end

def edit_or_quick_admin_link(item)
	item_link = ""
	if item.class == User
		if find_user.admin? && find_user.has_privilege?('user','edit')
			item_link << link_to("QuickAdmin", {:controller => "admin/users", :action => "edit_user", :id => item.id}, :class => "action") + " <br/> "
		else
			item_link << link_to("Edit", {:controller => "crm", :action => "edit_contact", :id => item.id}, :class => "action") + " <br/> "
		end
		item_link << link_to("Request an update", {:controller => "change_requests", :action => "new", :user_id => item.id}, :class => "action") + "<br />"
	elsif item.class == Project
		if find_user.admin? && find_user.has_privilege?('project','edit')
			item_link << link_to("QuickAdmin", {:controller => "admin/users", :action => "edit_project", :id => item.id}, :class => "action") + " <br/> "
		end
		item_link << link_to("Request an update", {:controller => "change_requests", :action => "new", :project_id => item.id}, :class => "action") + "<br />"
	elsif item.class == Council
		if find_user.admin? && find_user.has_privilege?('council','edit')
			item_link << link_to("QuickAdmin", {:controller => "admin/users", :action => "edit_council", :id => item.id}, :class => "action") + " <br/> "
		end
		item_link << link_to("Request an update", {:controller => "change_requests", :action => "new", :project_id => item.id}, :class => "action") + "<br />"
	end
	item_link
end

def short_tag_name(tag_name)
	if tag_name.length > 12
		tag_name[0..12] + "..."
	else
		tag_name
	end
end

def contact_method_display(contact_method)
	if ["LinkedIn", "Twitter", "Facebook"].include?(contact_method.contact_method_type)
		'<span class="contact-method-item">' + link_to(image_tag("admin/" + contact_method.contact_method_type.to_s.downcase + ".png"), contact_method.contact_link_url) + 
			'<span class="delete-item">' + link_to_remote(image_tag("bullet_delete.png"),:confirm => "You are about to delete this contact method. Are you sure you want to delete this?", :url => {:controller => "crm", :action => 'delete_contact_method', :id => contact_method.user.id, :contact_method => contact_method.id}) + '</span></span>'
	elsif (contact_method.contact_method_type == "Email")
		content_tag(:p,	'<span class="contact-method-item"><a class="reduced" href="mailto:' + contact_method.contact_method_value.to_s + '">' + contact_method.contact_method_value.to_s + "</a> (#{contact_method.description})" +
			'<span class="delete-item">' + link_to_remote(image_tag("bullet_delete.png"),:confirm => "You are about to delete this contact method. Are you sure you want to delete this?", :url => {:controller => "crm", :action => 'delete_contact_method', :id => contact_method.user.id, :contact_method => contact_method.id}) + '</span></span>')
	else
		content_tag(:p,	'<span class="contact-method-item">' + contact_method.contact_method_value.to_s + " (#{contact_method.description})" +
			'<span class="delete-item">' + link_to_remote(image_tag("bullet_delete.png"),:confirm => "You are about to delete this contact method. Are you sure you want to delete this?", :url => {:controller => "crm", :action => 'delete_contact_method', :id => contact_method.user.id, :contact_method => contact_method.id}) + '</span></span>')
	end
end

def select_for_user_searchable_fields
	result = '<select class="select-small" id="add_filter_select" name="add_filter_select" onchange="field_picklists.show_field();"><option value=""></option>'
	AvailableColumn.filterable_columns_for_picklist("User").each do |searchable_field|
		result << '<option value="' + searchable_field.first + '">' + searchable_field.last + '</option>'
	end
	result << '</select>'
	result
end

def project_company_link(project)
	result = ''
	if project.company
		result = image_tag('/images/link.png', :alt => 'linked to company', :title => 'This project is linked to a company', :class => 'icon')
	end
	result
end

def contact_company_link(contact)
	result = ''
	if contact.linked_company
		result = link_to(image_tag('/images/link.png', :alt => 'linked to company', :title => 'This contact is linked to a company', :class => 'icon'), 
			:controller => "crm", :action => "company", :id => contact.linked_company.id)
	end
	result
end

def contact_company_name_link(contact, link_controller="crm")
	result = contact.company
	if contact.linked_company
		conditions = {"company_id" => contact.company_id}
		search = {"conditions" => conditions}
		if link_controller == "users"
			result = link_to contact.company, :action => "list_user", :search => search
		else
			result = link_to contact.company, :action => "company", :id => contact.linked_company.id
		end
	end
	result
end

def crm_result_pages(collection, page_size=10)
	r = ''
	if collection.page_count > 1
		r << "<p id=\"pagination\"> "
		params[:page] = collection.current.previous
		r << link_to_if(collection.current.previous, "&lt; Previous</a>&nbsp;&nbsp;", {:params => params})
		window = ActionController::Pagination::Paginator::Window.new collection.current, page_size
		window.pages.each do |page|
			if page == collection.current
				r << "<span class=\"thispage\">#{page.number}</span>" if page == collection.current
			else
				params[:page] = page.number
				r << link_to(page.number, {:params => params})
			end
			r << "&nbsp;&nbsp;"
		end
		params[:page] = collection.current.next
		r << link_to_if(collection.current.next, "Next &gt;</a>&nbsp;&nbsp;", {:params => params})
		r << "</p>"
	end
	r
end

def fckeditor_textarea_tag(name, content = nil, options = {})
  id = options[:id].blank? ? name : options[:id]

  cols = options[:cols].nil? ? '' : "cols='" + options[:cols] + "'"
  rows = options[:rows].nil? ? '' : "rows='" + options[:rows] + "'"

  width = options[:width].nil? ? '100%' : options[:width]
  height = options[:height].nil? ? '100%' : options[:height]

  toolbarSet = options[:toolbarSet].nil? ? 'Default' : options[:toolbarSet]

  if options[:ajax]
    inputs = "<input type='hidden' id='#{id}_hidden' name='#{name}'>\n" +
             "<textarea id='#{id}' #{cols} #{rows} name='#{id}'>#{content}</textarea>\n"
  else
    inputs = "<textarea id='#{id}' #{cols} #{rows} name='#{name}'>#{content}</textarea>\n"
  end

  base_path = ActionController::Base.relative_url_root.to_s + '/javascripts/fckeditor/'
  inputs +
  javascript_tag( "var oFCKeditor = new FCKeditor('#{id}', '#{width}', '#{height}', '#{toolbarSet}');\n" +
                  "oFCKeditor.BasePath = \"#{base_path}\"\n" +
                  "oFCKeditor.Config['CustomConfigurationsPath'] = '../../fckcustom.js';\n" +
                  "oFCKeditor.ReplaceTextarea();\n")
end

end
