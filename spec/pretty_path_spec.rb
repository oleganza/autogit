require File.dirname(__FILE__) + "/spec_helper"

describe AutoGit.method(:pretty_path_for_url) do
  
  def assert(url, result)
    AutoGit.pretty_path_for_url(url).should == result
  end
  
  it "should parse all kinds of valid URLs" do
    assert("rsync://host.xz/path/to/repo.git/",           "host.xz-path-to-repo")
    assert("http://host.xz/path/to/repo.git/",            "host.xz-path-to-repo")
    assert("git://host.xz/~user/path/to/repo.git/",       "host.xz-~user-path-to-repo")
    assert("git://host.xz:123/~/path/to/repo.git/",       "host.xz.123-~-path-to-repo")
    assert("ssh://user@host.xz:123/~/path/to/repo.git/",  "user@host.xz.123-~-path-to-repo")
    assert("file:///path/to/repo.git/",                   "localhost-path-to-repo")
    assert("/path/to/repo.git/",                          "localhost-path-to-repo")
    
    assert("git://host.xz/path/to/repo.git",              "host.xz-path-to-repo")
    assert("git://host.xz/path/to/repo/",                 "host.xz-path-to-repo")
    assert("git://host.xz/path/to/repo",                  "host.xz-path-to-repo")
    assert("git://host.xz/path/to/repo.blah",             "host.xz-path-to-repo.blah")
  end
  
end
