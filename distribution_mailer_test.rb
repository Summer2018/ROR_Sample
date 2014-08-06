require File.dirname(__FILE__) + '/../test_helper'

class DistributionMailerTest < ActiveSupport::TestCase
	fixtures :users, :user_subscription_preferences, :reports, :distributions, :report_types, :report_tags, :rating_questions, :employees, :page_templates, :email_subscriptions
	set_fixture_class :wp_posts => WordPress::BlogPost, :headlines => DataAssets::Headline, :headline_tags => DataAssets::HeadlineTag, :headline_categories => DataAssets::HeadlineCategory
	
	CHARSET = "utf-8" 

	def setup
		ActionMailer::Base.delivery_method = :test
		ActionMailer::Base.perform_deliveries = true
		ActionMailer::Base.deliveries = []

		@expected = TMail::Mail.new
		@expected.set_content_type "text", "plain", { "charset" => CHARSET }
	end

	context "A distribution for daily HTML headlines" do
		setup do
			@dist = distributions(:dailyhtmlheadlines)
			@user = User.find 1
			@headline_date = Date.parse "2009-9-17"
			DistributionMailer.deliver_daily_headlines @dist, @headline_date, @user
		end
		
		should "have a subject that matches the Headlines" do
			assert_equal "Outsell's Information Industry Headlines - 17-Sep-09", ActionMailer::Base.deliveries.first.subject
		end
		should "have two parts - text and HTML" do
			assert_equal 2, ActionMailer::Base.deliveries.first.parts.size
		end
		should "have a to line that matches the selected user" do
			assert_equal @user.email, ActionMailer::Base.deliveries.first.to[0]
		end
		should "have a section with a headline about Fitch" do
			assert ActionMailer::Base.deliveries.first.body.include?("Fitch Publishes")
		end
	end

	context "A distribution for daily HTML headlines and a user with specific preferences" do
		setup do
			@dist = distributions(:dailyhtmlheadlines)
			@user = User.find 2
			@headline_date = Date.parse "2009-9-17"
			DistributionMailer.deliver_daily_headlines @dist, @headline_date, @user
		end
		
		should "not have a section with a headline about Fitch" do
			assert !ActionMailer::Base.deliveries.first.body.include?("Fitch Publishes")
		end
	end
	
	context "A distribution for daily HTML headlines with an announcement" do
		setup do
			@dist = distributions(:dailyhtmlheadlines)
			@user = User.find 1
			@headline_date = Date.parse "2009-9-17"
			pt = PageTemplate.find :first
			PageModule.new(:url_text => "headlines_announcement", 
				:title => "Headlines Announcement", :page_template => pt,
				:body_content => "Here's an announcement!", :pub_date => Time.now.to_date).save
			DistributionMailer.deliver_daily_headlines @dist, @headline_date, @user
		end
		
		should "have content of the announcement in the body" do
			assert ActionMailer::Base.deliveries.first.body.include?("an announcement")
		end
  end

	context "A distribution for daily HTML Insights to an employee" do
		setup do
			@dist = distributions(:dailyhtmlinsights)
			@user = User.find 1
			enewsletter_posts_content = @dist.enewsletter_posts_content
			user_posts = []
			user_posts << @dist.blog_post
			DistributionMailer.deliver_enewsletter_html @user, @dist, user_posts, '', '', enewsletter_posts_content
		end
		
		should "have a subject that matches the Insight" do
			assert_equal 'Data Explorers: Part of the Future of Equity Markets', ActionMailer::Base.deliveries.first.subject
		end
		should "have two parts - text and HTML" do
			assert_equal 2, ActionMailer::Base.deliveries.first.parts.size
		end
		should "have content of blog post in the body" do
			assert ActionMailer::Base.deliveries.first.body.include?("Data Explorers")
		end
		should "have a to line that matches the selected user" do
			assert_equal @user.email, ActionMailer::Base.deliveries.first.to[0]
		end
		should "have a section with the headlines" do
			assert ActionMailer::Base.deliveries.first.body.include?("Information Industry Headlines for")
		end
		should "have a section with a headline about Fitch" do
			assert ActionMailer::Base.deliveries.first.body.include?("Fitch Publishes")
		end
  end

	context "A distribution for daily HTML Insights to a regular user" do
		setup do
			@dist = distributions(:dailyhtmlinsights)
			@user = users(:testregularuser)
			enewsletter_posts_content = @dist.enewsletter_posts_content
			user_posts = []
			user_posts << @dist.blog_post
			DistributionMailer.deliver_enewsletter_html @user, @dist, user_posts, '', '', enewsletter_posts_content
		end
		
		should "be sent to a user who is not an employee" do
			assert !@user.employee?
		end

		should "have a subject that matches the Insight" do
			assert_equal 'Data Explorers: Part of the Future of Equity Markets', ActionMailer::Base.deliveries.first.subject
		end
		should "have a link to the Insight on the web" do
			assert ActionMailer::Base.deliveries.first.body.include?(">Link</a> to this <strong><em>Insights</em></strong> article.")
		end
		should "have a link to email the author about the Insight" do
			assert ActionMailer::Base.deliveries.first.body.include?(">Email #{@dist.blog_post.author.full_name} about this Insight.")
		end
		should "have a link to provide feedback about the Insight" do
			assert ActionMailer::Base.deliveries.first.body.include?(">Provide feedback on this Insight.</a>")
		end
		should "have a link to join the discussion about the Insight" do
			assert ActionMailer::Base.deliveries.first.body.include?(">Join the discussion.</a>")
		end
		should "have a link to share this Insight with others" do
			assert ActionMailer::Base.deliveries.first.body.include?(">Forward to someone.</a>")
		end
  end


	context "A distribution for daily text Insights" do
		setup do
			@dist = distributions(:dailytextinsights)
			@user = User.find 1
			enewsletter_posts_content = @dist.enewsletter_posts_content
			user_posts = []
			user_posts << @dist.blog_post
			DistributionMailer.deliver_enewsletter_text @user, @dist, user_posts, '', '', enewsletter_posts_content
		end
		
		should "have a subject that matches the Insight" do
			assert_equal 'Data Explorers: Part of the Future of Equity Markets', ActionMailer::Base.deliveries.first.subject
		end
		should "have no parts" do
			assert_equal 0, ActionMailer::Base.deliveries.first.parts.size
		end
		should "have content of blog post in the body" do
			assert ActionMailer::Base.deliveries.first.body.include?("Data Explorers")
		end
		should "have a to line that matches the selected user" do
			assert_equal @user.email, ActionMailer::Base.deliveries.first.to[0]
		end
		should "have a section with the headlines" do
			assert ActionMailer::Base.deliveries.first.body.include?("Information Industry Headlines")
		end
		should "have a section with a headline about Fitch" do
			assert ActionMailer::Base.deliveries.first.body.include?("Fitch Publishes")
		end
		should "have a link to the Insight on the web" do
			assert ActionMailer::Base.deliveries.first.body.include?("Link to this Insights article")
		end
		should "have a link to email the author about the Insight" do
			assert ActionMailer::Base.deliveries.first.body.include?("Email #{@dist.blog_post.author.full_name} about this Insight")
		end
		should "have a link to provide feedback about the Insight" do
			assert ActionMailer::Base.deliveries.first.body.include?("Provide feedback on this Insight")
		end
		should "have a link to join the discussion about the Insight" do
			assert ActionMailer::Base.deliveries.first.body.include?("Join the discussion")
		end
		should "have a link to share this Insight with others" do
			assert ActionMailer::Base.deliveries.first.body.include?("Forward to someone")
		end
	end

	context "A distribution for daily html Insights with an announcement" do
		setup do
			@dist = distributions(:dailyhtmlinsights)
			@user = User.find 1
			enewsletter_posts_content = @dist.enewsletter_posts_content
			user_posts = []
			user_posts << @dist.blog_post
			pt = PageTemplate.find :first
			PageModule.new(:url_text => "insights_announcement", 
				:title => "Insights Announcement", :page_template => pt,
				:body_content => "Here's an announcement!", :pub_date => Time.now.to_date).save
			DistributionMailer.deliver_enewsletter_html @user, @dist, user_posts, '', '', enewsletter_posts_content
		end
		
		should "have content of the announcement in the body" do
			assert ActionMailer::Base.deliveries.first.body.include?("an announcement")
		end
	end

	context "A distribution for daily text Insights with an announcement" do
		setup do
			@dist = distributions(:dailytextinsights)
			@user = User.find 1
			enewsletter_posts_content = @dist.enewsletter_posts_content
			user_posts = []
			user_posts << @dist.blog_post
			pt = PageTemplate.find :first
			PageModule.new(:url_text => "insights_announcement", 
				:title => "Insights Announcement", :page_template => pt,
				:body_content => "Here's an announcement!", :pub_date => Time.now.to_date).save
			DistributionMailer.deliver_enewsletter_text @user, @dist, user_posts, '', '', enewsletter_posts_content
		end
		
		should "have content of the announcement in the body" do
			assert ActionMailer::Base.deliveries.first.body.include?("an announcement")
		end
  end

	context "A distribution for a report email" do
		setup do
			@dist = distributions(:reportdistribution)
			@user = User.find 1
			@dist_mail = DistributionMailer.create_report_email @dist, 1, @user
		end

		should "have a subject matching the distribution subject" do
			assert_equal 'Outsell Briefing, "Test 1"', @dist_mail.subject
		end
		should "be two parts to the email - the email and report attachment" do
			assert_equal 2, @dist_mail.parts.size
		end
		should "contain a Greetings line" do
			assert_match /Greetings/, @dist_mail.parts[0].body
		end
		should "have a to line that matches the selected user" do
			assert_equal @user.email, @dist_mail.to[0]
		end
  end

	context "A distribution for a report email with rating" do
		setup do
			@dist = distributions(:reportwithrating)
			@user = User.find 1
			DistributionMailer.deliver_report_email @dist, 1, @user
		end
		should "contain a line with a rating link" do
			assert ActionMailer::Base.deliveries.first.body.include?("/rate/report/1"), ActionMailer::Base.deliveries.first.body.to_s
		end
  end

	context "A distribution for a report email with a sharing URL" do
		setup do
			@dist = distributions(:reportwithsharelink)
			@user = User.find 1
			DistributionMailer.deliver_report_email @dist, 1, @user
		end
		should "contain a line with a sharing link" do
			assert ActionMailer::Base.deliveries.first.body.include?("/share/report/1"), ActionMailer::Base.deliveries.first.body.to_s
		end
  end

end
