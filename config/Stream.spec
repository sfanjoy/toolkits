#
# Macros
#
%define APP_NAME        Toolkits
%define APP_VERSION     01
%define BRANCH_NAME     main
#
# Pre-amble
#
Summary: Configuration and Admin script for linux servers
Name:  %(echo %APP_NAME)-fAloha
Version: %(echo %APP_VERSION)
Release: 1
Group: fAloha Applications
License: Apache
Packager: devops 
BuildRoot: %{_tmppath}/toolkits
ExclusiveArch: x86_64
Requires: shadow-utils
#
%description
Configuration and Admin scripts for Local Notion Servers

%prep
# current dir is RPM_BUILD_DIR
rm -rf $RPM_BUILD_DIR/Toolkits
# clean up any previous failed builds
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT
cp -r $HOME/projects/toolkits/pkg .
mv pkg toolkits

%build
# current dir is RPM_BUILD_DIR

%install
mkdir -p $RPM_BUILD_ROOT/opt/toolkits
cp -r $RPM_BUILD_DIR/toolkits $RPM_BUILD_ROOT/opt

%clean
rm -rf $RPM_BUILD_ROOT
rm -rf $RPM_BUILD_DIR/toolkits

%pre

%post
chmod 744 /opt/toolkits/bin/*

%postun

%files
%dir /opt/toolkits
/opt/toolkits/*
