# Include pundit functions
# require "pundit/rspec"
require "active_support/core_ext/array/conversions"

module Pundit
  module RSpec
    module Matchers
      extend ::RSpec::Matchers::DSL

      matcher :permit do |action|
        match do |policy|
          policy.public_send("#{action}?")
        end
      
        failure_message do |policy|
          "#{policy.class} does not permit #{action} on #{policy.record} for #{policy.user.inspect}."
        end
      
        failure_message_when_negated do |policy|
          "#{policy.class} does not forbid #{action} on #{policy.record} for #{policy.user.inspect}."
        end
      end
    end

    module DSL
      def permissions(*list, &block)
        describe(list.to_sentence, :permissions => list, :caller => caller) { instance_eval(&block) }
      end
    end

    module PolicyExampleGroup
      include Pundit::RSpec::Matchers

      def self.included(base)
        base.metadata[:type] = :policy
        base.extend Pundit::RSpec::DSL
        super
      end
    end
  end
end

RSpec.configure do |config|
  if RSpec::Core::Version::STRING.split(".").first.to_i >= 3
    config.include(Pundit::RSpec::PolicyExampleGroup, {
      :type => :policy,
      :file_path => /spec\/policies/,
    })
  else
    config.include(Pundit::RSpec::PolicyExampleGroup, {
      :type => :policy,
      :example_group => { :file_path => /spec\/policies/ }
    })
  end
end