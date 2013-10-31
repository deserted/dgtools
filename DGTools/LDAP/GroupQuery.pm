package DGTools::LDAP::GroupQuery;
use strict;
use warnings;
use Net::LDAP;

sub new {
    my ($class, $host, $DN, $user, $pass) = @_;
    my $self = bless {}, $class;
	$self->{LDAPHost} = $host;
	$self->{BaseDN} = $DN;
	$self->{LDAPUser} = $user;
	$self->{LDAPPass} = $pass;
    return $self;
}

sub GetMembers {
	my $self = shift;
	my ($group, $userOU, $recursion) = @_;
	if ($recursion > 10) {
		print "Looping more then 10 deep currently on group $group, there is likely a circular reference in group membership. exiting!\n";
		exit 1;
	}
	$recursion++;

	## Configure filter for matching group by name
	my $LDAPFilter = '(&(objectClass=group)(cn='.$group.'))';
	my $ldap = Net::LDAP->new($self->{LDAPHost}) or die "$@";
	$ldap->bind("$self->{LDAPUser}", password=> "$self->{LDAPPass}");
	#generate search results returning the member attribute for the supplied group
	my $result = $ldap->search( base=>"$self->{BaseDN}", filter=>"$LDAPFilter",attrs=>['member'], scope => "sub");
	if ($result->code) {
		print $result->error."\n";
		exit 1;
	}
	if ($result->count > 0) {
		my $entry = $result->entry;
		my @members = $entry->get_value('member');
		my @users;
		foreach my $member (@members) {
			if ($member =~ /OU=Users XP/) {
				$member =~ /CN=(.*),OU/;
				my $user =  $1;
				$user =~ s/\\//g;
				$user =~ s/,OU.*//;
				push @users, $self->getUsername($user, $userOU);
			} elsif ($member =~ /OU=GCC Groups/) {
				$member =~ /CN=(.*),OU/;
				my $subGroup = $1;
				$subGroup =~ s/\\//g;
				$subGroup =~ s/,OU.*//;
				push @users, $self->GetMembers($subGroup, $userOU, $recursion);

			}

		}
		$ldap->unbind;
		return @users;
	}

	return 0;

}

sub getUsername {
	my ($self, $user, $userBaseDN) = @_;
	##				 '(&(objectClass=group)(cn='.$group.'))'
	my $LDAPFilter = '(&(objectClass=person)(cn='.$user.'))';
	my $ldap = Net::LDAP->new($self->{LDAPHost}) or die "$@";
	$ldap->bind("$self->{LDAPUser}", password=> "$self->{LDAPPass}");
	## Query ad again to get the sAMAccountName
	my $userResult = $ldap->search( base=>"$userBaseDN", scope=>'sub', filter=>"$LDAPFilter", attrs=>['sAMAccountName']);
	if ($userResult->code) {
		print $userResult->error." Error code: ". $userResult->code ."\n";
		exit 1;
	}
	my $userEntry = $userResult->entry;
	my $userName = $userEntry->get_value('sAMAccountName');
	$ldap->unbind;
	return $userName;
}


1;