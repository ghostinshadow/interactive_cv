class DocumentEnqueueValidator
	
  def initialize(opts = {})
    @feedback = opts.fetch(:feedback)
    @queue_name = opts.fetch(:queue_name, "documents")
    @feedback_filter = ->(e) { e["args"].last["feedback"] == @feedback}
  end

  def task_valid_to_enqueue?
    group_task_present_in_queue? && group_task_processing_now?
  end
  
  private

  def task_present_in_queue?
    samples = Resque.sample_queues[@queue_name][:samples]
    return false unless samples.any?
    samples.select(&@feedback_filter).any?
  end

  def task_processing_now?
    given_queue_workers = Resque.workers.select{|w| w.queues.include?(@queue_name)}
    return false unless given_queue_workers.any?
    active_workers = given_queue_workers.reject{|w| w.processing.blank? }
    return false unless active_workers.any?
    active_workers.map{|w| w.processing["payload"] }.select(&@feedback_filter).any?
  end

end