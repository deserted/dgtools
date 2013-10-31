dgtools
=======

Dansguardian Tools, initially providing methods to pull Group membership from LDAP/Active Directory and generate the filtergrouplist file for users.


## Usage

This package currently supports querying LDAP or AD for members of a defined set of groups, fed into a number of filter groups

Currently this only supports a dans config of 3 filter groups, a filter1 with no web access, filter2 as the general access, filter3 being an elevated group - this can either be an unrestricted group, or a filtergroup with it's own filter lists.

This package has been created for internal use at Glenorchy City Council, but is released under the GPL in case others find it useful.

DGTools requires File::Copy and Net::LDAP
