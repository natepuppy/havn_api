# frozen_string_literal: true

class RepNormalizer < ::BaseResponseNormalizer
  attributes(
    :id,
    :first_name,
    :last_name,
    :email,
    :phone,
    :street,
    :city,
    :state,
    :zip,
    :start_date,
    :end_date,
    :shirt_size,
    :drivers_license_number,
    :market,
    :notes,
    :status,
    :active,
    :onboarding_completed,
    :recruited_by_id,
    :created_at,
    :updated_at,
  )

  custom_attributes :full_name, :recruiter_name, :recruiter_email, :level, :housing,
                     :role, :agreement_completed, :agreement_signed, :documents_sent_count, :deliveries

  def full_name object
    object.full_name
  end

  def recruiter_name object
    [object.recruited_by&.first_name, object.recruited_by&.last_name].compact.join " "
  end

  def recruiter_email object
    object.recruited_by&.email
  end

  def level object
    object.level
  end

  def housing object
    object.user&.housing
  end

  def role object
    object.user&.role&.name
  end

  def agreement_completed object
    agreement_deliveries(object).any? { |delivery| DocumentDelivery::OUTBOUND_STATUSES.include?(delivery.status) }
  end

  def agreement_signed object
    agreement_deliveries(object).any? { |delivery| delivery.status == "completed" }
  end

  def documents_sent_count object
    object.document_deliveries.to_a.count { |delivery| DocumentDelivery::OUTBOUND_STATUSES.include?(delivery.status) }
  end

  def agreement_deliveries object
    object.document_deliveries.to_a.select do |delivery|
      delivery.onboarding_document&.agreement?
    end
  end

  def deliveries object
    records = object.document_deliveries.sort_by { |delivery| delivery.created_at || Time.zone.at(0) }.reverse
    DocumentDeliveryNormalizer.new(records).as_data
  end
end
