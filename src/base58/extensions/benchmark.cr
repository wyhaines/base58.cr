require "colorize"
require "./colorize"
require "benchmark"

module Benchmark
  def self.ips(calculation = 5, warmup = 2, interactive = STDOUT.tty?, &)
    {% if !flag?(:release) %}
      puts "Warning: benchmarking without the `--release` flag won't yield useful results"
    {% end %}

    job = ::Benchmark::IPS::Job.new(calculation, warmup, interactive)
    yield job
    job.execute
    job.report
    job
  end

  module IPS
    class Entry
      property label : String | Colorize::Object(String)
      property? separator : Bool = false
      setter ran : Bool = false

      def initialize(label : String | Colorize::Object(String), action : ->)
        @label = label
        @action = action
      end

      def calculate_stats(samples) : Nil
        if separator?
          @ran = true
          @size = 0
          @mean = 0
          @variance = 0
          @stddev = 0
          @relative_stddev = 0
          @slower = 0
          @bytes_per_op = 0
        else
          @ran = true
          @size = samples.size
          @mean = samples.sum.to_f / size.to_f
          @variance = (samples.reduce(0) { |acc, i| acc + ((i - mean) ** 2) }).to_f / size.to_f
          @stddev = Math.sqrt(variance)
          @relative_stddev = 100.0 * (stddev / mean)
        end
      end
    end

    class Job
      def initialize(calculation = 5, warmup = 2, interactive = STDOUT.tty?)
        @interactive = !!interactive
        @warmup_time = warmup.seconds
        @calculation_time = calculation.seconds
        @items = [] of Entry
        print "\e[s" if @interactive
      end

      def separator(label) : Benchmark::IPS::Entry
        item = Entry.new(label, ->{})
        item.separator = true
        @items << item

        item
      end

      def separator(label, &action) : Benchmark::IPS::Entry
        item = Entry.new(label, action)
        item.separator = true
        @items << item

        item
      end

      def execute : Nil
        run_warmup
        run_calculation
        run_comparison
      end

      def report : Nil
        print "\e[2J\e[H" if @interactive
        # print "\e[2J\e[u\e[0J\e[u"
        max_label = ran_items.max_of &.label.size
        max_compare = ran_items.max_of &.human_compare.size
        max_bytes_per_op = ran_items.max_of &.bytes_per_op.humanize(base: 1024).size

        ran_items.each do |item|
          if item.separator?
            printf "%s\n", "".rjust(max_label - count_non_control_characters(item.label)) + item.label.to_s
            item.action.call
          else
            fastest = item.human_compare == "fastest"
            printf "#{fastest ? "\e[4m" : ""}%s %s (%s) (±%5.2f%%)  %sB/op  %s#{fastest ? "\e[0m" : ""}\n",
              item.label.rjust(max_label),
              item.human_mean,
              item.human_iteration_time,
              item.relative_stddev,
              item.bytes_per_op.humanize(base: 1024).rjust(max_bytes_per_op),
              @interactive && fastest ? "".rjust(max_compare - 7) + "fastest".colorize.green.bold.to_s : item.human_compare.rjust(max_compare)
          end
        end
      end

      private def run_warmup
        print "\e[2J\e[H" if @interactive
        @items.each_with_index do |item, index|
          print "\rWarming up [\e[48;5;231m#{" " * index}\e[0m\e[48;5;240m#{" " * (@items.size - index - 1)}\e[0m]" if @interactive
          next if item.separator?

          GC.collect

          count = 0
          elapsed = Time.measure do
            target = Time.monotonic + @warmup_time

            while Time.monotonic < target
              item.call
              count += 1
            end
          end

          item.set_cycles(elapsed, count)
        end
        print "\e[2K"
      end

      private def run_calculation
        @items.each do |item|
          if item.separator?
            item.calculate_stats([] of Int32)
            next
          end

          GC.collect

          measurements = [] of Time::Span
          bytes = 0_i64
          cycles = 0_i64

          target = Time.monotonic + @calculation_time

          loop do
            elapsed = nil
            bytes_taken = Benchmark.memory do
              elapsed = Time.measure { item.call_for_100ms }
            end
            bytes += bytes_taken
            cycles += item.cycles
            measurements << elapsed.not_nil!
            break if Time.monotonic >= target
          end

          ips = measurements.map { |m| item.cycles.to_f / m.total_seconds }
          item.calculate_stats(ips)

          item.bytes_per_op = (bytes.to_f / cycles.to_f).round.to_u64

          if @interactive
            run_comparison
            report
          end
        end
      end

      private def run_comparison
        fastest = ran_items.reject(&.separator?).max_by(&.mean)
        ran_items.reject(&.separator?).each do |item|
          item.slower = (fastest.mean / item.mean).to_f
        end
      end

      private def count_non_control_characters(string)
        string.each_char.count { |char| !char.ascii_control? }
      end
    end
  end
end
