openstack-election
==================

A simple set of tools to support nominations and elections for OpenStack BoD, TC and PTLs.

http://en.wikipedia.org/wiki/Cumulative_voting

Proposed API:

GET /nominees/
GET /nominees/<md5-hash-of-email>
POST /nominees
PUT /nominees/<md5-hash-of-email>


