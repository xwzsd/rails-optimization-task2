# frozen_string_literal: true

require 'json'
require 'pry'
require 'minitest/autorun'
require 'Oj'

DATA_PATH = 'data.txt'.freeze
RESULT_PATH = 'result.json'.freeze
SEPARATOR = ','.freeze

class User
  attr_accessor :sessions, :browsers, :dates, :session_times
  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes
    @sessions = []
    @browsers = []
    @dates = []
    @session_times = []
  end
end

def parse_user(fields)
  fields = fields.split(SEPARATOR)
  User.new({
    'id' => fields[1],
    'first_name' => fields[2],
    'last_name' => fields[3],
    'age' => fields[4],
  })
end

def parse_session(fields)
  fields = fields.split(SEPARATOR)
  {
    'user_id' => fields[1],
    'session_id' => fields[2],
    'browser' => fields[3],
    'time' => fields[4],
    'date' => fields[5],
  }
end

def collect_stats_from_users(user)
  {
    # Собираем количество сессий по пользователям
    'sessionsCount' => user.sessions.size,
    # Собираем количество времени по пользователям
    'totalTime' => "#{user.session_times.sum} min.",
    # Выбираем самую длинную сессию пользователя
    'longestSession' => "#{user.session_times.max} min.",
    # Браузеры пользователя через запятую
    'browsers' => user.browsers.sort.join(', '),
    # Хоть раз использовал IE?
    'usedIE' => user.sessions.any? { |s| s['browser'].upcase =~ /INTERNET EXPLORER/ },
    # Всегда использовал только Chrome?
    'alwaysUsedChrome' => user.sessions.all? { |s| s['browser'].upcase =~ /CHROME/ },
    # Даты сессий через запятую в обратном порядке в формате iso8601
    'dates' => user.dates.sort.reverse
  }
end

def work(disable_gc: true)
  GC.disable if disable_gc

  result_file = File.open(RESULT_PATH, 'w')
  writer = Oj::StreamWriter.new(result_file, {})
  writer.push_object
  writer.push_object('usersStats')

  users = []
  uniqueBrowsers = []
  total_sessions = []

  File.foreach(DATA_PATH, chomp: true) do |line|
    if line.include? 'user'
      user = parse_user(line)
      users << user
    else
      session = parse_session(line)
      users.last.sessions << session
      users.last.browsers << session['browser'].upcase
      users.last.dates << session['date']
      users.last.session_times << session['time'].to_i
      uniqueBrowsers << session['browser'].upcase
      total_sessions << session
    end
  end

  users.each do |user|
    user_data = collect_stats_from_users(user)
    user_name = "#{user.attributes['first_name']}" + ' ' + "#{user.attributes['last_name']}"
    writer.push_value(user_data, user_name)
  end

  writer.pop
  writer.push_value(users.count, 'totalUsers')
  writer.push_value(uniqueBrowsers.uniq.count, 'uniqueBrowsersCount')
  writer.push_value(total_sessions.count, 'totalSessions')
  writer.push_value(uniqueBrowsers.sort.uniq.join(','), 'allBrowsers')
  writer.pop_all
end

class TestMe < Minitest::Test
  def setup
    File.write('result.json', '')
    File.write('data.txt',
'user,0,Leida,Cira,0
session,0,0,Safari 29,87,2016-10-23
session,0,1,Firefox 12,118,2017-02-27
session,0,2,Internet Explorer 28,31,2017-03-28
session,0,3,Internet Explorer 28,109,2016-09-15
session,0,4,Safari 39,104,2017-09-27
session,0,5,Internet Explorer 35,6,2016-09-01
user,1,Palmer,Katrina,65
session,1,0,Safari 17,12,2016-10-21
session,1,1,Firefox 32,3,2016-12-20
session,1,2,Chrome 6,59,2016-11-11
session,1,3,Internet Explorer 10,28,2017-04-29
session,1,4,Chrome 13,116,2016-12-28
user,2,Gregory,Santos,86
session,2,0,Chrome 35,6,2018-09-21
session,2,1,Safari 49,85,2017-05-22
session,2,2,Firefox 47,17,2018-02-02
session,2,3,Chrome 20,84,2016-11-25
')
  end

  def test_result
    work
    expected_result = JSON.parse('{"totalUsers":3,"uniqueBrowsersCount":14,"totalSessions":15,"allBrowsers":"CHROME 13,CHROME 20,CHROME 35,CHROME 6,FIREFOX 12,FIREFOX 32,FIREFOX 47,INTERNET EXPLORER 10,INTERNET EXPLORER 28,INTERNET EXPLORER 35,SAFARI 17,SAFARI 29,SAFARI 39,SAFARI 49","usersStats":{"Leida Cira":{"sessionsCount":6,"totalTime":"455 min.","longestSession":"118 min.","browsers":"FIREFOX 12, INTERNET EXPLORER 28, INTERNET EXPLORER 28, INTERNET EXPLORER 35, SAFARI 29, SAFARI 39","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-09-27","2017-03-28","2017-02-27","2016-10-23","2016-09-15","2016-09-01"]},"Palmer Katrina":{"sessionsCount":5,"totalTime":"218 min.","longestSession":"116 min.","browsers":"CHROME 13, CHROME 6, FIREFOX 32, INTERNET EXPLORER 10, SAFARI 17","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-04-29","2016-12-28","2016-12-20","2016-11-11","2016-10-21"]},"Gregory Santos":{"sessionsCount":4,"totalTime":"192 min.","longestSession":"85 min.","browsers":"CHROME 20, CHROME 35, FIREFOX 47, SAFARI 49","usedIE":false,"alwaysUsedChrome":false,"dates":["2018-09-21","2018-02-02","2017-05-22","2016-11-25"]}}}')
    assert_equal expected_result, JSON.parse(File.read('result.json')).to_h
  end
end
