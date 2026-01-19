# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

seeds = [
	"populate_countries",
	"populate_states",
	"populate_cities",
	"populate_default",
	"populate_users",
	"populate_to_development",
]

seeds.each { |seed| Rake::Task["db:seed:#{seed}"].invoke }