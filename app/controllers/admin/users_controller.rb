class Admin::UsersController < ApplicationController
  before_filter :search_results, :except => [:destroy]

  def index
    render
  end



  def update
    @profile = Profile.find(params[:id])
    respond_to do |wants|
      wants.js do
        render :update do |page|
          if @p == @profile
            page << "message('#{t(:cannot_deactivate_yourself)}!');"
          else
            @profile.toggle! :is_active
            page << "message('#{t(:marked_as)} #{@profile.is_active ? t(:active) : t(:inactive)}');"
            page.replace_html @profile.dom_id('link'), (@profile.is_active ? t(:deactivate) : t(:activate))
          end
        end
      end
    end
  end

  private

  def allow_to
    super :admin, :all => true
  end

  def search_results
    if params[:search]
      p = params[:search].dup
    else
      p = []
    end

    @results = Profile.search(p.delete(:q) || '', :page => @page, :per_page => 21)
  end
end

