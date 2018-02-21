# coding: utf-8
require 'octokit'

def exec_or_raise(command)
  puts `#{command}`
  if (! $?.success?)
    raise "'#{command}' failed"
  end
end

namespace :book do
  desc 'build basic book formats'
  task :build do

    puts "Generating contributors list"
    exec_or_raise("git shortlog -s --all| grep -v -E '(Straub|Chacon)' | cut -f 2- | column -c 120 > book/contributors.txt")

    # detect if the deployment is using glob
    travis = File.read(".travis.yml")
    version_string = ENV['TRAVIS_TAG'] || '0'
    if travis.match(/file_glob/)
      progit_v = "progit_v#{version_string}"
    else
      progit_v = "progit"
    end
    text = File.read('progit.asc')
    new_contents = text.gsub("$$VERSION$$", version_string).gsub("$$DATE$$", Time.now.strftime("%Y-%m-%d"))
    File.open("#{progit_v}.asc", "w") {|file| file.puts new_contents }

    puts "Converting to HTML..."
    exec_or_raise("bundle exec asciidoctor #{progit_v}.asc")
    puts " -- HTML output at #{progit_v}.html"

    puts "Converting to EPub..."
    exec_or_raise("bundle exec asciidoctor-epub3 #{progit_v}.asc")
    puts " -- Epub output at #{progit_v}.epub"

    exec_or_raise("epubcheck #{progit_v}.epub")

    puts "Converting to Mobi (kf8)..."
    exec_or_raise("bundle exec asciidoctor-epub3 -a ebook-format=kf8 #{progit_v}.asc")
    # remove the fake epub that would shadow the really one
    exec_or_raise("rm progit*kf8.epub")
    puts " -- Mobi output at #{progit_v}.mobi"

    repo = ENV['TRAVIS_REPO_SLUG']
    puts "Converting to PDF... (this one takes a while)"
    if (repo == "progit/progit2-zh")
      exec_or_raise("asciidoctor-pdf-cjk-kai_gen_gothic-install")
      exec_or_raise("bundle exec asciidoctor-pdf -r asciidoctor-pdf-cjk -r asciidoctor-pdf-cjk-kai_gen_gothic -a pdf-style=KaiGenGothicCN #{progit_v}.asc")
    elsif (repo == "progit/progit2-ja")
      exec_or_raise("asciidoctor-pdf-cjk-kai_gen_gothic-install")
      exec_or_raise("bundle exec asciidoctor-pdf -r asciidoctor-pdf-cjk -r asciidoctor-pdf-cjk-kai_gen_gothic -a pdf-style=KaiGenGothicJP #{progit_v}.asc")
    else
      exec_or_raise("bundle exec asciidoctor-pdf #{progit_v}.asc 2>/dev/null")
    end
    puts " -- PDF output at #{progit_v}.pdf"
  end

  desc 'tag the repo with the latest version'
  task :tag do
    api_token = ENV['GITHUB_API_TOKEN']
    if (api_token && (ENV['TRAVIS_PULL_REQUEST'] == 'false') && (ENV['TRAVIS_BRANCH']=='master'))
      repo = ENV['TRAVIS_REPO_SLUG']
      @octokit = Octokit::Client.new(:access_token => api_token)
      begin
        last_version=@octokit.latest_release(repo).tag_name
      rescue
        last_version="2.1.-1"
      end
      new_patchlevel= last_version.split('.')[-1].to_i + 1
      new_version="2.1.#{new_patchlevel}"
      obj = @octokit.create_tag(repo, new_version, "Version " + new_version, ENV['TRAVIS_COMMIT'],
                          'commit',
                          'Automatic build', 'automatic@no-domain.org',
                          Time.now.utc.iso8601)
      @octokit.create_ref(repo, "tags/#{new_version}", obj.sha)
      p "Created tag #{new_version}"
    else
      p 'This only runs on a commit to master'
    end
  end

  desc 'convert book to asciidoctor compatibility'
  task:convert do
    `cp -aR ../progit2/images .`
    `sed -i -e 's!/images/!!' .gitignore`
    `git add images`
    `git rm -r book/*/images`

    chapters = [
      ["01", "introduction"              ],
      ["02", "git-basics"                ],
      ["03", "git-branching"             ],
      ["04", "git-server"                ],
      ["05", "distributed-git"           ],
      ["06", "github"                    ],
      ["07", "git-tools"                 ],
      ["08", "customizing-git"           ],
      ["09", "git-and-other-scms"        ],
      ["10", "git-internals"             ],
      ["A",  "git-in-other-environments" ],
      ["B",  "embedding-git"             ],
      ["C",  "git-commands"              ]
    ]

    crossrefs = {}
    chapters.each { | num, title |
      if num =~ /[ABC]/
        chap = "#{num}-#{title}"
      else
        chap = "ch#{num}-#{title}"
      end
      Dir[File.join ["book","#{num}-#{title}" , "sections","*.asc"]].map { |filename|
        File.read(filename).scan(/\[\[(.*?)\]\]/)
      }.flatten.each { |ref|
        crossrefs[ref] = "#{chap}"
      }
    }

    headrefs = {}
    chapters.each { | num, title |
      if num =~ /[ABC]/
        chap = "#{num}-#{title}"
      else
        chap = "ch#{num}-#{title}"
      end
      Dir[File.join ["book","#{num}-#{title}", "*.asc"]].map { |filename|
        File.read(filename).scan(/\[\[(.*?)\]\]/)
      }.flatten.each { |ref|
        headrefs[ref] = "#{chap}"
      }
    }

    # transform all internal cross refs
    chapters.each { | num, title |
      if num =~ /[ABC]/
        chap = "#{num}-#{title}"
      else
        chap = "ch#{num}-#{title}"
      end
      files = Dir[File.join ["book","#{num}-#{title}" , "sections","*.asc"]] +
              Dir[File.join ["book","#{num}-#{title}" ,"1-*.asc"]]
      p files
      files.each { |filename|
        content = File.read(filename)
        new_contents = content.gsub(/\[\[(.*?)\]\]/, '[[r\1]]').gsub(
          "&rarr;", "→").gsub(/<<(.*?)>>/) { |match|
          ch = crossrefs[$1]
          h = headrefs[$1]
          # p " #{match} -> #{ch}, #{h}"
          if ch
            # if local do not add the file
            if ch==chap
              "<<r#{$1}>>"
            else
              "<<#{ch}#r#{$1}>>"
            end
          elsif h
            if h==chap
              "<<#{chap}>>"
            else
              "<<#{h}##{h}>>"
            end
          end
        }
        File.open(filename, "w") {|file| file.puts new_contents }
      }
    }

    chapters.each { | num, title |
      if num =~ /[ABC]/
        chap = "#{num}-#{title}"
      else
        chap = "ch#{num}-#{title}"
      end
      Dir[File.join ["book","#{num}-#{title}" ,"1*.asc"]].map { |filename|
        content = File.read (filename)
        new_contents = content.gsub(/include::(.*?)asc/) {|match|
          "include::book/#{num}-#{title}/#{$1}asc"}
        `git rm -f #{filename}`
        File.open("#{chap}.asc", "w") {|file|
          file.puts "[##{chap}]\n"
          file.puts new_contents }
        `git add "#{chap}.asc"`
      }
    }
  end
end



task :default => "book:build"
