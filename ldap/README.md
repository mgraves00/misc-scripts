# LDAP Helper fiels

These scripts are used to assist with manipulating LDAP entries.

- *ldap.env* Used to place static values for use by other scripts.  Because
  passwords could be in there this file is sensitive.  The scripts will look
  for this file in /etc/ldap.env, /etc/openldap/ldap.env,
  /usr/local/etc/ldap.env and ~/.ldap.env .

- *ldapuser* Used to manipulate user records.  Use ldpauser -h for options.

- *ldapgroup* Used to manipulate group records.  Use ldapgroup -h for options.

- *init_schema.sh* Used to create the initial schema for LDAP.

- *upload_ldif.sh* Used to upload an ldif file to LDAP.

- *modify_data.sh* Used to add/remove/delete data within a DN.

- *delete_all.sh*  Used to delete all records within a LDAP server.

