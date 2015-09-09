require 'twitter'

# General Settings
MAX_RANK           = 100
EXCEPT_MY_FOLLOWEE = true

# Application Settings
CONSUMER_KEY    = "[Your Application's Consumer Key]"
CONSUMER_SECRET = "[Your Application's Consumer Secret]"

# Target Settings
TARGET_ACCESS_TOKEN        = "[Target's Access Token]"
TARGET_ACCESS_TOKEN_SECRET = "[Target's Access Token Secret]"

# Research Acount Settings
RESEARCH_ACOUNTS_TOKENS = [
  ["[Access Token 1]", "[Access Token Secret 1]"],
  ["[Access Token 2]", "[Access Token Secret 2]"],
  ["[Access Token 3]", "[Access Token Secret 3]"],
  ["[Access Token 4]", "[Access Token Secret 4]"]
]

# Define ResearchAccount Class
class ResearchAccount
  attr_reader :limit_end_point

  def initialize(token, token_secret)
    @client = Twitter::REST::Client.new do |config|  # account setting
      config.consumer_key        = CONSUMER_KEY
      config.consumer_secret     = CONSUMER_SECRET
      config.access_token        = token
      config.access_token_secret = token_secret
    end
    @limit_end_point = nil                           # end point of API limit
  end

  def friend_ids(id = "")                            # get followee list
    @client.friend_ids(id).attrs[:ids]
  end

  def secret_account?(id)                            # judge secret account
    @client.user_timeline(id)
  rescue Twitter::Error::Unauthorized
    true
  else
    false
  end

  def friend_ids_limited?                            # judge friends/ids API limit
    if @limit_end_point != nil
      return true if Time.now.to_i < @limit_end_point
    end
    limited_data = @client.__send__(:perform_get, '/1.1/application/rate_limit_status.json')
    if limited_data[:resources][:friends][:"/friends/ids"][:remaining] == 0
      @limit_end_point = limited_data[:resources][:friends][:"/friends/ids"][:reset]
      true
    else
      @limit_end_point = nil
      false
    end
  end
end

target = ResearchAccount.new(TARGET_ACCESS_TOKEN, TARGET_ACCESS_TOKEN_SECRET)
research_accounts = RESEARCH_ACOUNTS_TOKENS.map{ |t| ResearchAccount.new(t[0], t[1]) }

# Define Count Method
class Array
  def count                                          # count overlap
    k = Hash.new(0)
    self.each{|x| k[x] += 1 }
    return k
  end
end

# Get Target's followees
if target.friend_ids_limited?
  puts "Target's API is being limited. Please wait a minutes and try again."
  exit
end
untreated_followees = target.friend_ids              # untreated followees
TARGET_FOLLOWEES = untreated_followees.size          # number of target's followees
puts "Get complete target's followees."

# 配列の用意
treated_followees   = []                             # treated followees
secret_followees    = []                             # secret followees
followees_followees = []                             # followees' followees

# 調査の実行
puts "Getting data..."

catch :main_loop do
  loop do
    limit_end_point = []                             # end points of API limit
    
    research_accounts.each do |account|
      until account.friend_ids_limited? || untreated_followees.empty?
        followee = untreated_followees.shift
        if account.secret_account?(followee)
          secret_followees << followee
        else
          followees_followees += account.friend_ids(followee)
          treated_followees << followee
        end
        
        str = "-----#{treated_followees.size}/#{TARGET_FOLLOWEES}-----"
        printf str
        printf "\e[#{str.size}D"
        STDOUT.flush
        
        throw :main_loop if treated_followees.size == TARGET_FOLLOWEES
      end
      limit_end_point << account.limit_end_point unless untreated_followees.empty?
    end
  
    until target.friend_ids_limited?
      if secret_followees.empty?
        followee = untreated_followees.shift
      else
        followee = secret_followees.shift
      end
      followees_followees += target.friend_ids(followee)
      treated_followees << followee
      
      str = "-----#{treated_followees.size}/#{TARGET_FOLLOWEES}-----"
      printf str
      printf "\e[#{str.size}D"
      STDOUT.flush
      
      throw :main_loop if treated_followees.size == TARGET_FOLLOWEES
    end
  
    limit_end_point << target.limit_end_point
  
    if limit_end_point.all?                          # if all accounts are limited
      sleep_time = limit_end_point.min - Time.now.to_i
      if sleep_time > 0
        puts "-----#{treated_followees.size}/#{TARGET_FOLLOWEES}-----"
        puts "Waiting for API limit's reset..."
        
        sleep sleep_time
        
        puts "Getting data..."
      end
    end
  end
end

# 結果の分析
puts "-----#{treated_followees.size}/#{TARGET_FOLLOWEES}-----"
puts "Analyzing data..."
result = followees_followees.count                   # count overlap (return: Hash)

if EXCEPT_MY_FOLLOWEE                                # if true, remove target's followees
  treated_followees.each do |f|
    result.delete(f)
  end
end

i = 1
while result.size > MAX_RANK                         # make result no more than MAX_RNAK
  result.reject!{ |key, val| val == i }
  i += 1
end

result = result.sort_by{ |key, val| val }.reverse    # sort by value (return: Array)

# Output HTML
ranking_list = ""
result.each do |a|
  ranking_list += '<li><a href="https://twitter.com/intent/user?user_id=' + a[0].to_s + '.html">' + a[0].to_s + "</a> (" + a[1].to_s + ")</li>\n"
end

ranking_html = <<"HTML"
<!DOCTYPE html><html>
<head>
<meta charset="utf-8">
<title>Ranking</title>

</head>
<body>
<h1>Followee's Followee Rancking</h1>
<ol>

#{ranking_list}
</ol>

</body>
</html>
HTML

unless File.exist?('ranking.html')                   # default file name: ranking.html
  File.open 'ranking.html', 'w' do |html|
    html.write(ranking_html)
  end
  puts "Output result to ranking.html."
else                                                 # avoid overwrite
  i = 1
  i += 1 while File.exist?("ranking-#{i}.html")
  File.open "ranking-#{i}.html", 'w' do |html|
    html.write(ranking_html)
  end
  puts "Output result to ranking-#{i}.html."
end
