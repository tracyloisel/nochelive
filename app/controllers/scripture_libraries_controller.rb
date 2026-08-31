class ScriptureLibrariesController < ApplicationController
  def show
    remember_device
    @screen = ScriptureLibraries::Screen.call(
      person: current_street_person,
      locale: I18n.locale,
      preview: Rails.env.local? && params[:preview] == "1"
    )
  end

  def search
    @query = params[:q].to_s
    @result = Scriptures::QueryResolver.call(query: @query, locale: I18n.locale)
    return redirect_to @result.path, status: :see_other if @result.exact?

    @screen = ScriptureLibraries::Screen.call(person: current_street_person, locale: I18n.locale)
    render :show, status: @result.status == :invalid ? :unprocessable_entity : :ok
  end

  def legacy_program
    redirect_to scripture_library_path(locale: params[:locale]), status: :found
  end

  def legacy_history
    redirect_to scripture_library_path(locale: params[:locale], anchor: "mes-ecritures"), status: :found
  end

  def legacy_community
    redirect_to scripture_library_path(locale: params[:locale], anchor: "ma-rama"), status: :found
  end
end
