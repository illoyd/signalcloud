require 'spec_helper'

class BasicJob; def perform; end;  end
class PriorityJob < Struct.new( :priority ); def perform; end; end
class QueueJob < Struct.new( :queue ); def perform; end;  end

describe Jobs do
  let(:priority)      { 10 }
  let(:queue)         { 'test' }
  let(:high_priority) { 5 }
  let(:high_queue)    { 'important' }


  describe '.push' do

    it 'adds a job to the Delayed::Job queue' do
      expect{ Jobs.push BasicJob.new }.to change{Delayed::Job.count}.by(1)
    end
  
    context 'when pushing multiple jobs' do

      it 'adds several jobs to the Delayed::Job queue' do
        expect{ Jobs.push BasicJob.new, BasicJob.new, BasicJob.new }.to change{Delayed::Job.count}.by(3)
      end
  
      it 'adds several jobs to the Delayed::Job queue with default options' do
        expect{ Jobs.push BasicJob.new, BasicJob.new, BasicJob.new, priority: priority, queue: queue }.to change{Delayed::Job.count}.by(3)
      end
  
      it 'applies default priority to all jobs' do
        Jobs.push BasicJob.new, BasicJob.new, BasicJob.new, priority: priority
        Delayed::Job.all { |job| job.priority.should == priority }
      end
  
      it 'applies default queue to all jobs' do
        Jobs.push BasicJob.new, BasicJob.new, BasicJob.new, queue: queue
        Delayed::Job.all { |job| job.queue.should == queue }
      end
  
    end # Multiple jobs context
    
    context 'when job has queue' do
      
      it 'adds a queue job to the Delayed::Job queue' do
        expect{ Jobs.push QueueJob.new(queue) }.to change{Delayed::Job.count}.by(1)
      end

      it 'enqueues with job\'s queue' do
        Jobs.push QueueJob.new(queue)
        Delayed::Job.first.queue.should == queue
      end

      it 'overrides job\'s queue' do
        Jobs.push QueueJob.new(queue), queue: high_queue
        Delayed::Job.first.queue.should == high_queue
      end

    end # Queue job context
    
    context 'when job has priority' do

      it 'adds a priority job to the Delayed::Job queue' do
        expect{ Jobs.push PriorityJob.new(priority) }.to change{Delayed::Job.count}.by(1)
      end
      
      it 'enqueues with job\'s priority' do
        Jobs.push PriorityJob.new(priority)
        Delayed::Job.first.priority.should == priority
      end

      it 'overrides job\'s priority' do
        Jobs.push PriorityJob.new(priority), priority: high_priority
        Delayed::Job.first.priority.should == high_priority
      end

    end # Priority job context

  end

end
