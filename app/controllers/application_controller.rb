class ApplicationController < ActionController::Base
  helper :all
  include ExceptionNotifiable
  filter_parameter_logging "password"


  before_filter :set_locale, :allow_to, :check_user, :set_profile, :login_from_cookie, :login_required, :check_permissions, :pagination_defaults
  after_filter :store_location, OutputCompressionFilter
  layout 'application'


  def check_featured
    #return if Profile.featured_profile[:date] == Date.today
    Profile.featured_profile[:date] = Date.today
    Profile.featured_profile[:profile] = Profile.featured
  end

  def pagination_defaults
    @page = (params[:page] || 1).to_i
    @page = 1 if @page < 1
    @per_page = (params[:per_page] || (RAILS_ENV=='test' ? 1 : 6)).to_i
  end

  def set_profile
    @p = @u.profile if @u && @u.profile
    #Time.zone = @p.time_zone if @p && @p.time_zone
    Time.zone = "Brasilia"
    @p.update_attribute :last_activity_at, Time.now if @p
  end

  def set_locale
    I18n.locale = "pt-BR" if RAILS_ENV != 'test'
  end








  helper_method :flickr, :flickr_images
  # API objects that get built once per request
  def flickr(user_name = nil, tags = nil )
    @flickr_object ||= Flickr.new(FLICKR_CACHE, FLICKR_KEY, FLICKR_SECRET)
  end

  def flickr_images(user_name = "", tags = "")
    unless RAILS_ENV == "test"# || RAILS_ENV == "development"
      begin
        flickr.photos.search(user_name.blank? ? nil : user_name, tags.blank? ? nil : tags , nil, nil, nil, nil, nil, nil, nil, nil, 20)
      rescue
        nil
      rescue Timeout::Error
        nil
      end
    end
  end


  protected

  def allow_to level = nil, args = {}
    return unless level
    @level ||= []
    @level << [level, args]
  end



  def check_permissions
    logger.debug "IN check_permissions :: @level => #{@level.inspect}"
    return failed_check_permissions if @p && !@p.is_active
    return true if @u && @u.is_admin
    raise '@level is blank. Did you override the allow_to method in your controller?' if @level.blank?
    @level.each do |l|
      next unless (l[0] == :all) ||
        (l[0] == :non_user && !@u) ||
        (l[0] == :user && @u) ||
        (l[0] == :owner && @p && @profile && @p == @profile)
      args = l[1]
      @level = [] and return true if args[:all] == true

      if args.has_key? :only
        actions = [args[:only]].flatten
        actions.each{ |a| @level = [] and return true if a.to_s == action_name}
      end
    end
    return failed_check_permissions
  end

  def failed_check_permissions
    if RAILS_ENV != 'development'
      flash[:error] = t(:check_permission_development)
      redirect_back_or_default home_path and return true
    else
      render :text=><<-EOS
      <h1>#{t(:check_permission_production)}</h1>
      <div>
        #{t(:field_permission)}: #{@level.inspect}<br />
        #{t(:field_controller)}: #{controller_name}<br />
        #{t(:field_action)}: #{action_name}<br />
        #{t(:field_params)}: #{params.inspect}<br />
        #{t(:field_session)}: #{session.instance_variable_get("@data").inspect}<br/>
      </div>
      EOS
    end
    @level = []
    false
  end

end

