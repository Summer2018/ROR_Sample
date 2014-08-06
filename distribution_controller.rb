class DistributionController < ApplicationController
	def send_waiting
		dsi = DistributionStatusInfo.get
	  
		# don't send anything if paused
		if DistributionStatusInfo.paused?
			puts "Pausing before sending a distribution"
			dsi.reload
			dsi.update_attribute 'status', 'IDLE'
			exit
		end
	  	  
	  # the distribution model returns at most one distribution to process from 'find_waiting',
	  # to allow multiple rake tasks to run simultaneously if desired
		Distribution.find_waiting.each do |d|
			dsi.reload
			dsi.update_attribute 'status', 'SENDING'
			d.update_attribute 'started_at', DateTime.now if d.started_at.nil?
			mail_creation_method = "create_" + d.method_name
			distribution_error_count = 0
			
			# do setup and cache prepared content for enewsletter distributions
			format = 'html'
			format = 'text' if d.name =~ /text/
			if d.method_name =~ /^enewsletter/
				enewsletter_posts_content = d.enewsletter_posts_content
				weekly_posts = WordPress::BlogPost.published_the_week_ending(d.pub_date, d.days_to_go_back) if d.name =~ /weekly/i
      	blurb  = WordPress::BlogPost.get_sidebar_content('blurb')
      	advert = WordPress::BlogPost.get_sidebar_content('advert')
			end
			num_headlines = 0
			if d.method_name == "daily_headlines"
				headlines = DataAssets::Headline.find_for_email_on_date
				num_headlines = headlines.size
			elsif d.method_name == "weekly_headlines"
				headlines = DataAssets::HeadlineTag.find_headlines_for_week(Time.now)
				num_headlines = headlines.size
			end
			
			watchlist_headlines_criteria_date = 2.days.ago
			if Time.now.wday == 1
				watchlist_headlines_criteria_date = 4.days.ago
			end
	    
			d.distribution_members.find_waiting.each do |dm|  
				# don't send anything if paused
				if DistributionStatusInfo.paused?
					d.update_attribute 'status', 'RETRY'
					dsi.reload
					dsi.update_attribute 'status', 'IDLE'
					exit
				end

				dm.update_attribute 'times_sent', dm.times_sent+1

				# attempt send, evaluate result, set status to one of:
				# success => 'COMPLETED'
				# error => 'RETRY'
				# error and number attempts > x  => 'FAILED'
				begin
					next if skip_this_distribution_member?(d, dm)
					
					if d.method_name == "report_email"
						dist_report_id = d.report.nil? ? nil : d.report.id
						email = DistributionMailer.send mail_creation_method, d, dist_report_id, dm.member, dm.subscription_id
					elsif d.method_name =~ /^enewsletter/
						# Insights e-newsletter mailings
						user_posts = dm.enewsletter_posts format, weekly_posts
					  if user_posts.empty?
							# change member status to avoid delivering message with header & footer but no content
							dm.update_attribute 'status', 'NO POSTS'
							next
						else
							dm.update_attribute 'post_ids', user_posts.map { |p| p.ID }.join(',')
							email = DistributionMailer.send mail_creation_method, dm.member, d, user_posts, blurb, advert, enewsletter_posts_content
						end
					elsif d.method_name == "daily_headlines" || d.method_name == "weekly_headlines"
						if num_headlines == 0
							dm.update_attribute 'status', 'NO POSTS'
							next
						end
						email = DistributionMailer.send mail_creation_method, d, Time.now, dm.member, headlines
					elsif d.method_name == "watchlist_alert"
						dm.member.subscription_preferences.find(:all, :conditions => "user_subscription_preferences.frequency= 'weekly' AND user_subscription_preferences.preference_type='UserFavoriteGroup'").each do |watchlist_pref|
							watchlist = dm.member.user_favorite_groups.find_by_id watchlist_pref.subscription_product_id
							if watchlist
								DistributionMailer.deliver_watchlist_alert d, dm.member, watchlist
							end
						end
					elsif d.method_name == "watchlist_headlines"
						dm.member.subscription_preferences.find(:all, :conditions => "user_subscription_preferences.frequency= 'daily' AND user_subscription_preferences.preference_type='UserFavoriteGroup'").each do |watchlist_pref|
							watchlist = dm.member.user_favorite_groups.find_by_id watchlist_pref.subscription_product_id
							if watchlist && !watchlist.company_ids.nil? && !watchlist.company_ids.empty?
								DistributionMailer.deliver_watchlist_headlines d, dm.member, watchlist, watchlist_headlines_criteria_date
							end
						end
						dm.update_attribute 'status', 'COMPLETED'
					elsif d.method_name == "product_review"
						email = DistributionMailer.send mail_creation_method, d, dm.member, d.product_review
					elsif d.method_name == "company_and_product_summary"
						timeframe = d.days_to_go_back.to_i.days.ago
						company_reports = CompanyReport.find_for_timeframe_and_user timeframe, dm.member
						product_reviews = DataAssets::ProductReview.find_for_timeframe_and_user timeframe, dm.member
						if product_reviews.empty? && company_reports.empty?
							dm.update_attribute 'status', 'NO POSTS'
							next
						else
							email = DistributionMailer.send mail_creation_method, d, dm.member, timeframe
						end
					elsif d.method_name == "research_advisory"
						email = DistributionMailer.send mail_creation_method, d, d.report.id, dm.member
					elsif d.method_name == "company_report"
						email = DistributionMailer.send mail_creation_method, d, dm.member, d.company_report
					else
						email = DistributionMailer.send mail_creation_method, d, dm.member
					end
					
					unless dm.status == 'NO POSTS' or dm.status == 'TOO MANY BOUNCES'
					  DistributionMailer.deliver(email) unless email.nil?
					  dm.update_attribute 'status', 'COMPLETED'
				  end
				rescue Exception => e
					distribution_error_count += 1
					log_error(e)
					dm.status = 'RETRY'
					dm.status = 'FAILED' if dm.times_sent > 10
					dm.status_message = e.message.to_s
					dm.save
				end
        
				if dm.status == 'COMPLETED'
					# log contact record into Goldmine CRM (except for insights and headlines msgs)
					begin
						unless d.method_name =~ /^enewsletter/i or d.method_name =~ /headlines/ or d.method_name == "watchlist_alert"
							if dm.member.is_a?(User)
								dm.member.add_email_record(email.subject, '', Date.today.strftime("%m/%d/%Y"), d.id)
							end
						end
					rescue Exception => e
						log_error(e)
          end
					# now log that deliverables were sent, except for the employee weekly summary
					if d.method_name == "report_email" and !d.report.nil?
						if dm.member.is_a?(User)
							UserSentDeliverable.new(:user => dm.member, :distribution => d, :deliverable_id => d.report.id, :deliverable_type => 'Report', :format => d.report.format, :sent_at => DateTime.now).save
						end
					elsif d.method_name =~ /^enewsletter/i and not d.name =~ /^Employee enewsletter-weekly/i
						user_posts.each do |post|
							if dm.member.is_a?(User)
								UserSentDeliverable.new(:user => dm.member, :distribution => d, :deliverable_id => post.id, :deliverable_type => 'WordPress::BlogPost', :format => format, :sent_at => DateTime.now).save
							end
						end
					end
				end
			end
	    
			# mark the entire distribution as completed once we have no more problem members
			# (i.e. they all succeeded or the retry count disqualified them)
			if distribution_error_count == 0
				d.update_attributes :status => 'COMPLETED', :completed_at => DateTime.now
			else
				d.update_attribute 'status', 'RETRY'
			end
		end
		dsi.reload
		dsi.update_attribute 'status', 'IDLE'
	end

	def skip_this_distribution_member?(distribution, distribution_member)
		if distribution_member.member.email_bounce_counter > EMAIL_BOUNCE_CUTOFF
			# exclude users with too many bounces
			distribution_member.update_attribute 'status',  'TOO MANY BOUNCES'
			return true
		elsif distribution_member.member.no_marketing_messages? && distribution.distribution_type == "Other"
			distribution_member.update_attribute 'status',  'DO NOT MAIL'
			return true
		elsif distribution_member.member.no_subscription_messages? && (distribution.distribution_type == "Report" || distribution.distribution_type == "SubscriptionProduct")
			distribution_member.update_attribute 'status',  'DO NOT SEND SUBSCRIPTION'
			return true
		end
	end

end
