require File.dirname(__FILE__) + '/spec_helper'
require 'rbing'

describe "RBing" do
  before :each do
    @bing = RBing.new
  end
  
  it "should provide an ad search method" do
    @bing.should respond_to(:ad)
  end
  
  it "should provide an image search method" do
    @bing.should respond_to(:image)
  end
  
  it "should provide an instant_answer search method" do
    @bing.should respond_to(:instant_answer)
  end
  
  it "should provide a news search method" do
    @bing.should respond_to(:news)
  end
  
  it "should provide a phonebook search method" do
    @bing.should respond_to(:phonebook)
  end
  
  it "should provide a related_search method" do
    @bing.should respond_to(:related_search)
  end
  
  it "should provide an spell method" do
    @bing.should respond_to(:spell)
  end
  
  it "should provide a web search method" do
    @bing.should respond_to(:web)
  end
  
  it "should return a ResponseData object" do
    @bing.web("ruby").should be_a(RBing::ResponseData)
  end
  
  it "should return search results" do
    @bing.web("ruby").web.results.should_not be_empty
  end
end
