require 'benchmark'
require_relative 'task-2'

puts 'Start'
puts "START MEMORY USAGE: %d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)

time = Benchmark.realtime do
  work(disable_gc: false)
end

puts 'Count objects: '
pp ObjectSpace.count_objects
puts GC.stat

puts 'Finish'
puts "FINISH MEMORY USAGE: %d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)

puts "Time: #{time}"
