class ScriptureReadsController < ApplicationController
  def create
    result = Scriptures::RecordRead.call(
      reference: params[:reference],
      reader_digest: scripture_reader_digest,
      locale: I18n.locale,
      person: current_street_person
    )

    render json: {
      counted: result.counted,
      reads_count: result.reads_count,
      label: scripture_reads_label(result.reads_count)
    }
  rescue ArgumentError, ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  private

    def scripture_reader_digest
      person = current_street_person
      return street_device_digest unless person

      GameSession.digest_token("#{street_device_digest}:person:#{person.id}")
    end

    def scripture_reads_label(count)
      helpers.scripture_read_count_label(count)
    end
end
