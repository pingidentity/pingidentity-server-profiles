# Purpose
This directory contains example server profiles for configuring SSO with PingOne for a
pingdataconsole container. This feature is only available in pingdataconsole and pingdirectory
versions 8.2.0.0 or later.

## PingOne configuration
Some steps will need to be taken in PingOne to enable SSO to the PingData Console, including
creating an application and a user. See the comments in 13-enable-console-sso.dsconfig and
the PingDirectory documentation ("Configuring PingOne to use SSO for the PingData Administrative
Console") for more information.

## PingDirectory configuration
The necessary PingDirectory configuration is included in the 13-enable-console-sso.dsconfig
file in the pingdirectory profile. Root user DNs for SSO can be created in the 12-root-dns.dsconfig file.
One example root user DN (Jane Smith, username jsmith) is already configured.

### Required PingDirectory variables to enable SSO
**PD_CONSOLE_SSO_ISSUER_URI**
The Issuer defined in the PingOne application.

## PingDataConsole configuration
The necessary PingDataConsole configuration is included in the application.yml.subst file in the
pingdataconsole profile, in the PingData.SSO.OIDC section.

### Required PingDataConsole variables to enable SSO
**PD_CONSOLE_SSO_ENABLED**
Whether to enable SSO with PingOne for the PingDataConsole

**PD_CONSOLE_SSO_ISSUER_URI**
The Issuer defined in the PingOne application.

**PD_CONSOLE_SSO_CLIENT_ID**
The Client ID defined in the PingOne application.

**PD_CONSOLE_SSO_CLIENT_SECRET**
The Client Secret defined in the PingOne application.


