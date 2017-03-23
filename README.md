## Oracle Enterprise Manager 13.2.0.0 for Puppet 4

### Software
- linuxamd64_12c_database_1of2.zip  ( 12.1.0.2 )
- linuxamd64_12c_database_2of2.zip
- em13200p1_linux64.bin   ( 13.2.0.0 )
- em13200p1_linux64-2.zip to em13200p1_linux64-7.zip

### Vagrant
Update the local path of the /software share in Vagrantfile to your own DB & EM software location

### EM DB steps
- vagrant up emdb

### EM App steps
- vagrant up emapp

### default urls
- Enterprise Manager Cloud Control URL: https://10.10.10.25:7799/em
- Admin Server URL: https://10.10.10.25:7102/console

````
this information is also available at:

 	/oracle/product/13.2/em/install/setupinfo.txt

 See the following for information pertaining to your Enterprise Manager installation:


 Use the following URL to access:

 	1. Enterprise Manager Cloud Control URL: https://emapp.example.com:7799/em
 	2. Admin Server URL: https://emapp.example.com:7101/console
 	3. BI Publisher URL: https://emapp.example.com:9801/xmlpserver

 The following details need to be provided while installing an additional OMS:

 	1. Admin Server Host Name: emapp.example.com
 	2. Admin Server Port: 7101

 You can find the details on ports used by this deployment at : /oracle/product/13.2/em/install/portlist.ini
````


### passwords
- em weblogic Welcome01
- em sysman Welcome01
- db sys Welcome01