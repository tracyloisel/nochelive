module FichaDesk
  extend ActiveSupport::Concern

  included do
    helper_method :ficha_path_for, :ficha_merge_path_for, :fichas_path_for
  end

  def index
    @people = @ward.people.includes(:last_ward_team).order(:given_name, :family_name)
  end

  def show
    load_person
    @others = @ward.people.where.not(id: @person.id).order(:given_name, :family_name)
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
    redirect_to ficha_path_for(@person), notice: "Ficha guardada."
  rescue People::Error => error
    flash.now[:alert] = error.message
    @others = @ward.people.where.not(id: @person.id).order(:given_name, :family_name)
    render "fichas/show", status: :unprocessable_entity
  end

  def merge
    load_person
    source = @ward.people.find(params[:source_id])
    People::Merge.call(keeper: @person, source:)
    redirect_to ficha_path_for(@person), notice: "Fichas fusionadas. Se queda #{@person.display_name}."
  rescue People::Error => error
    redirect_to ficha_path_for(@person), alert: error.message
  end

  private

    def load_person
      @person = @ward.people.find(params[:id])
    end

    def ficha_path_for(person)
      @night ? presenter_ficha_path(@night.code, person) : ward_ficha_path(person)
    end

    def ficha_merge_path_for(person)
      @night ? presenter_ficha_merge_path(@night.code, person) : ward_ficha_merge_path(person)
    end

    def fichas_path_for
      @night ? presenter_fichas_path(@night.code) : ward_fichas_path
    end
end
