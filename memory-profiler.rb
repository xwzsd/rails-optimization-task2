require 'memory_profiler'
require_relative 'task-2'

report = MemoryProfiler.report do
  work(disable_gc: false)
end

report.pretty_print(to_file: 'mem_reports/report.txt', scale_bytes: true)
