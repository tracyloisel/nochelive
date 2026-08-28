module AdminApi
  class StatsController < BaseController
    def index
      stats = Platform::Stats.call
      render json: {
        platform: {
          people: stats.people,
          wards: stats.wards,
          countries: stats.countries,
          languages: stats.languages.map { |row| { code: row.code, count: row.count, share: row.share } },
          quiz_answers: stats.answers,
          correct_answers: stats.correct,
          wrong_answers: stats.wrong,
          accuracy: stats.path_share,
          duels: stats.duels,
          nights: stats.nights,
          teams: stats.teams,
          invitations_sent: stats.invitations_sent,
          invitations_opened: stats.invitations_opened,
          friends_joined: stats.friends_joined,
          invitation_duels_completed: stats.invitation_duels_completed,
          invitation_conversion: stats.invitation_share
        }
      }
    end
  end
end
