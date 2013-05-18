require 'spec_helper'

describe AccountPlan do

  PROVIDER_COSTS = %w( 0.00, 0.01, 0.02, 0.03, 0.04, 0.044, 0.077, 0.10, 0.11, 1.00, 1.50, 2.00, 100.00 ).map{ |e| -BigDecimal.new(e) }
  ADDITION_VALUES = %w( 0.0, 0.001, 0.01, 0.1, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0 ).map{ |e| -BigDecimal.new(e) }
  MULTIPLIER_VALUES = %w( 0.0, 0.8, 0.9, 1.0, 1.001, 1.01, 1.1, 1.11, 1.5, 2.0 ).map{ |e| BigDecimal.new(e) }

  describe '#calculate_phone_number_cost' do

    it "handles all cases of flat charges" do
      ADDITION_VALUES.each do |add_value|
        PROVIDER_COSTS.each do |provider_cost|
          plan = build :account_plan, phone_add: add_value
          plan.calculate_phone_number_cost(provider_cost).should == add_value
        end
      end
    end

    it "handles all cases of multiplier charges" do
      MULTIPLIER_VALUES.each do |mult_value|
        PROVIDER_COSTS.each do |provider_cost|
          plan = build :account_plan, phone_mult: mult_value
          plan.calculate_phone_number_cost(provider_cost).should == provider_cost * mult_value
        end
      end
    end

    it "handles all cases of both flat and multiplier charges" do
      MULTIPLIER_VALUES.each do |mult_value|
        ADDITION_VALUES.each do |add_value|
          PROVIDER_COSTS.each do |provider_cost|
            plan = build :account_plan, phone_add: add_value, phone_mult: mult_value
            plan.calculate_phone_number_cost(provider_cost).should == provider_cost * mult_value + add_value
          end
        end
      end
    end

  end

  describe '#calculate_inbound_call_cost' do  

    it "handles all cases of flat charges" do
      ADDITION_VALUES.each do |add_value|
        PROVIDER_COSTS.each do |provider_cost|
          plan = build :account_plan, call_in_add: add_value
          plan.calculate_inbound_call_cost(provider_cost).should == add_value
        end
      end
    end

    it "handles all cases of multiplier charges" do
      MULTIPLIER_VALUES.each do |mult_value|
        PROVIDER_COSTS.each do |provider_cost|
          plan = build :account_plan, call_in_mult: mult_value
          plan.calculate_inbound_call_cost(provider_cost).should == provider_cost * mult_value
        end
      end
    end

    it "handles all cases of both flat and multiplier charges" do
      MULTIPLIER_VALUES.each do |mult_value|
        ADDITION_VALUES.each do |add_value|
          PROVIDER_COSTS.each do |provider_cost|
            plan = build :account_plan, call_in_add: add_value, call_in_mult: mult_value
            plan.calculate_inbound_call_cost(provider_cost).should == provider_cost * mult_value + add_value
          end
        end
      end
    end

  end

  describe '#calculate_inbound_sms_cost' do  

    it "handles all cases of flat charges" do
      ADDITION_VALUES.each do |add_value|
        PROVIDER_COSTS.each do |provider_cost|
          plan = build :account_plan, sms_in_add: add_value
          plan.calculate_inbound_sms_cost(provider_cost).should == add_value
        end
      end
    end

    it "handles all cases of multiplier charges" do
      MULTIPLIER_VALUES.each do |mult_value|
        PROVIDER_COSTS.each do |provider_cost|
          plan = build :account_plan, sms_in_mult: mult_value
          plan.calculate_inbound_sms_cost(provider_cost).should == provider_cost * mult_value
        end
      end
    end

    it "handles all cases of both flat and multiplier charges" do
      MULTIPLIER_VALUES.each do |mult_value|
        ADDITION_VALUES.each do |add_value|
          PROVIDER_COSTS.each do |provider_cost|
            plan = build :account_plan, sms_in_add: add_value, sms_in_mult: mult_value
            plan.calculate_inbound_sms_cost(provider_cost).should == provider_cost * mult_value + add_value
          end
        end
      end
    end

  end

  describe '#calculate_outbound_sms_cost' do  

    it "handles all cases of flat charges" do
      ADDITION_VALUES.each do |add_value|
        PROVIDER_COSTS.each do |provider_cost|
          plan = build :account_plan, sms_out_add: add_value
          plan.calculate_outbound_sms_cost(provider_cost).should == add_value
        end
      end
    end

    it "handles all cases of multiplier charges" do
      MULTIPLIER_VALUES.each do |mult_value|
        PROVIDER_COSTS.each do |provider_cost|
          plan = build :account_plan, sms_out_mult: mult_value
          plan.calculate_outbound_sms_cost(provider_cost).should == provider_cost * mult_value
        end
      end
    end

    it "handles all cases of both flat and multiplier charges" do
      MULTIPLIER_VALUES.each do |mult_value|
        ADDITION_VALUES.each do |add_value|
          PROVIDER_COSTS.each do |provider_cost|
            plan = build :account_plan, sms_out_add: add_value, sms_out_mult: mult_value
            plan.calculate_outbound_sms_cost(provider_cost).should == provider_cost * mult_value + add_value
          end
        end
      end
    end

  end

end
