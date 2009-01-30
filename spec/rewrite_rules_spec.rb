require File.dirname(__FILE__) + "/spec_helper"

describe AutoGit.method(:rewrite) do
  
  before(:each) do
    @obj = Object.new
    @obj.extend(AutoGit)
    @qbf = "Quick brown fox"
  end
  
  it "should respond to #rewrite_rules" do
    @obj.rewrite_rules.should == []
  end
  
  it "should accept regexp and block with captures as arguments" do
    @obj.rewrite(%r{(\w+) (\w+)}) do |full_string, quick, brown|
      full_string.should == @qbf
      quick.should == "Quick"
      brown.should == "brown"
      :result
    end
    @obj.rewrite_rules.first.call(@qbf).should == :result
  end
  
  it "should accept string and block with single argument" do 
    @obj.rewrite(@qbf) do |full_string|
      full_string.should == @qbf
      :result
    end
    @obj.rewrite_rules.first.call(@qbf).should == :result
  end

  it "should accept string and string result" do
    @obj.rewrite(@qbf, "phrase")
    @obj.rewrite_rules.first.call(@qbf).should == "phrase"
  end
  
  it "should accept string and nil" do
    @obj.rewrite(@qbf, nil)
    @obj.rewrite_rules.first.call(@qbf).should == nil
  end
  
  it "should accept just string to remove url from list" do
    @obj.rewrite(@qbf)
    @obj.rewrite_rules.first.call(@qbf).should == nil
  end
  
  it "should accept just regexp to remove url from list" do 
    @obj.rewrite(%r{.*})
    @obj.rewrite_rules.first.call(@qbf).should == nil
  end
    
  it "should return argument if not matched" do
    AutoGit::RewriteRule.new("a", proc{|*_| "b"}).call("c").should == "c"
  end
  
  it "should filter a list of urls with a list of rules" do 
    @obj.filter_urls([
      proc {|url| url == "a" ? nil : url  },                   # remove "a"
      proc {|url| url == "b" ? ["b", "b1", "b2"] : url  },     # duplicate "b"
      proc {|url| url == "c" ? ["c", "c1", "c2"] : url  },     # duplicate "c"
      proc {|url| url == "b" ? "d" : url  },                   # rewrite "b" -> "d"
      proc {|url| url == "c2" ? nil : url  },                  # remove "c2"
    ], %w[a b c]).should == %w[d b1 b2 c c1 ]
  end
  
end
