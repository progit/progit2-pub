rm -f Gemfile.lock Gemfile Rakefile
if grep "= Pro Git" progit.asc >/dev/null
then
    wget -O Gemfile https://raw.githubusercontent.com/progit/progit2-pub/master/Gemfile.new
else
    wget https://raw.githubusercontent.com/progit/progit2-pub/master/Gemfile
fi
wget https://raw.githubusercontent.com/progit/progit2-pub/master/Rakefile
