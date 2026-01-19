class Visitors::NewslettersController < ApplicationController
	skip_before_action :authenticate_user
	
	def new
		@newsletter = Newsletter.new
	end

	def create
		@newsletter = Newsletter.new(newsletter_params)
		if @newsletter.save
			flash[:success] = Newsletter.human_attribute_name(:success_save)
			redirect_to root_path
		else
			flash[:error] = @newsletter.errors.full_messages.join('<br>')
			render :new
		end
	end

	private

	def newsletter_params
		params
		.require(:newsletter)
		.permit(:name, 
			:email)
	end

end