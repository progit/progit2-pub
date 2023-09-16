# coding: utf-8
require 'octokit'
require 'github_changelog_generator'
require 'open-uri'
require 'html-proofer'

def exec_or_raise(command)
  puts `#{command}`
  if (! $?.success?)
    raise "'#{command}' failed"
  end
end

module GitHubChangelogGenerator

  #OPTIONS = %w[ user project token date_format output
  #              bug_prefix enhancement_prefix issue_prefix
  #              header merge_prefix issues
  #              add_issues_wo_labels add_pr_wo_labels
  #              pulls filter_issues_by_milestone author
  #              unreleased_only unreleased unreleased_label
  #              compare_link include_labels exclude_labels
  #              bug_labels enhancement_labels
  #              between_tags exclude_tags exclude_tags_regex since_tag max_issues
  #              github_site github_endpoint simple_list
  #              future_release release_branch verbose release_url
  #              base configure_sections add_sections]

  def get_log(&task_block)
    options = Parser.default_options
    yield(options) if task_block

    options[:user], options[:project] = ENV['TRAVIS_REPO_SLUG'].split('/')
    options[:token] = ENV['GITHUB_API_TOKEN']
    options[:unreleased] = false

    generator = Generator.new options
    generator.compound_changelog
  end

  module_function :get_log
end

module BookGenerator

  def build_book(repo)

    lang_match = repo.match(/progit2-([a-z-]*)/)
    if lang_match
      lang = lang_match[1]
    else
      lang = "en"
    end

    begin
      lang_file = "attributes-#{lang}.adoc"

      # Several language files in asciidoc repo have different naming
      if (lang == "zh-tw")
        lang_file = "attributes-zh_TW.adoc"
      elsif (lang == "zh")
        lang_file = "attributes-zh_CN.adoc"
      elsif (lang == "pt-br")
        lang_file = "attributes-pt_BR.adoc"
      end

      l10n_text = URI.open("https://raw.githubusercontent.com/asciidoctor/asciidoctor/master/data/locale/#{lang_file}").read
      File.open(lang_file, 'w') {|file| file.puts l10n_text}

      progit_txt = File.open('progit.asc').read
      if not progit_txt.include?(lang_file)
        progit_txt.gsub!(":doctype: book", "include::#{lang_file}[]\n:doctype: book")
        File.open('progit.asc', 'w') {|file| file.puts progit_txt}
      end
    rescue
      puts "[WARNING] Can not download attributes file #{lang_file}"
    end

    version_string = ENV['TRAVIS_TAG'] || ENV['GITHUB_VERSION'] || `git describe --tags`.chomp
    if version_string.empty?
      version_string = '0'
    end

    date_string = Time.now.strftime("%Y-%m-%d")
    params = "--attribute revnumber='#{version_string}' --attribute revdate='#{date_string}' --attribute lang=#{lang} "

    puts "Generating contributors list"
    exec_or_raise("git shortlog -s --all $translation_origin | grep -v -E '(Straub|Chacon|dependabot)' | cut -f 2- | sort | column -c 110 > book/contributors.txt")

    puts "Converting to HTML..."
    exec_or_raise("bundle exec asciidoctor -a data-uri #{params} progit.asc")
    puts " -- HTML output at progit.html"
    puts " -- Validate HTML file progit.html"
    HTMLProofer.check_file("progit.html", {
                             typhoeus: {
                               accept_encoding: "gzip,deflate,br",
                               ssl_verifypeer: false,
                               ssl_verifyhost: 0},
                             enforce_https: false,
                             check_external_hash: false,
                             ignore_status_codes: [403]
                           }).run

    puts "Converting to EPub..."
    exec_or_raise("bundle exec asciidoctor-epub3 #{params} progit.asc")
    puts " -- Epub output at progit.epub"
    puts " -- Validate EPub file progit.epub"
    exec_or_raise("epubcheck progit.epub")

    if (lang == "zh")
      exec_or_raise("asciidoctor-pdf-cjk-kai_gen_gothic-install")
      exec_or_raise("bundle exec asciidoctor-pdf #{params} -r asciidoctor-pdf-cjk -r asciidoctor-pdf-cjk-kai_gen_gothic -a pdf-style=KaiGenGothicCN progit.asc")
    elsif (lang == "ja")
      exec_or_raise("asciidoctor-pdf-cjk-kai_gen_gothic-install")
      exec_or_raise("bundle exec asciidoctor-pdf #{params} -r asciidoctor-pdf-cjk -r asciidoctor-pdf-cjk-kai_gen_gothic -a pdf-style=KaiGenGothicJP progit.asc")
    elsif (lang == "zh-tw")
      exec_or_raise("asciidoctor-pdf-cjk-kai_gen_gothic-install")
      exec_or_raise("bundle exec asciidoctor-pdf #{params} -r asciidoctor-pdf-cjk -r asciidoctor-pdf-cjk-kai_gen_gothic -a pdf-style=KaiGenGothicTW progit.asc")
    elsif (lang == "ko")
      exec_or_raise("asciidoctor-pdf-cjk-kai_gen_gothic-install")
      exec_or_raise("bundle exec asciidoctor-pdf #{params} -r asciidoctor-pdf-cjk -r asciidoctor-pdf-cjk-kai_gen_gothic -a pdf-style=KaiGenGothicKR progit.asc")
    else
      exec_or_raise("bundle exec asciidoctor-pdf #{params} progit.asc 2>/dev/null")
    end
    puts " -- PDF output at progit.pdf"

  end
  module_function :build_book
