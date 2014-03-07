# e.g.:
# @user.should have_ability(:create, for: Post.new)
# @user.should have_ability([:create, :read], for: Post.new)
# @user.should have_ability({create: true, read: false, update: false, destroy: true}, for: Post.new)
RSpec::Matchers.define :have_ability do |ability_hash, options = {}|
  match do |user|
    ability         = Ability.new(user)
    target          = options[:for]
    @ability_result = {}
    ability_hash    = {ability_hash => true} if ability_hash.is_a? Symbol # e.g.: :create => {:create => true}
    ability_hash    = ability_hash.inject({}){|_, i| _.merge({i=>true}) } if ability_hash.is_a? Array # e.g.: [:create, :read] => {:create=>true, :read=>true}
    ability_hash.each do |action, true_or_false|
      @ability_result[action] = ability.can?(action, target)
    end
    !HashDiff.diff(ability_hash, @ability_result).any?
  end

  failure_message_for_should do |user|
    ability_hash,options = expected
    ability_hash         = {ability_hash => true} if ability_hash.is_a? Symbol # e.g.: :create
    ability_hash         = ability_hash.inject({}){|_, i| _.merge({i=>true}) } if ability_hash.is_a? Array # e.g.: [:create, :read] => {:create=>true, :read=>true}
    target               = options[:for]
    message              = "expected User:#{user} to have ability:#{ability_hash} for #{target}, but actual result is #{@ability_result}"
  end
  
  description do
    ability_string = case ability_hash.try(:size)
      when 0, nil
        "have no abilities"
      when 1
        "have ability #{ability_hash.keys.first}: #{ability_hash.values.first}"
      else
        ability_string = ability_hash.to_a.map{ |ability| '%s: %s' % ability }.join( ', ' )
        "have abilities #{ability_string}"
    end
    if options.fetch(:for)
      ability_string += options[:for].is_a?(Class) ? " for #{options[:for].name}" : " for instance of #{options[:for].class.name}"
    end
    ability_string
  end
end
