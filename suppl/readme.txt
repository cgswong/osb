Oracle Service Bus
==================

The following supplemental or dependent software are required for the successful setup of
the Oracle Service Bus (OSB) software stack:

  - Oracle Grid Infrastructure (GI) 11.2.0.4
    - p13390677_112040_Linux-x86-64_1of7.zip
    - p13390677_112040_Linux-x86-64_2of7.zip
    
  - Oracle Database 11.2.0.4
    - p13390677_112040_Linux-x86-64_3of7.zip
    
  - Oracle JRockit 1.6u45R28.2.7-4.1.0
    - jrockit-jdk1.6.0_45-R28.2.7-4.1.0-linux-x64.bin
    
  - Oracle WebLogic Server (WLS) 10.3.6
    - wls1036_generic.jar

  - Repository Configuration Utility (RCU) 11.1.1.7*
    - rcu-11.1.1.7_linx64-custom.zip

* RCU is provided outside this distribution given requirements for SYSDBA access to the repository
database when creating the required OSB schemas. A DBA will typically be responsible for running the
package.
    
To Do
-----
1. Packaging of the Oracle GI and Database stacks into a cloned software package with applied
patches for more convenient deployment and quicker installation.

2. Packaging of WLS into a cloned software package with applied PSU and patches for more convenient
deployment and quicker installation.