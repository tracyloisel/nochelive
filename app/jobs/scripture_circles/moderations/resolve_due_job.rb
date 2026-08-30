module ScriptureCircles
  module Moderations
    class ResolveDueJob < ApplicationJob
      queue_as :maintenance

      def perform
        ResolveDue.call
      end
    end
  end
end
