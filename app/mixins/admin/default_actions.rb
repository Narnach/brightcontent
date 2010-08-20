# Mixin for admin controllers
# has default CRUD actions and sets:
# * @model          (e.g. @model = Page)
# * @items or @item (e.g. @item = Page.new)
# * @<modelname(s)>    (e.g. @pages = Pages.all or @page = Page.find(1))
#
# Catches:
# * Controllername and modelname must match
# * BrightContent/Admin specific (uses admin namespace, save and continue support etc) 
module Admin::DefaultActions
  
  def initialize
    @model = model
    super
  end
  
  # Crud actions
  def index
    @list_fields ||= model.column_names - ['created_at', 'updated_at', 'password']
    respond_with(self.plural = model.try(:paginate, :page => params[:page]) || model.all)
  end
  
  def show
    @form_fields ||= model.column_names - ['created_at', 'updated_at']
    respond_with(self.singular = model.find(params[:id]))
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
    respond_with(self.singular = model.create(params[singular_name.to_sym]), :location => params[:commit_and_continue] ? 
      polymorphic_url([:admin, singular], :action => singular.errors.blank? ? "edit" : "new" ) : 
      polymorphic_url([:admin, model])
    )
  end
  
  def update
    id = params[:id]
    self.singular = model.find(id)
    if singular.update_attributes(params[singular_name.to_sym])
      flash[:notice] = "saved!"
    else
      flash[:error] = singular.errors.full_messages.to_sentence
    end
    respond_with(singular, :location => params[:commit_and_continue] ? 
      polymorphic_url([:admin, singular], :action => "edit") : 
      polymorphic_url([:admin, model])
      )
  end
  
  def destroy
    self.singular = model.find(params[:id])
    singular.destroy
    respond_with([:admin, singular], :status => :deleted) 
  end
  
  
  private
  
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
end