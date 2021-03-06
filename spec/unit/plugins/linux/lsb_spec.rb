#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

# We do not alter case for lsb attributes and consume them as provided

describe Ohai::System, "Linux lsb plugin" do
  before(:each) do
    @ohai = Ohai::System.new
    Ohai::Loader.new(@ohai).load_plugin(File.join(PLUGIN_PATH, "linux/lsb.rb"), "lsb")
    @plugin = @ohai.plugins[:lsb][:plugin].new(@ohai)
    @plugin[:os] = "linux"
    @plugin.extend(SimpleFromFile)
  end

  describe "on systems with /etc/lsb-release" do
    before(:each) do
      @double_file = double("/etc/lsb-release")
      @double_file.stub(:each).
        and_yield("DISTRIB_ID=Ubuntu").
        and_yield("DISTRIB_RELEASE=8.04").
        and_yield("DISTRIB_CODENAME=hardy").
        and_yield('DISTRIB_DESCRIPTION="Ubuntu 8.04"')
      File.stub(:open).with("/etc/lsb-release").and_return(@double_file) 
      File.stub(:exists?).with("/etc/lsb-release").and_return(true)
    end

    it "should set lsb[:id]" do
      @plugin.run
      @plugin[:lsb][:id].should == "Ubuntu"
    end
  
    it "should set lsb[:release]" do
      @plugin.run
      @plugin[:lsb][:release].should == "8.04"
    end
  
    it "should set lsb[:codename]" do
      @plugin.run
      @plugin[:lsb][:codename].should == "hardy"
    end
  
    it "should set lsb[:description]" do
      @plugin.run
      @plugin[:lsb][:description].should == "Ubuntu 8.04"
    end
  end

  describe "on systems with /usr/bin/lsb_release" do
    before(:each) do
      File.stub(:exists?).with("/etc/lsb-release").and_return(false)
      File.stub(:exists?).with("/usr/bin/lsb_release").and_return(true)
  
      @stdin = double("STDIN", { :close => true })
      @pid = 10
      @stderr = double("STDERR")
      @stdout = double("STDOUT")
      @status = 0

    end
    
    describe "on Centos 5.4 correctly" do
      before(:each) do
        @stdout.stub(:each).
          and_yield("LSB Version: :core-3.1-ia32:core-3.1-noarch:graphics-3.1-ia32:graphics-3.1-noarch").
          and_yield("Distributor ID: CentOS").
          and_yield("Description:  CentOS release 5.4 (Final)").
          and_yield("Release:  5.4").
          and_yield("Codename: Final")
  
        @plugin.stub(:popen4).with("lsb_release -a").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      end

      it "should set lsb[:id]" do
        @plugin.run
        @plugin[:lsb][:id].should == "CentOS"
      end
    
      it "should set lsb[:release]" do
        @plugin.run
        @plugin[:lsb][:release].should == "5.4"
      end
    
      it "should set lsb[:codename]" do
        @plugin.run
        @plugin[:lsb][:codename].should == "Final"
      end
    
      it "should set lsb[:description]" do
        @plugin.run
        @plugin[:lsb][:description].should == "CentOS release 5.4 (Final)"
      end
    end

    describe "on Fedora 14 correctly" do
      before(:each) do
        @stdout.stub(:each).
          and_yield("LSB Version:    :core-4.0-ia32:core-4.0-noarch").
          and_yield("Distributor ID: Fedora").
          and_yield("Description:    Fedora release 14 (Laughlin)").
          and_yield("Release:        14").
          and_yield("Codename:       Laughlin")
  
        @plugin.stub(:popen4).with("lsb_release -a").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      end
  
      it "should set lsb[:id]" do
        @plugin.run
        @plugin[:lsb][:id].should == "Fedora"
      end
    
      it "should set lsb[:release]" do
        @plugin.run
        @plugin[:lsb][:release].should == "14"
      end
    
      it "should set lsb[:codename]" do
        @plugin.run
        @plugin[:lsb][:codename].should == "Laughlin"
      end
    
      it "should set lsb[:description]" do
        @plugin.run
        @plugin[:lsb][:description].should == "Fedora release 14 (Laughlin)"
      end
    end
  end

  it "should not set any lsb values if /etc/lsb-release or /usr/bin/lsb_release do not exist " do
    File.stub(:exists?).with("/etc/lsb-release").and_return(false)
    File.stub(:exists?).with("/usr/bin/lsb_release").and_return(false)
    @plugin.attribute?(:lsb).should be(false)
  end
end
