class ScriptureLibrariesController < ApplicationController
  def show
    remember_device
    assign_library
  end

  def search
    @query = params[:q].to_s
    @result = Scriptures::QueryResolver.call(query: @query, locale: I18n.locale, context: :library)
    if @result.exact?
      return redirect_to @result.path, status: :see_other unless params[:suggest] == "1"

      @result = Scriptures::QueryResolver::Result.new(
        status: :ambiguous,
        path: nil,
        suggestions: [ Scriptures::QueryResolver::Suggestion.new(
          label: @query.squish,
          path: @result.path,
          study: nil
        ) ],
        message_key: nil
      )
    end

    return render_search_suggestions if params[:suggest] == "1"

    assign_library
    render :show, status: search_status
  end

  def legacy_program
    redirect_to scripture_library_path(locale: params[:locale], section: "program", anchor: "selection"), status: :found
  end

  def legacy_history
    redirect_to scripture_library_path(locale: params[:locale], section: "bookmarks", anchor: "selection"), status: :found
  end

  def legacy_community
    redirect_to scripture_circle_path(locale: params[:locale]), status: :found
  end

  def legacy_week
    redirect_to scripture_library_path(
      locale: params[:locale], section: "weekly", unit: params[:id], anchor: "selection"
    ), status: :found
  end

  private

    def render_search_suggestions
      render :search, layout: false, status: search_status
    end

    def search_status
      return :unprocessable_entity if @result.invalid?

      :ok
    end

    def assign_library
      preview = Rails.env.local? && params[:preview] == "1"
      person = current_street_person
      @screen = ScriptureLibraries::Screen.call(person:, locale: I18n.locale, preview:)
      @selection = ScriptureLibraries::Selection.call(
        person:, locale: I18n.locale,
        section: params[:section], collection: params[:collection], book: params[:book],
        unit: params[:unit], cursor: params[:cursor], preview:
      )
    end
end