end
namespace :book do
  desc 'build basic book formats on Travis'
  task :build do
    repo = ENV['TRAVIS_REPO_SLUG']
    BookGenerator.build_book(repo)
  end

  desc 'build basic book formats on GitHub actions'
  task :build_action do
    repo = ENV['GITHUB_REPOSITORY']
    BookGenerator.build_book(repo)
  end

  desc 'tag the repo with the latest version from Travis'
  task :tag do
    api_token = ENV['GITHUB_API_TOKEN']
    if ((api_token) && (ENV['TRAVIS_PULL_REQUEST'] == 'false'))
      repo = ENV['TRAVIS_REPO_SLUG']
      @octokit = Octokit::Client.new(:access_token => api_token)
      begin
        last_version=@octokit.latest_release(repo).tag_name
      rescue
        last_version="2.1.-1"
      end
      new_patchlevel= last_version.split('.')[-1].to_i + 1
      new_version="2.1.#{new_patchlevel}"
      if  (ENV['TRAVIS_BRANCH']=='master')
        obj = @octokit.create_tag(repo, new_version, "Version " + new_version,
                                  ENV['TRAVIS_COMMIT'], 'commit',
                                  'Automatic build', 'automatic@no-domain.org',
                                  Time.now.utc.iso8601)
        begin
          @octokit.create_ref(repo, "tags/#{new_version}", obj.sha)
          p "Created tag #{last_version}"
        rescue
          raise "[ERROR] Can not create new tag #{new_version}. The ref already exists ???"
        end
      elsif (ENV['TRAVIS_TAG'])
        version = ENV['TRAVIS_TAG']
        changelog = GitHubChangelogGenerator.get_log do |config|
          config[:since_tag] = last_version
        end
        credit_line = "\\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*"
        changelog.gsub!(credit_line, "")
        @octokit.create_release(repo, new_version, {:name => "v#{new_version}", :body => changelog})
        p "Created release #{new_version}"
      else
        p 'This only runs on a commit to master'
      end
    else
      p 'No interaction with GitHub'
    end
  end

  desc 'tag the repo with the latest version from GitHub Actions'
  task :tag_gh do

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
        File.read(filename).scan(/\[\[([_a-z0-9]*?)\]\]/)
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
        new_contents = content.gsub(/\[\[([_a-z0-9]*?)\]\]/, '[[r\1]]').gsub(
          "&rarr;", "→").gsub(/<<([_a-z0-9]*?)>>/) { |match|
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
          else
            p "could not match xref #{$1}"
            "<<#{$1}>>"
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
