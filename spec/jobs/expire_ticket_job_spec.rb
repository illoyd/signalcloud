require 'spec_helper'

describe ExpireTicketJob do
  before(:all) { VCR.insert_cassette 'expire_ticket_job' }
  after(:all)  { VCR.eject_cassette }

  describe '#find_ticket' do
    let(:ticket) { create(:ticket) }
    subject { ExpireTicketJob.new( ticket.id ) }
    its(:find_ticket) { should eq(ticket) }
  end
  
  describe '#perform' do
    #let(:appliance) { appliances(:test_appliance) }
    #let(:ticket) { appliance.open_ticket( to_number: Twilio::VALID_NUMBER, expected_confirmed_answer: 'YES' ) }
    let(:account)           { create(:account, :test_twilio, :with_sid_and_token) }
    let(:appliance)         { create(:appliance, account: account) }
    let(:ticket)            { create(:ticket, appliance: appliance) }
    let(:ready_to_expire_ticket) { create(:ticket, expires_at: 180.seconds.ago, appliance: appliance) }
    let(:sent_ticket)       { create(:ticket, :challenge_sent, appliance: appliance) }
    let(:confirmed_ticket)  { create(:ticket, :challenge_sent, :response_received, :reply_sent, :confirmed, appliance: appliance) }
    let(:denied_ticket)     { create(:ticket, :challenge_sent, :response_received, :reply_sent, :denied, appliance: appliance) }
    let(:failed_ticket)     { create(:ticket, :challenge_sent, :response_received, :reply_sent, :failed, appliance: appliance) }
    let(:expired_ticket)    { create(:ticket, :challenge_sent, :response_received, :reply_sent, :expired, appliance: appliance) }

    context 'when ticket is open' do

      context 'and ticket has not yet passed expiration' do
        it 'enqueues a new expire ticket job' do
          expect { # Messages count
            expect { # Ledger entry count
    
              # Enqueue job
              expect { # Job count during enqueue
                Delayed::Job.enqueue ExpireTicketJob.new( ticket.id )
              }.to change{Delayed::Job.count}.from(0).to(1)
              
              # Now, work that job!
              expect{ # Job count after run
                expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
                @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
              }.to_not change{Delayed::Job.count}.from(1).to(0)

              ticket.reload
    
            }.to_not change{ticket.appliance.account.ledger_entries.count}.by(1)
          }.to_not change{ticket.messages.count}.by(1)
    
          # Check that the ticket status has been expired
          ticket.status.should_not == Ticket::EXPIRED
        end
      end

      context 'and ticket has passed expiration' do
        it 'expires ticket' do
          expect { # Messages count
            expect { # Ledger entry count
    
              # Enqueue job
              expect { # Job count during enqueue
                Delayed::Job.enqueue ExpireTicketJob.new( ready_to_expire_ticket.id )
              }.to change{Delayed::Job.count}.from(0).to(1)
              
              # Now, work that job!
              expect{ # Job count after run
                expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
                @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
              }.to change{Delayed::Job.count}.from(1).to(0)
              
              ready_to_expire_ticket.reload
    
            }.to_not change{ready_to_expire_ticket.appliance.account.ledger_entries.count}
          }.to change{ready_to_expire_ticket.messages.count}.by(1)
    
          # Check that the ticket status has been expired
          ready_to_expire_ticket.status.should == Ticket::EXPIRED
        end
      end
    end
    
    context 'when ticket is closed' do
      it 'ignores confirmed ticket' do
        expect { # Messages count
          expect { # Ledger entry count
  
            # Enqueue job
            expect { # Job count during enqueue
              Delayed::Job.enqueue ExpireTicketJob.new( confirmed_ticket.id )
            }.to change{Delayed::Job.count}.from(0).to(1)
            
            # Now, work that job!
            expect{ # Job count after run
              expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
              @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
            }.to change{Delayed::Job.count}.from(1).to(0)
  
            confirmed_ticket.reload
  
          }.to_not change{confirmed_ticket.appliance.account.ledger_entries.count}.by(1)
        }.to_not change{confirmed_ticket.messages.count}.by(1)
  
        # Check that the ticket has not been changed
        confirmed_ticket.status.should == Ticket::CONFIRMED
      end

      it 'ignores denied ticket' do
        expect { # Messages count
          expect { # Ledger entry count
  
            # Enqueue job
            expect { # Job count during enqueue
              Delayed::Job.enqueue ExpireTicketJob.new( denied_ticket.id )
            }.to change{Delayed::Job.count}.from(0).to(1)
            
            # Now, work that job!
            expect{ # Job count after run
              expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
              @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
            }.to change{Delayed::Job.count}.from(1).to(0)
  
            denied_ticket.reload
  
          }.to_not change{denied_ticket.appliance.account.ledger_entries.count}.by(1)
        }.to_not change{denied_ticket.messages.count}.by(1)
  
        # Check that the ticket has not been changed
        denied_ticket.status.should == Ticket::DENIED
      end

      it 'ignores failed ticket' do
        expect { # Messages count
          expect { # Ledger entry count
  
            # Enqueue job
            expect { # Job count during enqueue
              Delayed::Job.enqueue ExpireTicketJob.new( failed_ticket.id )
            }.to change{Delayed::Job.count}.from(0).to(1)
            
            # Now, work that job!
            expect{ # Job count after run
              expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
              @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
            }.to change{Delayed::Job.count}.from(1).to(0)
  
            failed_ticket.reload
  
          }.to_not change{failed_ticket.appliance.account.ledger_entries.count}.by(1)
        }.to_not change{failed_ticket.messages.count}.by(1)
  
        # Check that the ticket has not been changed
        failed_ticket.status.should == Ticket::FAILED
      end

      it 'ignores expired ticket' do
        expect { # Messages count
          expect { # Ledger entry count
  
            # Enqueue job
            expect { # Job count during enqueue
              Delayed::Job.enqueue ExpireTicketJob.new( expired_ticket.id )
            }.to change{Delayed::Job.count}.from(0).to(1)
            
            # Now, work that job!
            expect{ # Job count after run
              expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
              @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
            }.to change{Delayed::Job.count}.from(1).to(0)
  
            expired_ticket.reload
  
          }.to_not change{expired_ticket.appliance.account.ledger_entries.count}.by(1)
        }.to_not change{expired_ticket.messages.count}.by(1)
  
        # Check that the ticket has not been changed
        expired_ticket.status.should == Ticket::EXPIRED
      end
    end

  end #perform
  
end
