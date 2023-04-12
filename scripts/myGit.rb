#!/usr/bin/env ruby

require 'git' # https://github.com/ruby-git/ruby-git

$LOAD_PATH.push( File.expand_path( __FILE__ ) )

def main
  myGit( ARGV[0], ARGV[1..] )
end

def myGit( gitdir, *add_gitignore_whiteist )

  # Dir.mkdir(gitdir)
  # File.exist?(gitdir)
  # st = %x(git -C #{gitdir} init --quiet )
  unless File.directory?( [ gitdir, ".git" ].join( "/" ) )
    Git.init( gitdir )
    gitignore = [
      "# すべてをignore", "*",
      "# 全ディレクトリホワイトリストに追加", "!*/",
      "# 個別ホワイトリスト対象ファイル登録", "!.gitignore",
    ]
    File.open( "#{gitdir}/.gitignore", "w" ) do | f |
      f.puts [ gitignore, add_gitignore_whiteist ].flatten.join("\n")
    end

    %x( git -C #{gitdir} config --local core.autocrlf false --quiet ) # checkout 時 LF のままにする
    %x( git -C #{gitdir} config --local user.name  "anonymous anonymous"     --quiet )
    %x( git -C #{gitdir} config --local user.email "anonymous@do.not.replay" --quiet )
  end

  gg = Git.open( gitdir )

  st = %x( git -C #{gitdir} status --short )
         .gsub( /^.*[[:blank:]]+([^[:blank:]]+)\n/, ' \1' )
  if st.length > 0
    gg.add( :all=>true )

    # st = %x( git -C #{gitdir} commit --message 'auto commit' st} )
    gg.commit_all( 'auto commit' )
  end

end

if __FILE__ == $0 then main end
