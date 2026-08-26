module FichaDesk
  extend ActiveSupport::Concern
  PER_PAGE = 48

  included do
    helper_method :ficha_path_for, :ficha_merge_path_for, :fichas_path_for
  end

  def index
    scope = people_scope
    @q = params[:q].to_s.strip
    @page = [ params[:page].to_i, 1 ].max
    @total = scope.count
    @pages = [ (@total.to_f / PER_PAGE).ceil, 1 ].max
    @people = scope.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
  end

  def show
    load_person
    @others = people_scope.where.not(id: @person.id).limit(PER_PAGE)
  end

  def update
    load_person
    People::Update.call(
      person: @person,
      given_name: params[:given_name],
      family_name: params[:family_name],
      avatar_key: params[:avatar_key],
      favorite_year: params[:favorite_year]
    )
    redirect_to ficha_path_for(@person), notice: I18n.t("flashes.ficha_saved")
    rescue People::Error => error
      flash.now[:alert] = error.message
      @others = people_scope.where.not(id: @person.id).limit(PER_PAGE)
      render "fichas/show", status: :unprocessable_entity
    end

  def merge
    load_person
    source = @ward.people.find(params[:source_id])
    People::Merge.call(keeper: @person, source:)
    redirect_to ficha_path_for(@person), notice: I18n.t("flashes.fichas_merged", name: @person.display_name)
  rescue People::Error => error
    redirect_to ficha_path_for(@person), alert: error.message
  end

  private

    def load_person
      @person = @ward.people.find(params[:id])
    end

    def people_scope
      scope = @ward.people.includes(:last_ward_team).order(:given_name, :family_name)
      if params[:q].present?
        key = Person.name_key(params[:q])
        scope = scope.where("given_name_key LIKE :key OR family_name_key LIKE :key", key: "#{key}%")
      end
      scope
    end

    def ficha_path_for(person)
      @night ? presenter_ficha_path(@night.code, person) : ward_ficha_path(person)
    end

    def ficha_merge_path_for(person)
      @night ? presenter_ficha_merge_path(@night.code, person) : ward_ficha_merge_path(person)
    end

    def fichas_path_for(**params)
      @night ? presenter_fichas_path(@night.code, **params) : ward_fichas_path(**params)
    end
end
