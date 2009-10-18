module Redcar
  class Command
    class Executor
      def self.current_environment
        {:win => Redcar.app.windows.first}
      end
      
      def initialize(command_instance, options={})
        @command_instance = command_instance
        @options          = options
      end
      
      def execute
        @command_instance.environment(Executor.current_environment)
        begin
          @command_instance.execute
        rescue Object => e
          @command_instance.error = e
          log_error
        rescue java.lang.StackOverflowError => e
          @command_instance.error = e
          log_error
        end
        record
      end
      
      private
      
      def log_error
        puts "* Error in command #{@command_instance.class}"
        if @command_instance.error.respond_to?(:backtrace)
          puts "  " + @command_instance.error.message.to_s
          puts @command_instance.error.backtrace.map {|l| "  " + l }
        end
      end
      
      def record
        if Redcar.history
          Redcar.history.record(@command_instance)
        end
      end
    end
  end
end