# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Establish an admin user (me!)
admin = User.create_with(name: 'Ian Lloyd', nickname: 'Ian', password: 'password').find_or_initialize_by(email: 'ian@signalcloudapp.com').tap do |u|
  u.skip_confirmation!
  u.save!
end

admin_team = Team.create_with(name: 'Examples', owner: admin).find_or_create_by!(name: 'Examples')
Membership.create_with(roles: nil).find_or_create_by!(user: admin, team: admin_team)

admin_team.phone_numbers.create_with(number: '+1 202-601-3854', workflow_state: :active).find_or_create_by!(provider_sid: 'PNf7abf4d06e5faecb7d6878fa37b8cdc3')


# Establish an alternate user
jack = User.create_with(name: 'Jack', nickname: 'J', password: 'password').find_or_initialize_by(email: 'hello+jack@signalcloudapp.com').tap do |u|
  u.skip_confirmation!
  u.save!
end

jack_team = Team.create_with(owner: jack).find_or_create_by!(name: 'Jack\'s Team')
Membership.create_with(roles: nil).find_or_create_by!(user: jack, team: jack_team)

