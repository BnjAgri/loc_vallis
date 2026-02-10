namespace :owners do
  desc "Enforce the single primary owner and reassign all rooms/articles to them. Set DELETE_EXTRA_OWNERS=1 to remove other owners after reassignment."
  task enforce_singleton: :environment do
    primary_email = Owner.primary_email
    raise "PRIMARY_OWNER_EMAIL is blank" if primary_email.blank?

    owner = Owner.find_by(email: primary_email) || Owner.order(:id).first
    raise "No owner exists yet; create the primary owner first (email: #{primary_email})" if owner.nil?

    if !owner.email.to_s.casecmp(primary_email).zero?
      if Owner.where(email: primary_email).where.not(id: owner.id).exists?
        raise "Cannot rename Owner##{owner.id} to #{primary_email}: another owner already has that email"
      end

      owner.update!(email: primary_email)
    end

    now = Time.current
    rooms_updated = Room.where.not(owner_id: owner.id).update_all(owner_id: owner.id, updated_at: now)
    articles_updated = Article.where.not(owner_id: owner.id).update_all(owner_id: owner.id, updated_at: now)

    extra_owners = Owner.where.not(id: owner.id)

    puts "Primary owner: #{owner.email} (id=#{owner.id})"
    puts "Rooms reassigned: #{rooms_updated}"
    puts "Articles reassigned: #{articles_updated}"
    puts "Extra owners remaining: #{extra_owners.count}"

    delete_extras = ENV["DELETE_EXTRA_OWNERS"].to_s.downcase.in?(["1", "true", "yes"])
    if delete_extras && extra_owners.exists?
      deleted = extra_owners.delete_all
      puts "Extra owners deleted: #{deleted}"
    end
  end
end
