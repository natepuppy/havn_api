# frozen_string_literal: true

class OnboardingMailer < ApplicationMailer
  def document_packet delivery
    @rep       = delivery.rep
    @document  = delivery.onboarding_document
    @recruiter = @rep.recruited_by

    mail to: @rep.email, subject: "#{@document.name} — Pest onboarding"
  end
end
