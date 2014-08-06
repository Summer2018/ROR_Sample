class User < ActiveRecord::Base
	attr_accessor :logged_in
	attr_accessor :cookie_login
	attr_accessor :password_confirmation
	attr_accessor :contact_data
	attr_accessor :email_addresses
	attr_accessor :goldmine_email_addresses
	attr_accessor :entitled_databases
	attr_accessor :entitled_newsletters
	attr_accessor :admin_privileges
	attr_accessor :net_suite_contact_name
	attr_accessor :councils
	before_save :reset_bounces_on_email_change
	before_save :set_full_name
	before_save :reset_company_link
	before_save :set_has_address_flag
	before_destroy :check_for_connections
	before_validation_on_create :setup_password_and_salt

	IMPORT_FIELDS = ["first_name", "last_name", "email", "company", "title", "phone", "zipcode", "market_segment_id", "assigned_ae_id", "address_line_1", "address_line_2", "city", "state", "country" ]
	REQUIRED_FIELDS = ["first_name", "last_name", "email", "company", "title" ]
	SALUTATIONS = ["Mr.","Ms.","Miss","Dr.", "Dame", "Sir", "Mrs.", "Madam"]
	USER_TYPES = ["User","GoldMineContact","NetSuiteContact"]
	APPLICATION_SOURCES = ["GoldMine", "QuickAdmin", "QuickView", "NetSuite", "Web", "System"]
	GROUP_BY_FIELDS = [["Segment", "segment"],
		["Level", "contact_level"],
		["Function", "contact_function"],
		["Market Segment", "market_segment"],
		["Lead Type", "lead_source_type"],
		["CSE", "assigned_ae"]]
	acts_as_tag_owner
	acts_as_user_taggable
	maintain_audit_log

	has_many :user_privileges, :dependent => :destroy
	has_many :privileges, :class_name => 'Privilege', :through => :user_privileges, :source => :privilege
	has_many :user_entitlements, :dependent => :destroy
	has_many :reports, :through => :user_entitlements, :source => :report, :conditions => "user_entitlements.entitlement_type = 'Report'"
	has_many :event_seats, :through => :user_entitlements, :source => :event_seat, :conditions => "user_entitlements.entitlement_type = 'EventSeat'"
	has_many :packages, :through => :user_entitlements, :source => :package, :conditions => "user_entitlements.entitlement_type = 'Package'"
	has_many :subscription_products, :through => :user_entitlements, :source => :subscription_product, :conditions => "user_entitlements.entitlement_type = 'SubscriptionProduct'"
	has_many :paid_subscription_products, :through => :user_entitlements, :source => :subscription_product, :conditions => "user_entitlements.entitlement_type = 'SubscriptionProduct' AND user_entitlements.is_trial != 1 AND user_entitlements.is_comp != 1 AND subscription_products.price IS NOT NULL AND subscription_products.price != 0"
	has_many :saved_reports, :dependent => :destroy, :order => 'updated_at DESC'
	has_many :purchases, :class_name => 'Order'
	has_many :completed_purchases, :class_name => 'Order', :conditions => "orders.state = 'PAID'"
	has_many :user_logins, :dependent => :destroy
	has_many :trial_requests, :dependent => :destroy
	has_many :search_logs, :dependent => :destroy
	has_many :site_activity_logs, :dependent => :destroy
	has_many :addresses, :class_name => 'UserAddress', :dependent => :destroy
	has_many :distribution_members, :dependent => :destroy
	has_one :primary_address, :class_name => 'UserAddress', :conditions => "is_primary = 1"
	has_many :contact_methods, :class_name => 'UserContactMethod', :order => "Field(contact_method_type,'Phone','Fax','Email','Other','LinkedIn','Twitter','Facebook')"
	has_many :bounces, :class_name => 'Bounce'
	has_many :gold_mine_contact_activity_records, :order => 'on_date DESC'
	has_many :sent_deliverables, :class_name => 'UserSentDeliverable', :dependent => :destroy
	has_many :sent_blog_posts, :class_name => 'UserSentDeliverable', :conditions => "deliverable_type='WordPress::BlogPost'"
	has_many :sent_reports, :class_name => 'UserSentDeliverable', :conditions => "deliverable_type='Report'"
	has_many :sent_headlines, :class_name => 'UserSentDeliverable', :conditions => "deliverable_type='DataAssets::Headline'"
	has_many :sent_welcome_messages, :class_name => 'UserSentDeliverable', :conditions => "deliverable_type='UserWelcomeMessage'"	
	has_many :subscription_preferences, :class_name => 'UserSubscriptionPreference', :dependent => :destroy
	has_many :blog_posts
	has_many :event_option_selections, :class_name => 'UserEventOptionSelection'
	has_many :assigned_products, :class_name => 'Package', :foreign_key => 'analyst_id'
	has_many :assigned_project_entitlements, :class_name => 'ProjectEntitlement', :foreign_key => 'analyst_id'
	has_many :analyst_projects, :through => :assigned_project_entitlements, :source => :project, :order => 'projects.project_name'
	has_many :sales_projects, :class_name => 'Project', :foreign_key => 'account_executive_id', :order => 'project_name'
	has_many :analyst_open_projects, :through => :assigned_project_entitlements, :source => :project, :uniq => true, :order => 'projects.project_name', :conditions => "projects.status = 'OPEN'"
	has_many :sales_open_projects, :class_name => 'Project', :foreign_key => 'account_executive_id', :uniq => true, :order => 'project_name', :conditions => "projects.status = 'OPEN'"
	has_many :analyst_closed_projects, :through => :assigned_project_entitlements, :source => :project, :uniq => true, :order => 'project_name', :conditions => "projects.status = 'CLOSED'"
	has_many :sales_closed_projects, :class_name => 'Project', :foreign_key => 'account_executive_id', :uniq => true, :order => 'project_name', :conditions => "projects.status = 'CLOSED'"
	has_many :owned_projects, :class_name => 'Project', :foreign_key => 'owner_id'
	has_many :user_favorites, :class_name => 'UserFavorite', :foreign_key => 'user_id'
	has_many :user_favorite_groups, :class_name => 'UserFavoriteGroup', :foreign_key => 'user_id'
	has_many :recent_places, :limit => 10, :group => "recent_controller, recent_action, recent_id", :order => "MAX(created_at) DESC"
	has_many :assigned_users, :class_name => "User", :foreign_key => "assigned_ae_id"
	has_many :quick_view_track_messages, :foreign_key => "created_user_id", :order => "created_at DESC"
	has_many :annotations, :class_name => 'Note', :foreign_key => "owner_id", :order => "created_at DESC"
	has_many :portfolios
	has_many :change_requests
	has_many :submitted_change_requests, :class_name => "ChangeRequest", :foreign_key => "created_by_user_id"
	has_many :relationships_from, :class_name => 'UserRelationship', :foreign_key => 'from_user_id', :dependent => :delete_all
	has_many :relationships_to, :class_name => 'UserRelationship', :foreign_key => 'to_user_id', :dependent => :delete_all
	has_many :search_agents, :dependent => :delete_all
	has_many :saved_im_metrics, :class_name => 'SavedImMetric', :foreign_key => 'user_id'
	has_many :content_ratings
	has_many :notes, :as => :annotated, :dependent => :delete_all, :order => 'created_at DESC'
	has_many :project_memberships, :class_name => "ProjectMember"
	has_many :projects, :through => :project_memberships, :order => "projects.status DESC, FIELD(project_type, 'SUBSCRIPTION', 'CUSTOM', 'OTHER', 'LIST'), projects.end_date ASC", :after_add => :audit_log_add_habtm, :before_remove => :audit_log_remove_habtm
	has_many :closed_projects, :through => :project_memberships, :class_name => "Project", :conditions => "projects.status = 'CLOSED'"
	has_many :open_projects, :through => :project_memberships, :class_name => "Project", :conditions => "projects.status = 'OPEN'"
	has_many :subscription_projects, :through => :project_memberships, :source => :project, :order => "projects.status DESC, projects.end_date ASC", :conditions => "projects.project_type = 'SUBSCRIPTION'"
	has_many :custom_projects, :through => :project_memberships, :source => :project, :order => "projects.status DESC, projects.end_date ASC", :conditions => "projects.project_type = 'CUSTOM'"
	has_many :other_projects, :through => :project_memberships,  :source => :project, :order => "projects.status DESC, projects.end_date ASC", :conditions => "projects.project_type != 'SUBSCRIPTION' AND projects.project_type != 'CUSTOM'"
	has_many :authored_insights,  :class_name => "WordPress::Post", :foreign_key => "post_author"
	has_many :leads
	has_many :tasks, :foreign_key => 'owner_id', :order => 'due_date'
	has_many :related_tasks, :foreign_key => 'user_id', :order => 'due_date', :class_name => "Task"
	has_many :onboarding_steps, :include => :task_group, :foreign_key => 'user_id', :order => 'due_date', :class_name => "Task", :conditions => "task_groups.name like '%Onboarding%'"
	has_one :contact_info_cache, :dependent => :destroy
	has_one :latest_activity, :dependent => :destroy
	has_one :visitor, :dependent => :destroy
	has_one :avatar
	has_one :user_profile
	belongs_to :created_by_user, :class_name => 'User', :foreign_key => 'created_by_id'
	belongs_to :employee
	belongs_to :segment
	belongs_to :market_segment
	belongs_to :job_function
	belongs_to :net_suite_company
	belongs_to :linked_company, :class_name => "DataAssets::Company", :foreign_key => 'company_id'
	belongs_to :assigned_ae, :class_name => 'User', :foreign_key => 'assigned_ae_id'
	belongs_to :last_verified_by, :class_name => 'User', :foreign_key => 'last_verified_by_id'
	belongs_to :contact_level
	belongs_to :contact_function
	belongs_to :lead_source_type
	has_and_belongs_to_many :promotions, :join_table => 'users_promotions'
	has_and_belongs_to_many :distributions, :join_table => 'distribution_members'
	has_and_belongs_to_many :successful_distributions, :class_name => 'Distribution', :join_table => 'distribution_members', :conditions => "distribution_members.status='COMPLETED'", :order => 'distribution_members.updated_at DESC'
	has_and_belongs_to_many :successful_report_distributions, :class_name => 'Distribution', :join_table => 'distribution_members', :conditions => "distributions.distribution_type='Report' AND distribution_members.status='COMPLETED'", :order => 'distribution_members.updated_at DESC'
	has_and_belongs_to_many :contact_type

	validates_presence_of :first_name, :last_name, :email, :company, :application_source, :title
	validates_presence_of :password, :if => Proc.new { |record| record.user_type == "User" }
	validates_inclusion_of :user_type, :in=>USER_TYPES, :message=>"Users must be one of User, GoldMineContact or NetSuiteContact"
	validates_inclusion_of :application_source, :in => APPLICATION_SOURCES
	
	validates_format_of :email,
	            :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i,
	            :message => I18n.translate('activerecord.errors.messages')[:email],
	            :if => Proc.new {|u| not u.email.blank?}
	validates_length_of :password, :minimum => 3, :too_short => "Your password must be at least 6 characters long."
	validates_format_of :password,
	            :with => /^\S+$/,
	            :message => I18n.translate('activerecord.errors.messages')[:password],
	            :if => Proc.new {|u| (not u.password.blank?) && (u.user_type == "User")}

	validates_uniqueness_of :email
	validates_confirmation_of :password
	
	concerned_with "finders"
	concerned_with "preferences"
	concerned_with "contact_info"
	concerned_with "history"
	concerned_with "entitlements"
	concerned_with "authentication"
	concerned_with "headshot"
	
	def self.update_last_report_distributions
		self.find(:all).each do |user|
			if user.latest_activity.nil?
				latest_activity = user.build_latest_activity
			else
				latest_activity = user.latest_activity
			end
			
			last_report = user.last_successful_report_distribution
			if last_report
				latest_activity.last_successful_report_distribution = last_report.send_date
				latest_activity.last_successful_report_name = last_report.report.title unless last_report.report.nil?
			end
			latest_activity.save
		end
	end

	def self.update_all_net_suite_quick_view_links(additional_conditions="")
		self.find(:all, :conditions => "net_suite_id IS NOT NULL #{additional_conditions}").each do |user|
			NetSuiteService.update_quick_view_link(user)
		end
	end
	
	def password_hash(plaintext)
		Digest::MD5.hexdigest(" SOMe piece.of mystery-text" + plaintext.to_s)
	end
	
	def recent_insights
		if insights_author?
			authored_insights.find(:all, :order => "post_date DESC", :limit => 5)
		end
	end
	
	def already_rated?(content, question)
		content_ratings.count(:conditions => ["content_type = ? AND content_id = ? AND rating_question_id = ?", content.class.to_s, content.id, question]) > 0
	end
		
	def exceeds_email_bounce_limit?
		if email_bounce_counter.nil?
			false
		elsif email_bounce_counter > EMAIL_BOUNCE_CUTOFF
			true
		end
	end
	
	def all_accessible_reports
		@all_accessible_reports=[]
		if self.packages.count > 0
			self.packages.each do |package|
				@all_accessible_reports << package.reports
			end 
		end
		if self.reports.count > 0
			@all_accessible_reports << self.reports
		end
		@all_accessible_reports.flatten.uniq.sort_by{|a| a.pub_date }.reverse
	end
	
	def mark_registered
		update_attribute("registered", 1)
	end
	
	def report_preferences_mismatch?
		mismatch = false
		delivery_pref_hash = reports_preferences
		if delivery_pref_hash
			unless delivery_pref_hash['topics'].include? "-9"
				topic_ids = delivery_pref_hash['topics'].split(",").collect{|x| x.to_i}
			end
		end
		if topic_ids
			packages.each do |package|
				if package.segment_id == -9
					mismatch = true
				elsif !topic_ids.include?(package.segment_id)
					mismatch = true
				end
			end
		end
		mismatch
	end

	def name_for_comments
		"#{first_name} #{last_name.first}."
	end
		
	def full_name_and_email
		ret = ''
		if (first_name.nil? or first_name.blank?) and (last_name.nil? or last_name.blank?)
			ret = email
		elsif first_name.nil? or first_name.blank?
			ret = "#{last_name} <#{email}>"
		elsif last_name.nil? or last_name.blank?
			ret = "#{first_name} <#{email}>"
		else
			ret = "#{full_name} <#{email}>"
		end
		ret
	end

	def councils
		@councils = []
		packages.each do |package|
			@councils << package.council unless package.council.nil?
		end
		@councils
	end
	
	def preferred_dear_name
		dear.to_s.empty? ? first_name : dear
	end
	
	def net_suite_company_linked?
		net_suite_company.nil? ? "No" : "Yes"
	end
	
	def net_suite_contact_name
		if @net_suite_contact_name
			@net_suite_contact_name
		else
			ns = NetSuiteContact.new(net_suite_id)
			if ns
				if ns.contact_data
					@net_suite_contact_name = ns.contact_data.entityId
				end
			end
		end
	end

	def overdue_tasks
		tasks.find(:all, :conditions => ["due_date < ? AND status NOT IN (?)", Date.today, Task::CLOSED_STATUSES])
	end

	def daily_tasks
		tasks.find(:all, :conditions => ["due_date > ? AND due_date < ? AND status NOT IN (?)", Date.today-1.day, Date.today + 1.day, Task::CLOSED_STATUSES])
	end

	def weekly_tasks
		tasks.find(:all, :conditions => ["due_date > ? AND due_date < ? AND status NOT IN (?)", Date.today-1.day, Date.today + 1.week, Task::CLOSED_STATUSES])
	end

	def apply_task_template(task_template, template_start_date=Time.now, template_end_date=Time.now)
		tg = TaskGroup.new :name => "#{task_template.name} for #{full_name} on #{Time.now.strftime('%Y-%b-%d')}"
		tg.save
		task_template.task_template_tasks.each do |t|
			# determine due date and owner
			if t.relative_start_date == "start_date"
				task_due_date = template_start_date + t.days_due_from_relative_start_date.days
			elsif t.relative_start_date == "end_date"
				task_due_date = template_end_date + t.days_due_from_relative_start_date.days
			elsif t.relative_start_date == "now"
				task_due_date = t.days_due_from_relative_start_date.days.from_now
			else
				task_due_date = 7.days.from_now
			end

			if t.default_owner == "analyst"
				if la
					task_owner = la
				else
					task_owner = account_executive
				end
			elsif t.default_owner == "council_chair"
				if packages && packages.first && packages.first.council
					task_owner = packages.first.council.account_executive
				else
					task_owner = account_executive
				end
			elsif t.default_owner == "account_executive"
				task_owner = account_executive
			elsif t.default_owner == "other"
				task_owner = t.default_owner_user
			else
				task_owner = account_executive
			end

			add_task t.task_type, task_due_date, task_owner, false, tg
		end
	end

	def add_task(type_of_task, due_date, owner, notify_owner, group=nil)
		# Don't assign tasks on the weekends
		if due_date.wday == 6
			due_date = due_date - 1.day
		end
		if due_date.wday == 0
			due_date = due_date - 2.day
		end

		related_tasks.create :task_type => type_of_task, 
			:due_date => due_date, :notify_owner => notify_owner,
			:summary => "#{type_of_task} for #{full_name}", :owner => owner, :task_group => group
	end

	def onboarding_setup?
		onboarding_steps.count > 0
	end

	def onboarding_started?
		onboarding_steps.count(:all, :conditions => "status = 'COMPLETE'") > 0
	end

	def onboarding_sent?
		onboarding_steps.count(:all, :conditions => "status = 'COMPLETE' and task_type = 'Welcome letter'") > 0
	end

	def onboarding_welcome_setup?
		onboarding_steps.count(:all, :conditions => "task_type = 'Initial letter'") > 0
	end

	def onboarding_welcome_sent?
		onboarding_steps.count(:all, :conditions => "status = 'COMPLETE' and task_type = 'Initial letter'") > 0
	end

	def onboarding_welcome_task
		onboarding_steps.find(:first, :conditions => "task_type = 'Initial letter'")
	end

	def task_for_task_type(task_type)
		onboarding_steps.find(:first, :conditions => ["task_type = ?", task_type])
	end

	def has_related_task?(task_type)
		onboarding_steps.count(:all, :conditions => ["task_type = ?", task_type]) > 0
	end

	def related_task_completed?(task_type)
		onboarding_steps.count(:all, :conditions => ["status = 'COMPLETE' and task_type = ?", task_type]) > 0
	end

	def net_suite_company_contact_name
		net_suite_company_customer_id_and_name + " : " + net_suite_contact_name.to_s
	end

	def net_suite_linked?
		(net_suite_id == 0) ? "No" : "Yes"
	end
	
	def gold_mine_linked?
		if goldmine_account_number.nil? || goldmine_account_number == 0
			return "No"
		elsif contact_info.nil? || contact_info.contact_data.nil? || contact_info.contact_data.empty?
			# does GM id no longer function
			return "No"
		else
			return "Yes"
		end
	end
	
	def project_membership_status(project)
		pm = project_memberships.find(:first, :conditions => ["project_id = ?", project.id])
		if pm
			pm.status.nil? ? "" : pm.status.to_s 
		else
			""
		end
	end
	
	def project_member_created_date(project)
		pm = project_memberships.find(:first, :conditions => ["project_id = ? and user_id = ?", project.id, id])
		if pm
			pm.created_at.nil? ? "" : pm.created_at.strftime("%Y-%m-%d") 
		else
			""
		end
	end
	
	def sub_project_name_status(project)
		status = ""
		project.children.each do |project|
			if project.users.include?(self)
				status << project.project_name
			end
		end
		status
	end

	def profile_bio
		user_profile.nil? ? "" : user_profile.bio.to_s
	end

	def profile_interests
		user_profile.nil? ? "" : user_profile.interests.to_s
	end
	
	def account_executive_name
		account_executive.nil? ? "" : account_executive.full_name
	end
	
	def created_by_user_name
		created_by_user.nil? ? "System" : created_by_user.full_name
	end

	def last_bounce_date
		most_recent_bounce = bounces.find(:first, :order => "created_at DESC")
		most_recent_bounce.nil? ? nil : most_recent_bounce.created_at
	end
	
	def account_executive
		# get account exec from user record
		# if that fails, get the AE for the user's segment;
		# if that fails, return nil
		ae = nil
		if assigned_ae && assigned_ae.employee
			ae = assigned_ae.employee
		end
		ae
	end
	
	def lead_analyst
		# get lead analyst from projects assigned to this user;
		# if that fails, get the LA for the user's segment;
		# if that fails, return nil
		la = nil
		analysts = Array.new
		unless open_projects.empty?
			open_projects.each do |p|
				next if (p.project_type != 'SUBSCRIPTION' && p.project_type != 'CONTINUOUS CUSTOM')
				if !p.analysts.nil? && !p.analysts.empty?
					analysts += p.analysts
				end
			end
		end
		analysts.compact!
		if !analysts.nil? && !analysts.empty?
			la = analysts.first
		else
			unless segment.nil?
				la = segment.lead_analyst.user
			end
		end
		la
	end

	def no_marketing_messages?
		marketing_messages_ok != 1
	end
	
	def no_subscription_messages?
		subscription_messages_ok != 1
	end

	def employee?
		is_employee == "Y"
	end

	def is_employee?
		is_employee == "Y"
	end
	
	def active_employee?
		employee? && !employee.nil? && employee.current?
	end

	def admin?
		is_admin == "1"
	end
	alias is_admin? admin?

	def thinking_out_loud_author?
		!thinking_out_loud_author.nil? && thinking_out_loud_author > 0
	end

	def insights_author?
		!enewsletter_level.nil? && enewsletter_level > 0
	end

	def enabled?
		!disabled?
	end
	
	def disabled?
		disabled == 1 and (disabled_date.nil? or DateTime.now > disabled_date)
	end
	
	def archived?
		archived == 1
	end
	
	def status
		if disabled? and archived?
			status = 'Archived and Disabled'
		elsif disabled?
			status = 'Disabled'
		elsif archived?
			status = 'Archived'
		else
			status = 'Active'
		end
		status
	end
	
	def active?
		!disabled? and !archived?
	end
	
	def make_up_password
		first_name.to_s.delete(" ").downcase + last_name.to_s.strip[0..0].downcase + '-' + ['zero', 'tulip', 'snow', 'wind', 'iris', 'lily', 'jade', 'park', 'rain', 'sun', 'leaf', 'tree', 'daisy'][Time.now.strftime('%I').to_i]
	end
	
	def forgot_password!
		write_attribute :confirmation_token, Digest::SHA1.hexdigest("--#{salt}--#{password}--")
		save(false)
	end

	def expire_date
		user_entitlements.minimum :renewal_date
	end

	def market_segment_name
		market_segment.nil? ? "N/A" : market_segment.name
	end

	def segment_name
		segment.nil? ? "N/A" : segment.caption
	end

	def segment_dashboard
		if segment.nil? or segment.visible == 'N'
			'/all_segments'
		else
			'/' + segment.url_text
		end
	end

	def homepage
		'/dashboard'
	end

	def analyst_access?
		user_entitlements.count(:all, :conditions => "notes = 'Analyst Access'") > 0
	end

	def decision_maker?
		is_decision_maker?
	end

	def client?
		!reports.empty? || !packages.empty?  || !paid_subscription_products.empty?
	end

	def subscription_client?
		!packages.empty?
	end

	def demo_client?
		!subscription_products.find(:all,:conditions => "user_entitlements.is_trial = 1").empty?
	end

	def client_for_event_seat_pricing?
		client?
	end
	
	def package_names
		packages.collect{|p| p.short_name}.join(", ")
	end

	def project_names
		projects.collect{|p| p.project_name}.join(", ")
	end
	
	def deliverable_names
		subscription_products.collect{|p| p.name}.join(",")
	end
	
	def primary_address_line
		primary_address.nil? ? "" : primary_address.address_line_1.to_s + "," + primary_address.address_line_2.to_s
	end
	
	def primary_address_city
		primary_address.nil? ? "" : primary_address.city.to_s
	end
	
	def primary_address_state
		primary_address.nil? ? "" : primary_address.state.to_s
	end

	def primary_address_country
		primary_address.nil? ? "" : primary_address.country.to_s
	end

	def primary_address_postal_code
		primary_address.nil? ? "" : primary_address.zip.to_s
	end

	def company_description
		if linked_company
			linked_company.description
		else
			""
		end
	end
	
	def linked_company_name
		if linked_company
			linked_company.company_name
		else
			""
		end
	end

	def company_segment
		if linked_company
			linked_company.primary_segment_name
		else
			""
		end
	end

	def linked_to_company?
		linked_company.nil? ? false : true
	end

	def company_revenue
		if linked_company
			linked_company.current_year_total_revenue_in_millions
		else
			""
		end
	end
	
	def company_employee
		if linked_company
			linked_company.current_year_employees.to_i
		else
			""
		end
	end

	def parent_company
		if linked_company && linked_company.parent
			linked_company.parent.company_name
		else
			""
		end
	end

	def mobile_phone
		if contact_methods.nil?
			""
		else
			tmp_method = contact_methods.find(:first, :conditions => "contact_method_type='Phone' and (description = 'Mobile' or description = 'Cell')")
			if tmp_method
				tmp_method.contact_method_value
			else
				""
			end
		end
	end
	
	def contact_level_name
		contact_level.nil? ? "" : contact_level.name
	end
	
	def contact_function_name
		contact_function.nil? ? "" : contact_function.name
	end
	
	def job_function_name
		job_function.nil? ? "" : job_function.name
	end
	
	def merge_into(existing_contact)
		RAILS_DEFAULT_LOGGER.info "Checking if this is an employee "
		return false if employee?
		merge_success = false
		transaction do
			RAILS_DEFAULT_LOGGER.info "Updating standard has_many associations"
			notes.update_all "annotated_id = #{existing_contact.id}"
			user_entitlements.update_all "user_id = #{existing_contact.id}"
			saved_reports.update_all "user_id = #{existing_contact.id}"
			purchases.update_all "user_id = #{existing_contact.id}"
			user_logins.update_all "user_id = #{existing_contact.id}"
			trial_requests.update_all "user_id = #{existing_contact.id}"
			search_logs.update_all "user_id = #{existing_contact.id}"
			site_activity_logs.update_all "user_id = #{existing_contact.id}"
			addresses.update_all "is_primary = 0"
			addresses.update_all "user_id = #{existing_contact.id}"
			# Delete duplicate contact methods between the two
			existing_contact.contact_methods.each do |existing_contact_method|
				UserContactMethod.delete_all("user_id = #{id} AND contact_method_type = '#{existing_contact_method.contact_method_type}' 
					AND contact_method_value = '#{existing_contact_method.contact_method_value}' AND description = '#{existing_contact_method.description.gsub("'", %q(\\\'))}'")
			end
			contact_methods.update_all "user_id = #{existing_contact.id}"
			gold_mine_contact_activity_records.update_all "user_id = #{existing_contact.id}"
			sent_deliverables.update_all "user_id = #{existing_contact.id}"
			user_tagged_items.update_all "tagged_item_id = #{existing_contact.id}", "tagged_item_type='User'"

			# If the new user doesn't have any - then migrate these
			RAILS_DEFAULT_LOGGER.info "Updating event_option_selections"
			if existing_contact.event_option_selections.empty?
				event_option_selections.update_all "user_id = #{existing_contact.id}"
			else
				event_option_selections.destroy_all
			end

			# If the new user doesn't have any - then migrate these
			RAILS_DEFAULT_LOGGER.info "Updating subscription_preferences"
			if existing_contact.subscription_preferences.empty?
				subscription_preferences.update_all "user_id = #{existing_contact.id}"
			else
				subscription_preferences.destroy_all
			end

			RAILS_DEFAULT_LOGGER.info "Updating merged into contact projects"
			projects.each do |merged_user_project|
				unless existing_contact.projects.include? merged_user_project
					existing_contact.projects << merged_user_project
				end
			end

			RAILS_DEFAULT_LOGGER.info "Clearing projects, promotions and distributions"
			projects.clear
			promotions.clear
			distributions.clear

			# Now copy in values where there are none
			RAILS_DEFAULT_LOGGER.info "Merging user values"
			existing_contact.attributes = attributes.merge(existing_contact.attributes){|key,oldval,newval| newval.nil? ? oldval : newval  }
			# Add a note to the notes field
			RAILS_DEFAULT_LOGGER.info "Updating notes in existing contact"
			if existing_contact.internal_notes.nil?
				existing_contact.internal_notes = "Merged from contact #{full_name} - #{email} (#{id})"
			else
				existing_contact.internal_notes << "\nMerged from contact #{full_name} - #{email} (#{id})"
			end
			existing_contact.save
			RAILS_DEFAULT_LOGGER.info "Deleting"
			merge_success = true if destroy != false
		end
		merge_success
	end
	
	def has_been_sent_this_blog_post?(post, format)
		sent_blog_posts.count(:all, :conditions => ["deliverable_id = ? AND format = ?", post.id, format]) > 0
	end
	
	def unsubscribe_hash
		if public_hash.nil?
			if last_name.nil?
				ln = 'nil'
			else
				ln = last_name
			end
			if first_name.nil?
				fn = 'nil'
			else
				fn = first_name
			end
			hash = Digest::MD5.hexdigest(ln + " SOMe	piece.of mystery-text" + fn + id.to_s + DateTime.now.to_s)[0..20]
			unless new_record?
				update_attribute :public_hash, hash
			end
		end
		public_hash
	end
	
	def public_id
		unless new_record?
			sprintf "%x", (id + 42101070890)
		end
	end
	
	def admin_privileges
		@admin_privileges ||= user_privileges.find(:all, :include => :privilege).map{|x| x.privilege.item + "--" + x.privilege_type}
	end
	
	def has_privilege?(itemtype, operation)
		admin_privileges.include?(itemtype + "--" + operation)
	end
	
	def has_any_privilege_for_item?(itemtype)
		admin_privileges.find{|priv| priv =~ /^#{itemtype}--/}
	end

	def opened_email_image(distribution_id)
		"http://#{WEB_ADDRESS}/em/#{public_id}-#{distribution_id}.gif"
	end

	def opened_report_image(report)
		"http://#{WEB_ADDRESS}/rem/#{public_id}-#{report.id}.gif"
	end

	def opened_insights_image(insight)
		"http://#{WEB_ADDRESS}/insights/image/#{public_id}-#{insight.id}"
	end
	
	def opened_daily_headlines_image(distribution_id)
		"http://#{WEB_ADDRESS}/em/#{public_id}-#{distribution_id}.gif"
	end

	def olc_onboarding_url
		idstring = password + email
		digest_value = Digest::MD5.hexdigest( idstring )
		"https://olc.outsellinc.com/welcome.html?token=#{digest_value}"
	end

	def unsubscribe_url_for_product(product_name='')
		short = ''
		short = 'hl' if product_name =~ /^headlines$/i
		short = 'in' if product_name =~ /^insights$/i
		short = 'ra' if product_name =~ /^Research Advisory$/i
		short = 'me' if product_name =~ /^marketing_emails$/i
		"http://#{WEB_ADDRESS}/unsub_#{short}?a=#{unsubscribe_hash}&b=#{public_id}"
	end

	def unsubscribe_url(distribution_id)
		"http://#{WEB_ADDRESS}/unsub_me?a=#{unsubscribe_hash}&b=#{public_id}&d=#{distribution_id}"
	end
	
	def sent_setup_message?
		sent_setup_message==1
	end
	alias sent_welcome_message? sent_setup_message?
	alias insights_entitled? osnow_entitled?
	
	def remaining_connections
		connections = []
		connections << "Entitlements" unless user_entitlements.empty?
		connections << "Saved reports" unless saved_reports.empty?
		connections << "Purchases" unless purchases.empty?
		connections << "Logins" unless user_logins.empty?
		connections << "Search logs" unless search_logs.empty?
		connections << "Site activity" unless site_activity_logs.empty?
		connections << "Sent deliverables" unless sent_deliverables.empty?
		connections << "Projects" unless projects.empty?
		connections << "Distributions" unless distributions.empty?
		connections << "Owned projects" unless owned_projects.empty?
		connections
	end

	private
	def check_for_connections
		remaining_connections.empty?
	end
			
	def reset_bounces_on_email_change
		if changes && changes["email"]
			self.email_bounce_counter = 0
		end
	end
	
	def set_full_name
		write_attribute :full_name, first_name + ' ' + last_name
	end
	
	def reset_company_link
		if linked_company && (company != linked_company.company_name)
			write_attribute(:company_id, nil)
		end
	end

	def set_has_address_flag
		if primary_address && (!primary_address.address_line_1.to_s.empty? && (!primary_address.city.to_s.empty? || !primary_address.state.to_s.empty? || !primary_address.country.to_s.empty?))
			write_attribute(:has_mailing_address, 1)
		else
			write_attribute(:has_mailing_address, 0)
		end
	end

	def setup_password_and_salt
		if new_record?
			if password.blank?
				write_attribute :password, make_up_password
			end
			write_attribute :salt, Digest::SHA1.hexdigest("--#{Time.now.utc}--#{password}--")
		end
	end

end
