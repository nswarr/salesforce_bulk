require 'net/https'
require 'xmlsimple'
require 'csv'
require "salesforce_bulk/version"
require 'salesforce_bulk/job'
require 'salesforce_bulk/connection'

module SalesforceBulk
  # Your code goes here...
  class Api

    @@SALESFORCE_API_VERSION = '23.0'

    def initialize(username, password, login_host)
      @connection = SalesforceBulk::Connection.new(username, password, @@SALESFORCE_API_VERSION, login_host)
    end

    def upsert(sobject, records, external_field)
      self.do_operation('upsert', sobject, records, external_field)
    end

    def update(sobject, records)
      self.do_operation('update', sobject, records, nil)
    end

    def create(sobject, records)
      self.do_operation('insert', sobject, records, nil)
    end

    def delete(sobject, records)
      self.do_operation('delete', sobject, records, nil)
    end

    def query(sobject, query)
      self.do_operation('query', sobject, query, nil)
    end

    #private

    def do_operation(operation, sobject, records, external_field)
      job = SalesforceBulk::Job.new(operation, sobject, records, external_field, @connection)

      # TODO: put this in one function
      job_id = job.create_job()
      if(operation == "query")
        batch_id = job.add_query()
      else
        batch_id = job.add_batch()
      end
      job.close_job()

      while true
        status = job.check_batch_status()
        #puts "\nstate is #{state}\n"
        state = status[:state]
        if state != "Queued" && state != "InProgress"
          break
        end
        sleep(2) # wait x seconds and check again
      end

      if state == 'Completed'
        results = job.get_batch_result()
      end

      {
          :status => status,
          :upsert_results => results
      }
    end

  end  # End class
end
