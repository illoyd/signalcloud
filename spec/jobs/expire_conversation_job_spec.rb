require 'spec_helper'

describe ExpireConversationJob, :vcr do

  describe '#find_conversation' do
    let(:conversation) { create(:conversation) }
    subject { ExpireConversationJob.new( conversation.id ) }
    its(:find_conversation) { should eq(conversation) }
  end
  
  describe '#perform' do
    #let(:stencil) { stencils(:test_stencil) }
    #let(:conversation) { stencil.open_conversation( to_number: Twilio::VALID_NUMBER, expected_confirmed_answer: 'YES' ) }
    let(:organization)           { create(:organization, :test_twilio, :with_sid_and_token) }
    let(:stencil)           { create(:stencil, organization: organization) }
    let(:conversation)            { create(:conversation, stencil: stencil, expires_at: 900.seconds.from_now) }
    let(:ready_to_expire_conversation) { create(:conversation, expires_at: 180.seconds.ago, stencil: stencil) }
    let(:sent_conversation)       { create(:conversation, :challenge_sent, stencil: stencil) }
    let(:confirmed_conversation)  { create(:conversation, :challenge_sent, :response_received, :reply_sent, :confirmed, stencil: stencil) }
    let(:denied_conversation)     { create(:conversation, :challenge_sent, :response_received, :reply_sent, :denied, stencil: stencil) }
    let(:failed_conversation)     { create(:conversation, :challenge_sent, :response_received, :reply_sent, :failed, stencil: stencil) }
    let(:expired_conversation)    { create(:conversation, :challenge_sent, :response_received, :reply_sent, :expired, stencil: stencil) }

    context 'when conversation is open' do

      context 'and conversation has not yet passed expiration' do
        subject { ExpireConversationJob.new( conversation.id ) }
        
        it 'does not raise error' do
          expect { subject.perform }.not_to raise_error
        end

        it 'does not change conversation status' do
          expect { subject.perform }.not_to change{conversation.status}
        end

        it 'enqueues a follow-up expire job' do
          expect { subject.perform }.to change{Delayed::Job.count}.by(1)
        end

        it 'does not create a new ledger entry' do
          expect { subject.perform }.not_to change{conversation.stencil.organization.ledger_entries.count}
        end

        it 'does not create a new message' do
          expect { subject.perform }.not_to change{conversation.messages.count}
        end
        
#         it 'enqueues a new expire conversation job' do
#           expect { # Messages count
#             expect { # Ledger entry count
#     
#               # Enqueue job
#               expect { # Job count during enqueue
#                 Delayed::Job.enqueue ExpireConversationJob.new( conversation.id )
#               }.to change{Delayed::Job.count}.from(0).to(1)
#               
#               # Now, work that job!
#               expect{ # Job count after run
#                 expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
#                 @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
#               }.to_not change{Delayed::Job.count}.from(1).to(0)
# 
#               conversation.reload
#     
#             }.to_not change{conversation.stencil.organization.ledger_entries.count}.by(1)
#           }.to_not change{conversation.messages.count}.by(1)
#     
#           # Check that the conversation status has been expired
#           conversation.status.should_not == Conversation::EXPIRED
#         end
      end

      context 'and conversation has passed expiration' do
        it 'expires conversation' do
          expect { # Messages count
            expect { # Ledger entry count
    
              # Enqueue job
              expect { # Job count during enqueue
                Delayed::Job.enqueue ExpireConversationJob.new( ready_to_expire_conversation.id )
              }.to change{Delayed::Job.count}.from(0).to(1)
              
              # Now, work that job!
              expect{ # Job count after run
                expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
                @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
              }.to change{Delayed::Job.count}.from(1).to(0)
              
              ready_to_expire_conversation.reload
    
            }.to_not change{ready_to_expire_conversation.stencil.organization.ledger_entries.count}
          }.to change{ready_to_expire_conversation.messages.count}.by(1)
    
          # Check that the conversation status has been expired
          ready_to_expire_conversation.status.should == Conversation::EXPIRED
        end
      end
    end
    
    context 'when conversation is closed' do
      it 'ignores confirmed conversation' do
        expect { # Messages count
          expect { # Ledger entry count
  
            # Enqueue job
            expect { # Job count during enqueue
              Delayed::Job.enqueue ExpireConversationJob.new( confirmed_conversation.id )
            }.to change{Delayed::Job.count}.from(0).to(1)
            
            # Now, work that job!
            expect{ # Job count after run
              expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
              @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
            }.to change{Delayed::Job.count}.from(1).to(0)
  
            confirmed_conversation.reload
  
          }.to_not change{confirmed_conversation.stencil.organization.ledger_entries.count}.by(1)
        }.to_not change{confirmed_conversation.messages.count}.by(1)
  
        # Check that the conversation has not been changed
        confirmed_conversation.status.should == Conversation::CONFIRMED
      end

      it 'ignores denied conversation' do
        expect { # Messages count
          expect { # Ledger entry count
  
            # Enqueue job
            expect { # Job count during enqueue
              Delayed::Job.enqueue ExpireConversationJob.new( denied_conversation.id )
            }.to change{Delayed::Job.count}.from(0).to(1)
            
            # Now, work that job!
            expect{ # Job count after run
              expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
              @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
            }.to change{Delayed::Job.count}.from(1).to(0)
  
            denied_conversation.reload
  
          }.to_not change{denied_conversation.stencil.organization.ledger_entries.count}.by(1)
        }.to_not change{denied_conversation.messages.count}.by(1)
  
        # Check that the conversation has not been changed
        denied_conversation.status.should == Conversation::DENIED
      end

      it 'ignores failed conversation' do
        expect { # Messages count
          expect { # Ledger entry count
  
            # Enqueue job
            expect { # Job count during enqueue
              Delayed::Job.enqueue ExpireConversationJob.new( failed_conversation.id )
            }.to change{Delayed::Job.count}.from(0).to(1)
            
            # Now, work that job!
            expect{ # Job count after run
              expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
              @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
            }.to change{Delayed::Job.count}.from(1).to(0)
  
            failed_conversation.reload
  
          }.to_not change{failed_conversation.stencil.organization.ledger_entries.count}.by(1)
        }.to_not change{failed_conversation.messages.count}.by(1)
  
        # Check that the conversation has not been changed
        failed_conversation.status.should == Conversation::FAILED
      end

      it 'ignores expired conversation' do
        expect { # Messages count
          expect { # Ledger entry count
  
            # Enqueue job
            expect { # Job count during enqueue
              Delayed::Job.enqueue ExpireConversationJob.new( expired_conversation.id )
            }.to change{Delayed::Job.count}.from(0).to(1)
            
            # Now, work that job!
            expect{ # Job count after run
              expect { @work_results = Delayed::Worker.new.work_off(1) }.to_not raise_error
              @work_results.should eq( [ 1, 0 ] ) # One success, zero failures
            }.to change{Delayed::Job.count}.from(1).to(0)
  
            expired_conversation.reload
  
          }.to_not change{expired_conversation.stencil.organization.ledger_entries.count}.by(1)
        }.to_not change{expired_conversation.messages.count}.by(1)
  
        # Check that the conversation has not been changed
        expired_conversation.status.should == Conversation::EXPIRED
      end
    end

  end #perform
  
end
