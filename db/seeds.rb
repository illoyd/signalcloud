# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Establish an admin user (me!)
admin = User.initialize_with(name: 'Ian Lloyd', nickname: 'Ian', password: 'password').find_or_initialize_by(email: 'ian@signalcloudapp.com').tap |u|
  u.skip_confirmation!
  u.save
end
admin_team = Team.create_with(name: 'Examples', owner: admin).find_or_create_by(name: 'Examples')