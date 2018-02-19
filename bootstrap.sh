rm -f Gemfile.lock Gemfile Rakefile
wget https://raw.githubusercontent.com/progit/progit2-pub/master/Gemfile
wget https://raw.githubusercontent.com/progit/progit2-pub/master/Rakefile

if [[ $TRAVIS_REPO_SLUG == "progit/progit2-zh" ]] || [[ $TRAVIS_REPO_SLUG == "progit/progit2-ja" ]]
then
    echo "gem 'asciidoctor-pdf-cjk', '~> 0.1.3'" >> Gemfile
    echo "gem 'asciidoctor-pdf-cjk-kai_gen_gothic', '~> 0.1.1'" >> Gemfile
fi

