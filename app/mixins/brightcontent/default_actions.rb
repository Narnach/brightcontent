# Mixin for brightcontent controllers
# has default CRUD actions and sets:
# * @model          (e.g. @model = Page)
# * @items or @item (e.g. @item = Page.new)
# * @<modelname(s)>    (e.g. @pages = Pages.all or @page = Page.find(1))
#
# Catches:
# * Controllername and modelname must match
# * BrightContent/Brightcontent specific (uses brightcontent namespace, save and continue support etc) 
module Brightcontent::DefaultActions
  
  def initialize
    @model = model
    @search_fields = []
    super
  end
  
  # Crud actions
  def index
    @list_fields ||= model.column_names - ['created_at', 'updated_at', 'password_digest']
    respond_with( responder_model )
  end
  
  def show
    redirect_to :action => :edit
  end
  
  def new
    @form_fields ||= model.column_names - ['created_at', 'updated_at']
    respond_with(self.singular = model.new)
  end
  
  def edit
    @form_fields ||= model.column_names - ['created_at', 'updated_at']
    respond_with(self.singular = model.find(params[:id]))
  end
  
  def create
    @form_fields ||= model.column_names - ['created_at', 'updated_at']
    self.singular = model.new(params[singular_name.to_sym])
    if singular.save
      flash[:notice] = "saved!"
    else
      flash.now[:error] = singular.errors.full_messages.to_sentence
    end
    respond_with(singular, :location => requested_location)
  end
  
  def update
    @form_fields ||= model.column_names - ['created_at', 'updated_at']
    self.singular = model.find(params[:id])
    if singular.update_attributes(params[singular_name.to_sym])
      flash[:notice] = "saved!"
    else
      flash.now[:error] = singular.errors.full_messages.to_sentence
    end
    respond_with(singular, :location => requested_location)
  end
  
  def destroy
    self.singular = model.find(params[:id])
    singular.destroy
    respond_with([:brightcontent, singular], :status => :deleted, :location => params[:url])
  end
  
  
  private
  
  def responder_model(m=nil)
    m = model unless m.present?
    if @search_fields.present?
      @search_term = params[:term]
      if @search_term.present?
        like_keyword = ::ActiveRecord::Base.connection.adapter_name == "PostgreSQL" ? "ILIKE" : "LIKE"
        query = []
        terms = []
        possible_joins = []
        @search_fields.each do |field|
          if field.include?(".")
            field = field.split(".")
            possible_joins << field[0].to_sym
          end
        end

        if possible_joins.present?
          possible_joins.uniq!
          possible_joins.each do |join_model|
            m = m.includes(join_model)
          end
        end

        @search_fields.each do |field|
            query << "#{field} #{like_keyword} ?"
            terms << "%#{@search_term}%"
        end
        
        # Offer.joins(:brand).where("brands.name LIKE ? OR offer.body LIKE ?", '%oxbow%', '%oxbow%').to_sql
        # "SELECT \"offers\".* FROM \"offers\" INNER JOIN \"brands\" ON \"brands\".\"id\" = \"offers\".\"brand_id\" WHERE (brands.name LIKE '%oxbow%' OR offer.body LIKE '%test%') ORDER BY available_at DESC, id DESC"
        m = m.where([query.join(" OR "), terms].flatten)
      end
    end

    if @filters.present?
      @filter = params[:filter]
      if @filter.present? && @filters.include?(@filter)
        m = m.send(@filter.to_sym)
      end
    end

    m = m.try(:paginate, :page => params[:page]) || m
    self.plural = m
  end
  
  def plural_name
    self.controller_name
  end
  
  def singular_name
    plural_name.singularize
  end
  
  def model
    Kernel.const_get(singular_name.camelize)
  end  
  
  def singular
    instance_variable_get "@#{singular_name}"
  end
  
  def singular=(value)
    instance_variable_set "@#{singular_name}", value
    instance_variable_set "@item", value
  end
  
  def plural
    instance_variable_get "@#{plural_name}"
  end
  
  def plural=(value)
    instance_variable_set "@#{plural_name}", value
    instance_variable_set "@items", value
  end
  
  def requested_location
    if singular.invalid?
      nil
    elsif params[:commit_and_continue]
      polymorphic_url([:brightcontent, singular], :action => "edit")
    else
      polymorphic_url([:brightcontent, model])
    end
  end
end
