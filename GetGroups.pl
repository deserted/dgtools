#!/usr/bin/perl -w

#    Copyright 2013 Tim Allingham
#    For questions, comments or bug reports you can contact
#    me at tim@timallingham.net
#		 This file is part of the DGTools package.
#
#    DGTools is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    DGTools is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with DGTools.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use lib 'DGTools';
use DGTools::LDAP::GroupQuery;
use File::Copy;
use Config::Simple;

my $cfg =  Config::Simple->new('DansGroups.cfg');


my $ldap = $cfg->get_block('ldap');
## Variable setup
## Location of dansguardian filtergroupslist file
my $filterListFile = ($cfg->param('dansguardian.filterlist') ? $cfg->param('dansguardian.filterlist') : '/etc/dansguardian/lists/filtergroupslist');

## LDAP query details
## LDAP Host
my $LDAPHost = $ldap->{'host'};

## BaseDN for LDAP Lookup
my $LDAPGroupDN = $ldap->{'groupdn'};
my $LDAPUserDN = $ldap->{'userdn'};

## Login details for LDAP
my $LDAPUsername = $ldap->{'username'};
my $LDAPPassword = $ldap->{'password'};

## Define a temporary directory for generating the file
my $tempDir = ($cfg->param('general.tempfolder') ? $cfg->param('general.tempfolder') : '/tmp');


my $groups = $cfg->get_block('groups');

#################################################################
## --- No modifications should be required below this line --- ##
#################################################################

## Open LDAP handle to server
my $queryHandle = DGTools::LDAP::GroupQuery->new($LDAPHost, $LDAPGroupDN, $LDAPUsername, $LDAPPassword);

##Define a temp file for the config to write to
my $tempfile = $tempDir.'/dansfilter.tmp';
my %users;

## Retrieve list of Users for each group, then feed them into the %users hash
## If a user is in an elevated group, it will not be replaced with the standard group
foreach my $groupName (keys %{$groups}) {
	my @members = $queryHandle->GetMembers($groupName, $LDAPUserDN, 1);
	foreach my $member (@members) {
		if ((not exists $users{$member}) || $users{$member} ne 'filter3') {
			$users{$member} = $groups->{$groupName};
		}


	}
}
open(my $tmpfile, '>', $tempfile) or die "Could not open file $tempDir/dansfilter.tmp";
foreach my $user (keys %users) {
	print $tmpfile "$user=$users{$user}\n";
}
close($tmpfile);

# Replace the old file
unlink $filterListFile;
move ($tempfile, $filterListFile);
