# Purpose
This repository serves as an example of how configuration can be stored and passed into a PingDirectory container for runtime customization based on a common image

## motd
A text file that will be used to create the motd on the container when started.

## .sec
Location for secrets (i.e. passwords) to be placed.  It 
is **NOT RECOMENDED** to place secrets, such as passwords, here in 
production instances.  This is used in these examples to help in ease
of use of getting-started profiles.  Standard secrets include:
  - **root-user-password** - Directory Manager password
  - **admin-user-password** - Admin (i.e. dsreplication) password
  - **encryption-password** - Passphrase used for encryption settings

## pd.profile/dsconfig
configuration batches organized in the order in which they should be applied, bearing the .dsconfig extension
For example:
  - 01-first-batch.dsconfig
  - 02-second-batch.dsconfig

## pd.profile/ldif
LDIF files organized by back-end, bearing the .ldif extension.  The format that should be used for 
naming these files is:

   `{back-end name}/NN-{description}.ldif`

The default back-end for PingDirectory is named userRoot, so a good place to start would be for example:
 - **pd.profile/ldif/userRoot/00-dit.ldif** - Contains the entries used to create the skeleton Directory Information Tree (dit)
 - **pd.profile/ldif/userRoot/10-users.ldif** - Contains the user entries
 - **pd.profile/ldif/userRoot/20-groups.ldif** - Contains the group entries

## server-root
In this directory, you can place any file you would like, following the normal layout of the Ping Identity product that the server-profile is intended for.

For example, for PingDirectory:
  - to apply custom schema
    - server-root/pre-setup/config/schema/77-microsoft.ldif
    - server-root/pre-setup/config/schema/99-custom.ldif
  - to deploy your certificates
    - server-root/pre-setup/config/keystore
    - server-root/pre-setup/config/keystore.pin
    - server-root/pre-setup/config/truststore

