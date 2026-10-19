# frozen_string_literal: true

module Docusign
  class SendEnvelope
    AGREEMENT_TEMPLATE_ID = "736474c4-34c8-4f48-a4a3-8727bd55a9ba"

    def self.call delivery
      new(delivery).call
    end

    def self.fail_attached delivery, error
      new(delivery).fail_attached error
    end

    def initialize delivery
      self.delivery = delivery
    end

    def call
      raise Client::Error, "DocuSign is not configured" unless Config.configured?

      result = Client.new.create_envelope(payload)
      envelope_id = result["envelopeId"]
      raise Client::Error, "DocuSign did not return an envelope id" if envelope_id.blank?

      sent_at = Time.current
      delivery.update! status: "sent", sent_at: sent_at, docusign_envelope_id: envelope_id, error_message: nil
      addendum_delivery&.update! status: "sent", sent_at: sent_at, docusign_envelope_id: envelope_id, error_message: nil
      delivery
    end

    def fail_attached error
      return unless rep_agreement?

      queued_addendums.find_each do |item|
        item.update status: "failed", error_message: error.message
      end
    end

    private

    attr_accessor :delivery

    def payload
      body = {
        status: "sent",
        emailSubject: email_subject,
        customFields: {
          textCustomFields: [
            { name: "delivery_id", value: delivery.id.to_s, show: "false" },
          ],
        },
      }
      return body.merge(compositeTemplates: composite_templates) if addendum_delivery

      body.merge templateId: delivery.onboarding_document.docusign_template_id, templateRoles: template_roles(delivery.rep)
    end

    def email_subject
      name = delivery.onboarding_document.name
      name = "#{name} and #{addendum_delivery.onboarding_document.name}" if addendum_delivery
      "Havn Pest Control — #{name}"
    end

    def composite_templates
      rep = delivery.rep
      [
        composite("1", delivery.onboarding_document.docusign_template_id, agreement_signers(rep)),
        composite("2", addendum_delivery.onboarding_document.docusign_template_id, addendum_signers(rep)),
      ]
    end

    def composite sequence, template_id, signers
      {
        compositeTemplateId: sequence,
        serverTemplates: [{ sequence: "1", templateId: template_id }],
        inlineTemplates: [
          { sequence: "2", recipients: { signers: signers } },
        ],
      }
    end

    def agreement_signers rep
      signers = [
        {
          roleName: "Rep",
          recipientId: "1",
          name: rep.full_name,
          email: rep.email,
          tabs: { textTabs: agreement_tabs(rep) },
        },
      ]
      company = company_tabs(rep)
      signers << { roleName: "Company", recipientId: "2", tabs: { textTabs: company } } if company.any?
      signers
    end

    def addendum_signers rep
      [
        {
          roleName: "Rep",
          recipientId: "1",
          name: rep.full_name,
          email: rep.email,
          tabs: { textTabs: labeled_tabs(rep) },
        },
      ]
    end

    def template_roles rep
      roles = [
        {
          roleName: "Rep",
          name: rep.full_name,
          email: rep.email,
          tabs: { textTabs: rep_tabs(rep) },
        },
      ]
      company = company_tabs(rep)
      roles << { roleName: "Company", tabs: { textTabs: company } } if company.any?
      roles
    end

    def rep_tabs rep
      return labeled_tabs(rep) unless rep_agreement?

      agreement_tabs rep
    end

    def agreement_tabs rep
      [
        tab("1ba14f97-f479-4e19-a5f0-8e62b5783954", rep.full_name),
        tab("08b8757a-d757-4392-80f0-2a17900065ac", rep.email),
      ].compact
    end

    def company_tabs rep
      return [] unless rep_agreement?

      manager = rep.recruited_by
      manager_name = [manager&.first_name, manager&.last_name].compact.join(" ")
      [tab("d580bc98-88d9-4dfa-8551-ec22d02c88a8", manager_name)].compact
    end

    def labeled_tabs rep
      [
        ["rep_name", rep.full_name],
        ["rep_email", rep.email],
        ["start_date", rep.start_date&.strftime("%B %-d, %Y")],
        ["market", rep.market],
        ["drivers_license", rep.drivers_license_number],
      ].filter_map do |label, value|
        next if value.blank?

        { tabLabel: label, value: value.to_s }
      end
    end

    def tab id, value
      return if value.blank?

      { tabId: id, value: value.to_s }
    end

    def addendum_delivery
      return @addendum_delivery if defined?(@addendum_delivery)

      @addendum_delivery = queued_addendums.order(:id).last if rep_agreement?
    end

    def queued_addendums
      level = delivery.rep.level
      return DocumentDelivery.none if level.blank?

      DocumentDelivery.joins(:onboarding_document)
                      .where(rep_id: delivery.rep_id, status: "queued")
                      .where(onboarding_documents: { level: level })
                      .where.not(id: delivery.id)
    end

    def rep_agreement?
      delivery.onboarding_document.docusign_template_id == AGREEMENT_TEMPLATE_ID
    end
  end
end
