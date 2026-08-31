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
    assign_merge_cards
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
      assign_merge_cards
      render "fichas/show", status: :unprocessable_entity
    end

  def merge
    load_person
    candidate = @ward.people.find(params[:source_id])
    unless candidate.given_name_key == @person.given_name_key
      raise People::Error.new(:merge_name, I18n.t("errors.people.merge_name"))
    end

    keeper, source = [ @person, candidate ].sort_by { |person| [ person.created_at, person.id ] }
    People::Merge.call(keeper:, source:)
    redirect_to ficha_path_for(keeper), notice: I18n.t("flashes.fichas_merged", name: keeper.display_name)
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

    def assign_merge_cards
      @merge_cards = People::MergeCandidates.call(person: @person, device_token: nil)
      @profile_score = Quizzes::Leaderboard.pack_best_totals(ward: @ward)[@person.id].to_i
    end

    def ficha_path_for(person)
      ward_ficha_path(person)
    end

    def ficha_merge_path_for(person)
      ward_ficha_merge_path(person)
    end

    def fichas_path_for(**params)
      ward_fichas_path(**params)
    end
end
