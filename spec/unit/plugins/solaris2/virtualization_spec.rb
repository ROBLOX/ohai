#
# Author:: Sean Walbran (<seanwalbran@gmail.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

describe Ohai::System, "Solaris virtualization platform" do
  before(:each) do
    @ohai = Ohai::System.new
    Ohai::Loader.new(@ohai).load_plugin(File.join(PLUGIN_PATH, "solaris2/virtualization.rb"), "svirt")
    @plugin = @ohai.plugins[:svirt][:plugin].new(@ohai)
    @plugin[:os] = "solaris2"
    @plugin.extend(SimpleFromFile)

    # default to all requested Files not existing
    File.stub(:exists?).with("/usr/sbin/psrinfo").and_return(false)
    File.stub(:exists?).with("/usr/sbin/smbios").and_return(false)
    File.stub(:exists?).with("/usr/sbin/zoneadm").and_return(false)
  end

  describe "when we are checking for kvm" do
    before(:each) do
      File.should_receive(:exists?).with("/usr/sbin/psrinfo").and_return(true)
      @stdin = double("STDIN", { :close => true })
      @pid = 10
      @stderr = double("STDERR")
      @stdout = double("STDOUT")
      @status = 0
    end

    it "should run psrinfo -pv" do
      @plugin.should_receive(:popen4).with("/usr/sbin/psrinfo -pv").and_return(true)
      @plugin.run
    end

    it "Should set kvm guest if psrinfo -pv contains QEMU Virtual CPU" do
      @stdout.stub(:read).and_return("QEMU Virtual CPU") 
      @plugin.stub(:popen4).with("/usr/sbin/psrinfo -pv").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @plugin.run
      @plugin[:virtualization][:system].should == "kvm"
      @plugin[:virtualization][:role].should == "guest"
    end

    it "should not set virtualization if kvm isn't there" do
      @plugin.should_receive(:popen4).with("/usr/sbin/psrinfo -pv").and_return(true)
      @plugin.run
      @plugin[:virtualization].should == {}
    end
  end

  describe "when we are parsing smbios" do
    before(:each) do
      File.should_receive(:exists?).with("/usr/sbin/smbios").and_return(true)
      @stdin = double("STDIN", { :close => true })
      @pid = 20
      @stderr = double("STDERR")
      @stdout = double("STDOUT")
      @status = 0
    end

    it "should run smbios" do
      @plugin.should_receive(:popen4).with("/usr/sbin/smbios").and_return(true)
      @plugin.run
    end

    it "should set virtualpc guest if smbios detects Microsoft Virtual Machine" do
      ms_vpc_smbios=<<-MSVPC
ID    SIZE TYPE
1     72   SMB_TYPE_SYSTEM (system information)

  Manufacturer: Microsoft Corporation
  Product: Virtual Machine
  Version: VS2005R2
  Serial Number: 1688-7189-5337-7903-2297-1012-52

  UUID: D29974A4-BE51-044C-BDC6-EFBC4B87A8E9
  Wake-Up Event: 0x6 (power switch)
MSVPC
      @stdout.stub(:read).and_return(ms_vpc_smbios) 
       
      @plugin.stub(:popen4).with("/usr/sbin/smbios").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @plugin.run
      @plugin[:virtualization][:system].should == "virtualpc"
      @plugin[:virtualization][:role].should == "guest"
    end

    it "should set vmware guest if smbios detects VMware Virtual Platform" do
      vmware_smbios=<<-VMWARE
ID    SIZE TYPE
1     72   SMB_TYPE_SYSTEM (system information)

  Manufacturer: VMware, Inc.
  Product: VMware Virtual Platform
  Version: None
  Serial Number: VMware-50 3f f7 14 42 d1 f1 da-3b 46 27 d0 29 b4 74 1d

  UUID: a86cc405-e1b9-447b-ad05-6f8db39d876a
  Wake-Up Event: 0x6 (power switch)
VMWARE
      @stdout.stub(:read).and_return(vmware_smbios)
      @plugin.stub(:popen4).with("/usr/sbin/smbios").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @plugin.run
      @plugin[:virtualization][:system].should == "vmware"
      @plugin[:virtualization][:role].should == "guest"
    end

    it "should run smbios and not set virtualization if nothing is detected" do
      @plugin.should_receive(:popen4).with("/usr/sbin/smbios").and_return(true)
      @plugin.run
      @plugin[:virtualization].should == {}
    end
  end

  it "should not set virtualization if no tests match" do
    @plugin.run
    @plugin[:virtualization].should == {}
  end
end


